import 'dart:async';
import 'dart:io' as io;
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';

import '../models/chat_models.dart';
import '../providers/theme_provider.dart';
import '../themes/platform_themes.dart';
import '../utils/video_helper.dart';
import 'message_bubble.dart' show ProgressRingPainter;
import '../utils/language_helper.dart';

/// Dialog helper for showing full screen media viewers matching real WhatsApp / Telegram:
/// 1. Fullscreen Image (Pinch-to-zoom, top WhatsApp bar with star/share/download, bottom reply & reactions)
/// 2. Fullscreen Video (WhatsApp full-screen player with speed multiplier, scrubber, top bar & bottom reply/reactions)
/// 3. Enlarged Circle Video (Telegram / WhatsApp style enlarged circular video note)
class MediaViewerDialog {
  MediaViewerDialog._();

  /// Show Fullscreen Image Viewer
  static void showImage({
    required BuildContext context,
    required Uint8List imageBytes,
    String? caption,
    String? formattedTime,
    String? senderName,
    bool isSender = false,
  }) {
    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        barrierColor: Colors.black.withValues(alpha: 0.95),
        barrierDismissible: true,
        transitionDuration: const Duration(milliseconds: 250),
        reverseTransitionDuration: const Duration(milliseconds: 200),
        pageBuilder: (context, animation, secondaryAnimation) {
          return FullscreenImageViewer(
            imageBytes: imageBytes,
            caption: caption,
            formattedTime: formattedTime,
            senderName: senderName,
            isSender: isSender,
          );
        },
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: animation,
            child: ScaleTransition(
              scale: Tween<double>(begin: 0.95, end: 1.0).animate(
                CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
              ),
              child: child,
            ),
          );
        },
      ),
    );
  }

  /// Show Fullscreen Rectangular Video Player
  static void showVideo({
    required BuildContext context,
    required ChatMessage message,
    required Platform platform,
    required PlatformTheme platformTheme,
    String? senderName,
  }) {
    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        barrierColor: Colors.black.withValues(alpha: 0.96),
        barrierDismissible: true,
        transitionDuration: const Duration(milliseconds: 250),
        reverseTransitionDuration: const Duration(milliseconds: 200),
        pageBuilder: (context, animation, secondaryAnimation) {
          return FullscreenVideoViewer(
            message: message,
            platform: platform,
            platformTheme: platformTheme,
            senderName: senderName,
          );
        },
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: animation,
            child: ScaleTransition(
              scale: Tween<double>(begin: 0.95, end: 1.0).animate(
                CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
              ),
              child: child,
            ),
          );
        },
      ),
    );
  }

  /// Show Enlarged Circle Video Note Viewer
  static void showCircleVideo({
    required BuildContext context,
    required ChatMessage message,
    required Platform platform,
    required PlatformTheme platformTheme,
    String? senderName,
  }) {
    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        barrierColor: Colors.black.withValues(alpha: 0.88),
        barrierDismissible: true,
        transitionDuration: const Duration(milliseconds: 250),
        reverseTransitionDuration: const Duration(milliseconds: 200),
        pageBuilder: (context, animation, secondaryAnimation) {
          return EnlargedCircleVideoViewer(
            message: message,
            platform: platform,
            platformTheme: platformTheme,
            senderName: senderName,
          );
        },
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: animation,
            child: ScaleTransition(
              scale: Tween<double>(begin: 0.8, end: 1.0).animate(
                CurvedAnimation(parent: animation, curve: Curves.easeOutBack),
              ),
              child: child,
            ),
          );
        },
      ),
    );
  }
}

// =============================================================================
// 1. FULLSCREEN IMAGE VIEWER (WhatsApp / Telegram style)
// =============================================================================
class FullscreenImageViewer extends StatefulWidget {
  final Uint8List imageBytes;
  final String? caption;
  final String? formattedTime;
  final String? senderName;
  final bool isSender;

  const FullscreenImageViewer({
    super.key,
    required this.imageBytes,
    this.caption,
    this.formattedTime,
    this.senderName,
    this.isSender = false,
  });

  @override
  State<FullscreenImageViewer> createState() => _FullscreenImageViewerState();
}

class _FullscreenImageViewerState extends State<FullscreenImageViewer> {
  final TransformationController _transformationController = TransformationController();
  TapDownDetails? _doubleTapDetails;
  bool _showOverlay = true;

  void _handleDoubleTapDown(TapDownDetails details) {
    _doubleTapDetails = details;
  }

  void _handleDoubleTap() {
    if (_transformationController.value != Matrix4.identity()) {
      _transformationController.value = Matrix4.identity();
    } else {
      final position = _doubleTapDetails!.localPosition;
      _transformationController.value = Matrix4.identity()
        ..translate(-position.dx * 1.5, -position.dy * 1.5)
        ..scale(2.5);
    }
  }

  @override
  void dispose() {
    _transformationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isArabic = Provider.of<ThemeProvider>(context).isArabic;
    final bool hasCaption = widget.caption != null && widget.caption!.trim().isNotEmpty;
    final displayName = widget.senderName ?? (widget.isSender ? (LanguageHelper.pick(isArabic, 'أنت', 'You')) : 'Khaled Nageh');
    final timeSubtitle = widget.formattedTime ?? (LanguageHelper.pick(isArabic, 'اليوم، ٥:٢٣ ص', 'Today at 5:23 AM'));

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            // Image with Pinch & Zoom
            GestureDetector(
              onTap: () {
                setState(() {
                  _showOverlay = !_showOverlay;
                });
              },
              onDoubleTapDown: _handleDoubleTapDown,
              onDoubleTap: _handleDoubleTap,
              child: Center(
                child: InteractiveViewer(
                  transformationController: _transformationController,
                  clipBehavior: Clip.none,
                  minScale: 0.8,
                  maxScale: 4.0,
                  child: Image.memory(
                    widget.imageBytes,
                    fit: BoxFit.contain,
                    width: double.infinity,
                    height: double.infinity,
                  ),
                ),
              ),
            ),

            // Top Header Bar (Real WhatsApp Layout: Back arrow, Name & Time, Action Icons)
            AnimatedOpacity(
              opacity: _showOverlay ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 200),
              child: IgnorePointer(
                ignoring: !_showOverlay,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.black87, Colors.transparent],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                  child: Row(
                    textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
                    children: [
                      IconButton(
                        icon: Icon(
                          isArabic ? Icons.arrow_forward_rounded : Icons.arrow_back_rounded,
                          color: Colors.white,
                          size: 24,
                        ),
                        onPressed: () => Navigator.of(context).pop(),
                        tooltip: 'Back',
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
                          children: [
                            Text(
                              displayName,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              timeSubtitle,
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 11.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.file_download_outlined, color: Colors.white, size: 23),
                        onPressed: () {},
                        tooltip: 'Download',
                      ),
                      IconButton(
                        icon: const Icon(Icons.shortcut_rounded, color: Colors.white, size: 23),
                        onPressed: () {},
                        tooltip: 'Forward',
                      ),
                      IconButton(
                        icon: const Icon(Icons.add_reaction_outlined, color: Colors.white, size: 23),
                        onPressed: () {},
                        tooltip: 'React',
                      ),
                      IconButton(
                        icon: const Icon(Icons.more_vert_rounded, color: Colors.white, size: 23),
                        onPressed: () {},
                        tooltip: 'More',
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Bottom Area: Caption + Quick Reactions + Reply Pill
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: AnimatedOpacity(
                opacity: _showOverlay ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 200),
                child: IgnorePointer(
                  ignoring: !_showOverlay,
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.transparent, Colors.black87, Colors.black],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (hasCaption) ...[
                          Text(
                            widget.caption!,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              height: 1.3,
                            ),
                            textAlign: isArabic ? TextAlign.right : TextAlign.left,
                            textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
                          ),
                          const SizedBox(height: 12),
                        ],

                        // Quick Reactions & Reply bar (Exact WhatsApp Image 2 match)
                        Row(
                          textDirection: TextDirection.ltr,
                          children: [
                            // Quick Reactions Pill
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(24),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.add_reaction_outlined, color: Colors.white70, size: 20),
                                  SizedBox(width: 10),
                                  Text('😂', style: TextStyle(fontSize: 18)),
                                  SizedBox(width: 10),
                                  Text('❤️', style: TextStyle(fontSize: 18)),
                                ],
                              ),
                            ),
                            const Spacer(),
                            // Reply Pill ("رد")
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 9),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(24),
                              ),
                              child: Text(
                                LanguageHelper.pick(isArabic, 'رد', 'Reply'),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// 2. FULLSCREEN RECTANGULAR VIDEO VIEWER (Exact WhatsApp Image 1 Match)
// =============================================================================
class FullscreenVideoViewer extends StatefulWidget {
  final ChatMessage message;
  final Platform platform;
  final PlatformTheme platformTheme;
  final String? senderName;

  const FullscreenVideoViewer({
    super.key,
    required this.message,
    required this.platform,
    required this.platformTheme,
    this.senderName,
  });

  @override
  State<FullscreenVideoViewer> createState() => _FullscreenVideoViewerState();
}

class _FullscreenVideoViewerState extends State<FullscreenVideoViewer> {
  VideoPlayerController? _controller;
  bool _isInitialized = false;
  bool _isPlaying = false;
  bool _isMuted = false;
  bool _isInitializing = false;
  bool _showControls = true;
  Timer? _hideControlsTimer;
  Timer? _simulatedTimer;

  double _playbackSpeed = 1.0;
  Duration _currentPosition = Duration.zero;
  Duration _totalDuration = Duration.zero;
  String? _resolvedVideoPath;

  @override
  void initState() {
    super.initState();
    _totalDuration = widget.message.audioDuration ?? const Duration(seconds: 24);
    _resolveAndPlay();
    _startControlsTimer();
  }

  void _startControlsTimer() {
    _hideControlsTimer?.cancel();
    _hideControlsTimer = Timer(const Duration(milliseconds: 3500), () {
      if (mounted && _isPlaying) {
        setState(() {
          _showControls = false;
        });
      }
    });
  }

  void _toggleControls() {
    setState(() {
      _showControls = !_showControls;
    });
    if (_showControls && _isPlaying) {
      _startControlsTimer();
    }
  }

  void _cyclePlaybackSpeed() {
    setState(() {
      if (_playbackSpeed == 1.0) {
        _playbackSpeed = 1.5;
      } else if (_playbackSpeed == 1.5) {
        _playbackSpeed = 2.0;
      } else {
        _playbackSpeed = 1.0;
      }
    });
    _controller?.setPlaybackSpeed(_playbackSpeed);
  }

  Future<void> _resolveAndPlay() async {
    if (widget.message.videoBytes != null) {
      setState(() {
        _isInitializing = true;
      });
      final path = await VideoHelper.prepareVideoSource(widget.message.videoBytes!);
      if (mounted && path != null) {
        _resolvedVideoPath = path;
        await _initVideoPlayer();
      }
    } else {
      _startSimulation();
    }
  }

  Future<void> _initVideoPlayer() async {
    if (_resolvedVideoPath == null) return;
    try {
      VideoPlayerController controller;
      if (kIsWeb) {
        controller = VideoPlayerController.networkUrl(Uri.parse(_resolvedVideoPath!));
      } else {
        controller = VideoPlayerController.file(io.File(_resolvedVideoPath!));
      }

      _controller = controller;
      await controller.initialize();

      if (mounted) {
        setState(() {
          _isInitialized = true;
          _totalDuration = controller.value.duration;
          _isInitializing = false;
        });

        controller.addListener(() {
          if (mounted) {
            setState(() {
              _currentPosition = controller.value.position;
              _isPlaying = controller.value.isPlaying;
            });
          }
        });

        await controller.play();
        setState(() {
          _isPlaying = true;
        });
      }
    } catch (e) {
      debugPrint('Error initializing full screen video player: $e');
      if (mounted) {
        setState(() {
          _isInitializing = false;
        });
        _startSimulation();
      }
    }
  }

  void _startSimulation() {
    setState(() {
      _isPlaying = true;
    });
    _simulatedTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      if (!mounted) return;
      setState(() {
        _currentPosition += const Duration(milliseconds: 100);
        if (_currentPosition >= _totalDuration) {
          _currentPosition = _totalDuration;
          _isPlaying = false;
          _simulatedTimer?.cancel();
        }
      });
    });
  }

  Future<void> _togglePlay() async {
    if (_controller != null && _isInitialized) {
      if (_isPlaying) {
        await _controller!.pause();
      } else {
        if (_currentPosition >= _totalDuration) {
          await _controller!.seekTo(Duration.zero);
        }
        await _controller!.play();
        _startControlsTimer();
      }
    } else {
      if (_isPlaying) {
        _simulatedTimer?.cancel();
        setState(() {
          _isPlaying = false;
        });
      } else {
        if (_currentPosition >= _totalDuration) {
          _currentPosition = Duration.zero;
        }
        _startSimulation();
        _startControlsTimer();
      }
    }
  }

  Future<void> _seekTo(double value) async {
    final target = Duration(milliseconds: value.toInt());
    if (_controller != null && _isInitialized) {
      await _controller!.seekTo(target);
    } else {
      setState(() {
        _currentPosition = target;
      });
    }
  }

  String _formatDuration(Duration d) {
    final m = d.inMinutes.toString();
    final s = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  void dispose() {
    _hideControlsTimer?.cancel();
    _simulatedTimer?.cancel();
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isArabic = Provider.of<ThemeProvider>(context).isArabic;
    final bool hasCaption = widget.message.text.isNotEmpty;
    final displayName = widget.senderName ?? (widget.message.isSender ? (LanguageHelper.pick(isArabic, 'أنت', 'You')) : 'Khaled Nageh');
    final timeSubtitle = widget.message.formattedTime.isNotEmpty 
        ? (LanguageHelper.pick(isArabic, 'اليوم، ${widget.message.formattedTime}', 'Today at ${widget.message.formattedTime}'))
        : (LanguageHelper.pick(isArabic, 'اليوم، ٥:٢٣ ص', 'Today at 5:23 AM'));

    const greenColor = Color(0xFF25D366);

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: GestureDetector(
          onTap: _toggleControls,
          behavior: HitTestBehavior.opaque,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Video Player Body or Image Thumbnail
              Center(
                child: _isInitialized && _controller != null
                    ? AspectRatio(
                        aspectRatio: _controller!.value.aspectRatio,
                        child: VideoPlayer(_controller!),
                      )
                    : widget.message.imageBytes != null
                        ? Image.memory(
                            widget.message.imageBytes!,
                            fit: BoxFit.contain,
                            width: double.infinity,
                            height: double.infinity,
                          )
                        : _isInitializing
                            ? const CircularProgressIndicator(color: Colors.white)
                            : const Icon(Icons.videocam_rounded, color: Colors.white54, size: 64),
              ),

              // Controls Overlay
              AnimatedOpacity(
                opacity: _showControls ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 200),
                child: IgnorePointer(
                  ignoring: !_showControls,
                  child: Stack(
                    children: [
                      // Top Bar (Matching Image 1: Back arrow, Name & Subtitle, Options/Star/Share/Download)
                      Positioned(
                        top: 0,
                        left: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Colors.black87, Colors.transparent],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                            ),
                          ),
                          child: Row(
                            textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
                            children: [
                              IconButton(
                                icon: Icon(
                                  isArabic ? Icons.arrow_forward_rounded : Icons.arrow_back_rounded,
                                  color: Colors.white,
                                  size: 24,
                                ),
                                onPressed: () => Navigator.of(context).pop(),
                                tooltip: 'Back',
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
                                  children: [
                                    Text(
                                      displayName,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    Text(
                                      timeSubtitle,
                                      style: const TextStyle(
                                        color: Colors.white70,
                                        fontSize: 11.5,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.file_download_outlined, color: Colors.white, size: 23),
                                onPressed: () {},
                                tooltip: 'Download',
                              ),
                              IconButton(
                                icon: const Icon(Icons.shortcut_rounded, color: Colors.white, size: 23),
                                onPressed: () {},
                                tooltip: 'Forward',
                              ),
                              IconButton(
                                icon: const Icon(Icons.add_reaction_outlined, color: Colors.white, size: 23),
                                onPressed: () {},
                                tooltip: 'React',
                              ),
                              IconButton(
                                icon: const Icon(Icons.more_vert_rounded, color: Colors.white, size: 23),
                                onPressed: () {},
                                tooltip: 'More',
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Center Translucent Circle Play/Pause Button (Matching Image 1)
                      Center(
                        child: GestureDetector(
                          onTap: _togglePlay,
                          child: Container(
                            width: 56,
                            height: 56,
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.5),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              _isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                              color: Colors.white,
                              size: 38,
                            ),
                          ),
                        ),
                      ),

                      // Bottom Scrubber Bar & Caption & Reply Bar (Matching Image 1)
                      Positioned(
                        bottom: 0,
                        left: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Colors.transparent, Colors.black87, Colors.black],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                            ),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // Caption Text above scrubber (Image 1 "كلام جميل")
                              if (hasCaption) ...[
                                Text(
                                  widget.message.text,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  textAlign: isArabic ? TextAlign.right : TextAlign.left,
                                  textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
                                ),
                                const SizedBox(height: 8),
                              ],

                              // Timeline Scrubber Row: Elapsed (Left) | Slider | Total | Speed (1.0X) (Right)
                              Row(
                                textDirection: TextDirection.ltr,
                                children: [
                                  Text(
                                    _formatDuration(_currentPosition),
                                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                                  ),
                                  Expanded(
                                    child: SliderTheme(
                                      data: SliderTheme.of(context).copyWith(
                                        activeTrackColor: greenColor,
                                        inactiveTrackColor: Colors.white30,
                                        thumbColor: greenColor,
                                        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                                        overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
                                        trackHeight: 3.0,
                                      ),
                                      child: Slider(
                                        min: 0.0,
                                        max: _totalDuration.inMilliseconds.toDouble() > 0
                                            ? _totalDuration.inMilliseconds.toDouble()
                                            : 1.0,
                                        value: _currentPosition.inMilliseconds
                                            .toDouble()
                                            .clamp(0.0, _totalDuration.inMilliseconds.toDouble()),
                                        onChanged: (val) => _seekTo(val),
                                      ),
                                    ),
                                  ),
                                  Text(
                                    _formatDuration(_totalDuration),
                                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                                  ),
                                  const SizedBox(width: 8),
                                  // Speed Multiplier Button (Image 1 & 2 "1.0X")
                                  GestureDetector(
                                    onTap: _cyclePlaybackSpeed,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withValues(alpha: 0.15),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        '${_playbackSpeed.toStringAsFixed(1)}X',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 12),

                              // Quick Reactions & Reply Bar (Exact WhatsApp Image 2 match)
                              Row(
                                textDirection: TextDirection.ltr,
                                children: [
                                  // Quick Reactions Pill
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(24),
                                    ),
                                    child: const Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.add_reaction_outlined, color: Colors.white70, size: 20),
                                        SizedBox(width: 10),
                                        Text('😂', style: TextStyle(fontSize: 18)),
                                        SizedBox(width: 10),
                                        Text('❤️', style: TextStyle(fontSize: 18)),
                                      ],
                                    ),
                                  ),
                                  const Spacer(),
                                  // Reply Pill ("رد")
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 9),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(24),
                                    ),
                                    child: Text(
                                      LanguageHelper.pick(isArabic, 'رد', 'Reply'),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// 3. ENLARGED CIRCLE VIDEO NOTE VIEWER (Telegram / WhatsApp Video Note Popup)
// =============================================================================
class EnlargedCircleVideoViewer extends StatefulWidget {
  final ChatMessage message;
  final Platform platform;
  final PlatformTheme platformTheme;
  final String? senderName;

  const EnlargedCircleVideoViewer({
    super.key,
    required this.message,
    required this.platform,
    required this.platformTheme,
    this.senderName,
  });

  @override
  State<EnlargedCircleVideoViewer> createState() => _EnlargedCircleVideoViewerState();
}

class _EnlargedCircleVideoViewerState extends State<EnlargedCircleVideoViewer> {
  VideoPlayerController? _controller;
  bool _isInitialized = false;
  bool _isPlaying = false;
  bool _isInitializing = false;
  Timer? _simulatedTimer;

  Duration _currentPosition = Duration.zero;
  Duration _totalDuration = Duration.zero;
  String? _resolvedVideoPath;

  @override
  void initState() {
    super.initState();
    _totalDuration = widget.message.audioDuration ?? const Duration(seconds: 15);
    _resolveAndPlay();
  }

  Future<void> _resolveAndPlay() async {
    if (widget.message.videoBytes != null) {
      setState(() {
        _isInitializing = true;
      });
      final path = await VideoHelper.prepareVideoSource(widget.message.videoBytes!);
      if (mounted && path != null) {
        _resolvedVideoPath = path;
        await _initVideoPlayer();
      }
    } else {
      _startSimulation();
    }
  }

  Future<void> _initVideoPlayer() async {
    if (_resolvedVideoPath == null) return;
    try {
      VideoPlayerController controller;
      if (kIsWeb) {
        controller = VideoPlayerController.networkUrl(Uri.parse(_resolvedVideoPath!));
      } else {
        controller = VideoPlayerController.file(io.File(_resolvedVideoPath!));
      }

      _controller = controller;
      await controller.initialize();

      if (mounted) {
        setState(() {
          _isInitialized = true;
          _totalDuration = controller.value.duration;
          _isInitializing = false;
        });

        controller.addListener(() {
          if (mounted) {
            setState(() {
              _currentPosition = controller.value.position;
              _isPlaying = controller.value.isPlaying;
            });
          }
        });

        await controller.play();
        setState(() {
          _isPlaying = true;
        });
      }
    } catch (e) {
      debugPrint('Error initializing circle video player: $e');
      if (mounted) {
        setState(() {
          _isInitializing = false;
        });
        _startSimulation();
      }
    }
  }

  void _startSimulation() {
    setState(() {
      _isPlaying = true;
    });
    _simulatedTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      if (!mounted) return;
      setState(() {
        _currentPosition += const Duration(milliseconds: 100);
        if (_currentPosition >= _totalDuration) {
          _currentPosition = _totalDuration;
          _isPlaying = false;
          _simulatedTimer?.cancel();
        }
      });
    });
  }

  Future<void> _togglePlay() async {
    if (_controller != null && _isInitialized) {
      if (_isPlaying) {
        await _controller!.pause();
      } else {
        if (_currentPosition >= _totalDuration) {
          await _controller!.seekTo(Duration.zero);
        }
        await _controller!.play();
      }
    } else {
      if (_isPlaying) {
        _simulatedTimer?.cancel();
        setState(() {
          _isPlaying = false;
        });
      } else {
        if (_currentPosition >= _totalDuration) {
          _currentPosition = Duration.zero;
        }
        _startSimulation();
      }
    }
  }

  String _formatDuration(Duration d) {
    final m = d.inMinutes.toString();
    final s = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  void dispose() {
    _simulatedTimer?.cancel();
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isArabic = Provider.of<ThemeProvider>(context).isArabic;
    final screenSize = MediaQuery.of(context).size;
    final double circleSize = (screenSize.width - 48.0).clamp(250.0, 340.0);
    final total = _totalDuration;
    final double progressPct = total.inMilliseconds > 0
        ? _currentPosition.inMilliseconds / total.inMilliseconds
        : 0.0;

    const activeRingColor = Color(0xFF25D366);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Stack(
          children: [
            // Tap outside to close
            Positioned.fill(
              child: GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                behavior: HitTestBehavior.opaque,
                child: Container(color: Colors.transparent),
              ),
            ),

            // Top Header Bar with Close Button
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.close_rounded, color: Colors.white, size: 28),
                      onPressed: () => Navigator.of(context).pop(),
                      tooltip: 'Close',
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        widget.message.formattedTime,
                        style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Center Big Circle Video Note (Matching Image 2)
            Center(
              child: GestureDetector(
                onTap: _togglePlay,
                child: Container(
                  width: circleSize,
                  height: circleSize,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFF1E1E1E),
                    boxShadow: [
                      BoxShadow(
                        color: activeRingColor.withValues(alpha: 0.35),
                        blurRadius: 24,
                        spreadRadius: 4,
                      ),
                    ],
                  ),
                  child: CustomPaint(
                    painter: ProgressRingPainter(progress: progressPct, color: activeRingColor),
                    child: Padding(
                      padding: const EdgeInsets.all(7),
                      child: ClipOval(
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            // Video player or image/placeholder
                            if (_isInitialized && _controller != null)
                              SizedBox.expand(
                                child: FittedBox(
                                  fit: BoxFit.cover,
                                  clipBehavior: Clip.hardEdge,
                                  child: SizedBox(
                                    width: _controller!.value.size.width,
                                    height: _controller!.value.size.height,
                                    child: VideoPlayer(_controller!),
                                  ),
                                ),
                              )
                            else if (widget.message.imageBytes != null)
                              Image.memory(
                                widget.message.imageBytes!,
                                width: double.infinity,
                                height: double.infinity,
                                fit: BoxFit.cover,
                              )
                            else
                              Container(
                                color: const Color(0xFF1E1E1E),
                                child: Center(
                                  child: _isInitializing
                                      ? const SizedBox(
                                          width: 40,
                                          height: 40,
                                          child: CircularProgressIndicator(
                                            color: Colors.white38,
                                            strokeWidth: 2.5,
                                          ),
                                        )
                                      : const Icon(Icons.videocam_rounded, color: Colors.white38, size: 64),
                                ),
                              ),

                            // Play button overlay when paused
                            if (!_isPlaying && !_isInitializing)
                              Container(
                                width: 56,
                                height: 56,
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.45),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.play_arrow_rounded,
                                  color: Colors.white,
                                  size: 38,
                                ),
                              ),

                            // Bottom duration badge
                            Positioned(
                              bottom: 18,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.65),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  _formatDuration(total - _currentPosition),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
