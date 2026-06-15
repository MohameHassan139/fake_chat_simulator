import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../models/chat_models.dart';
import '../providers/chat_provider.dart';
import '../providers/theme_provider.dart';
import '../utils/language_helper.dart';

const _uuid = Uuid();

class MessageEditorSheet extends StatefulWidget {
  final ChatMessage? editingMessage;
  final MessageType? defaultType;
  final ChatMessage? repliedToMessage;

  const MessageEditorSheet({
    super.key,
    this.editingMessage,
    this.defaultType,
    this.repliedToMessage,
  });

  @override
  State<MessageEditorSheet> createState() => _MessageEditorSheetState();
}

class _MessageEditorSheetState extends State<MessageEditorSheet> {
  late TextEditingController _textController;
  late TextEditingController _reactionController;
  late bool _isSender;
  late MessageStatus _status;
  late DateTime _timestamp;
  late MessageType _type;

  int _minutes = 0;
  int _seconds = 30;
  String _callStatus = 'Answered';
  String? _selectedReaction;
  Uint8List? _imageBytes;

  String? _repliedToId;
  String? _repliedToText;
  String? _repliedToSenderName;

  @override
  void initState() {
    super.initState();
    final msg = widget.editingMessage;
    final chatProvider = context.read<ChatProvider>();

    _textController = TextEditingController(text: msg?.text ?? '');
    _reactionController = TextEditingController(text: msg?.reaction ?? '');
    _isSender = msg?.isSender ?? chatProvider.isSenderMode;
    _status = msg?.status ?? MessageStatus.read;
    _timestamp = msg?.timestamp ?? DateTime.now();
    _type = msg?.type ?? widget.defaultType ?? MessageType.text;
    _selectedReaction = msg?.reaction;
    _imageBytes = msg?.imageBytes;

    _repliedToId = msg?.repliedToId;
    _repliedToText = msg?.repliedToText;
    _repliedToSenderName = msg?.repliedToSenderName;

    if (widget.repliedToMessage != null) {
      _repliedToId = widget.repliedToMessage!.id;
      _repliedToText = widget.repliedToMessage!.text.isNotEmpty
          ? widget.repliedToMessage!.text
          : '[${widget.repliedToMessage!.type.name}]';
      _repliedToSenderName = widget.repliedToMessage!.isSender
          ? 'You'
          : (chatProvider.activeSession?.contactUser.name ?? 'Contact');
    }

    // Load duration details if call or audio
    if (msg?.audioDuration != null) {
      _minutes = msg!.audioDuration!.inMinutes;
      _seconds = msg.audioDuration!.inSeconds % 60;
    }

    if (_type == MessageType.voiceCall || _type == MessageType.videoCall) {
      if (msg != null && msg.text.isNotEmpty) {
        _callStatus = msg.text;
      } else {
        _callStatus = 'Answered';
      }
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    _reactionController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final file = await picker.pickImage(source: ImageSource.gallery, maxWidth: 1024, maxHeight: 1024);
    if (file != null) {
      final bytes = await file.readAsBytes();
      setState(() => _imageBytes = bytes);
    }
  }

  void _save() {
    final chatProvider = context.read<ChatProvider>();
    final text = _textController.text.trim();

    final Duration? finalDuration = (_type == MessageType.audio || _type == MessageType.voiceCall || _type == MessageType.videoCall)
        ? Duration(minutes: _minutes, seconds: _seconds)
        : null;

    final String finalMsgText = (_type == MessageType.voiceCall || _type == MessageType.videoCall)
        ? _callStatus
        : text;

    if (widget.editingMessage != null) {
      chatProvider.updateMessage(
        widget.editingMessage!.id,
        widget.editingMessage!.copyWith(
          text: finalMsgText,
          isSender: _isSender,
          status: _status,
          timestamp: _timestamp,
          type: _type,
          audioDuration: finalDuration,
          reaction: _selectedReaction,
          clearReaction: _selectedReaction == null,
          imageBytes: _imageBytes,
          repliedToId: _repliedToId,
          repliedToText: _repliedToText,
          repliedToSenderName: _repliedToSenderName,
          clearRepliedTo: _repliedToId == null,
        ),
      );
    } else {
      final newMessage = ChatMessage(
        id: _uuid.v4(),
        text: finalMsgText,
        type: _type,
        isSender: _isSender,
        timestamp: _timestamp,
        status: _status,
        audioDuration: finalDuration,
        reaction: _selectedReaction,
        imageBytes: _imageBytes,
        repliedToId: _repliedToId,
        repliedToText: _repliedToText,
        repliedToSenderName: _repliedToSenderName,
      );
      chatProvider.addMessage(newMessage);
    }
    Navigator.pop(context);
  }

  String _typeLabel(MessageType t) {
    switch (t) {
      case MessageType.text: return 'Text Message';
      case MessageType.image: return 'Image Message';
      case MessageType.audio: return 'Audio Message';
      case MessageType.voiceCall: return 'Voice Call Record';
      case MessageType.videoCall: return 'Video Call Record';
      case MessageType.dateDivider: return 'Date Separator';
    }
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
            Text(
              LanguageHelper.translate(widget.editingMessage != null ? 'edit_message' : 'add_message', context.read<ThemeProvider>().isArabic),
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: Colors.white),
            ),
            const SizedBox(height: 20),

            // Dropdown selection for message/divider type
            _SLabel('Component Type'),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: const Color(0xFF242424),
                borderRadius: BorderRadius.circular(12),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<MessageType>(
                  value: _type,
                  dropdownColor: const Color(0xFF1E1E1E),
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                  icon: const Icon(Icons.arrow_drop_down, color: Colors.white54),
                  isExpanded: true,
                  items: MessageType.values.map((type) {
                    return DropdownMenuItem<MessageType>(
                      value: type,
                      child: Text(_typeLabel(type)),
                    );
                  }).toList(),
                  onChanged: (newVal) {
                    if (newVal != null) {
                      setState(() {
                        _type = newVal;
                        if (_type == MessageType.voiceCall || _type == MessageType.videoCall) {
                          _callStatus = 'Answered';
                        } else if (_type == MessageType.dateDivider && _textController.text.isEmpty) {
                          _textController.text = 'Today';
                        }
                      });
                    }
                  },
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Quoted Reply Section (Hidden for dateDividers)
            if (_type != MessageType.dateDivider) ...[
              _SLabel('Quoted Reply'),
              const SizedBox(height: 6),
              if (_repliedToId != null) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF242424),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFF4CAF50).withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 3.5,
                        height: 36,
                        decoration: BoxDecoration(
                          color: const Color(0xFF4CAF50),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _repliedToSenderName ?? 'Contact',
                              style: const TextStyle(
                                color: Color(0xFF4CAF50),
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _repliedToText ?? '',
                              style: const TextStyle(color: Colors.white70, fontSize: 12),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded, color: Colors.white38),
                        onPressed: () {
                          setState(() {
                            _repliedToId = null;
                            _repliedToText = null;
                            _repliedToSenderName = null;
                          });
                        },
                      ),
                    ],
                  ),
                ),
              ] else ...[
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white60,
                    side: const BorderSide(color: Colors.white12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  ),
                  icon: const Icon(Icons.reply_rounded, size: 18),
                  label: const Text('Add Quoted Reply'),
                  onPressed: () => _showSelectReplyDialog(context),
                ),
              ],
              const SizedBox(height: 16),
            ],

            // Text Input Box (Hidden for calls, shown for text/image/dateDividers)
            if (_type != MessageType.voiceCall && _type != MessageType.videoCall) ...[
              // Image picker (only for image type)
              if (_type == MessageType.image) ...[
                _SLabel('Image'),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: _pickImage,
                  child: Container(
                    width: double.infinity,
                    height: _imageBytes != null ? 180 : 100,
                    decoration: BoxDecoration(
                      color: const Color(0xFF242424),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _imageBytes != null ? const Color(0xFF6C63FF) : Colors.white12,
                        width: _imageBytes != null ? 1.5 : 1,
                      ),
                    ),
                    child: _imageBytes != null
                        ? Stack(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(11),
                                child: Image.memory(
                                  _imageBytes!,
                                  width: double.infinity,
                                  height: double.infinity,
                                  fit: BoxFit.cover,
                                ),
                              ),
                              Positioned(
                                top: 8,
                                right: 8,
                                child: GestureDetector(
                                  onTap: () => setState(() => _imageBytes = null),
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                      color: Colors.black54,
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: const Icon(Icons.close_rounded, size: 16, color: Colors.white),
                                  ),
                                ),
                              ),
                              Positioned(
                                bottom: 8,
                                right: 8,
                                child: GestureDetector(
                                  onTap: _pickImage,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: Colors.black54,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.swap_horiz_rounded, size: 14, color: Colors.white),
                                        SizedBox(width: 4),
                                        Text('Change', style: TextStyle(color: Colors.white, fontSize: 12)),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          )
                        : const Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.add_photo_alternate_outlined, size: 32, color: Colors.white38),
                              SizedBox(height: 8),
                              Text('Tap to pick image', style: TextStyle(color: Colors.white38, fontSize: 13)),
                            ],
                          ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
              _SLabel(_type == MessageType.dateDivider ? 'Date Separator Label' : (_type == MessageType.image ? 'Caption (Optional)' : 'Message Text')),
              const SizedBox(height: 6),
              TextField(
                controller: _textController,
                style: const TextStyle(color: Colors.white),
                maxLines: _type == MessageType.dateDivider ? 1 : 3,
                decoration: InputDecoration(
                  hintText: _type == MessageType.dateDivider ? 'e.g., Sunday, May 25, or TODAY' : 'Type your text here...',
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Date Preset capsules (Only for dateDivider)
            if (_type == MessageType.dateDivider) ...[
              _SLabel('Date Presets'),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: ['Today', 'Yesterday', 'Sunday', 'Monday', 'May 25, 2026', 'Call Logs'].map((preset) {
                  return GestureDetector(
                    onTap: () => setState(() => _textController.text = preset),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFF242424),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.white10),
                      ),
                      child: Text(preset, style: const TextStyle(color: Colors.white70, fontSize: 12)),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
            ],

            // Call Status Selector capsules (Only for voice/video calls)
            if (_type == MessageType.voiceCall || _type == MessageType.videoCall) ...[
              _SLabel('Call Status Details'),
              const SizedBox(height: 8),
              Row(
                children: ['Answered', 'Missed', 'Declined', 'No Answer'].map((status) {
                  final isSelected = _callStatus == status;
                  return Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _callStatus = status),
                      child: Container(
                        margin: const EdgeInsets.only(right: 6),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? const Color(0xFF6C63FF).withOpacity(0.18)
                              : const Color(0xFF242424),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: isSelected ? const Color(0xFF6C63FF) : Colors.transparent,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            status,
                            style: TextStyle(
                              fontSize: 11,
                              color: isSelected ? const Color(0xFF6C63FF) : Colors.white70,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
            ],

            // Call / Audio Duration Picker (Only when audio OR call status is Answered)
            if (_type == MessageType.audio || 
                ((_type == MessageType.voiceCall || _type == MessageType.videoCall) && _callStatus == 'Answered')) ...[
              _SLabel('Call / Audio Duration'),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _NumberPickerSimple(
                    label: 'Min',
                    value: _minutes,
                    min: 0,
                    max: 59,
                    onChanged: (v) => setState(() => _minutes = v),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: Text(':', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                  ),
                  _NumberPickerSimple(
                    label: 'Sec',
                    value: _seconds,
                    min: 0,
                    max: 59,
                    onChanged: (v) => setState(() => _seconds = v),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],

            // Emoji Reaction Selector (Hidden for dateDividers)
            if (_type != MessageType.dateDivider) ...[
              _SLabel('Message Reaction (Emoji)'),
              const SizedBox(height: 8),
              Row(
                children: ['❤️', '👍', '😂', '😮', '😢', '🙏'].map((emoji) {
                  final isSelected = _selectedReaction == emoji;
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        if (isSelected) {
                          _selectedReaction = null;
                          _reactionController.clear();
                        } else {
                          _selectedReaction = emoji;
                          _reactionController.text = emoji;
                        }
                      });
                    },
                    child: Container(
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? const Color(0xFF6C63FF).withOpacity(0.18)
                            : const Color(0xFF242424),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isSelected ? const Color(0xFF6C63FF) : Colors.transparent,
                        ),
                      ),
                      child: Text(emoji, style: const TextStyle(fontSize: 16)),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _reactionController,
                maxLength: 4,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  hintText: 'Or type custom reaction emoji...',
                  counterText: '',
                ),
                onChanged: (v) {
                  setState(() {
                    _selectedReaction = v.trim().isEmpty ? null : v.trim();
                  });
                },
              ),
              const SizedBox(height: 16),
            ],

            // Sender / Receiver Toggle (Hidden for dateDividers)
            if (_type != MessageType.dateDivider) ...[
              _SLabel(_type == MessageType.voiceCall || _type == MessageType.videoCall ? 'Call Direction' : 'Side'),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _SideButton(
                      label: (_type == MessageType.voiceCall || _type == MessageType.videoCall) ? 'Outgoing (Right)' : 'Me (Right)',
                      icon: Icons.send_rounded,
                      isActive: _isSender,
                      color: const Color(0xFF6C63FF),
                      onTap: () => setState(() => _isSender = true),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _SideButton(
                      label: (_type == MessageType.voiceCall || _type == MessageType.videoCall) ? 'Incoming (Left)' : 'Them (Left)',
                      icon: Icons.person_rounded,
                      isActive: !_isSender,
                      color: const Color(0xFF42A5F5),
                      onTap: () => setState(() => _isSender = false),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],

            // Message Status (only for sender & text/image/audio)
            if (_isSender && _type != MessageType.dateDivider && _type != MessageType.voiceCall && _type != MessageType.videoCall) ...[
              _SLabel('Message Status'),
              const SizedBox(height: 8),
              Row(
                children: MessageStatus.values.map((s) {
                  return Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _status = s),
                      child: Container(
                        margin: const EdgeInsets.only(right: 6),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: _status == s
                              ? const Color(0xFF6C63FF).withOpacity(0.18)
                              : const Color(0xFF242424),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: _status == s ? const Color(0xFF6C63FF) : Colors.transparent,
                          ),
                        ),
                        child: Column(
                          children: [
                            Icon(_statusIcon(s), size: 18, color: _status == s ? const Color(0xFF6C63FF) : Colors.white38),
                            const SizedBox(height: 3),
                            Text(
                              _statusLabel(s),
                              style: TextStyle(
                                fontSize: 10,
                                color: _status == s ? const Color(0xFF6C63FF) : Colors.white38,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
            ],

            // Timestamp (Editable for all messages!)
            _SLabel('Timestamp (Change Time)'),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: () async {
                final picked = await _pickDateTime(context);
                if (picked != null) setState(() => _timestamp = picked);
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
                      _formatDateTime(_timestamp),
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                    ),
                    const Spacer(),
                    const Icon(Icons.edit_rounded, color: Colors.white24, size: 16),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                _TimePreset(label: 'Just now', offset: Duration.zero, onSelect: (dt) => setState(() => _timestamp = dt)),
                _TimePreset(label: '5 min ago', offset: const Duration(minutes: 5), onSelect: (dt) => setState(() => _timestamp = dt)),
                _TimePreset(label: '1 hr ago', offset: const Duration(hours: 1), onSelect: (dt) => setState(() => _timestamp = dt)),
                _TimePreset(label: 'Yesterday', offset: const Duration(days: 1), onSelect: (dt) => setState(() => _timestamp = dt)),
              ],
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
                child: Text(
                  widget.editingMessage != null ? 'Update Component' : 'Add Component',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _statusIcon(MessageStatus s) {
    switch (s) {
      case MessageStatus.sending: return Icons.access_time_rounded;
      case MessageStatus.sent: return Icons.check_rounded;
      case MessageStatus.delivered: return Icons.done_all_rounded;
      case MessageStatus.read: return Icons.done_all_rounded;
    }
  }

  String _statusLabel(MessageStatus s) {
    switch (s) {
      case MessageStatus.sending: return 'Sending';
      case MessageStatus.sent: return 'Sent';
      case MessageStatus.delivered: return 'Delivered';
      case MessageStatus.read: return 'Read';
    }
  }

  String _formatDateTime(DateTime dt) {
    return '${dt.day}/${dt.month}/${dt.year}  ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  Future<DateTime?> _pickDateTime(BuildContext context) async {
    final date = await showDatePicker(
      context: context,
      initialDate: _timestamp,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(hours: 1)),
    );
    if (date == null || !context.mounted) return null;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_timestamp),
    );
    if (time == null) return null;
    return DateTime(date.year, date.month, date.day, time.hour, time.minute);
  }

  void _showSelectReplyDialog(BuildContext context) {
    final chatProvider = context.read<ChatProvider>();
    final session = chatProvider.activeSession;
    if (session == null) return;

    final otherMessages = session.messages.where((m) {
      if (m.type == MessageType.dateDivider) return false;
      if (widget.editingMessage != null && m.id == widget.editingMessage!.id) return false;
      return true;
    }).toList();

    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Select Message to Quote', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
        content: SizedBox(
          width: double.maxFinite,
          child: otherMessages.isEmpty
              ? const Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: Text(
                    'No other messages in this chat to reply to.',
                    style: TextStyle(color: Colors.white38),
                    textAlign: TextAlign.center,
                  ),
                )
              : ListView.builder(
                  shrinkWrap: true,
                  itemCount: otherMessages.length,
                  itemBuilder: (listCtx, index) {
                    final m = otherMessages[index];
                    final senderName = m.isSender
                        ? 'You'
                        : (session.contactUser.name.isNotEmpty ? session.contactUser.name : 'Contact');
                    return ListTile(
                      dense: true,
                      contentPadding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                      title: Text(
                        senderName,
                        style: TextStyle(
                          color: m.isSender ? const Color(0xFF6C63FF) : const Color(0xFF42A5F5),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      subtitle: Text(
                        m.text.isNotEmpty ? m.text : '[${m.type.name}]',
                        style: const TextStyle(color: Colors.white70),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      onTap: () {
                        setState(() {
                          _repliedToId = m.id;
                          _repliedToText = m.text.isNotEmpty ? m.text : '[${m.type.name}]';
                          _repliedToSenderName = senderName;
                        });
                        Navigator.pop(dialogCtx);
                      },
                    );
                  },
                ),
        ),
        actions: [
          TextButton(
            child: const Text('Cancel', style: TextStyle(color: Colors.white38)),
            onPressed: () => Navigator.pop(dialogCtx),
          ),
        ],
      ),
    );
  }
}

class _SLabel extends StatelessWidget {
  final String text;
  const _SLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white38, letterSpacing: 0.5),
    );
  }
}

class _SideButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isActive;
  final Color color;
  final VoidCallback onTap;

  const _SideButton({
    required this.label,
    required this.icon,
    required this.isActive,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isActive ? color.withOpacity(0.15) : const Color(0xFF242424),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isActive ? color : Colors.transparent),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 18, color: isActive ? color : Colors.white38),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: isActive ? color : Colors.white38,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TimePreset extends StatelessWidget {
  final String label;
  final Duration offset;
  final void Function(DateTime) onSelect;

  const _TimePreset({required this.label, required this.offset, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onSelect(DateTime.now().subtract(offset)),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFF242424),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(label, style: const TextStyle(color: Colors.white38, fontSize: 12)),
      ),
    );
  }
}

class _NumberPickerSimple extends StatelessWidget {
  final String label;
  final int value;
  final int min;
  final int max;
  final void Function(int) onChanged;

  const _NumberPickerSimple({
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
        Text(label, style: const TextStyle(color: Colors.white38, fontSize: 11)),
        const SizedBox(height: 4),
        Row(
          children: [
            IconButton(
              icon: const Icon(Icons.remove_circle_outline, color: Colors.white38, size: 20),
              onPressed: value > min ? () => onChanged(value - 1) : null,
            ),
            SizedBox(
              width: 32,
              child: Text(
                value.toString().padLeft(2, '0'),
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.add_circle_outline, color: Color(0xFF6C63FF), size: 20),
              onPressed: value < max ? () => onChanged(value + 1) : null,
            ),
          ],
        ),
      ],
    );
  }
}
