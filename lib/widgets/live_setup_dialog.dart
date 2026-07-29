import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/chat_models.dart';
import '../providers/chat_provider.dart';
import '../providers/theme_provider.dart';
import '../utils/language_helper.dart';
import '../utils/sound_effect_helper.dart';

class LiveSetupDialog extends StatefulWidget {
  final ChatSession session;
  final Function({
    required double speed,
    required bool isMuted,
    required bool autoRecordWeb,
  }) onStart;

  const LiveSetupDialog({
    super.key,
    required this.session,
    required this.onStart,
  });

  @override
  State<LiveSetupDialog> createState() => _LiveSetupDialogState();
}

class _LiveSetupDialogState extends State<LiveSetupDialog> {
  late double _selectedSpeed;
  late bool _soundEnabled;
  bool _autoRecordWeb = false;

  @override
  void initState() {
    super.initState();
    final provider = context.read<ChatProvider>();
    _selectedSpeed = provider.playbackSpeed;
    _soundEnabled = false;
  }

  Future<void> _pickCustomSoundFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.audio,
      withData: true,
    );
    if (result != null && result.files.isNotEmpty) {
      final file = result.files.first;
      if (file.bytes != null) {
        SoundEffectHelper.setCustomSound(file.bytes, file.name);
        setState(() {});
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isAr = context.read<ThemeProvider>().isArabic;
    final textColor = isDark ? Colors.white : Colors.black87;

    final String platformSoundName;
    switch (widget.session.platform) {
      case Platform.whatsapp:
        platformSoundName = 'WhatsApp Tone';
        break;
      case Platform.messenger:
        platformSoundName = 'Messenger Pop';
        break;
      case Platform.instagram:
        platformSoundName = 'Instagram Chime';
        break;
      case Platform.snapchat:
        platformSoundName = 'Snapchat Sound';
        break;
    }

    return AlertDialog(
      backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      contentPadding: const EdgeInsets.all(20),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF00C853), Color(0xFF00E676)],
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 12),
          Text(
            LanguageHelper.translate('live_setup_title', isAr),
            style: TextStyle(
              color: textColor,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),

            // Playback Speed
            Text(
              LanguageHelper.translate('playback_speed', isAr),
              style: TextStyle(
                color: textColor.withValues(alpha: 0.8),
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [1.0, 1.5, 2.0].map((speed) {
                final isSelected = _selectedSpeed == speed;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text('${speed}x'),
                    selected: isSelected,
                    selectedColor: const Color(0xFF00C853),
                    backgroundColor: isDark ? const Color(0xFF2C2C2C) : const Color(0xFFEEEEEE),
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : textColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                    onSelected: (val) {
                      if (val) setState(() => _selectedSpeed = speed);
                    },
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: 16),
            Divider(height: 1, color: isDark ? Colors.white10 : Colors.black12),
            const SizedBox(height: 12),

            // Sound Effects (Muted)
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              activeTrackColor: const Color(0xFF00C853),
              title: Text(
                LanguageHelper.translate('sound_effects', isAr),
                style: TextStyle(color: textColor, fontSize: 14, fontWeight: FontWeight.w600),
              ),
              subtitle: Text(
                isAr ? 'تم إيقاف الصوت تلقائياً' : 'All sound muted',
                style: TextStyle(color: textColor.withValues(alpha: 0.5), fontSize: 11),
              ),
              value: _soundEnabled,
              onChanged: (val) {
                setState(() => _soundEnabled = val);
              },
            ),

            const SizedBox(height: 12),
            // Clean view tip card
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF00C853).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF00C853).withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.videocam_rounded, color: Color(0xFF00C853), size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      isAr
                          ? 'عرض كامل ونظيف بدون أي أزرار فوق الشاشة لالتقاط تسجيل فيديو احترافي.'
                          : '100% clean full-screen view without overlay buttons for professional video recording.',
                      style: TextStyle(
                        color: textColor.withValues(alpha: 0.9),
                        fontSize: 11,
                        height: 1.3,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(
            LanguageHelper.translate('cancel', isAr),
            style: TextStyle(color: textColor.withValues(alpha: 0.6)),
          ),
        ),
        ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF00C853),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          ),
          icon: const Icon(Icons.play_arrow_rounded, size: 18),
          label: Text(
            LanguageHelper.translate('start_live_now', isAr),
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          ),
          onPressed: () {
            Navigator.pop(context);
            widget.onStart(
              speed: _selectedSpeed,
              isMuted: !_soundEnabled,
              autoRecordWeb: _autoRecordWeb,
            );
          },
        ),
      ],
    );
  }
}
