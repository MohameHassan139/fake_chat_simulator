import 'dart:async';
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
import '../widgets/live_setup_dialog.dart';

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
  bool _isLiveSimMode = false;
  bool _showExitHint = false;
  Timer? _liveTimer;
  int _liveSeconds = 0;
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
    _liveTimer?.cancel();
    _panelAnimController.dispose();
    super.dispose();
  }

  void _startLiveSimulation(BuildContext context) {
    final chatProvider = Provider.of<ChatProvider>(context, listen: false);
    final session = chatProvider.activeSession;
    if (session == null) return;

    showDialog(
      context: context,
      builder: (_) => LiveSetupDialog(
        session: session,
        onStart: ({required speed, required isMuted, required autoRecordWeb}) async {
          chatProvider.setPlaybackSpeed(speed);
          if (chatProvider.isMuted != isMuted) {
            chatProvider.toggleMute();
          }

          _liveTimer?.cancel();
          setState(() {
            _isLiveSimMode = true;
            _isFullScreenRecordMode = true;
            _liveSeconds = 0;
            _showExitHint = true;
          });

          // Automatically fade out the exit hint toast after 2.5 seconds for 100% clean video recording
          Future.delayed(const Duration(milliseconds: 2500), () {
            if (mounted) {
              setState(() {
                _showExitHint = false;
              });
            }
          });

          _liveTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
            if (!mounted || !_isLiveSimMode) {
              timer.cancel();
              return;
            }
            if (!chatProvider.isPlaybackPaused) {
              setState(() {
                _liveSeconds++;
              });
            }
          });

          chatProvider.startConversationPlayback(() {
            // Completed full playback
          });
        },
      ),
    );
  }

  void _stopLiveSimulation() {
    _liveTimer?.cancel();
    final chatProvider = Provider.of<ChatProvider>(context, listen: false);
    chatProvider.stopConversationPlayback();
    setState(() {
      _isLiveSimMode = false;
      _isFullScreenRecordMode = false;
      _showExitHint = false;
      _liveSeconds = 0;
    });
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
            if (_isLiveSimMode) {
              _stopLiveSimulation();
            } else {
              setState(() {
                _isFullScreenRecordMode = false;
                if (_isWebRecording) {
                  _isWebRecording = false;
                  ScreenshotHelper.stopScreenRecord();
                }
              });
            }
            return KeyEventResult.handled;
          }
          return KeyEventResult.ignored;
        },
        child: GestureDetector(
          onDoubleTap: () {
            if (_isLiveSimMode) {
              _stopLiveSimulation();
            } else {
              setState(() {
                _isFullScreenRecordMode = false;
                if (_isWebRecording) {
                  _isWebRecording = false;
                  ScreenshotHelper.stopScreenRecord();
                }
              });
            }
          },
          child: Stack(
            children: [
              Screenshot(
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
              if (_isLiveSimMode && _showExitHint)
                Positioned(
                  top: 24,
                  left: 20,
                  right: 20,
                  child: Center(
                    child: _buildExitHintToast(context),
                  ),
                ),
            ],
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

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final Color systemStatusBarBg;
    final Brightness systemStatusBarIconBrightness;

    if (_isFullScreenRecordMode) {
      systemStatusBarBg = platformTheme.statusBarBg;
      final bool isLightStatusBarText = session.platform == Platform.whatsapp || session.isDarkMode;
      systemStatusBarIconBrightness = isLightStatusBarText ? Brightness.light : Brightness.dark;
    } else {
      systemStatusBarBg = Colors.transparent;
      systemStatusBarIconBrightness = isDark ? Brightness.light : Brightness.dark;
    }

    final systemOverlayStyle = SystemUiOverlayStyle(
      statusBarColor: systemStatusBarBg,
      statusBarIconBrightness: systemStatusBarIconBrightness,
      statusBarBrightness: systemStatusBarIconBrightness == Brightness.light ? Brightness.dark : Brightness.light,
      systemNavigationBarColor: _isFullScreenRecordMode ? platformTheme.statusBarBg : Theme.of(context).scaffoldBackgroundColor,
      systemNavigationBarIconBrightness: _isFullScreenRecordMode
          ? (systemStatusBarIconBrightness == Brightness.light ? Brightness.light : Brightness.dark)
          : (isDark ? Brightness.light : Brightness.dark),
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
          backgroundColor: _isFullScreenRecordMode ? platformTheme.statusBarBg : Theme.of(context).scaffoldBackgroundColor,
          body: SafeArea(
            child: bodyContent,
          ),
        ),
      ),
    );
  }



  Widget _buildRecordingHUD(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isAr = context.read<ThemeProvider>().isArabic;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.5 : 0.15),
            blurRadius: 15,
            spreadRadius: 2,
          ),
        ],
        border: Border.all(color: isDark ? const Color(0xFF333333) : const Color(0xFFE0E0E0)),
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
                  style: TextStyle(
                    color: isDark ? Colors.white : Colors.black87,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
                Text(
                  isAr ? 'يجري تسجيل الشاشة حاليًا' : 'Recording the simulator screen as video...',
                  style: TextStyle(color: isDark ? Colors.white54 : Colors.black54, fontSize: 10),
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
    final themeProvider = context.watch<ThemeProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(bottom: BorderSide(color: isDark ? const Color(0xFF1A1A1A) : const Color(0xFFE2E2E2))),
      ),
      child: Row(
        children: [
          IconButton(
            icon: Icon(Icons.arrow_back_ios_rounded, color: Theme.of(context).colorScheme.onSurface, size: 20),
            onPressed: () => Navigator.pop(context),
          ),
          Container(
            width: 8,
            height: 8,
            margin: const EdgeInsets.only(right: 6),
            decoration: BoxDecoration(
              color: session.platformColor,
              shape: BoxShape.circle,
            ),
          ),
          Flexible(
            child: Text(
              session.platformName,
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface,
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 4),
          // App Theme Toggle
          GestureDetector(
            onTap: themeProvider.toggleTheme,
            child: Container(
              padding: const EdgeInsets.all(6),
              margin: const EdgeInsets.only(right: 6),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF242424) : const Color(0xFFEEEEEE),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                size: 18,
                color: isDark ? Colors.amber : const Color(0xFF6C63FF),
              ),
            ),
          ),
          // Inbox toggle
          GestureDetector(
            onTap: () {
              chatProvider.setViewChatList(!chatProvider.viewChatList);
            },
            child: Container(
              padding: const EdgeInsets.all(6),
              margin: const EdgeInsets.only(right: 6),
              decoration: BoxDecoration(
                color: chatProvider.viewChatList
                    ? const Color(0xFF6C63FF).withValues(alpha: 0.2)
                    : (isDark ? const Color(0xFF242424) : const Color(0xFFEEEEEE)),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                chatProvider.viewChatList ? Icons.chat_bubble_rounded : Icons.forum_rounded,
                size: 18,
                color: chatProvider.viewChatList ? const Color(0xFF6C63FF) : (isDark ? Colors.white38 : Colors.black45),
              ),
            ),
          ),
          // Platform switch
          _PlatformSwitcher(session: session),
          const SizedBox(width: 6),
          // Toggle editor
          GestureDetector(
            onTap: _toggleEditor,
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: _showEditor
                    ? const Color(0xFF6C63FF).withValues(alpha: 0.2)
                    : (isDark ? const Color(0xFF242424) : const Color(0xFFEEEEEE)),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                _showEditor ? Icons.edit_rounded : Icons.edit_off_rounded,
                size: 18,
                color: _showEditor ? const Color(0xFF6C63FF) : (isDark ? Colors.white38 : Colors.black45),
              ),
            ),
          ),
          const SizedBox(width: 6),
          // Play Live Chat button
          GestureDetector(
            onTap: () => _startLiveSimulation(context),
            child: Tooltip(
              message: LanguageHelper.translate('play_live', Provider.of<ThemeProvider>(context, listen: false).isArabic),
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF00C853), Color(0xFF00E676)],
                  ),
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF00C853).withValues(alpha: 0.4),
                      blurRadius: 6,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: const Icon(Icons.play_arrow_rounded, size: 18, color: Colors.white),
              ),
            ),
          ),
          const SizedBox(width: 6),
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
                    : (isDark ? const Color(0xFF242424) : const Color(0xFFEEEEEE)),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                _isWebRecording ? Icons.videocam_off_rounded : Icons.videocam_rounded,
                size: 18,
                color: _isWebRecording ? Colors.white : (isDark ? Colors.white70 : Colors.black54),
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

  Widget _buildExitHintToast(BuildContext context) {
    final isAr = context.read<ThemeProvider>().isArabic;
    return AnimatedOpacity(
      opacity: _showExitHint ? 1.0 : 0.0,
      duration: const Duration(milliseconds: 400),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.85),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.5),
              blurRadius: 10,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Text(
          LanguageHelper.translate('double_tap_exit_hint', isAr),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildLiveHUD(BuildContext context, ChatProvider chatProvider) {
    final isAr = context.read<ThemeProvider>().isArabic;
    final minutes = (_liveSeconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (_liveSeconds % 60).toString().padLeft(2, '0');
    final timeStr = '$minutes:$seconds';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xEE141414),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.6),
            blurRadius: 16,
            spreadRadius: 2,
          ),
        ],
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
          // Live Pulse Badge
          TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 0.3, end: 1.0),
            duration: const Duration(milliseconds: 600),
            builder: (context, value, child) {
              return Opacity(opacity: value, child: child);
            },
            onEnd: () {},
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.redAccent,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    LanguageHelper.translate('live_badge', isAr),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 10),
          // Timer
          Text(
            timeStr,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 12),
          Container(width: 1, height: 16, color: Colors.white24),
          const SizedBox(width: 10),

          // Play/Pause button
          IconButton(
            constraints: const BoxConstraints(),
            padding: const EdgeInsets.all(4),
            icon: Icon(
              chatProvider.isPlaybackPaused ? Icons.play_arrow_rounded : Icons.pause_rounded,
              color: Colors.white,
              size: 20,
            ),
            onPressed: () => chatProvider.togglePlaybackPause(),
            tooltip: chatProvider.isPlaybackPaused ? LanguageHelper.translate('resume', isAr) : LanguageHelper.translate('pause', isAr),
          ),

          // Speed Toggle (1x, 1.5x, 2x)
          GestureDetector(
            onTap: () {
              double nextSpeed = 1.0;
              if (chatProvider.playbackSpeed == 1.0) {
                nextSpeed = 1.5;
              } else if (chatProvider.playbackSpeed == 1.5) {
                nextSpeed = 2.0;
              }
              chatProvider.setPlaybackSpeed(nextSpeed);
            },
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFF333333),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                '${chatProvider.playbackSpeed}x',
                style: const TextStyle(
                  color: Color(0xFF00E676),
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),

          // Mute / Unmute Sound
          IconButton(
            constraints: const BoxConstraints(),
            padding: const EdgeInsets.all(4),
            icon: Icon(
              chatProvider.isMuted ? Icons.volume_off_rounded : Icons.volume_up_rounded,
              color: chatProvider.isMuted ? Colors.white38 : const Color(0xFF42A5F5),
              size: 18,
            ),
            onPressed: () => chatProvider.toggleMute(),
            tooltip: chatProvider.isMuted ? LanguageHelper.translate('unmute', isAr) : LanguageHelper.translate('mute', isAr),
          ),

          // Replay Button
          IconButton(
            constraints: const BoxConstraints(),
            padding: const EdgeInsets.all(4),
            icon: const Icon(Icons.replay_rounded, color: Colors.white70, size: 18),
            onPressed: () {
              chatProvider.stopConversationPlayback();
              _startLiveSimulation(context);
            },
            tooltip: LanguageHelper.translate('replay', isAr),
          ),

          // Exit Button
          IconButton(
            constraints: const BoxConstraints(),
            padding: const EdgeInsets.all(4),
            icon: const Icon(Icons.close_rounded, color: Colors.redAccent, size: 20),
            onPressed: _stopLiveSimulation,
            tooltip: LanguageHelper.translate('stop_live', isAr),
          ),
        ],
      ),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: () => _showPlatformPicker(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF242424) : const Color(0xFFEEEEEE),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(_icon(session.platform), size: 14, color: session.platformColor),
            const SizedBox(width: 4),
            Icon(Icons.swap_horiz_rounded, size: 14, color: isDark ? Colors.white38 : Colors.black45),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black87;
    final isAr = context.read<ThemeProvider>().isArabic;

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1A1A1A) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          LanguageHelper.translate('switch_platform', isAr),
          style: TextStyle(color: textColor),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: Platform.values.map((p) {
            final isActive = p == session.platform;
            return ListTile(
              leading: Icon(_icon(p), color: _color(p)),
              title: Text(_name(p), style: TextStyle(
                color: isActive ? _color(p) : textColor,
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

