import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../models/chat_models.dart';
import '../providers/chat_provider.dart';
import '../providers/theme_provider.dart';
import '../themes/platform_themes.dart';
import '../utils/language_helper.dart';

class ContactEditorSheet extends StatefulWidget {
  const ContactEditorSheet({super.key});

  @override
  State<ContactEditorSheet> createState() => _ContactEditorSheetState();
}

class _ContactEditorSheetState extends State<ContactEditorSheet> {
  late TextEditingController _nameController;
  UserOnlineStatus _onlineStatus = UserOnlineStatus.online;
  bool _isTyping = false;
  DateTime? _lastSeen;
  bool _isBlocked = false;
  bool _isBlockedMe = false;
  bool _isDisappearing = false;

  @override
  void initState() {
    super.initState();
    final session = context.read<ChatProvider>().activeSession;
    final contact = session?.contactUser;
    _nameController = TextEditingController(text: contact?.name ?? '');
    _onlineStatus = contact?.onlineStatus ?? UserOnlineStatus.online;
    _isTyping = contact?.isTyping ?? false;
    _lastSeen = contact?.lastSeen;
    _isBlocked = session?.isBlocked ?? false;
    _isBlockedMe = session?.isBlockedMe ?? false;
    _isDisappearing = session?.isDisappearing ?? false;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _save() {
    final chatProvider = context.read<ChatProvider>();
    final session = chatProvider.activeSession;
    final contact = session?.contactUser;
    if (contact == null) return;

    chatProvider.updateContact(
      contact.copyWith(
        name: _nameController.text.trim(),
        onlineStatus: _isTyping ? UserOnlineStatus.typing : _onlineStatus,
        isTyping: _isTyping,
        lastSeen: _lastSeen,
      ),
    );
    chatProvider.updateSessionSettings(
      isBlocked: _isBlocked,
      isBlockedMe: _isBlockedMe,
      isDisappearing: _isDisappearing,
    );
    Navigator.pop(context);
  }

  Future<void> _pickAvatar() async {
    final picker = ImagePicker();
    final file = await picker.pickImage(source: ImageSource.gallery, maxWidth: 512, maxHeight: 512);
    if (file != null && mounted) {
      final bytes = await file.readAsBytes();
      final chatProvider = context.read<ChatProvider>();
      final contact = chatProvider.activeSession?.contactUser;
      if (contact != null) {
        chatProvider.updateContact(contact.copyWith(avatarBytes: bytes));
        setState(() {});
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final contact = context.watch<ChatProvider>().activeSession?.contactUser;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final chatProvider = context.watch<ChatProvider>();
    final themeProvider = context.watch<ThemeProvider>();
    final isAr = themeProvider.isArabic;
    final session = chatProvider.activeSession;
    final platformTheme = session != null ? PlatformTheme.of(session.platform, isDark: true) : null;
    final accentColor = platformTheme?.sendButtonColor ?? const Color(0xFF6C63FF);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black87;
    final labelColor = isDark ? Colors.white38 : Colors.black45;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(20, 16, 20, 20 + bottomInset),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark ? Colors.white24 : Colors.black12,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              LanguageHelper.translate('edit_contact', isAr),
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: textColor),
            ),
            const SizedBox(height: 20),

            // Avatar picker
            Center(
              child: GestureDetector(
                onTap: _pickAvatar,
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: 42,
                      backgroundColor: accentColor.withValues(alpha: 0.2),
                      backgroundImage: contact?.avatarBytes != null
                          ? MemoryImage(contact!.avatarBytes!)
                          : null,
                      child: contact?.avatarBytes == null
                          ? Text(
                              contact?.name.isNotEmpty == true
                                  ? contact!.name[0].toUpperCase()
                                  : '?',
                              style: TextStyle(
                                color: accentColor,
                                fontSize: 36,
                                fontWeight: FontWeight.w700,
                              ),
                            )
                          : null,
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: accentColor,
                          shape: BoxShape.circle,
                          border: Border.all(color: isDark ? const Color(0xFF1A1A1A) : Colors.white, width: 2),
                        ),
                        child: const Icon(Icons.camera_alt, size: 14, color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Name field
            _Label(LanguageHelper.translate('display_name', isAr)),
            const SizedBox(height: 6),
            TextField(
              controller: _nameController,
              style: TextStyle(color: textColor),
              decoration: InputDecoration(
                hintText: LanguageHelper.translate('contact_name', isAr),
                prefixIcon: Icon(Icons.person_outline, color: labelColor),
              ),
            ),
            const SizedBox(height: 16),

            // Online status
            _Label(LanguageHelper.translate('online_status', isAr)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: UserOnlineStatus.values.map((s) {
                if (s == UserOnlineStatus.typing) return const SizedBox.shrink();
                final isActive = _onlineStatus == s && !_isTyping;
                return _StatusChip(
                  label: _statusLabel(s, isAr),
                  isActive: isActive,
                  onTap: () => setState(() {
                    _onlineStatus = s;
                    _isTyping = false;
                  }),
                );
              }).toList(),
            ),
            const SizedBox(height: 12),

            // Typing toggle
            _ToggleRow(
              label: LanguageHelper.translate('show_typing_indicator', isAr),
              value: _isTyping,
              onChanged: (v) => setState(() => _isTyping = v),
            ),

            // Block toggle
            _ToggleRow(
              label: LanguageHelper.translate('block_contact', isAr),
              value: _isBlocked,
              onChanged: (v) => setState(() => _isBlocked = v),
            ),

            // Blocked Me toggle
            _ToggleRow(
              label: LanguageHelper.translate('contact_blocked_me', isAr),
              value: _isBlockedMe,
              onChanged: (v) => setState(() => _isBlockedMe = v),
            ),

            // Disappearing Messages toggle
            _ToggleRow(
              label: LanguageHelper.translate('disappearing_messages', isAr),
              value: _isDisappearing,
              onChanged: (v) => setState(() => _isDisappearing = v),
            ),

            // Last seen (only when offline)
            if (_onlineStatus == UserOnlineStatus.offline || _onlineStatus == UserOnlineStatus.lastSeen) ...[
              const SizedBox(height: 16),
              _Label(LanguageHelper.translate('last_seen', isAr)),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: () async {
                  final picked = await showDateTimePicker(context);
                  if (picked != null) setState(() => _lastSeen = picked);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF242424) : const Color(0xFFEEEEEE),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.access_time, color: labelColor, size: 18),
                      const SizedBox(width: 10),
                      Text(
                        _lastSeen != null ? _formatDt(_lastSeen!) : LanguageHelper.translate('tap_to_set_last_seen', isAr),
                        style: TextStyle(
                          color: _lastSeen != null ? textColor : labelColor,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],

            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: accentColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                onPressed: _save,
                child: Text(LanguageHelper.translate('save_contact', isAr), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _statusLabel(UserOnlineStatus s, bool isAr) {
    switch (s) {
      case UserOnlineStatus.online: return LanguageHelper.translate('status_online', isAr);
      case UserOnlineStatus.offline: return LanguageHelper.translate('status_offline', isAr);
      case UserOnlineStatus.lastSeen: return LanguageHelper.translate('status_last_seen', isAr);
      case UserOnlineStatus.typing: return LanguageHelper.translate('status_typing', isAr);
    }
  }

  String _formatDt(DateTime dt) {
    return '${dt.day}/${dt.month}/${dt.year} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  Future<DateTime?> showDateTimePicker(BuildContext context) async {
    final date = await showDatePicker(
      context: context,
      initialDate: _lastSeen ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (date == null) return null;
    if (!context.mounted) return null;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_lastSeen ?? DateTime.now()),
    );
    if (time == null) return null;
    return DateTime(date.year, date.month, date.day, time.hour, time.minute);
  }
}

// ─── Shared UI components ────────────────────────────────────────────────────

class _Label extends StatelessWidget {
  final String text;
  const _Label(this.text);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Text(
      text,
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: isDark ? Colors.white38 : Colors.black45,
        letterSpacing: 0.5,
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _StatusChip({required this.label, required this.isActive, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final chatProvider = context.watch<ChatProvider>();
    final session = chatProvider.activeSession;
    final platformTheme = session != null ? PlatformTheme.of(session.platform, isDark: true) : null;
    final accentColor = platformTheme?.sendButtonColor ?? const Color(0xFF6C63FF);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isActive
              ? accentColor.withValues(alpha: 0.2)
              : (isDark ? const Color(0xFF242424) : const Color(0xFFEEEEEE)),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isActive ? accentColor : Colors.transparent,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isActive ? accentColor : (isDark ? Colors.white54 : Colors.black54),
            fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}

class _ToggleRow extends StatelessWidget {
  final String label;
  final bool value;
  final void Function(bool) onChanged;

  const _ToggleRow({required this.label, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final chatProvider = context.watch<ChatProvider>();
    final session = chatProvider.activeSession;
    final platformTheme = session != null ? PlatformTheme.of(session.platform, isDark: true) : null;
    final accentColor = platformTheme?.sendButtonColor ?? const Color(0xFF6C63FF);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Row(
      children: [
        Expanded(
          child: Text(label, style: TextStyle(color: isDark ? Colors.white70 : Colors.black87, fontSize: 14)),
        ),
        Switch(
          value: value,
          onChanged: onChanged,
          activeColor: accentColor,
        ),
      ],
    );
  }
}

