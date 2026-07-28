import 'dart:io' as io;
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../models/chat_models.dart';
import '../providers/chat_provider.dart';
import '../providers/theme_provider.dart';
import '../themes/platform_themes.dart';
import '../utils/language_helper.dart';
import 'editor_panel.dart';
import 'background_remover_dialog.dart';

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
  late TextEditingController _fileNameController;
  late TextEditingController _fileSizeController;
  late bool _isSender;
  late MessageStatus _status;
  late DateTime _timestamp;
  late MessageType _type;
  late bool _isVoiceNote;
  late bool _isVideoMessage;
  late bool _isForwarded;
  late bool _isDeleted;
  late bool _isOneTime;
  late bool _isOneTimeOpened;

  int _minutes = 0;
  int _seconds = 30;
  String _callStatus = 'Answered';
  String? _selectedReaction;
  Uint8List? _imageBytes;
  Uint8List? _videoBytes;
  Uint8List? _audioBytes;

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
    _fileNameController = TextEditingController(text: msg?.fileName ?? '');
    _fileSizeController = TextEditingController(text: msg?.fileSize ?? '');
    _isSender = msg?.isSender ?? chatProvider.isSenderMode;
    _status = msg?.status ?? MessageStatus.read;
    _timestamp = msg?.timestamp ?? DateTime.now();
    _type = msg?.type ?? widget.defaultType ?? MessageType.text;
    _selectedReaction = msg?.reaction;
    _imageBytes = msg?.imageBytes;
    _videoBytes = msg?.videoBytes;
    _audioBytes = msg?.audioBytes;
    _isVoiceNote = msg?.isVoiceNote ?? false;
    _isVideoMessage = msg?.isVideoMessage ?? false;
    _isForwarded = msg?.isForwarded ?? false;
    _isDeleted = msg?.isDeleted ?? false;
    _isOneTime = msg?.isOneTime ?? false;
    _isOneTimeOpened = msg?.isOneTimeOpened ?? false;

    // Guard against stale data (e.g. edited on a different platform before)
    // that no real app could actually produce - e.g. a one-time voice note
    // on Instagram, which has no such feature.
    final loadedPlatform = chatProvider.activeSession?.platform ?? Platform.whatsapp;
    if (_isOneTime && !MessageFeatureRules.canBeOneTime(loadedPlatform, _type)) {
      _isOneTime = false;
    }

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

    // Load duration details if call or audio or video
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
    _fileNameController.dispose();
    _fileSizeController.dispose();
    super.dispose();
  }

  ChatMessage? _getRepliedToMessageObj() {
    if (_repliedToId == null) return null;
    final chatProvider = context.read<ChatProvider>();
    for (final m in chatProvider.activeMessages) {
      if (m.id == _repliedToId) {
        return m;
      }
    }
    return null;
  }

  String _getMediaReplyLabelText(ChatMessage m, bool isMessengerOrInstagram) {
    if (m.text.isNotEmpty) return m.text;
    
    final isArabicLocale = context.read<ThemeProvider>().isArabic;
    if (isMessengerOrInstagram) {
      return isArabicLocale ? 'مرفق' : 'Attachment';
    }
    
    switch (m.type) {
      case MessageType.image:
        return isArabicLocale ? 'صورة' : 'Photo';
      case MessageType.video:
        final durationStr = _formatAudioDuration(m.audioDuration);
        return isArabicLocale ? 'مقطع فيديو$durationStr' : 'Video$durationStr';
      case MessageType.audio:
        final durationStr = _formatAudioDuration(m.audioDuration);
        final label = isArabicLocale ? 'رسالة صوتية' : 'Voice message';
        return '$label$durationStr';
      default:
        return '[${m.type.name}]';
    }
  }

  String _formatAudioDuration(Duration? d) {
    if (d == null || d == Duration.zero) return '';
    final mins = d.inMinutes;
    final secs = d.inSeconds % 60;
    final secsStr = secs.toString().padLeft(2, '0');
    return ' ($mins:$secsStr)';
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final file = await picker.pickImage(source: ImageSource.gallery, maxWidth: 1024, maxHeight: 1024);
    if (file != null) {
      final bytes = await file.readAsBytes();
      setState(() => _imageBytes = bytes);
    }
  }

  Future<void> _pickStickerDirect() async {
    final picker = ImagePicker();
    final file = await picker.pickImage(source: ImageSource.gallery, maxWidth: 1024, maxHeight: 1024);
    if (file != null) {
      final bytes = await file.readAsBytes();
      setState(() {
        _imageBytes = bytes;
        _type = MessageType.sticker;
      });
    }
  }

  Future<void> _pickStickerAndRemoveBackground() async {
    final picker = ImagePicker();
    final file = await picker.pickImage(source: ImageSource.gallery, maxWidth: 1024, maxHeight: 1024);
    if (file != null) {
      final bytes = await file.readAsBytes();
      if (!mounted) return;
      final processedBytes = await showDialog<Uint8List>(
        context: context,
        builder: (_) => BackgroundRemoverDialog(originalBytes: bytes),
      );
      if (processedBytes != null) {
        setState(() {
          _imageBytes = processedBytes;
          _type = MessageType.sticker;
        });
      }
    }
  }

  Future<void> _pickVideo() async {
    final picker = ImagePicker();
    final file = await picker.pickVideo(source: ImageSource.gallery);
    if (file != null) {
      final bytes = await file.readAsBytes();
      setState(() => _videoBytes = bytes);
    }
  }

  Future<void> _pickAudioFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.audio,
        withData: true,
      );
      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        Uint8List? bytes = file.bytes;
        if (bytes == null && file.path != null) {
          bytes = await io.File(file.path!).readAsBytes();
        }
        if (bytes != null) {
          setState(() {
            _audioBytes = bytes;
            _fileNameController.text = file.name;
            final mb = bytes!.length / (1024 * 1024);
            _fileSizeController.text = '${mb.toStringAsFixed(1)} MB';
          });
        }
      }
    } catch (e) {
      debugPrint('Error picking audio file: $e');
    }
  }

  void _recordVoiceNote() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => VoiceRecorderDialog(
        onConfirm: (duration, audioBytes) {
          setState(() {
            _audioBytes = audioBytes;
            _minutes = duration.inMinutes;
            _seconds = duration.inSeconds % 60;
          });
        },
      ),
    );
  }

  void _save() {
    final chatProvider = context.read<ChatProvider>();
    final text = _textController.text.trim();

    if (_type == MessageType.text && text.isEmpty && !_isDeleted && !_isOneTime) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Message text cannot be empty')),
      );
      return;
    }
    if (_type == MessageType.dateDivider && text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Date separator text cannot be empty')),
      );
      return;
    }

    final Duration? finalDuration = (_type == MessageType.audio || _type == MessageType.video || _type == MessageType.voiceCall || _type == MessageType.videoCall)
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
          isVoiceNote: _isVoiceNote,
          isVideoMessage: _isVideoMessage,
          fileName: _fileNameController.text.trim().isEmpty ? null : _fileNameController.text.trim(),
          fileSize: _fileSizeController.text.trim().isEmpty ? null : _fileSizeController.text.trim(),
          videoBytes: _videoBytes,
          isForwarded: _isForwarded,
          audioBytes: _audioBytes,
          clearAudioBytes: _audioBytes == null,
          isDeleted: _isDeleted,
          isOneTime: _isOneTime,
          isOneTimeOpened: _isOneTimeOpened,
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
        isVoiceNote: _isVoiceNote,
        isVideoMessage: _isVideoMessage,
        fileName: _fileNameController.text.trim().isEmpty ? null : _fileNameController.text.trim(),
        fileSize: _fileSizeController.text.trim().isEmpty ? null : _fileSizeController.text.trim(),
        videoBytes: _videoBytes,
        isForwarded: _isForwarded,
        audioBytes: _audioBytes,
        isDeleted: _isDeleted,
        isOneTime: _isOneTime,
        isOneTimeOpened: _isOneTimeOpened,
      );
      chatProvider.addMessage(newMessage);
    }
    Navigator.pop(context);
  }

  String _typeLabel(MessageType t, bool isAr) {
    switch (t) {
      case MessageType.text: return isAr ? 'رسالة نصية' : 'Text Message';
      case MessageType.image: return isAr ? 'رسالة صورة' : 'Image Message';
      case MessageType.sticker: return isAr ? 'ملصق' : 'Sticker';
      case MessageType.audio: return isAr ? 'رسالة صوتية' : 'Audio Message';
      case MessageType.video: return isAr ? 'رسالة فيديو' : 'Video Message';
      case MessageType.voiceCall: return isAr ? 'سجل مكالمة صوتية' : 'Voice Call Record';
      case MessageType.videoCall: return isAr ? 'سجل مكالمة فيديو' : 'Video Call Record';
      case MessageType.dateDivider: return isAr ? 'فاصل تاريخ' : 'Date Separator';
    }
  }

  String _oneTimeChipLabel(MessageType t, bool isAr) {
    switch (t) {
      case MessageType.image: return isAr ? 'صورة' : 'Photo';
      case MessageType.video: return isAr ? 'مقطع فيديو' : 'Video';
      case MessageType.audio: return isAr ? 'صوتية' : 'Voice';
      default: return isAr ? 'وسائط' : 'Media';
    }
  }

  String _platformDisplayName(Platform p, bool isAr) {
    switch (p) {
      case Platform.whatsapp: return 'WhatsApp';
      case Platform.messenger: return 'Messenger';
      case Platform.instagram: return 'Instagram';
      case Platform.snapchat: return 'Snapchat';
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final chatProvider = context.watch<ChatProvider>();
    final themeProvider = context.watch<ThemeProvider>();
    final isAr = themeProvider.isArabic;
    final session = chatProvider.activeSession;
    final platform = session?.platform ?? Platform.whatsapp;
    final platformTheme = session != null ? PlatformTheme.of(session.platform, isDark: true) : null;
    final accentColor = platformTheme?.sendButtonColor ?? const Color(0xFF6C63FF);
    final labelColor = Colors.white30;

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
            _SLabel(LanguageHelper.translate('choose_type', isAr)),
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
                      child: Text(_typeLabel(type, isAr)),
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
                        if (_isOneTime && !MessageFeatureRules.canBeOneTime(platform, _type)) {
                          _isOneTime = false;
                        }
                        if (_isDeleted && !MessageFeatureRules.canBeDeleted(_type)) {
                          _isDeleted = false;
                        }
                      });
                    }
                  },
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Presentation Formats (Voice Note vs Audio File, Circular Video vs Standard Video)
            if (_type == MessageType.audio) ...[
              _SLabel(LanguageHelper.translate('layout_format', isAr)),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFF242424),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<bool>(
                    value: _isVoiceNote,
                    dropdownColor: const Color(0xFF1E1E1E),
                    isExpanded: true,
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                    items: [
                      DropdownMenuItem(value: true, child: Text(LanguageHelper.translate('rec_voice_note_menu', isAr))),
                      DropdownMenuItem(value: false, child: Text(LanguageHelper.translate('add_audio_file_menu', isAr))),
                    ],
                    onChanged: (v) {
                      if (v != null) {
                        setState(() {
                          _isVoiceNote = v;
                          _audioBytes = null;
                        });
                      }
                    },
                  ),
                ),
              ),
              const SizedBox(height: 16),
              if (_isVoiceNote) ...[
                _SLabel(LanguageHelper.translate('recording_voice_note', isAr)),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: _recordVoiceNote,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF242424),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _audioBytes != null ? const Color(0xFF00A884) : Colors.white12,
                        width: _audioBytes != null ? 1.5 : 1,
                      ),
                    ),
                    child: Center(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            _audioBytes != null ? Icons.check_circle_rounded : Icons.mic_none_rounded,
                            color: _audioBytes != null ? const Color(0xFF00A884) : Colors.white38,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _audioBytes != null
                                ? (isAr ? 'تم تسجيل رسالة صوتية (${_minutes.toString().padLeft(2, '0')}:${_seconds.toString().padLeft(2, '0')})' : 'Voice Note Recorded (${_minutes.toString().padLeft(2, '0')}:${_seconds.toString().padLeft(2, '0')})')
                                : (isAr ? 'اضغط لتسجيل رسالة صوتية' : 'Tap to Record Voice Note'),
                            style: TextStyle(
                              color: _audioBytes != null ? Colors.white : Colors.white38,
                              fontSize: 13,
                            ),
                          ),
                          if (_audioBytes != null) ...[
                            const SizedBox(width: 12),
                            GestureDetector(
                              onTap: () {
                                setState(() {
                                  _audioBytes = null;
                                  _minutes = 0;
                                  _seconds = 0;
                                });
                              },
                              child: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 18),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ] else ...[
                _SLabel(LanguageHelper.translate('add_audio_file', isAr)),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: _pickAudioFile,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF242424),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _audioBytes != null ? const Color(0xFF6C63FF) : Colors.white12,
                        width: _audioBytes != null ? 1.5 : 1,
                      ),
                    ),
                    child: Center(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            _audioBytes != null ? Icons.audiotrack_rounded : Icons.library_music_rounded,
                            color: _audioBytes != null ? const Color(0xFF6C63FF) : Colors.white38,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _audioBytes != null
                                  ? '${LanguageHelper.translate('audio', isAr)}: ${_fileNameController.text} (${_fileSizeController.text})'
                                  : LanguageHelper.translate('tap_to_pick_audio', isAr),
                              textAlign: TextAlign.center,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: _audioBytes != null ? Colors.white : Colors.white38,
                                fontSize: 13,
                              ),
                            ),
                          ),
                          if (_audioBytes != null) ...[
                            const SizedBox(width: 12),
                            GestureDetector(
                              onTap: () {
                                setState(() {
                                  _audioBytes = null;
                                  _fileNameController.clear();
                                  _fileSizeController.clear();
                                });
                              },
                              child: const Padding(
                                padding: EdgeInsets.symmetric(horizontal: 8.0),
                                child: Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 18),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                _SLabel(LanguageHelper.translate('file_name', isAr)),
                const SizedBox(height: 6),
                TextField(
                  controller: _fileNameController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(hintText: isAr ? 'مثال: AUD-20260614-WA0001.mp3' : 'e.g. AUD-20260614-WA0001.mp3'),
                ),
                const SizedBox(height: 16),
                _SLabel(LanguageHelper.translate('file_size', isAr)),
                const SizedBox(height: 6),
                TextField(
                  controller: _fileSizeController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(hintText: isAr ? 'مثال: 1.2 ميجابايت' : 'e.g. 1.2 MB'),
                ),
                const SizedBox(height: 16),
              ],
            ],

            if (_type == MessageType.video) ...[
              _SLabel(LanguageHelper.translate('layout_format', isAr)),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFF242424),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<bool>(
                    value: _isVideoMessage,
                    dropdownColor: const Color(0xFF1E1E1E),
                    isExpanded: true,
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                    items: [
                      DropdownMenuItem(value: true, child: Text(LanguageHelper.translate('instant_video_note', isAr))),
                      DropdownMenuItem(value: false, child: Text(LanguageHelper.translate('standard_video_attachment', isAr))),
                    ],
                    onChanged: (v) {
                      if (v != null) {
                        setState(() {
                          _isVideoMessage = v;
                        });
                      }
                    },
                  ),
                ),
              ),
              const SizedBox(height: 16),
              if (!_isVideoMessage) ...[
                _SLabel(LanguageHelper.translate('file_name', isAr)),
                const SizedBox(height: 6),
                TextField(
                  controller: _fileNameController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(hintText: isAr ? 'مثال: VID-20260614-WA0001.mp4' : 'e.g. VID-20260614-WA0001.mp4'),
                ),
                const SizedBox(height: 16),
                _SLabel(LanguageHelper.translate('file_size', isAr)),
                const SizedBox(height: 6),
                TextField(
                  controller: _fileSizeController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(hintText: isAr ? 'مثال: 4.2 ميجابايت' : 'e.g. 4.2 MB'),
                ),
                const SizedBox(height: 16),
              ],
            ],

            // Quoted Reply Section (Hidden for dateDividers)
            if (_type != MessageType.dateDivider) ...[
              _SLabel(LanguageHelper.translate('add_quoted_reply', isAr)),
              const SizedBox(height: 6),
              if (_repliedToId != null) ...[
                Builder(
                  builder: (context) {
                    final repliedToMsgObj = _getRepliedToMessageObj();
                    IconData? quotedIcon;
                    String quotedText = _repliedToText ?? '';
                    final platform = session?.platform ?? Platform.whatsapp;
                    final isMessengerOrInstagram = platform == Platform.messenger || platform == Platform.instagram;
                    
                    if (repliedToMsgObj != null) {
                      quotedText = _getMediaReplyLabelText(repliedToMsgObj, isMessengerOrInstagram);
                      if (isMessengerOrInstagram) {
                        quotedIcon = Icons.attachment_rounded;
                      } else {
                        switch (repliedToMsgObj.type) {
                          case MessageType.image:
                            quotedIcon = Icons.camera_alt_rounded;
                            break;
                          case MessageType.video:
                            quotedIcon = Icons.videocam_rounded;
                            break;
                          case MessageType.audio:
                            quotedIcon = repliedToMsgObj.isVoiceNote ? Icons.mic_rounded : Icons.audiotrack_rounded;
                            break;
                          default:
                            break;
                        }
                      }
                    }

                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF242424),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFF4CAF50).withValues(alpha: 0.3)),
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
                                  _repliedToSenderName ?? LanguageHelper.translate('contact', isAr),
                                  style: const TextStyle(
                                    color: Color(0xFF4CAF50),
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Row(
                                  children: [
                                    if (quotedIcon != null) ...[
                                      Icon(quotedIcon, size: 13, color: Colors.white54),
                                      const SizedBox(width: 4),
                                    ],
                                    Expanded(
                                      child: Text(
                                        quotedText,
                                        style: const TextStyle(color: Colors.white70, fontSize: 12),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                           if (repliedToMsgObj != null &&
                              (repliedToMsgObj.type == MessageType.image || repliedToMsgObj.type == MessageType.video)) ...[
                            const SizedBox(width: 10),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: Builder(
                                builder: (context) {
                                  Widget imgWidget;
                                  if (repliedToMsgObj.imageBytes != null) {
                                    imgWidget = Image.memory(
                                      repliedToMsgObj.imageBytes!,
                                      width: 36,
                                      height: 36,
                                      fit: BoxFit.cover,
                                    );
                                  } else {
                                    final placeholderUrl = repliedToMsgObj.type == MessageType.image
                                        ? 'https://images.unsplash.com/photo-1618005182384-a83a8bd57fbe?w=100&h=100&fit=crop'
                                        : 'https://images.unsplash.com/photo-1492691527719-9d1e07e534b4?w=100&h=100&fit=crop';
                                    imgWidget = Image.network(
                                      placeholderUrl,
                                      width: 36,
                                      height: 36,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) => Container(
                                        width: 36,
                                        height: 36,
                                        color: Colors.white12,
                                        child: Icon(
                                          repliedToMsgObj.type == MessageType.image
                                              ? Icons.image_rounded
                                              : Icons.videocam_rounded,
                                          size: 14,
                                          color: Colors.white38,
                                        ),
                                      ),
                                    );
                                  }

                                  if (repliedToMsgObj.type == MessageType.video) {
                                    return SizedBox(
                                      width: 36,
                                      height: 36,
                                      child: Stack(
                                        alignment: Alignment.center,
                                        children: [
                                          Positioned.fill(child: imgWidget),
                                          Container(
                                            padding: const EdgeInsets.all(2),
                                            decoration: const BoxDecoration(
                                              shape: BoxShape.circle,
                                              color: Colors.black38,
                                            ),
                                            child: const Icon(
                                              Icons.play_arrow_rounded,
                                              size: 12,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  } else {
                                    return imgWidget;
                                  }
                                }
                              ),
                            ),
                          ],
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
                );
              },
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
                  label: Text(LanguageHelper.translate('add_quoted_reply', isAr)),
                  onPressed: () => _showSelectReplyDialog(context),
                ),
              ],
              const SizedBox(height: 16),
            ],

            // Text Input Box (Hidden for calls, shown for text/image/dateDividers)
            if (_type != MessageType.voiceCall && _type != MessageType.videoCall) ...[
              // Video picker (only for video type)
              if (_type == MessageType.video) ...[
                _SLabel(isAr ? 'إطار غلاف الفيديو / الصورة المصغرة' : 'Video Cover Frame / Thumbnail'),
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
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(Icons.swap_horiz_rounded, size: 14, color: Colors.white),
                                        const SizedBox(width: 4),
                                        Text(LanguageHelper.translate('change_cover_frame', isAr), style: const TextStyle(color: Colors.white, fontSize: 12)),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          )
                        : Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.add_photo_alternate_outlined, size: 32, color: labelColor),
                              const SizedBox(height: 8),
                              Text(LanguageHelper.translate('tap_to_pick_video_cover', isAr), style: TextStyle(color: labelColor, fontSize: 13)),
                            ],
                          ),
                  ),
                ),
                const SizedBox(height: 16),
                _SLabel(isAr ? 'ملف الفيديو (اختياري)' : 'Video File (Optional)'),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: _pickVideo,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF242424),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _videoBytes != null ? const Color(0xFF6C63FF) : Colors.white12,
                        width: _videoBytes != null ? 1.5 : 1,
                      ),
                    ),
                    child: Center(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            _videoBytes != null ? Icons.video_file_rounded : Icons.video_library_rounded,
                            color: _videoBytes != null ? const Color(0xFF6C63FF) : Colors.white38,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _videoBytes != null
                                ? (isAr
                                    ? 'تغيير ملف الفيديو (${(_videoBytes!.length / 1024 / 1024).toStringAsFixed(1)} ميجابايت)'
                                    : 'Change Video File (${(_videoBytes!.length / 1024 / 1024).toStringAsFixed(1)} MB)')
                                : (isAr ? 'اختر ملف الفيديو' : 'Pick Video File'),
                            style: TextStyle(
                              color: _videoBytes != null ? const Color(0xFF6C63FF) : Colors.white38,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
              // Image picker (only for image type)
              if (_type == MessageType.image) ...[
                _SLabel(LanguageHelper.translate('image', isAr)),
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
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(Icons.swap_horiz_rounded, size: 14, color: Colors.white),
                                        const SizedBox(width: 4),
                                        Text(LanguageHelper.translate('change', isAr), style: const TextStyle(color: Colors.white, fontSize: 12)),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          )
                        : Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.add_photo_alternate_outlined, size: 32, color: labelColor),
                              const SizedBox(height: 8),
                              Text(LanguageHelper.translate('tap_to_pick_image', isAr), style: TextStyle(color: labelColor, fontSize: 13)),
                            ],
                          ),
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Sticker picker options (for sticker type)
              if (_type == MessageType.sticker) ...[
                _SLabel(isAr ? 'صورة الملصق' : 'Sticker Image'),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF242424),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                            side: const BorderSide(color: Colors.white24),
                          ),
                        ),
                        icon: const Icon(Icons.image_outlined, size: 18),
                        label: Text(
                          isAr ? 'صورة مباشرة' : 'Direct Image',
                          style: const TextStyle(fontSize: 12.5),
                        ),
                        onPressed: _pickStickerDirect,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF25D366),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        icon: const Icon(Icons.auto_fix_high_rounded, size: 18),
                        label: Text(
                          isAr ? 'إزالة الخلفية' : 'Remove BG',
                          style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold),
                        ),
                        onPressed: _pickStickerAndRemoveBackground,
                      ),
                    ),
                  ],
                ),
                if (_imageBytes != null) ...[
                  const SizedBox(height: 10),
                  Center(
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF242424),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white24),
                      ),
                      child: Image.memory(_imageBytes!, width: 100, height: 100, fit: BoxFit.contain),
                    ),
                  ),
                ],
                const SizedBox(height: 16),
              ],
              _SLabel(_type == MessageType.dateDivider ? (isAr ? 'ملصق فاصل التاريخ' : 'Date Separator Label') : (_type == MessageType.image ? (isAr ? 'شرح الصورة (اختياري)' : 'Caption (Optional)') : (isAr ? 'نص الرسالة' : 'Message Text'))),
              const SizedBox(height: 6),
              TextField(
                controller: _textController,
                style: const TextStyle(color: Colors.white),
                maxLines: _type == MessageType.dateDivider ? 1 : 3,
                decoration: InputDecoration(
                  hintText: _type == MessageType.dateDivider ? (isAr ? 'مثال: الأحد، 25 مايو، أو اليوم' : 'e.g., Sunday, May 25, or TODAY') : (isAr ? 'اكتب رسالتك المحاكاة...' : 'Type your text here...'),
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Date Preset capsules (Only for dateDivider)
            if (_type == MessageType.dateDivider) ...[
              _SLabel(isAr ? 'قوالب التاريخ الجاهزة' : 'Date Presets'),
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
                      child: Text(
                        preset == 'Call Logs' && isAr ? 'سجل المكالمات' : LanguageHelper.translateDate(preset, isAr),
                        style: const TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
            ],

            // Call Status Selector capsules (Only for voice/video calls)
            if (_type == MessageType.voiceCall || _type == MessageType.videoCall) ...[
              _SLabel(isAr ? 'تفاصيل حالة المكالمة' : 'Call Status Details'),
              const SizedBox(height: 8),
              Row(
                children: ['Answered', 'Missed', 'Declined', 'No Answer'].map((status) {
                  final isSelected = _callStatus == status;
                  final statusLabelText = status == 'Answered'
                      ? (isAr ? 'تم الرد عليها' : 'Answered')
                      : status == 'Missed'
                          ? (isAr ? 'فائتة' : 'Missed')
                          : status == 'Declined'
                              ? (isAr ? 'مرفوضة' : 'Declined')
                              : (isAr ? 'لم يرد عليها' : 'No Answer');
                  return Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _callStatus = status),
                      child: Container(
                        margin: const EdgeInsets.only(right: 6),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? accentColor.withValues(alpha: 0.18)
                              : const Color(0xFF242424),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: isSelected ? accentColor : Colors.transparent,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            statusLabelText,
                            style: TextStyle(
                              fontSize: 11,
                              color: isSelected ? accentColor : Colors.white70,
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

            // Call / Audio / Video Duration Picker (Only when audio OR video OR call status is Answered)
            if (_type == MessageType.audio || 
                _type == MessageType.video ||
                ((_type == MessageType.voiceCall || _type == MessageType.videoCall) && _callStatus == 'Answered')) ...[
              _SLabel(isAr ? 'مدة المكالمة / الصوت' : 'Call / Audio Duration'),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _NumberPickerSimple(
                    label: isAr ? 'دقيقة' : 'Min',
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
                    label: isAr ? 'ثانية' : 'Sec',
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
              _SLabel(isAr ? 'تفاعل الرسالة (إيموجي)' : 'Message Reaction (Emoji)'),
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
                            ? accentColor.withValues(alpha: 0.18)
                            : const Color(0xFF242424),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isSelected ? accentColor : Colors.transparent,
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
                decoration: InputDecoration(
                  hintText: isAr ? 'أو اكتب تفاعل إيموجي مخصص...' : 'Or type custom reaction emoji...',
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
              _SLabel(_type == MessageType.voiceCall || _type == MessageType.videoCall ? (isAr ? 'اتجاه المكالمة' : 'Call Direction') : (isAr ? 'الطرف المرسل' : 'Side')),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _SideButton(
                      label: (_type == MessageType.voiceCall || _type == MessageType.videoCall) ? (isAr ? 'صادرة (يمين)' : 'Outgoing (Right)') : (isAr ? 'أنا (اليمين)' : 'Me (Right)'),
                      icon: Icons.send_rounded,
                      isActive: _isSender,
                      color: accentColor,
                      onTap: () => setState(() => _isSender = true),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _SideButton(
                      label: (_type == MessageType.voiceCall || _type == MessageType.videoCall) ? (isAr ? 'واردة (يسار)' : 'Incoming (Left)') : (isAr ? 'الطرف الآخر (اليسار)' : 'Them (Left)'),
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

            // Forwarded Message Toggle
            if (_type != MessageType.dateDivider) ...[
              Row(
                children: [
                  Expanded(
                    child: Text(LanguageHelper.translate('forwarded_message', isAr), style: const TextStyle(color: Colors.white70, fontSize: 14)),
                  ),
                  Switch(
                    value: _isForwarded,
                    activeColor: accentColor,
                    onChanged: (v) => setState(() => _isForwarded = v),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Deleted Message Toggle
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF242424),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.do_not_disturb_alt_rounded, color: Colors.redAccent, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        isAr ? 'رسالة محذوفة (ألغيت)' : 'Deleted Message (Unsent)',
                        style: const TextStyle(color: Colors.white, fontSize: 13.5),
                      ),
                    ),
                    Switch(
                      value: _isDeleted,
                      activeColor: Colors.redAccent,
                      onChanged: (v) => setState(() => _isDeleted = v),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),

              // View Once / One Time Toggle - only offered for media types that
              // are actually eligible on the current platform in real apps
              // (e.g. Messenger/Instagram have no one-time voice notes).
              if (MessageFeatureRules.isOneTimeCapableType(_type)) ...[
                Builder(builder: (context) {
                  final oneTimeSupported = MessageFeatureRules.canBeOneTime(platform, _type);
                  final eligibleTypes = [MessageType.image, MessageType.video, MessageType.audio]
                      .where((t) => MessageFeatureRules.canBeOneTime(platform, t))
                      .toList();
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF242424),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Icon(Icons.looks_one_rounded, color: oneTimeSupported ? const Color(0xFF25D366) : Colors.white24, size: 20),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                isAr ? 'عرض لمرة واحدة (View Once)' : 'View Once (One Time)',
                                style: TextStyle(color: oneTimeSupported ? Colors.white : Colors.white38, fontSize: 13.5),
                              ),
                            ),
                            Switch(
                              value: oneTimeSupported && _isOneTime,
                              activeColor: const Color(0xFF25D366),
                              onChanged: oneTimeSupported ? (v) => setState(() => _isOneTime = v) : null,
                            ),
                          ],
                        ),
                        if (!oneTimeSupported)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Align(
                              alignment: isAr ? Alignment.centerRight : Alignment.centerLeft,
                              child: Text(
                                isAr
                                    ? '${_platformDisplayName(platform, isAr)} لا يدعم عرض ${_oneTimeChipLabel(_type, isAr)} لمرة واحدة'
                                    : '${_platformDisplayName(platform, isAr)} doesn\'t support view-once ${_oneTimeChipLabel(_type, false).toLowerCase()}',
                                style: const TextStyle(color: Colors.white38, fontSize: 11.5, fontStyle: FontStyle.italic),
                              ),
                            ),
                          ),
                        if (_isOneTime && oneTimeSupported) ...[
                          const Divider(color: Colors.white10),
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      isAr ? 'حالة القراءة:' : 'Viewed State:',
                                      style: const TextStyle(color: Colors.white70, fontSize: 12.5),
                                    ),
                                    const Spacer(),
                                    ChoiceChip(
                                      label: Text(isAr ? 'لم تُفتح' : 'Unopened'),
                                      selected: !_isOneTimeOpened,
                                      selectedColor: const Color(0xFF25D366),
                                      backgroundColor: Colors.white10,
                                      labelStyle: TextStyle(color: !_isOneTimeOpened ? Colors.black : Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                                      onSelected: (val) => setState(() => _isOneTimeOpened = !val),
                                    ),
                                    const SizedBox(width: 8),
                                    ChoiceChip(
                                      label: Text(isAr ? 'تم فتحها' : 'Opened'),
                                      selected: _isOneTimeOpened,
                                      selectedColor: Colors.grey,
                                      backgroundColor: Colors.white10,
                                      labelStyle: TextStyle(color: _isOneTimeOpened ? Colors.black : Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                                      onSelected: (val) => setState(() => _isOneTimeOpened = val),
                                    ),
                                  ],
                                ),
                                if (!_isOneTimeOpened && eligibleTypes.length > 1) ...[
                                  const SizedBox(height: 8),
                                  Text(
                                    isAr ? 'نوع الوسائط:' : 'Media Category:',
                                    style: const TextStyle(color: Colors.white70, fontSize: 12.5),
                                  ),
                                  const SizedBox(height: 6),
                                  Row(
                                    children: [
                                      for (final t in eligibleTypes) ...[
                                        ChoiceChip(
                                          label: Text(_oneTimeChipLabel(t, isAr)),
                                          selected: _type == t,
                                          selectedColor: const Color(0xFF25D366),
                                          backgroundColor: Colors.white10,
                                          labelStyle: TextStyle(color: _type == t ? Colors.black : Colors.white, fontSize: 11.5),
                                          onSelected: (val) {
                                            if (val) {
                                              setState(() {
                                                _type = t;
                                                _textController.text = '';
                                              });
                                            }
                                          },
                                        ),
                                        if (t != eligibleTypes.last) const SizedBox(width: 6),
                                      ],
                                    ],
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  );
                }),
                const SizedBox(height: 16),
              ],
            ],

            // Message Status (only for sender & text/image/audio)
            if (_isSender && _type != MessageType.dateDivider && _type != MessageType.voiceCall && _type != MessageType.videoCall) ...[
              _SLabel(isAr ? 'حالة الرسالة' : 'Message Status'),
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
                              ? accentColor.withValues(alpha: 0.18)
                              : const Color(0xFF242424),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: _status == s ? accentColor : Colors.transparent,
                          ),
                        ),
                        child: Column(
                          children: [
                            Icon(_statusIcon(s), size: 18, color: _status == s ? accentColor : Colors.white38),
                            const SizedBox(height: 3),
                            Text(
                              _statusLabel(s, isAr),
                              style: TextStyle(
                                fontSize: 10,
                                color: _status == s ? accentColor : Colors.white38,
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
            _SLabel(isAr ? 'طابع الوقت (تغيير الوقت)' : 'Timestamp (Change Time)'),
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
                _TimePreset(label: isAr ? 'الآن' : 'Just now', offset: Duration.zero, onSelect: (dt) => setState(() => _timestamp = dt)),
                _TimePreset(label: isAr ? 'منذ 5 دقائق' : '5 min ago', offset: const Duration(minutes: 5), onSelect: (dt) => setState(() => _timestamp = dt)),
                _TimePreset(label: isAr ? 'منذ ساعة' : '1 hr ago', offset: const Duration(hours: 1), onSelect: (dt) => setState(() => _timestamp = dt)),
                _TimePreset(label: LanguageHelper.translate('yesterday', isAr), offset: const Duration(days: 1), onSelect: (dt) => setState(() => _timestamp = dt)),
              ],
            ),

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
                child: Text(
                  widget.editingMessage != null
                      ? (isAr ? 'تعديل المكون' : 'Update Component')
                      : (isAr ? 'إضافة المكون' : 'Add Component'),
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

  String _statusLabel(MessageStatus s, bool isAr) {
    switch (s) {
      case MessageStatus.sending: return isAr ? 'جاري الإرسال' : 'Sending';
      case MessageStatus.sent: return isAr ? 'تم الإرسال' : 'Sent';
      case MessageStatus.delivered: return isAr ? 'تم التسليم' : 'Delivered';
      case MessageStatus.read: return isAr ? 'مقروءة' : 'Read';
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
    final isAr = context.read<ThemeProvider>().isArabic;

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
        title: Text(LanguageHelper.translate('select_message_to_quote', isAr), style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
        content: SizedBox(
          width: double.maxFinite,
          child: otherMessages.isEmpty
              ? Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  child: Text(
                    isAr ? 'لا توجد رسائل أخرى في هذه الدردشة للرد عليها.' : 'No other messages in this chat to reply to.',
                    style: const TextStyle(color: Colors.white38),
                    textAlign: TextAlign.center,
                  ),
                )
              : ListView.builder(
                  shrinkWrap: true,
                  itemCount: otherMessages.length,
                  itemBuilder: (listCtx, index) {
                    final m = otherMessages[index];
                    final chatProvider = context.read<ChatProvider>();
                    final session = chatProvider.activeSession;
                    final platformTheme = session != null ? PlatformTheme.of(session.platform, isDark: true) : null;
                    final dialogAccentColor = platformTheme?.sendButtonColor ?? const Color(0xFF6C63FF);

                    final senderName = m.isSender
                        ? (isAr ? 'أنت' : 'You')
                        : (session != null && session.contactUser.name.isNotEmpty ? session.contactUser.name : LanguageHelper.translate('contact', isAr));

                    return ListTile(
                      dense: true,
                      contentPadding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                      title: Text(
                        senderName,
                        style: TextStyle(
                          color: m.isSender ? dialogAccentColor : const Color(0xFF42A5F5),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      subtitle: Builder(
                        builder: (context) {
                          final platform = session?.platform ?? Platform.whatsapp;
                          final isMessengerOrInstagram = platform == Platform.messenger || platform == Platform.instagram;
                          return Row(
                            children: [
                              if (isMessengerOrInstagram) ...[
                                if (m.type == MessageType.image || m.type == MessageType.video || m.type == MessageType.audio) ...[
                                  const Icon(Icons.attachment_rounded, size: 12, color: Colors.white54),
                                  const SizedBox(width: 4),
                                ],
                              ] else ...[
                                if (m.type == MessageType.image) ...[
                                  const Icon(Icons.camera_alt_rounded, size: 12, color: Colors.white54),
                                  const SizedBox(width: 4),
                                ] else if (m.type == MessageType.video) ...[
                                  const Icon(Icons.videocam_rounded, size: 12, color: Colors.white54),
                                  const SizedBox(width: 4),
                                ] else if (m.type == MessageType.audio) ...[
                                  Icon(m.isVoiceNote ? Icons.mic_rounded : Icons.audiotrack_rounded, size: 12, color: Colors.white54),
                                  const SizedBox(width: 4),
                                ],
                              ],
                              Expanded(
                                child: Text(
                                  _getMediaReplyLabelText(m, isMessengerOrInstagram),
                                  style: const TextStyle(color: Colors.white70),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          );
                        }
                      ),
                      trailing: (m.type == MessageType.image || m.type == MessageType.video)
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: Builder(
                                builder: (context) {
                                  Widget imgWidget;
                                  if (m.imageBytes != null) {
                                    imgWidget = Image.memory(
                                      m.imageBytes!,
                                      width: 32,
                                      height: 32,
                                      fit: BoxFit.cover,
                                    );
                                  } else {
                                    final placeholderUrl = m.type == MessageType.image
                                        ? 'https://images.unsplash.com/photo-1618005182384-a83a8bd57fbe?w=100&h=100&fit=crop'
                                        : 'https://images.unsplash.com/photo-1492691527719-9d1e07e534b4?w=100&h=100&fit=crop';
                                    imgWidget = Image.network(
                                      placeholderUrl,
                                      width: 32,
                                      height: 32,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) => Container(
                                        width: 32,
                                        height: 32,
                                        color: Colors.white12,
                                        child: Icon(
                                          m.type == MessageType.image
                                              ? Icons.image_rounded
                                              : Icons.videocam_rounded,
                                          size: 14,
                                          color: Colors.white38,
                                        ),
                                      ),
                                    );
                                  }

                                  if (m.type == MessageType.video) {
                                    return SizedBox(
                                      width: 32,
                                      height: 32,
                                      child: Stack(
                                        alignment: Alignment.center,
                                        children: [
                                          Positioned.fill(child: imgWidget),
                                          Container(
                                            padding: const EdgeInsets.all(2),
                                            decoration: const BoxDecoration(
                                              shape: BoxShape.circle,
                                              color: Colors.black38,
                                            ),
                                            child: const Icon(
                                              Icons.play_arrow_rounded,
                                              size: 10,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  } else {
                                    return imgWidget;
                                  }
                                }
                              ),
                            )
                          : null,
                      onTap: () {
                        final platform = session?.platform ?? Platform.whatsapp;
                        final isMessengerOrInstagram = platform == Platform.messenger || platform == Platform.instagram;
                        setState(() {
                          _repliedToId = m.id;
                          _repliedToText = _getMediaReplyLabelText(m, isMessengerOrInstagram);
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
            child: Text(LanguageHelper.translate('cancel', isAr), style: const TextStyle(color: Colors.white38)),
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
          color: isActive ? color.withValues(alpha: 0.15) : const Color(0xFF242424),
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
    final chatProvider = context.watch<ChatProvider>();
    final session = chatProvider.activeSession;
    final platformTheme = session != null ? PlatformTheme.of(session.platform, isDark: true) : null;
    final accentColor = platformTheme?.sendButtonColor ?? const Color(0xFF6C63FF);

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
              icon: Icon(Icons.add_circle_outline, color: accentColor, size: 20),
              onPressed: value < max ? () => onChanged(value + 1) : null,
            ),
          ],
        ),
      ],
    );
  }
}

