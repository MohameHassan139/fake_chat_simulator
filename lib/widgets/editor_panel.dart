import 'dart:async';
import 'dart:io' as io;
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import '../utils/audio_helper.dart';
import '../models/chat_models.dart';
import '../providers/chat_provider.dart';
import '../providers/theme_provider.dart';
import '../utils/language_helper.dart';
import 'contact_editor_sheet.dart';
import 'settings_editor_sheet.dart';
import 'message_editor_sheet.dart';
import 'background_remover_dialog.dart';

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
      final isDark = Theme.of(context).brightness == Brightness.dark;
      return Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF111111) : Colors.white,
          border: Border(top: BorderSide(color: isDark ? const Color(0xFF222222) : const Color(0xFFE2E2E2))),
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
                    color: const Color(0xFF6C63FF).withValues(alpha: 0.1),
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
                        style: TextStyle(
                          color: isDark ? Colors.white : Colors.black87,
                          fontSize: 15.5,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        isAr
                            ? 'أنت تعاين حاليًا صندوق الوارد لتطبيق ${session.platformName}. اضغط على أي محادثة في محاكي الهاتف لفتحها وتعديل محتواها.'
                            : 'You are previewing the inbox feed for ${session.platformName}. Tap any chat inside the phone frame above to open it and edit.',
                        style: TextStyle(
                          color: isDark ? Colors.white54 : Colors.black54,
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
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  // Back to chat button
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: isDark ? const Color(0xFF333333) : const Color(0xFFCCCCCC)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                    ),
                    icon: Icon(Icons.chat_bubble_outline_rounded, color: isDark ? Colors.white70 : Colors.black54, size: 16),
                    label: Text(
                      isAr ? 'العودة للمحادثة' : 'Back to Chat',
                      style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontWeight: FontWeight.bold),
                    ),
                    onPressed: () {
                      chatProvider.setViewChatList(false);
                    },
                  ),
                  const SizedBox(width: 12),
                  // Configure inbox header
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFF333333)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
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
                  const SizedBox(width: 12),
                  // Export screenshot
                  GestureDetector(
                    onTap: isCapturing ? null : onCapture,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 18, vertical: 12),
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
                                const Icon(Icons.camera_alt_rounded,
                                    size: 16, color: Colors.white),
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
            ),
          ],
        ),
      );
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF111111) : Colors.white,
        border: Border(top: BorderSide(color: isDark ? const Color(0xFF222222) : const Color(0xFFE2E2E2))),
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
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _ActionButton(
                    icon: Icons.person_outline_rounded,
                    label: LanguageHelper.translate('contact', isAr),
                    onTap: () => _showContactEditor(context),
                  ),
                  const SizedBox(width: 16),
                  _ActionButton(
                    icon: Icons.settings_outlined,
                    label: LanguageHelper.translate('settings', isAr),
                    onTap: () => _showSettingsEditor(context),
                  ),
                  const SizedBox(width: 16),
                  _ActionButton(
                    icon: Icons.image_outlined,
                    label: LanguageHelper.translate('image', isAr),
                    onTap: () => _pickImage(context),
                  ),
                  const SizedBox(width: 16),
                  _ActionButton(
                    icon: Icons.sticky_note_2_outlined,
                    label: LanguageHelper.translate('sticker', isAr),
                    onTap: () => _showStickerOptions(context),
                  ),
                  const SizedBox(width: 16),
                  _ActionButton(
                    icon: Icons.mic_outlined,
                    label: LanguageHelper.translate('audio', isAr),
                    onTap: () => _showAudioOptions(context),
                  ),
                  const SizedBox(width: 16),
                  _ActionButton(
                    icon: Icons.videocam_outlined,
                    label: LanguageHelper.translate('video', isAr),
                    onTap: () => _showVideoOptions(context),
                  ),
                  const SizedBox(width: 16),
                  _ActionButton(
                    icon: Icons.phone_outlined,
                    label: LanguageHelper.translate('call', isAr),
                    onTap: () => _addCallMessage(context),
                  ),
                  const SizedBox(width: 16),
                  _ActionButton(
                    icon: Icons.calendar_today_outlined,
                    label: LanguageHelper.translate('date', isAr),
                    onTap: () => _showDateDividerEditor(context),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
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

  void _showStickerOptions(BuildContext context) {
    final isAr = context.read<ThemeProvider>().isArabic;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (sheetCtx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.image_outlined, color: Color(0xFF25D366)),
              title: Text(isAr ? 'إضافة صورة كملصق مباشرة' : 'Add Image as Sticker (Direct)', style: TextStyle(color: isDark ? Colors.white : Colors.black87)),
              onTap: () {
                Navigator.pop(sheetCtx);
                _pickStickerDirect(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.auto_fix_high_rounded, color: Color(0xFFFF6584)),
              title: Text(isAr ? 'إضافة ملصق وإزالة الخلفية تلقائيًا' : 'Add Sticker with Background Removal', style: TextStyle(color: isDark ? Colors.white : Colors.black87)),
              onTap: () {
                Navigator.pop(sheetCtx);
                _pickStickerAndRemoveBackground(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickStickerDirect(BuildContext context) async {
    final picker = ImagePicker();
    final file = await picker.pickImage(source: ImageSource.gallery, maxWidth: 1024, maxHeight: 1024);
    if (file != null && context.mounted) {
      final bytes = await file.readAsBytes();
      final chatProvider = context.read<ChatProvider>();
      chatProvider.addMessage(ChatMessage(
        id: const Uuid().v4(),
        text: '',
        type: MessageType.sticker,
        isSender: chatProvider.isSenderMode,
        timestamp: DateTime.now(),
        imageBytes: bytes,
      ));
    }
  }

  Future<void> _pickStickerAndRemoveBackground(BuildContext context) async {
    final picker = ImagePicker();
    final file = await picker.pickImage(source: ImageSource.gallery, maxWidth: 1024, maxHeight: 1024);
    if (file != null && context.mounted) {
      final bytes = await file.readAsBytes();
      if (!context.mounted) return;
      final processedBytes = await showDialog<Uint8List>(
        context: context,
        builder: (_) => BackgroundRemoverDialog(originalBytes: bytes),
      );
      if (processedBytes != null && context.mounted) {
        final chatProvider = context.read<ChatProvider>();
        chatProvider.addMessage(ChatMessage(
          id: const Uuid().v4(),
          text: '',
          type: MessageType.sticker,
          isSender: chatProvider.isSenderMode,
          timestamp: DateTime.now(),
          imageBytes: processedBytes,
        ));
      }
    }
  }

  void _showAudioOptions(BuildContext context) {
    final isAr = context.read<ThemeProvider>().isArabic;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (sheetCtx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.mic, color: Color(0xFF6C63FF)),
              title: Text(isAr ? 'تسجيل رسالة صوتية (Voice Note)' : 'Record Voice Note (Recorded)', style: TextStyle(color: isDark ? Colors.white : Colors.black87)),
              onTap: () {
                Navigator.pop(sheetCtx);
                _recordVoiceNote(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.audiotrack, color: Color(0xFFF27B13)),
              title: Text(isAr ? 'إضافة ملف صوتي (Audio File)' : 'Add Audio File (Picked)', style: TextStyle(color: isDark ? Colors.white : Colors.black87)),
              onTap: () {
                Navigator.pop(sheetCtx);
                _pickAudioFile(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _recordVoiceNote(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => VoiceRecorderDialog(
        onConfirm: (duration, audioBytes) {
          final chatProvider = context.read<ChatProvider>();
          chatProvider.addAudioMessage(
            duration: duration,
            isSender: chatProvider.isSenderMode,
            timestamp: DateTime.now(),
            isVoiceNote: true,
            audioBytes: audioBytes,
          );
        },
      ),
    );
  }

  void _pickAudioFile(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => _AudioFileDialog(
        onConfirm: (duration, fileName, fileSize, audioBytes) {
          final chatProvider = context.read<ChatProvider>();
          chatProvider.addAudioMessage(
            duration: duration,
            isSender: chatProvider.isSenderMode,
            timestamp: DateTime.now(),
            isVoiceNote: false,
            fileName: fileName,
            fileSize: fileSize,
            audioBytes: audioBytes,
          );
        },
      ),
    );
  }

  void _showVideoOptions(BuildContext context) {
    final isAr = context.read<ThemeProvider>().isArabic;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (sheetCtx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.videocam, color: Color(0xFF6C63FF)),
              title: Text(isAr ? 'تسجيل فيديو بالكاميرا' : 'Record Video Note (Camera)', style: TextStyle(color: isDark ? Colors.white : Colors.black87)),
              onTap: () {
                Navigator.pop(sheetCtx);
                _captureVideo(context, ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.video_library, color: Color(0xFFE1306C)),
              title: Text(isAr ? 'اختيار فيديو من الاستوديو' : 'Pick Video File (Gallery)', style: TextStyle(color: isDark ? Colors.white : Colors.black87)),
              onTap: () {
                Navigator.pop(sheetCtx);
                _captureVideo(context, ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _captureVideo(BuildContext context, ImageSource source) async {
    final picker = ImagePicker();
    final file = await picker.pickVideo(source: source);
    if (file != null && context.mounted) {
      final bytes = await file.readAsBytes();
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => _VideoFormatChooseDialog(
          onConfirm: (isVideoMessage, duration, fileName, fileSize) {
            final chatProvider = context.read<ChatProvider>();
            chatProvider.addVideoMessage(
              videoBytes: bytes,
              isVideoMessage: isVideoMessage,
              duration: duration,
              isSender: chatProvider.isSenderMode,
              timestamp: DateTime.now(),
              fileName: fileName,
              fileSize: fileSize,
            );
          },
        ),
      );
    }
  }

  void _addCallMessage(BuildContext context) {
    final chatProvider = context.read<ChatProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black87;
    final isAr = context.read<ThemeProvider>().isArabic;

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1A1A1A) : Colors.white,
        title: Text(LanguageHelper.translate('add_call', isAr), style: TextStyle(color: textColor)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.phone, color: Color(0xFF6C63FF)),
              title: Text(LanguageHelper.translate('voice_call', isAr), style: TextStyle(color: textColor)),
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
              title: Text(LanguageHelper.translate('video_call', isAr), style: TextStyle(color: textColor)),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final inputBg = isDark ? const Color(0xFF1E1E1E) : const Color(0xFFF5F5F5);
    final borderCol = isDark ? const Color(0xFF2A2A2A) : const Color(0xFFE2E2E2);
    final textColor = isDark ? Colors.white : Colors.black87;
    final hintColor = isDark ? Colors.white24 : Colors.black38;
    final iconBg = isDark ? const Color(0xFF242424) : const Color(0xFFEEEEEE);
    final iconColor = isDark ? Colors.white54 : Colors.black54;

    final isAr = context.read<ThemeProvider>().isArabic;
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 42,
              decoration: BoxDecoration(
                color: inputBg,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: borderCol),
              ),
              child: TextField(
                controller: _controller,
                style: TextStyle(color: textColor, fontSize: 14),
                decoration: InputDecoration(
                  hintText: LanguageHelper.translate('type_message_to_add', isAr),
                  hintStyle: TextStyle(color: hintColor, fontSize: 14),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
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
                color: iconBg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.tune_rounded, color: iconColor, size: 20),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 20, color: isDark ? Colors.white54 : Colors.black54),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(fontSize: 9, color: isDark ? Colors.white38 : Colors.black45, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}

// ─── Audio Duration Dialog ─────────────────────────────────────────────────────

// ─── Voice Recorder Dialog (Recorded Waveform Simulation) ──────────────────────

class VoiceRecorderDialog extends StatefulWidget {
  final void Function(Duration duration, Uint8List? audioBytes) onConfirm;
  const VoiceRecorderDialog({required this.onConfirm});

  @override
  State<VoiceRecorderDialog> createState() => VoiceRecorderDialogState();
}

class VoiceRecorderDialogState extends State<VoiceRecorderDialog> {
  int _secondsElapsed = 0;
  Timer? _stopwatchTimer;
  Timer? _waveformTimer;
  final List<double> _waveHeights = List.generate(15, (_) => 5.0);

  // Mic recording states
  late final AudioRecorder _audioRecorder;
  bool _isRecording = false;

  @override
  void initState() {
    super.initState();
    _audioRecorder = AudioRecorder();
    _startRecordingWorkflow();
  }

  Future<void> _startRecordingWorkflow() async {
    try {
      if (await _audioRecorder.hasPermission()) {
        final tempDir = await getTemporaryDirectory();
        final path = '${tempDir.path}/recorded_audio_${DateTime.now().millisecondsSinceEpoch}.m4a';

        await _audioRecorder.start(
          const RecordConfig(encoder: AudioEncoder.aacLc, bitRate: 64000, sampleRate: 22050),
          path: path,
        );

        if (!mounted) return;
        setState(() {
          _isRecording = true;
        });
        _startTimers();
      } else {
        debugPrint('Microphone permission denied, falling back to simulation.');
        _startTimers();
      }
    } catch (e) {
      debugPrint('Error starting recording: $e');
      _startTimers();
    }
  }

  void _startTimers() {
    // Stopwatch timer
    _stopwatchTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _secondsElapsed++;
        });
      }
    });

    // Bouncing waveform reacting to mic amplitude!
    _waveformTimer = Timer.periodic(const Duration(milliseconds: 120), (timer) async {
      if (!mounted) return;

      double amplitudeDb = -50.0;
      if (_isRecording) {
        try {
          final amp = await _audioRecorder.getAmplitude();
          amplitudeDb = amp.current; // -160 to 0 (dB)
        } catch (_) {}
      }

      // Convert dB amplitude (e.g. -50 to 0) to visual height (5 to 45)
      final normalizedAmp = (amplitudeDb + 50.0).clamp(0.0, 50.0) / 50.0; // 0.0 to 1.0

      setState(() {
        for (int i = 0; i < _waveHeights.length; i++) {
          final waveOffset = (double.tryParse('${(i * 3 + timer.tick) % 10}') ?? 3.0) * 0.2;
          final targetHeight = 5.0 + normalizedAmp * 35.0 * (0.8 + waveOffset);
          _waveHeights[i] = targetHeight.clamp(5.0, 45.0);
        }
      });
    });
  }

  @override
  void dispose() {
    _stopwatchTimer?.cancel();
    _waveformTimer?.cancel();
    _audioRecorder.dispose();
    super.dispose();
  }

  String _formatTimerText(int secs) {
    final m = (secs ~/ 60).toString().padLeft(2, '0');
    final s = (secs % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  Future<void> _stopAndSave() async {
    Uint8List? audioBytes;
    try {
      if (_isRecording) {
        final path = await _audioRecorder.stop();
        _isRecording = false;
        if (path != null) {
          audioBytes = await AudioHelper.readAudioBytes(path);
        }
      }
    } catch (e) {
      debugPrint('Error stopping recording: $e');
    }

    final duration = Duration(seconds: _secondsElapsed == 0 ? 1 : _secondsElapsed);
    widget.onConfirm(duration, audioBytes);
    if (mounted) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black87;
    final labelColor = isDark ? Colors.white60 : Colors.black54;
    final cancelColor = isDark ? Colors.white38 : Colors.black45;

    final isAr = context.read<ThemeProvider>().isArabic;
    return AlertDialog(
      backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Flashing recording dot
              TweenAnimationBuilder<double>(
                tween: Tween<double>(begin: 0.2, end: 1.0),
                duration: const Duration(milliseconds: 800),
                curve: Curves.easeInOut,
                builder: (context, opacity, child) {
                  return Opacity(opacity: opacity, child: child);
                },
                onEnd: () {},
                child: Container(
                  width: 10,
                  height: 10,
                  decoration: const BoxDecoration(
                    color: Colors.redAccent,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                LanguageHelper.translate('recording_voice_note', isAr),
                style: TextStyle(
                  color: labelColor,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.0,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Bouncing Waveform Animation
          SizedBox(
            height: 50,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: _waveHeights.map((h) {
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 100),
                  width: 3.5,
                  height: h,
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFF00A884),
                    borderRadius: BorderRadius.circular(4),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 18),
          // Timer counter text
          Text(
            _formatTimerText(_secondsElapsed),
            style: TextStyle(
              color: textColor,
              fontSize: 32,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
      actionsAlignment: MainAxisAlignment.spaceEvenly,
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(LanguageHelper.translate('cancel', isAr), style: TextStyle(color: cancelColor)),
        ),
        ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF00A884),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          ),
          icon: const Icon(Icons.stop_circle_rounded),
          label: Text(LanguageHelper.translate('stop_save', isAr)),
          onPressed: _stopAndSave,
        ),
      ],
    );
  }
}

// ─── Picked Audio File Dialog ──────────────────────────────────────────────────

class _AudioFileDialog extends StatefulWidget {
  final void Function(Duration duration, String fileName, String fileSize, Uint8List? audioBytes) onConfirm;
  const _AudioFileDialog({required this.onConfirm});

  @override
  State<_AudioFileDialog> createState() => _AudioFileDialogState();
}

class _AudioFileDialogState extends State<_AudioFileDialog> {
  final _nameController = TextEditingController(text: 'AUD-20260614-WA0001.mp3');
  final _sizeController = TextEditingController(text: '1.2 MB');
  Uint8List? _audioBytes;
  int _minutes = 0;
  int _seconds = 30;

  Future<void> _pickFile() async {
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
            _nameController.text = file.name;
            final mb = bytes!.length / (1024 * 1024);
            _sizeController.text = '${mb.toStringAsFixed(1)} MB';
          });
        }
      }
    } catch (e) {
      debugPrint('Error picking audio in dialog: $e');
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _sizeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black87;
    final labelColor = isDark ? Colors.white38 : Colors.black45;
    final containerBg = isDark ? const Color(0xFF242424) : const Color(0xFFEEEEEE);
    final isAr = context.read<ThemeProvider>().isArabic;

    return AlertDialog(
      backgroundColor: isDark ? const Color(0xFF1A1A1A) : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text(LanguageHelper.translate('add_audio_file', isAr), style: TextStyle(color: textColor, fontWeight: FontWeight.bold)),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GestureDetector(
              onTap: _pickFile,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
                decoration: BoxDecoration(
                  color: containerBg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _audioBytes != null ? const Color(0xFF6C63FF) : (isDark ? Colors.white12 : Colors.black12),
                    width: _audioBytes != null ? 1.5 : 1,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      _audioBytes != null ? Icons.audiotrack_rounded : Icons.library_music_rounded,
                      color: _audioBytes != null ? const Color(0xFF6C63FF) : labelColor,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _audioBytes != null
                            ? '${LanguageHelper.translate('audio_loaded', isAr)}: ${_nameController.text}'
                            : LanguageHelper.translate('tap_to_pick_audio', isAr),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: _audioBytes != null ? textColor : labelColor,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(LanguageHelper.translate('file_name', isAr), style: TextStyle(color: labelColor, fontSize: 12)),
            const SizedBox(height: 6),
            TextField(
              controller: _nameController,
              style: TextStyle(color: textColor),
              decoration: const InputDecoration(hintText: 'e.g. Song.mp3'),
            ),
            const SizedBox(height: 14),
            Text(LanguageHelper.translate('file_size', isAr), style: TextStyle(color: labelColor, fontSize: 12)),
            const SizedBox(height: 6),
            TextField(
              controller: _sizeController,
              style: TextStyle(color: textColor),
              decoration: const InputDecoration(hintText: 'e.g. 4.2 MB'),
            ),
            const SizedBox(height: 18),
            Text(LanguageHelper.translate('audio_duration', isAr), style: TextStyle(color: labelColor, fontSize: 12)),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Flexible(
                  child: _NumberPicker(
                    label: 'Min',
                    value: _minutes,
                    min: 0,
                    max: 59,
                    onChanged: (v) => setState(() => _minutes = v),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text(':', style: TextStyle(color: textColor, fontSize: 24, fontWeight: FontWeight.bold)),
                ),
                Flexible(
                  child: _NumberPicker(
                    label: 'Sec',
                    value: _seconds,
                    min: 0,
                    max: 59,
                    onChanged: (v) => setState(() => _seconds = v),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(LanguageHelper.translate('cancel', isAr), style: TextStyle(color: labelColor)),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF6C63FF),
            foregroundColor: Colors.white,
          ),
          onPressed: () {
            final fileName = _nameController.text.trim().isEmpty ? 'audio.mp3' : _nameController.text.trim();
            final fileSize = _sizeController.text.trim().isEmpty ? '1.0 MB' : _sizeController.text.trim();
            widget.onConfirm(Duration(minutes: _minutes, seconds: _seconds), fileName, fileSize, _audioBytes);
            Navigator.pop(context);
          },
          child: Text(LanguageHelper.translate('save', isAr)),
        ),
      ],
    );
  }
}

// ─── Video Format Selection & Details Dialog ───────────────────────────────────

class _VideoFormatChooseDialog extends StatefulWidget {
  final void Function(bool isVideoMessage, Duration duration, String fileName, String fileSize) onConfirm;
  const _VideoFormatChooseDialog({required this.onConfirm});

  @override
  State<_VideoFormatChooseDialog> createState() => _VideoFormatChooseDialogState();
}

class _VideoFormatChooseDialogState extends State<_VideoFormatChooseDialog> {
  bool _isVideoMessage = true; // circular note vs rectangular attachment
  final _nameController = TextEditingController(text: 'VID-20260614-WA0001.mp4');
  final _sizeController = TextEditingController(text: '4.2 MB');
  int _minutes = 0;
  int _seconds = 16;

  @override
  void dispose() {
    _nameController.dispose();
    _sizeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black87;
    final labelColor = isDark ? Colors.white38 : Colors.black45;
    final containerBg = isDark ? const Color(0xFF242424) : const Color(0xFFEEEEEE);
    final dropdownBg = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final isAr = context.read<ThemeProvider>().isArabic;

    return AlertDialog(
      backgroundColor: isDark ? const Color(0xFF1A1A1A) : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text(LanguageHelper.translate('configure_video', isAr), style: TextStyle(color: textColor, fontWeight: FontWeight.bold)),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(LanguageHelper.translate('layout_format', isAr), style: TextStyle(color: labelColor, fontSize: 12)),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: containerBg,
                borderRadius: BorderRadius.circular(10),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<bool>(
                  value: _isVideoMessage,
                  dropdownColor: dropdownBg,
                  isExpanded: true,
                  style: TextStyle(color: textColor, fontSize: 14),
                  items: [
                    DropdownMenuItem(
                      value: true,
                      child: Text(LanguageHelper.translate('instant_video_note', isAr), style: TextStyle(color: textColor)),
                    ),
                    DropdownMenuItem(
                      value: false,
                      child: Text(LanguageHelper.translate('standard_video_attachment', isAr), style: TextStyle(color: textColor)),
                    ),
                  ],
                  onChanged: (v) {
                    if (v != null) {
                      setState(() {
                        _isVideoMessage = v;
                        _nameController.text = v ? 'Video Note' : 'VID-20260614-WA0001.mp4';
                      });
                    }
                  },
                ),
              ),
            ),
            const SizedBox(height: 14),
            Text(LanguageHelper.translate('file_name', isAr), style: TextStyle(color: labelColor, fontSize: 12)),
            const SizedBox(height: 6),
            TextField(
              controller: _nameController,
              style: TextStyle(color: textColor),
              decoration: const InputDecoration(hintText: 'e.g. video.mp4'),
            ),
            const SizedBox(height: 14),
            Text(LanguageHelper.translate('file_size', isAr), style: TextStyle(color: labelColor, fontSize: 12)),
            const SizedBox(height: 6),
            TextField(
              controller: _sizeController,
              style: TextStyle(color: textColor),
              decoration: const InputDecoration(hintText: 'e.g. 5.6 MB'),
            ),
            const SizedBox(height: 18),
            Text(LanguageHelper.translate('video_duration', isAr), style: TextStyle(color: labelColor, fontSize: 12)),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Flexible(
                  child: _NumberPicker(
                    label: 'Min',
                    value: _minutes,
                    min: 0,
                    max: 59,
                    onChanged: (v) => setState(() => _minutes = v),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text(':', style: TextStyle(color: textColor, fontSize: 24, fontWeight: FontWeight.bold)),
                ),
                Flexible(
                  child: _NumberPicker(
                    label: 'Sec',
                    value: _seconds,
                    min: 0,
                    max: 59,
                    onChanged: (v) => setState(() => _seconds = v),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(LanguageHelper.translate('cancel', isAr), style: TextStyle(color: labelColor)),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF6C63FF),
            foregroundColor: Colors.white,
          ),
          onPressed: () {
            final fileName = _nameController.text.trim().isEmpty ? 'video.mp4' : _nameController.text.trim();
            final fileSize = _sizeController.text.trim().isEmpty ? '5.0 MB' : _sizeController.text.trim();
            widget.onConfirm(_isVideoMessage, Duration(minutes: _minutes, seconds: _seconds), fileName, fileSize);
            Navigator.pop(context);
          },
          child: Text(LanguageHelper.translate('confirm_add', isAr)),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black87;
    final labelColor = isDark ? Colors.white38 : Colors.black45;

    return Column(
      children: [
        Text(label, style: TextStyle(color: labelColor, fontSize: 12)),
        const SizedBox(height: 4),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: Icon(Icons.remove_circle_outline, color: labelColor),
              iconSize: 22,
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              padding: EdgeInsets.zero,
              style: const ButtonStyle(
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              onPressed: value > min ? () => onChanged(value - 1) : null,
            ),
            SizedBox(
              width: 40,
              child: Text(
                value.toString().padLeft(2, '0'),
                textAlign: TextAlign.center,
                style: TextStyle(color: textColor, fontSize: 22, fontWeight: FontWeight.w600),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.add_circle_outline, color: Color(0xFF6C63FF)),
              iconSize: 22,
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              padding: EdgeInsets.zero,
              style: const ButtonStyle(
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              onPressed: value < max ? () => onChanged(value + 1) : null,
            ),
          ],
        ),
      ],
    );
  }
}

