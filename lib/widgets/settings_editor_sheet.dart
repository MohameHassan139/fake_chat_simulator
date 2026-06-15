import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/chat_provider.dart';
import '../models/chat_models.dart';

class SettingsEditorSheet extends StatefulWidget {
  const SettingsEditorSheet({super.key});

  @override
  State<SettingsEditorSheet> createState() => _SettingsEditorSheetState();
}

class _SettingsEditorSheetState extends State<SettingsEditorSheet> {
  late TextEditingController _timeController;
  late TextEditingController _bioController;
  late TextEditingController _subBioController;
  late int _battery;
  late bool _wifi;
  late bool _isDark;

  late bool _isContactOnline;

  late TextEditingController _unreadCountController;
  late TextEditingController _lastMsgController;
  late TextEditingController _lastMsgTimeController;
  late bool _isGroup;
  late TextEditingController _groupMembersController;
  late String _lastMsgSenderVal; // 'default', 'me', 'them'

  @override
  void initState() {
    super.initState();
    final session = context.read<ChatProvider>().activeSession;
    _timeController = TextEditingController(text: session?.fakeTime ?? '9:41');
    _bioController = TextEditingController(text: session?.contactBio ?? '');
    _subBioController = TextEditingController(text: session?.contactSubBio ?? '');
    _battery = session?.fakeBattery ?? 87;
    _wifi = session?.fakeWifi ?? true;
    _isDark = session?.isDarkMode ?? false;

    _isContactOnline = session?.contactUser.onlineStatus == UserOnlineStatus.online;

    _unreadCountController = TextEditingController(
      text: (session?.unreadCount != null && session!.unreadCount > 0)
          ? session.unreadCount.toString()
          : '',
    );
    _lastMsgController = TextEditingController(text: session?.customLastMessage ?? '');
    _lastMsgTimeController = TextEditingController(text: session?.customLastMessageTime ?? '');
    _isGroup = session?.isGroup ?? false;
    _groupMembersController = TextEditingController(text: session?.groupMembers ?? '');

    if (session?.lastMessageIsSender == null) {
      _lastMsgSenderVal = 'default';
    } else if (session!.lastMessageIsSender == true) {
      _lastMsgSenderVal = 'me';
    } else {
      _lastMsgSenderVal = 'them';
    }

    // Set some defaults based on platform if empty
    if (session != null && _bioController.text.isEmpty) {
      if (session.platform == Platform.instagram) {
        _bioController.text = '1.2M followers • 420 posts';
        _subBioController.text = 'You follow each other on Instagram';
      } else if (session.platform == Platform.messenger) {
        _bioController.text = 'Active on Facebook';
        _subBioController.text = "You're friends on Facebook";
      } else if (session.platform == Platform.whatsapp) {
        _bioController.text = 'Messages and calls are end-to-end encrypted.';
      }
    }
  }

  @override
  void dispose() {
    _timeController.dispose();
    _bioController.dispose();
    _subBioController.dispose();
    _unreadCountController.dispose();
    _lastMsgController.dispose();
    _lastMsgTimeController.dispose();
    _groupMembersController.dispose();
    super.dispose();
  }

  void _save() {
    final chatProvider = context.read<ChatProvider>();
    final unread = int.tryParse(_unreadCountController.text.trim()) ?? 0;

    bool? senderOverride;
    bool clearLastSender = false;
    if (_lastMsgSenderVal == 'me') {
      senderOverride = true;
    } else if (_lastMsgSenderVal == 'them') {
      senderOverride = false;
    } else {
      clearLastSender = true;
    }

    final customMsgText = _lastMsgController.text.trim();
    final customTimeText = _lastMsgTimeController.text.trim();

    final contact = chatProvider.activeSession?.contactUser;
    if (contact != null) {
      chatProvider.updateContact(
        contact.copyWith(
          onlineStatus: _isContactOnline ? UserOnlineStatus.online : UserOnlineStatus.offline,
        ),
      );
    }

    chatProvider.updateSessionSettings(
      fakeTime: _timeController.text.trim(),
      fakeBattery: _battery,
      fakeWifi: _wifi,
      isDarkMode: _isDark,
      contactBio: _bioController.text.trim(),
      contactSubBio: _subBioController.text.trim(),
      unreadCount: unread,
      customLastMessage: customMsgText.isEmpty ? null : customMsgText,
      clearCustomLastMessage: customMsgText.isEmpty,
      customLastMessageTime: customTimeText.isEmpty ? null : customTimeText,
      clearCustomLastMessageTime: customTimeText.isEmpty,
      lastMessageIsSender: senderOverride,
      clearLastMessageIsSender: clearLastSender,
      isGroup: _isGroup,
      groupMembers: _groupMembersController.text.trim(),
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF1A1A1A),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(20, 16, 20, 20 + bottomInset),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Mock Mockup Settings',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: Colors.white),
            ),
            const SizedBox(height: 6),
            const Text(
              'Customize mock status bar, dark mode, and user bios',
              style: TextStyle(color: Colors.white38, fontSize: 13),
            ),
            const SizedBox(height: 24),

            // Mock Dark Mode Toggle
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFF242424),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.dark_mode_rounded, color: Colors.amber, size: 22),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Mock Dark Mode',
                      style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600),
                    ),
                  ),
                  Switch(
                    value: _isDark,
                    onChanged: (v) => setState(() => _isDark = v),
                    activeColor: const Color(0xFF6C63FF),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Clock time
            _SectionLabel('Clock Time'),
            const SizedBox(height: 8),
            TextField(
              controller: _timeController,
              style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600),
              textAlign: TextAlign.center,
              decoration: const InputDecoration(
                hintText: '9:41',
                prefixIcon: Icon(Icons.access_time, color: Colors.white38),
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: ['9:41', '12:00', '3:15', '11:30', '7:00'].map((t) {
                return GestureDetector(
                  onTap: () {
                    _timeController.text = t;
                    setState(() {});
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF242424),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(t, style: const TextStyle(color: Colors.white54, fontSize: 13)),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),

            // First-Time Profile Header Info
            _SectionLabel('Profile Header Bio'),
            const SizedBox(height: 8),
            TextField(
              controller: _bioController,
              style: const TextStyle(color: Colors.white, fontSize: 14),
              decoration: const InputDecoration(
                hintText: 'e.g., 1.2M followers • 215 posts',
                prefixIcon: Icon(Icons.info_outline, color: Colors.white38),
              ),
            ),
            const SizedBox(height: 16),

            _SectionLabel('Profile Header Sub-Bio / Stats'),
            const SizedBox(height: 8),
            TextField(
              controller: _subBioController,
              style: const TextStyle(color: Colors.white, fontSize: 14),
              decoration: const InputDecoration(
                hintText: "e.g., You're friends on Facebook",
                prefixIcon: Icon(Icons.people_outline, color: Colors.white38),
              ),
            ),
            const SizedBox(height: 20),

            // Battery level
            _SectionLabel('Battery Level: $_battery%'),
            Slider(
              value: _battery.toDouble(),
              min: 5,
              max: 100,
              divisions: 19,
              activeColor: _batteryColor(_battery),
              onChanged: (v) => setState(() => _battery = v.round()),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: ['20%', '50%', '75%', '100%'].map((label) {
                final val = int.parse(label.replaceAll('%', ''));
                return GestureDetector(
                  onTap: () => setState(() => _battery = val),
                  child: Text(label, style: const TextStyle(color: Colors.white38, fontSize: 12)),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),

            // WiFi toggle
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFF242424),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.wifi_rounded, color: Colors.white54, size: 22),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Show WiFi Icon',
                      style: TextStyle(color: Colors.white, fontSize: 15),
                    ),
                  ),
                  Switch(
                    value: _wifi,
                    onChanged: (v) => setState(() => _wifi = v),
                    activeColor: const Color(0xFF6C63FF),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            _SectionLabel('INBOX FEED CONTROLS'),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF242424),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Contact Online Switch Toggle
                  Row(
                    children: [
                      const Icon(Icons.circle, color: Color(0xFF31A24C), size: 18),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'Contact is Online',
                          style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                        ),
                      ),
                      Switch(
                        value: _isContactOnline,
                        onChanged: (v) => setState(() => _isContactOnline = v),
                        activeColor: const Color(0xFF6C63FF),
                      ),
                    ],
                  ),
                  const Divider(color: Colors.white10, height: 24),

                  // Group Chat Switch Toggle
                  Row(
                    children: [
                      const Icon(Icons.groups_rounded, color: Colors.blueAccent, size: 22),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'Is Group Chat',
                          style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                        ),
                      ),
                      Switch(
                        value: _isGroup,
                        onChanged: (v) => setState(() => _isGroup = v),
                        activeColor: const Color(0xFF6C63FF),
                      ),
                    ],
                  ),
                  if (_isGroup) ...[
                    const SizedBox(height: 12),
                    const Text(
                      'Group Members (Description)',
                      style: TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _groupMembersController,
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                      decoration: const InputDecoration(
                        hintText: 'e.g., Sarah, Elon, Dev, You',
                        prefixIcon: Icon(Icons.people, color: Colors.white38),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                    ),
                  ],
                  const Divider(color: Colors.white10, height: 24),

                  // Unread Badge Count
                  const Text(
                    'Unread Messages Count',
                    style: TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _unreadCountController,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                    decoration: const InputDecoration(
                      hintText: 'e.g., 3 (Leave empty for 0)',
                      prefixIcon: Icon(Icons.mark_chat_unread_rounded, color: Colors.white38),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                  ),
                  const Divider(color: Colors.white10, height: 24),

                  // Last message text override
                  const Text(
                    'Override Last Message Preview',
                    style: TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _lastMsgController,
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                    decoration: const InputDecoration(
                      hintText: 'Custom last message text',
                      prefixIcon: Icon(Icons.history_edu_rounded, color: Colors.white38),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Last message time override
                  const Text(
                    'Override Last Message Time',
                    style: TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _lastMsgTimeController,
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                    decoration: const InputDecoration(
                      hintText: 'e.g., Just now, Yesterday, 2h, 3:15 PM',
                      prefixIcon: Icon(Icons.watch_later_rounded, color: Colors.white38),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                  ),
                  const Divider(color: Colors.white10, height: 24),

                  // Who sent the last message
                  const Text(
                    'Who Sent Last Message?',
                    style: TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E1E1E),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.white12),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _lastMsgSenderVal,
                        dropdownColor: const Color(0xFF1E1E1E),
                        style: const TextStyle(color: Colors.white, fontSize: 14),
                        icon: const Icon(Icons.arrow_drop_down, color: Colors.white54),
                        isExpanded: true,
                        items: const [
                          DropdownMenuItem(
                            value: 'default',
                            child: Text('Default (Use actual message sender)'),
                          ),
                          DropdownMenuItem(
                            value: 'me',
                            child: Text('Me (Sender / Double ticks)'),
                          ),
                          DropdownMenuItem(
                            value: 'them',
                            child: Text('Them (Contact / Received)'),
                          ),
                        ],
                        onChanged: (val) {
                          if (val != null) {
                            setState(() => _lastMsgSenderVal = val);
                          }
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6C63FF),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                onPressed: _save,
                child: const Text(
                  'Apply Mockup Settings',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _batteryColor(int level) {
    if (level > 50) return const Color(0xFF44BB44);
    if (level > 20) return const Color(0xFFFFBB00);
    return const Color(0xFFFF4444);
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: Colors.white38,
        letterSpacing: 0.5,
      ),
    );
  }
}
