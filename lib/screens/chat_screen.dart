import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:screenshot/screenshot.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../models/chat_models.dart';
import '../providers/chat_provider.dart';
import '../providers/theme_provider.dart';
import '../themes/platform_themes.dart';
import '../widgets/chat_viewport.dart';
import '../widgets/inbox_viewports.dart';
import '../widgets/editor_panel.dart';
import '../widgets/export_overlay.dart';
import '../utils/screenshot_helper.dart';
import '../utils/language_helper.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> with SingleTickerProviderStateMixin {
  final ScreenshotController _screenshotController = ScreenshotController();
  bool _isCapturing = false;
  bool _showEditor = true;
  bool _isWebRecording = false;
  bool _isFullScreenRecordMode = false;
  late AnimationController _panelAnimController;
  late Animation<double> _panelAnimation;

  @override
  void initState() {
    super.initState();
    _panelAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _panelAnimation = CurvedAnimation(
      parent: _panelAnimController,
      curve: Curves.easeOutCubic,
    );
    _panelAnimController.forward();
  }

  @override
  void dispose() {
    _panelAnimController.dispose();
    super.dispose();
  }

  void _toggleEditor() {
    setState(() => _showEditor = !_showEditor);
    if (_showEditor) {
      _panelAnimController.forward();
    } else {
      _panelAnimController.reverse();
    }
  }

  Future<void> _captureScreenshot() async {
    if (_isCapturing) return;
    setState(() => _isCapturing = true);

    // Hide editor briefly
    if (_showEditor) {
      _panelAnimController.reverse();
      await Future.delayed(const Duration(milliseconds: 350));
    }

    try {
      final Uint8List? imageBytes = await _screenshotController.capture(
        pixelRatio: 3.0,
        delay: const Duration(milliseconds: 100),
      );

      if (imageBytes != null && mounted) {
        await showDialog(
          context: context,
          builder: (_) => ExportOverlay(
            imageBytes: imageBytes,
            onSave: () async {
              final savedPath = await ScreenshotHelper.saveToGallery(imageBytes);
              if (mounted) {
                final isAr = context.read<ThemeProvider>().isArabic;
                final success = savedPath != null;
                final baseMsg = success
                    ? LanguageHelper.translate('screenshot_saved', isAr)
                    : (isAr ? 'فشل حفظ لقطة الشاشة' : 'Failed to save screenshot');
                final finalMsg = (success && savedPath != 'Gallery')
                    ? '$baseMsg: $savedPath'
                    : baseMsg;

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(finalMsg),
                    backgroundColor: success ? const Color(0xFF6C63FF) : Colors.redAccent,
                    behavior: SnackBarBehavior.floating,
                    duration: const Duration(seconds: 4),
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.all(Radius.circular(12)),
                    ),
                  ),
                );
              }
            },
            onShare: () async {
              await ScreenshotHelper.shareImage(imageBytes);
            },
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        final isAr = context.read<ThemeProvider>().isArabic;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${LanguageHelper.translate('capture_failed', isAr)}: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isCapturing = false);
        if (_showEditor) _panelAnimController.forward();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final chatProvider = context.watch<ChatProvider>();
    final session = chatProvider.activeSession;
    if (session == null) return const SizedBox.shrink();

    final platformTheme = PlatformTheme.of(session.platform, isDark: session.isDarkMode);

    Widget bodyContent;

    if (_isFullScreenRecordMode) {
      bodyContent = Focus(
        autofocus: true,
        onKeyEvent: (FocusNode node, KeyEvent event) {
          if (event is KeyDownEvent && event.logicalKey == LogicalKeyboardKey.escape) {
            setState(() {
              _isFullScreenRecordMode = false;
              if (_isWebRecording) {
                _isWebRecording = false;
                ScreenshotHelper.stopScreenRecord();
              }
            });
            return KeyEventResult.handled;
          }
          return KeyEventResult.ignored;
        },
        child: GestureDetector(
          onDoubleTap: () {
            setState(() {
              _isFullScreenRecordMode = false;
              if (_isWebRecording) {
                _isWebRecording = false;
                ScreenshotHelper.stopScreenRecord();
              }
            });
          },
          child: Screenshot(
            controller: _screenshotController,
            child: chatProvider.viewChatList
                ? PlatformInboxViewport(
                    session: session,
                    platformTheme: platformTheme,
                    hideStatusBar: true,
                  )
                : ChatViewport(
                    session: session,
                    platformTheme: platformTheme,
                    hideStatusBar: true,
                  ),
          ),
        ),
      );
    } else {
      bodyContent = Column(
        children: [
          // ── App top bar (always dark, part of our editor UI) ────────────
          _buildTopBar(context, session),

          // ── Phone mockup with screenshot boundary ───────────────────────
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  physics: _showEditor ? const ClampingScrollPhysics() : const NeverScrollableScrollPhysics(),
                  child: Column(
                    children: [
                      // Phone frame + screenshot zone
                      _buildPhoneFrame(context, session, platformTheme, constraints),

                      // Sender toggle bar
                      if (_showEditor) _buildSenderToggle(context, chatProvider),
                    ],
                  ),
                );
              },
            ),
          ),

          // ── Editor panel (slides in/out, NEVER captured) ─────────────────
          SizeTransition(
            sizeFactor: _panelAnimation,
            axisAlignment: -1,
            child: EditorPanel(
              onCapture: _captureScreenshot,
              isCapturing: _isCapturing,
            ),
          ),
        ],
      );

      if (_isWebRecording) {
        bodyContent = Stack(
          children: [
            bodyContent,
            Positioned(
              bottom: 24,
              left: 20,
              right: 20,
              child: _buildRecordingHUD(context),
            ),
          ],
        );
      }
    }

    final Color systemStatusBarBg;
    final Brightness systemStatusBarIconBrightness;

    if (_isFullScreenRecordMode) {
      systemStatusBarBg = platformTheme.statusBarBg;
      final bool isLightStatusBarText = session.platform == Platform.whatsapp || session.isDarkMode;
      systemStatusBarIconBrightness = isLightStatusBarText ? Brightness.light : Brightness.dark;
    } else {
      systemStatusBarBg = Colors.transparent;
      systemStatusBarIconBrightness = Brightness.light;
    }

    final systemOverlayStyle = SystemUiOverlayStyle(
      statusBarColor: systemStatusBarBg,
      statusBarIconBrightness: systemStatusBarIconBrightness,
      statusBarBrightness: systemStatusBarIconBrightness == Brightness.light ? Brightness.dark : Brightness.light,
      systemNavigationBarColor: _isFullScreenRecordMode ? platformTheme.statusBarBg : const Color(0xFF0D0D0D),
      systemNavigationBarIconBrightness: _isFullScreenRecordMode
          ? (systemStatusBarIconBrightness == Brightness.light ? Brightness.light : Brightness.dark)
          : Brightness.light,
    );

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: systemOverlayStyle,
      child: PopScope(
        canPop: !_isFullScreenRecordMode,
        onPopInvokedWithResult: (didPop, result) {
          if (didPop) return;
          if (_isFullScreenRecordMode) {
            setState(() {
              _isFullScreenRecordMode = false;
              if (_isWebRecording) {
                _isWebRecording = false;
                ScreenshotHelper.stopScreenRecord();
              }
            });
          }
        },
        child: Scaffold(
          backgroundColor: _isFullScreenRecordMode ? platformTheme.statusBarBg : const Color(0xFF0D0D0D),
          body: SafeArea(
            child: bodyContent,
          ),
        ),
      ),
    );
  }



  Widget _buildRecordingHUD(BuildContext context) {
    final isAr = context.read<ThemeProvider>().isArabic;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.5),
            blurRadius: 15,
            spreadRadius: 2,
          ),
        ],
        border: Border.all(color: const Color(0xFF333333)),
      ),
      child: Row(
        children: [
          TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 0.3, end: 1.0),
            duration: const Duration(milliseconds: 700),
            builder: (context, value, child) {
              return Opacity(opacity: value, child: child);
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
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  isAr ? 'يجري تسجيل الشاشة كفيديو...' : 'RECORDING VIDEO...',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
                Text(
                  isAr ? 'يجري تسجيل الشاشة حاليًا' : 'Recording the simulator screen as video...',
                  style: const TextStyle(color: Colors.white54, fontSize: 10),
                ),
              ],
            ),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE1306C),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            ),
            icon: const Icon(Icons.stop_rounded, size: 16),
            label: Text(isAr ? 'إيقاف' : 'Stop', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
            onPressed: () {
              setState(() {
                _isWebRecording = false;
              });
              ScreenshotHelper.stopScreenRecord();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTopBar(BuildContext context, ChatSession session) {
    final chatProvider = context.watch<ChatProvider>();

    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: const BoxDecoration(
        color: Color(0xFF0D0D0D),
        border: Border(bottom: BorderSide(color: Color(0xFF1A1A1A))),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_rounded, color: Colors.white, size: 20),
            onPressed: () => Navigator.pop(context),
          ),
          Container(
            width: 8,
            height: 8,
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              color: session.platformColor,
              shape: BoxShape.circle,
            ),
          ),
          Text(
            session.platformName,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const Spacer(),
          // Inbox toggle
          GestureDetector(
            onTap: () {
              chatProvider.setViewChatList(!chatProvider.viewChatList);
            },
            child: Container(
              padding: const EdgeInsets.all(6),
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                color: chatProvider.viewChatList
                    ? const Color(0xFF6C63FF).withValues(alpha: 0.2)
                    : const Color(0xFF242424),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                chatProvider.viewChatList ? Icons.chat_bubble_rounded : Icons.forum_rounded,
                size: 18,
                color: chatProvider.viewChatList ? const Color(0xFF6C63FF) : Colors.white38,
              ),
            ),
          ),
          // Platform switch
          _PlatformSwitcher(session: session),
          const SizedBox(width: 8),
          // Toggle editor
          GestureDetector(
            onTap: _toggleEditor,
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: _showEditor
                    ? const Color(0xFF6C63FF).withValues(alpha: 0.2)
                    : const Color(0xFF242424),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                _showEditor ? Icons.edit_rounded : Icons.edit_off_rounded,
                size: 18,
                color: _showEditor ? const Color(0xFF6C63FF) : Colors.white38,
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Record Chat button
          GestureDetector(
            onTap: () async {
              final isAr = Provider.of<ThemeProvider>(context, listen: false).isArabic;
              if (_isWebRecording) {
                setState(() {
                  _isWebRecording = false;
                  _isFullScreenRecordMode = false;
                });
                ScreenshotHelper.stopScreenRecord();
              } else {
                if (!kIsWeb) {
                  setState(() {
                    _isFullScreenRecordMode = true;
                  });
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        isAr
                            ? 'تم الدخول في وضع ملء الشاشة للتسجيل. يرجى استخدام مسجل الشاشة المدمج بجهازك للتسجيل. اضغط على خروج للعودة.'
                            : 'Entering full-screen mode. Use your device\'s built-in recorder to capture. Tap the exit button to return.',
                      ),
                      duration: const Duration(seconds: 5),
                      behavior: SnackBarBehavior.floating,
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.all(Radius.circular(12)),
                      ),
                    ),
                  );
                  return;
                }
                setState(() {
                  _isFullScreenRecordMode = true;
                });
                final success = await ScreenshotHelper.startScreenRecord();
                if (success) {
                  setState(() {
                    _isWebRecording = true;
                  });
                } else {
                  setState(() {
                    _isFullScreenRecordMode = false;
                  });
                }
              }
            },
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: _isWebRecording
                    ? const Color(0xFFE1306C)
                    : const Color(0xFF242424),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                _isWebRecording ? Icons.videocam_off_rounded : Icons.videocam_rounded,
                size: 18,
                color: _isWebRecording ? Colors.white : Colors.white70,
              ),
            ),
          ),
          // Capture button
          const SizedBox(width: 8),
          GestureDetector(
            onTap: _captureScreenshot,
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: const Color(0xFF6C63FF),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.camera_alt_rounded, size: 18, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhoneFrame(
    BuildContext context,
    ChatSession session,
    PlatformTheme platformTheme,
    BoxConstraints constraints,
  ) {
    final chatProvider = Provider.of<ChatProvider>(context);
    // The phone aspect is 9:19.5 (like iPhone). Width fills up to 390.
    final screenW = (constraints.maxWidth - 32).clamp(280.0, 390.0);
    final screenH = screenW * 19.5 / 9;

    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 12),
        width: screenW + 12,
        height: screenH + 24,
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(44),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.5),
              blurRadius: 30,
              spreadRadius: 5,
            ),
          ],
          border: Border.all(color: const Color(0xFF333333), width: 2),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(42),
          child: Screenshot(
            controller: _screenshotController,
            child: SizedBox(
              width: screenW,
              height: screenH,
              child: chatProvider.viewChatList
                  ? PlatformInboxViewport(
                      session: session,
                      platformTheme: platformTheme,
                    )
                  : ChatViewport(
                      session: session,
                      platformTheme: platformTheme,
                    ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSenderToggle(BuildContext context, ChatProvider chatProvider) {
    final isSender = chatProvider.isSenderMode;
    final isAr = context.read<ThemeProvider>().isArabic;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          _ToggleOption(
            label: LanguageHelper.translate('sender', isAr),
            icon: Icons.send_rounded,
            isActive: isSender,
            onTap: () => chatProvider.setSenderMode(true),
            activeColor: const Color(0xFF6C63FF),
          ),
          _ToggleOption(
            label: LanguageHelper.translate('receiver', isAr),
            icon: Icons.person_rounded,
            isActive: !isSender,
            onTap: () => chatProvider.setSenderMode(false),
            activeColor: const Color(0xFF42A5F5),
          ),
        ],
      ),
    );
  }
}

class _ToggleOption extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isActive;
  final VoidCallback onTap;
  final Color activeColor;

  const _ToggleOption({
    required this.label,
    required this.icon,
    required this.isActive,
    required this.onTap,
    required this.activeColor,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isActive ? activeColor.withValues(alpha: 0.2) : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 16, color: isActive ? activeColor : Colors.white38),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isActive ? activeColor : Colors.white38,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PlatformSwitcher extends StatelessWidget {
  final ChatSession session;
  const _PlatformSwitcher({required this.session});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _showPlatformPicker(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFF242424),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(_icon(session.platform), size: 14, color: session.platformColor),
            const SizedBox(width: 4),
            const Icon(Icons.swap_horiz_rounded, size: 14, color: Colors.white38),
          ],
        ),
      ),
    );
  }

  IconData _icon(Platform p) {
    switch (p) {
      case Platform.whatsapp: return Icons.chat_rounded;
      case Platform.messenger: return Icons.messenger_rounded;
      case Platform.instagram: return Icons.camera_alt_rounded;
      case Platform.snapchat: return Icons.face_rounded;
    }
  }

  void _showPlatformPicker(BuildContext context) {
    final chatProvider = context.read<ChatProvider>();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Switch Platform', style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: Platform.values.map((p) {
            final isActive = p == session.platform;
            return ListTile(
              leading: Icon(_icon(p), color: _color(p)),
              title: Text(_name(p), style: TextStyle(
                color: isActive ? _color(p) : Colors.white,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.normal,
              )),
              trailing: isActive ? const Icon(Icons.check_rounded, color: Color(0xFF6C63FF)) : null,
              onTap: () {
                chatProvider.updateSessionSettings(platform: p);
                Navigator.pop(context);
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  Color _color(Platform p) {
    switch (p) {
      case Platform.whatsapp: return const Color(0xFF25D366);
      case Platform.messenger: return const Color(0xFF0084FF);
      case Platform.instagram: return const Color(0xFFE1306C);
      case Platform.snapchat: return const Color(0xFFFFFC00);
    }
  }

  String _name(Platform p) {
    switch (p) {
      case Platform.whatsapp: return 'WhatsApp';
      case Platform.messenger: return 'Messenger';
      case Platform.instagram: return 'Instagram';
      case Platform.snapchat: return 'Snapchat';
    }
  }
}

