import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../providers/theme_provider.dart';
import '../services/ad_service.dart';
import '../utils/language_helper.dart';

/// Fake Call: set a caller, pick a delay, and the phone "rings" with a
/// full-screen incoming call; answer it and a call timer runs. The app must
/// stay open while it waits (no background alarm).
class FakeCallScreen extends StatefulWidget {
  const FakeCallScreen({super.key});

  @override
  State<FakeCallScreen> createState() => _FakeCallScreenState();
}

class _FakeCallScreenState extends State<FakeCallScreen> {
  late final TextEditingController _name;
  late final TextEditingController _subtitle;
  Uint8List? _photo;
  bool _video = false;
  bool _ring = true;
  int _delay = 0;
  static const List<int> delays = [0, 10, 30, 60, 300];

  @override
  void initState() {
    super.initState();
    final isAr = context.read<ThemeProvider>().isArabic;
    _name = TextEditingController(text: LanguageHelper.translate('fc_default_name', isAr));
    _subtitle = TextEditingController(text: LanguageHelper.translate('fc_default_label', isAr));
  }

  @override
  void dispose() {
    _name.dispose();
    _subtitle.dispose();
    super.dispose();
  }

  String _delayLabel(int s, bool isAr) {
    if (s == 0) return LanguageHelper.translate('fc_now', isAr);
    if (s < 60) return '$s ${LanguageHelper.translate('fc_seconds', isAr)}';
    return '${s ~/ 60} ${LanguageHelper.translate('fc_minutes', isAr)}';
  }

  Future<void> _pickPhoto() async {
    final file = await ImagePicker().pickImage(source: ImageSource.gallery, maxWidth: 800, maxHeight: 800);
    if (file == null) return;
    final bytes = await file.readAsBytes();
    if (mounted) setState(() => _photo = bytes);
  }

  Future<void> _start() async {
    final call = _CallSetup(
      name: _name.text.trim().isEmpty ? '?' : _name.text.trim(),
      subtitle: _subtitle.text.trim(),
      photo: _photo,
      video: _video,
      ring: _ring,
    );
    if (_delay > 0) {
      final go = await Navigator.of(context).push<bool>(
        MaterialPageRoute(builder: (_) => _WaitingScreen(seconds: _delay)),
      );
      if (go != true || !mounted) return;
    }
    await Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => _IncomingCallScreen(call: call),
        transitionDuration: Duration.zero,
      ),
    );
    AdService.instance.afterSave();                  // a natural break: same rules as after a saved screenshot
  }

  @override
  Widget build(BuildContext context) {
    final isAr = context.watch<ThemeProvider>().isArabic;
    String t(String key) => LanguageHelper.translate(key, isAr);
    const accent = Color(0xFF6C63FF);

    return Scaffold(
      appBar: AppBar(title: Text(t('fake_call'))),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Center(
            child: GestureDetector(
              onTap: _pickPhoto,
              child: CircleAvatar(
                radius: 48,
                backgroundColor: accent.withValues(alpha: 0.15),
                backgroundImage: _photo != null ? MemoryImage(_photo!) : null,
                child: _photo == null ? const Icon(Icons.add_a_photo_rounded, color: accent, size: 32) : null,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Center(child: Text(t('fc_photo'), style: const TextStyle(fontSize: 12, color: Colors.grey))),
          const SizedBox(height: 20),
          TextField(controller: _name, decoration: InputDecoration(labelText: t('fc_caller_name'))),
          const SizedBox(height: 12),
          TextField(controller: _subtitle, decoration: InputDecoration(labelText: t('fc_caller_label'))),
          const SizedBox(height: 20),
          SegmentedButton<bool>(
            segments: [
              ButtonSegment(value: false, icon: const Icon(Icons.call_rounded), label: Text(t('fc_voice'))),
              ButtonSegment(value: true, icon: const Icon(Icons.videocam_rounded), label: Text(t('fc_video'))),
            ],
            selected: {_video},
            onSelectionChanged: (v) => setState(() => _video = v.first),
          ),
          const SizedBox(height: 20),
          Text(t('fc_when'), style: const TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final s in delays)
                ChoiceChip(
                  label: Text(_delayLabel(s, isAr)),
                  selected: _delay == s,
                  onSelected: (_) => setState(() => _delay = s),
                ),
            ],
          ),
          const SizedBox(height: 12),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(t('fc_ringtone')),
            value: _ring,
            onChanged: (v) => setState(() => _ring = v),
          ),
          if (_delay > 0)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(t('fc_keep_open'), style: const TextStyle(fontSize: 12, color: Colors.grey)),
            ),
          const SizedBox(height: 8),
          FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: accent,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            onPressed: _start,
            icon: const Icon(Icons.phone_in_talk_rounded),
            label: Text(t('fc_start')),
          ),
        ],
      ),
    );
  }
}

class _CallSetup {
  final String name;
  final String subtitle;
  final Uint8List? photo;
  final bool video;
  final bool ring;
  const _CallSetup({
    required this.name,
    required this.subtitle,
    required this.photo,
    required this.video,
    required this.ring,
  });
}

/// A dark, quiet screen while the delay runs, so nobody sees what is coming.
class _WaitingScreen extends StatefulWidget {
  final int seconds;
  const _WaitingScreen({required this.seconds});

  @override
  State<_WaitingScreen> createState() => _WaitingScreenState();
}

class _WaitingScreenState extends State<_WaitingScreen> {
  late int _left = widget.seconds;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_left <= 1) {
        timer.cancel();
        Navigator.of(context).pop(true);
        return;
      }
      setState(() => _left--);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isAr = context.watch<ThemeProvider>().isArabic;
    final m = (_left ~/ 60).toString().padLeft(2, '0');
    final s = (_left % 60).toString().padLeft(2, '0');
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('$m:$s', style: const TextStyle(color: Colors.white24, fontSize: 28)),
              const SizedBox(height: 24),
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text(LanguageHelper.translate('cancel', isAr),
                    style: const TextStyle(color: Colors.white38)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  final _CallSetup call;
  final double radius;
  const _Avatar({required this.call, required this.radius});

  @override
  Widget build(BuildContext context) {
    final photo = call.photo;
    return CircleAvatar(
      radius: radius,
      backgroundColor: Colors.white24,
      backgroundImage: photo != null ? MemoryImage(photo) : null,
      child: photo == null
          ? Text(call.name.characters.first.toUpperCase(),
              style: TextStyle(color: Colors.white, fontSize: radius * 0.8, fontWeight: FontWeight.w300))
          : null,
    );
  }
}

/// The ringing screen: ringtone and vibration until answered or declined.
class _IncomingCallScreen extends StatefulWidget {
  final _CallSetup call;
  const _IncomingCallScreen({required this.call});

  @override
  State<_IncomingCallScreen> createState() => _IncomingCallScreenState();
}

class _IncomingCallScreenState extends State<_IncomingCallScreen> {
  final AudioPlayer _player = AudioPlayer();
  Timer? _buzz;
  Timer? _giveUp;
  bool _answered = false;

  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    if (widget.call.ring) {
      _player.setReleaseMode(ReleaseMode.loop);
      _player.play(AssetSource('sounds/ringtone.wav')).catchError((e) => debugPrint('Ringtone: $e'));
    }
    _buzz = Timer.periodic(const Duration(milliseconds: 1500), (_) => HapticFeedback.heavyImpact());
    _giveUp = Timer(const Duration(seconds: 45), () => _end(answered: false));   // a missed call, like a real phone
  }

  void _stopRinging() {
    _buzz?.cancel();
    _giveUp?.cancel();
    _player.stop();
  }

  void _end({required bool answered}) {
    _stopRinging();
    if (!mounted) return;
    if (answered) {
      _answered = true;                              // the call screen keeps the full screen
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (_, __, ___) => _InCallScreen(call: widget.call),
          transitionDuration: Duration.zero,
        ),
      );
    } else {
      Navigator.of(context).pop();
    }
  }

  @override
  void dispose() {
    _stopRinging();
    _player.dispose();
    if (!_answered) SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isAr = context.watch<ThemeProvider>().isArabic;
    final call = widget.call;
    return PopScope(
      canPop: false,
      child: Scaffold(
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF1F2A44), Color(0xFF0B0F1A)],
            ),
          ),
          child: SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 60),
                _Avatar(call: call, radius: 56),
                const SizedBox(height: 20),
                Text(call.name, style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w400)),
                const SizedBox(height: 8),
                Text(
                  LanguageHelper.translate(call.video ? 'fc_incoming_video' : 'fc_incoming_voice', isAr),
                  style: const TextStyle(color: Colors.white70, fontSize: 16),
                ),
                if (call.subtitle.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(call.subtitle, style: const TextStyle(color: Colors.white54, fontSize: 14)),
                  ),
                const Spacer(),
                Padding(
                  padding: const EdgeInsets.fromLTRB(48, 0, 48, 64),
                  child: Row(
                    textDirection: TextDirection.ltr,        // like a real phone: decline left, answer right
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _RoundButton(
                        color: const Color(0xFFE53935),
                        icon: Icons.call_end_rounded,
                        label: LanguageHelper.translate('fc_decline', isAr),
                        onTap: () => _end(answered: false),
                      ),
                      _RoundButton(
                        color: const Color(0xFF43A047),
                        icon: call.video ? Icons.videocam_rounded : Icons.call_rounded,
                        label: LanguageHelper.translate('fc_accept', isAr),
                        onTap: () => _end(answered: true),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// The answered call: a running timer and the usual call buttons.
class _InCallScreen extends StatefulWidget {
  final _CallSetup call;
  const _InCallScreen({required this.call});

  @override
  State<_InCallScreen> createState() => _InCallScreenState();
}

class _InCallScreenState extends State<_InCallScreen> {
  int _seconds = 0;
  Timer? _timer;
  bool _muted = false;
  bool _speaker = false;

  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => setState(() => _seconds++));
  }

  @override
  void dispose() {
    _timer?.cancel();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isAr = context.watch<ThemeProvider>().isArabic;
    final call = widget.call;
    final time = '${(_seconds ~/ 60).toString().padLeft(2, '0')}:${(_seconds % 60).toString().padLeft(2, '0')}';
    final photo = call.photo;

    final controls = Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _Toggle(
          icon: _muted ? Icons.mic_off_rounded : Icons.mic_rounded,
          label: LanguageHelper.translate('fc_mute', isAr),
          on: _muted,
          onTap: () => setState(() => _muted = !_muted),
        ),
        _Toggle(
          icon: Icons.volume_up_rounded,
          label: LanguageHelper.translate('fc_speaker', isAr),
          on: _speaker,
          onTap: () => setState(() => _speaker = !_speaker),
        ),
        _Toggle(
          icon: call.video ? Icons.cameraswitch_rounded : Icons.dialpad_rounded,
          label: LanguageHelper.translate(call.video ? 'fc_flip' : 'fc_keypad', isAr),
          on: false,
          onTap: () {},
        ),
      ],
    );

    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: const Color(0xFF0B0F1A),
        body: Stack(
          fit: StackFit.expand,
          children: [
            if (call.video && photo != null) Image.memory(photo, fit: BoxFit.cover),
            if (call.video) Container(color: Colors.black26),
            SafeArea(
              child: Column(
                children: [
                  const SizedBox(height: 48),
                  if (!call.video) _Avatar(call: call, radius: 56),
                  if (!call.video) const SizedBox(height: 20),
                  Text(call.name, style: const TextStyle(color: Colors.white, fontSize: 30)),
                  const SizedBox(height: 8),
                  Text(time, style: const TextStyle(color: Colors.white70, fontSize: 18)),
                  const Spacer(),
                  controls,
                  const SizedBox(height: 40),
                  _RoundButton(
                    color: const Color(0xFFE53935),
                    icon: Icons.call_end_rounded,
                    label: LanguageHelper.translate('fc_end', isAr),
                    onTap: () => Navigator.of(context).pop(),
                  ),
                  const SizedBox(height: 48),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RoundButton extends StatelessWidget {
  final Color color;
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _RoundButton({required this.color, required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Material(
          color: color,
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onTap,
            child: SizedBox(width: 72, height: 72, child: Icon(icon, color: Colors.white, size: 34)),
          ),
        ),
        const SizedBox(height: 8),
        Text(label, style: const TextStyle(color: Colors.white70)),
      ],
    );
  }
}

class _Toggle extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool on;
  final VoidCallback onTap;
  const _Toggle({required this.icon, required this.label, required this.on, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Material(
          color: on ? Colors.white : Colors.white12,
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onTap,
            child: SizedBox(
              width: 60,
              height: 60,
              child: Icon(icon, color: on ? Colors.black : Colors.white, size: 28),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
      ],
    );
  }
}
