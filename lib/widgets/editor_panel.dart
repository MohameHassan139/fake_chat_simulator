import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../models/chat_models.dart';
import '../providers/chat_provider.dart';
import '../providers/theme_provider.dart';
import '../utils/language_helper.dart';
import 'contact_editor_sheet.dart';
import 'settings_editor_sheet.dart';
import 'message_editor_sheet.dart';

class EditorPanel extends StatelessWidget {
  final VoidCallback onCapture;
  final bool isCapturing;

  const EditorPanel({
    super.key,
    required this.onCapture,
    required this.isCapturing,
  });

  @override
  Widget build(BuildContext context) {
    final chatProvider = context.watch<ChatProvider>();
    final session = chatProvider.activeSession;
    final isAr = context.read<ThemeProvider>().isArabic;

    if (chatProvider.viewChatList && session != null) {
      return Container(
        decoration: const BoxDecoration(
          color: Color(0xFF111111),
          border: Border(top: BorderSide(color: Color(0xFF222222))),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF6C63FF).withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.forum_rounded,
                    color: Color(0xFF6C63FF),
                    size: 28,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        isAr ? 'معاينة قائمة الرسائل نشطة' : 'Inbox (Chat List) Mode Active',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15.5,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        isAr
                            ? 'أنت تعاين حاليًا صندوق الوارد لتطبيق ${session.platformName}. اضغط على أي محادثة في محاكي الهاتف لفتحها وتعديل محتواها.'
                            : 'You are previewing the inbox feed for ${session.platformName}. Tap any chat inside the phone frame above to open it and edit.',
                        style: const TextStyle(
                          color: Colors.white54,
                          fontSize: 12,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                // Back to chat button
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFF333333)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    icon: const Icon(Icons.chat_bubble_outline_rounded, color: Colors.white70, size: 16),
                    label: Text(
                      isAr ? 'العودة للمحادثة' : 'Back to Chat',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                    onPressed: () {
                      chatProvider.setViewChatList(false);
                    },
                  ),
                ),
                const SizedBox(width: 12),
                // Configure inbox header
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFF333333)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    icon: const Icon(Icons.settings_outlined, color: Colors.white70, size: 16),
                    label: Text(
                      isAr ? 'إعدادات الإطار' : 'Mockup Settings',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                    onPressed: () {
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        backgroundColor: Colors.transparent,
                        builder: (_) => ChangeNotifierProvider.value(
                          value: context.read<ChatProvider>(),
                          child: const SettingsEditorSheet(),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 12),
                // Export screenshot
                GestureDetector(
                  onTap: isCapturing ? null : onCapture,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF6C63FF), Color(0xFFFF6584)],
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: isCapturing
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Row(
                            children: [
                              const Icon(Icons.camera_alt_rounded, size: 16, color: Colors.white),
                              const SizedBox(width: 6),
                              Text(
                                isAr ? 'تصدير' : 'Export',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    }

    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF111111),
        border: Border(top: BorderSide(color: Color(0xFF222222))),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Action row
          _ActionRow(onCapture: onCapture, isCapturing: isCapturing),
          // Quick add message row
          _QuickAddRow(),
        ],
      ),
    );
  }
}

class _ActionRow extends StatelessWidget {
  final VoidCallback onCapture;
  final bool isCapturing;

  const _ActionRow({required this.onCapture, required this.isCapturing});

  @override
  Widget build(BuildContext context) {
    final isAr = context.read<ThemeProvider>().isArabic;

    return Container(
      height: 52,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          // Contact settings
          _ActionButton(
            icon: Icons.person_outline_rounded,
            label: LanguageHelper.translate('contact', isAr),
            onTap: () => _showContactEditor(context),
          ),
          const SizedBox(width: 8),
          // Chat settings
          _ActionButton(
            icon: Icons.settings_outlined,
            label: LanguageHelper.translate('settings', isAr),
            onTap: () => _showSettingsEditor(context),
          ),
          const SizedBox(width: 8),
          // Add image message
          _ActionButton(
            icon: Icons.image_outlined,
            label: LanguageHelper.translate('image', isAr),
            onTap: () => _pickImage(context),
          ),
          const SizedBox(width: 8),
          // Add audio message
          _ActionButton(
            icon: Icons.mic_outlined,
            label: LanguageHelper.translate('audio', isAr),
            onTap: () => _addAudioMessage(context),
          ),
          const SizedBox(width: 8),
          // Add call
          _ActionButton(
            icon: Icons.phone_outlined,
            label: LanguageHelper.translate('call', isAr),
            onTap: () => _addCallMessage(context),
          ),
          const SizedBox(width: 8),
          // Add date divider
          _ActionButton(
            icon: Icons.calendar_today_outlined,
            label: LanguageHelper.translate('date', isAr),
            onTap: () => _showDateDividerEditor(context),
          ),
          const Spacer(),
          // Capture button in panel too
          GestureDetector(
            onTap: isCapturing ? null : onCapture,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF6C63FF), Color(0xFFFF6584)],
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: isCapturing
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Row(
                      children: [
                        const Icon(Icons.camera_alt_rounded, size: 16, color: Colors.white),
                        const SizedBox(width: 6),
                        Text(
                          LanguageHelper.translate('export', isAr),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }

  void _showContactEditor(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ChangeNotifierProvider.value(
        value: context.read<ChatProvider>(),
        child: const ContactEditorSheet(),
      ),
    );
  }

  void _showSettingsEditor(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ChangeNotifierProvider.value(
        value: context.read<ChatProvider>(),
        child: const SettingsEditorSheet(),
      ),
    );
  }

  Future<void> _pickImage(BuildContext context) async {
    final picker = ImagePicker();
    final file = await picker.pickImage(source: ImageSource.gallery, maxWidth: 1024, maxHeight: 1024);
    if (file != null && context.mounted) {
      final bytes = await file.readAsBytes();
      final chatProvider = context.read<ChatProvider>();
      chatProvider.addImageMessage(
        imageBytes: bytes,
        isSender: chatProvider.isSenderMode,
        timestamp: DateTime.now(),
      );
    }
  }

  void _addAudioMessage(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => _AudioDurationDialog(
        onConfirm: (duration) {
          final chatProvider = context.read<ChatProvider>();
          chatProvider.addAudioMessage(
            duration: duration,
            isSender: chatProvider.isSenderMode,
            timestamp: DateTime.now(),
          );
        },
      ),
    );
  }

  void _addCallMessage(BuildContext context) {
    final chatProvider = context.read<ChatProvider>();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        title: const Text('Add Call', style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.phone, color: Color(0xFF6C63FF)),
              title: const Text('Voice Call', style: TextStyle(color: Colors.white)),
              onTap: () {
                chatProvider.addCallMessage(
                  isVideo: false,
                  isSender: chatProvider.isSenderMode,
                  timestamp: DateTime.now(),
                );
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.videocam, color: Color(0xFF6C63FF)),
              title: const Text('Video Call', style: TextStyle(color: Colors.white)),
              onTap: () {
                chatProvider.addCallMessage(
                  isVideo: true,
                  isSender: chatProvider.isSenderMode,
                  timestamp: DateTime.now(),
                );
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showDateDividerEditor(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ChangeNotifierProvider.value(
        value: context.read<ChatProvider>(),
        child: const MessageEditorSheet(defaultType: MessageType.dateDivider),
      ),
    );
  }
}

class _QuickAddRow extends StatefulWidget {
  @override
  State<_QuickAddRow> createState() => _QuickAddRowState();
}

class _QuickAddRowState extends State<_QuickAddRow> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _sendMessage(BuildContext context) {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    final chatProvider = context.read<ChatProvider>();
    chatProvider.addTextMessage(
      text: text,
      isSender: chatProvider.isSenderMode,
      timestamp: DateTime.now(),
    );
    _controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 42,
              decoration: BoxDecoration(
                color: const Color(0xFF1E1E1E),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF2A2A2A)),
              ),
              child: TextField(
                controller: _controller,
                style: const TextStyle(color: Colors.white, fontSize: 14),
                decoration: const InputDecoration(
                  hintText: 'Type a message to add...',
                  hintStyle: TextStyle(color: Colors.white24, fontSize: 14),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                ),
                onSubmitted: (_) => _sendMessage(context),
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () => _sendMessage(context),
            child: Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: const Color(0xFF6C63FF),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.add_rounded, color: Colors.white, size: 22),
            ),
          ),
          const SizedBox(width: 6),
          GestureDetector(
            onTap: () => _showMessageEditor(context),
            child: Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: const Color(0xFF242424),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.tune_rounded, color: Colors.white54, size: 20),
            ),
          ),
        ],
      ),
    );
  }

  void _showMessageEditor(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ChangeNotifierProvider.value(
        value: context.read<ChatProvider>(),
        child: const MessageEditorSheet(),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 20, color: Colors.white54),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(fontSize: 9, color: Colors.white38, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}

// ─── Audio Duration Dialog ─────────────────────────────────────────────────────

class _AudioDurationDialog extends StatefulWidget {
  final void Function(Duration) onConfirm;
  const _AudioDurationDialog({required this.onConfirm});

  @override
  State<_AudioDurationDialog> createState() => _AudioDurationDialogState();
}

class _AudioDurationDialogState extends State<_AudioDurationDialog> {
  int _minutes = 0;
  int _seconds = 30;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF1A1A1A),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Text('Audio Duration', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Set audio message duration:', style: TextStyle(color: Colors.white54)),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _NumberPicker(
                label: 'Min',
                value: _minutes,
                min: 0,
                max: 9,
                onChanged: (v) => setState(() => _minutes = v),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 8),
                child: Text(':', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w700)),
              ),
              _NumberPicker(
                label: 'Sec',
                value: _seconds,
                min: 0,
                max: 59,
                onChanged: (v) => setState(() => _seconds = v),
              ),
            ],
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel', style: TextStyle(color: Colors.white38)),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF6C63FF)),
          onPressed: () {
            widget.onConfirm(Duration(minutes: _minutes, seconds: _seconds));
            Navigator.pop(context);
          },
          child: const Text('Add'),
        ),
      ],
    );
  }
}

class _NumberPicker extends StatelessWidget {
  final String label;
  final int value;
  final int min;
  final int max;
  final void Function(int) onChanged;

  const _NumberPicker({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(label, style: const TextStyle(color: Colors.white38, fontSize: 12)),
        const SizedBox(height: 4),
        Row(
          children: [
            IconButton(
              icon: const Icon(Icons.remove_circle_outline, color: Colors.white38),
              onPressed: value > min ? () => onChanged(value - 1) : null,
            ),
            SizedBox(
              width: 40,
              child: Text(
                value.toString().padLeft(2, '0'),
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w600),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.add_circle_outline, color: Color(0xFF6C63FF)),
              onPressed: value < max ? () => onChanged(value + 1) : null,
            ),
          ],
        ),
      ],
    );
  }
}
