import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../models/chat_models.dart';
import '../providers/chat_provider.dart';

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

  @override
  void initState() {
    super.initState();
    final contact = context.read<ChatProvider>().activeSession?.contactUser;
    _nameController = TextEditingController(text: contact?.name ?? '');
    _onlineStatus = contact?.onlineStatus ?? UserOnlineStatus.online;
    _isTyping = contact?.isTyping ?? false;
    _lastSeen = contact?.lastSeen;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _save() {
    final chatProvider = context.read<ChatProvider>();
    final contact = chatProvider.activeSession?.contactUser;
    if (contact == null) return;

    chatProvider.updateContact(
      contact.copyWith(
        name: _nameController.text.trim(),
        onlineStatus: _isTyping ? UserOnlineStatus.typing : _onlineStatus,
        isTyping: _isTyping,
        lastSeen: _lastSeen,
      ),
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
            // Handle
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
              'Edit Contact',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: Colors.white),
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
                      backgroundColor: const Color(0xFF6C63FF).withOpacity(0.2),
                      backgroundImage: contact?.avatarBytes != null
                          ? MemoryImage(contact!.avatarBytes!)
                          : null,
                      child: contact?.avatarBytes == null
                          ? Text(
                              contact?.name.isNotEmpty == true
                                  ? contact!.name[0].toUpperCase()
                                  : '?',
                              style: const TextStyle(
                                color: Color(0xFF6C63FF),
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
                          color: const Color(0xFF6C63FF),
                          shape: BoxShape.circle,
                          border: Border.all(color: const Color(0xFF1A1A1A), width: 2),
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
            _Label('Display Name'),
            const SizedBox(height: 6),
            TextField(
              controller: _nameController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                hintText: 'Contact name',
                prefixIcon: Icon(Icons.person_outline, color: Colors.white38),
              ),
            ),
            const SizedBox(height: 16),

            // Online status
            _Label('Online Status'),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: UserOnlineStatus.values.map((s) {
                if (s == UserOnlineStatus.typing) return const SizedBox.shrink();
                final isActive = _onlineStatus == s && !_isTyping;
                return _StatusChip(
                  label: _statusLabel(s),
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
              label: 'Show Typing Indicator',
              value: _isTyping,
              onChanged: (v) => setState(() => _isTyping = v),
            ),

            // Last seen (only when offline)
            if (_onlineStatus == UserOnlineStatus.offline || _onlineStatus == UserOnlineStatus.lastSeen) ...[
              const SizedBox(height: 16),
              _Label('Last Seen'),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: () async {
                  final picked = await showDateTimePicker(context);
                  if (picked != null) setState(() => _lastSeen = picked);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF242424),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.access_time, color: Colors.white38, size: 18),
                      const SizedBox(width: 10),
                      Text(
                        _lastSeen != null ? _formatDt(_lastSeen!) : 'Tap to set last seen time',
                        style: TextStyle(
                          color: _lastSeen != null ? Colors.white : Colors.white38,
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
                  backgroundColor: const Color(0xFF6C63FF),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                onPressed: _save,
                child: const Text('Save Contact', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _statusLabel(UserOnlineStatus s) {
    switch (s) {
      case UserOnlineStatus.online: return 'Online';
      case UserOnlineStatus.offline: return 'Offline';
      case UserOnlineStatus.lastSeen: return 'Last Seen';
      case UserOnlineStatus.typing: return 'Typing';
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
    return Text(
      text,
      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white38, letterSpacing: 0.5),
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
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFF6C63FF).withOpacity(0.2) : const Color(0xFF242424),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isActive ? const Color(0xFF6C63FF) : Colors.transparent,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isActive ? const Color(0xFF6C63FF) : Colors.white54,
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
    return Row(
      children: [
        Expanded(
          child: Text(label, style: const TextStyle(color: Colors.white70, fontSize: 14)),
        ),
        Switch(
          value: value,
          onChanged: onChanged,
          activeColor: const Color(0xFF6C63FF),
        ),
      ],
    );
  }
}
