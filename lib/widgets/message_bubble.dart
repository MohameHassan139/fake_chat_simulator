import 'dart:async';
import 'dart:io' as io;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:video_player/video_player.dart';
import '../models/chat_models.dart';
import '../utils/video_helper.dart';
import '../utils/audio_helper.dart';
import '../themes/platform_themes.dart';
import '../providers/theme_provider.dart';

bool _isArabic(String text) {
  final arabicRegExp = RegExp(
      r'[\u0600-\u06FF\u0750-\u077F\u08A0-\u08FF\uFB50-\uFDFF\uFE70-\uFEFF]');
  return arabicRegExp.hasMatch(text);
}

class MessageBubble extends StatelessWidget {
  final ChatMessage message;
  final ChatUser contactUser;
  final Platform platform;
  final PlatformTheme platformTheme;
  final bool isFirstInGroup;
  final bool isLastInGroup;
  final bool isBlockedMe;

  const MessageBubble({
    super.key,
    required this.message,
    required this.contactUser,
    required this.platform,
    required this.platformTheme,
    required this.isFirstInGroup,
    required this.isLastInGroup,
    this.isBlockedMe = false,
  });

  @override
  Widget build(BuildContext context) {
    if (platform == Platform.messenger || platform == Platform.instagram) {
      if (message.type == MessageType.voiceCall || message.type == MessageType.videoCall) {
        return _buildNativeCallRecord(context);
      }
    }

    final isSender = message.isSender;
    final bool isArabicLocale = Provider.of<ThemeProvider>(context).isArabic;
    final bool effectiveSender = isArabicLocale ? !isSender : isSender;
    final hasReaction = message.reaction != null && message.reaction!.isNotEmpty;

    // Determine high-fidelity external status indicator based on platform
    Widget? externalIndicator;
    if (isSender) {
      if (platform == Platform.whatsapp) {
        // WhatsApp status ticks reside INSIDE the green/white bubble at the bottom right
        externalIndicator = null;
      } else if (platform == Platform.messenger) {
        // Messenger displays ticks/avatar ONLY outside the very last message in a group
        if (isLastInGroup) {
          externalIndicator = Padding(
            padding: const EdgeInsets.only(bottom: 2),
            child: _MessengerStatusIndicator(
              status: message.status,
              contactUser: contactUser,
              theme: platformTheme,
            ),
          );
        }
      } else if (platform == Platform.instagram) {
        // Instagram: no "Seen" indicator
      } else {
        // Snapchat
        if (isBlockedMe) {
          externalIndicator = const Padding(
            padding: EdgeInsets.only(bottom: 2),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.play_arrow_outlined, size: 14, color: Colors.grey),
                SizedBox(width: 4),
                Text(
                  'Pending',
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          );
        } else {
          externalIndicator = Padding(
            padding: const EdgeInsets.only(bottom: 2),
            child: _StatusTick(status: message.status, platformTheme: platformTheme),
          );
        }
      }
    }

    // Wrap bubble in a Stack if it has an emoji reaction hovering over the bottom border
    Widget bubble = _buildBubble(context, isSender);
    if (hasReaction) {
      bubble = Stack(
        clipBehavior: Clip.none,
        children: [
          bubble,
          Positioned(
            bottom: -6,
            left: effectiveSender ? 12 : null,
            right: effectiveSender ? null : 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: platformTheme.chatBg == Colors.black || platformTheme.chatBg.value == 0xFF0B141A || platformTheme.chatBg.value == 0xFF000000 || platformTheme.chatBg.value == 0xFF0B0C0E
                    ? const Color(0xFF242526) 
                    : Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.12),
                    blurRadius: 3,
                    offset: const Offset(0, 1),
                  ),
                ],
                border: Border.all(
                  color: platformTheme.chatBg == Colors.black || platformTheme.chatBg.value == 0xFF0B141A || platformTheme.chatBg.value == 0xFF000000 || platformTheme.chatBg.value == 0xFF0B0C0E
                      ? const Color(0xFF3E4042)
                      : const Color(0xFFE4E6EB),
                  width: 0.8,
                ),
              ),
              child: Text(
                message.reaction!,
                style: const TextStyle(fontSize: 11.5),
              ),
            ),
          ),
        ],
      );
    }

    return Padding(
      padding: EdgeInsets.only(
        top: isFirstInGroup ? 6 : 2,
        bottom: isLastInGroup ? (hasReaction ? 12 : 6) : (hasReaction ? 8 : 2),
        left: 8,
        right: 8,
      ),
      child: Row(
        mainAxisAlignment: isSender ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isSender && platformTheme.showReceiverAvatar) ...[
            if (isLastInGroup)
              _AvatarWidget(user: contactUser, platform: platform)
            else
              const SizedBox(width: 28), // Standard CircleAvatar diameter is 28px
            const SizedBox(width: 6),
          ],
          Flexible(
            child: bubble,
          ),
          if (externalIndicator != null) ...[
            const SizedBox(width: 6),
            externalIndicator,
          ],
        ],
      ),
    );
  }

  Widget _buildBubble(BuildContext context, bool isSender) {
    final bool isArabicLocale = Provider.of<ThemeProvider>(context).isArabic;
    final bool effectiveSender = isArabicLocale ? !isSender : isSender;
    final radius = platformTheme.bubbleRadius;
    final BorderRadius borderRadius;

    if (platform == Platform.messenger || platform == Platform.instagram) {
      borderRadius = _getMessengerInstagramBorderRadius(
        effectiveSender,
        isFirstInGroup,
        isLastInGroup,
        radius,
      );
    } else {
      if (effectiveSender) {
        borderRadius = BorderRadius.only(
          topLeft: Radius.circular(radius),
          topRight: Radius.circular(isFirstInGroup ? radius : platformTheme.senderBubbleRadiusTR),
          bottomLeft: Radius.circular(radius),
          bottomRight: Radius.circular(isLastInGroup ? platformTheme.senderBubbleRadiusTR : radius),
        );
      } else {
        borderRadius = BorderRadius.only(
          topLeft: Radius.circular(isFirstInGroup ? radius : platformTheme.senderBubbleRadiusTR),
          topRight: Radius.circular(radius),
          bottomLeft: Radius.circular(isLastInGroup ? platformTheme.senderBubbleRadiusTR : radius),
          bottomRight: Radius.circular(radius),
        );
      }
    }

    Widget bubbleContent;

    final bool isRtl = isArabicLocale || _isArabic(message.text);
    final hasReply =
        message.repliedToId != null && message.repliedToText != null;

    switch (message.type) {
      case MessageType.text:
        bubbleContent = _TextContent(
          message: message,
          isSender: isSender,
          platform: platform,
          platformTheme: platformTheme,
          hasReply: hasReply,
          isBlockedMe: isBlockedMe,
        );
        break;
      case MessageType.image:
        bubbleContent = _ImageContent(
          message: message,
          isSender: isSender,
          platform: platform,
          platformTheme: platformTheme,
          isBlockedMe: isBlockedMe,
        );
        break;
      case MessageType.audio:
        bubbleContent = _AudioPlayerWidget(
          message: message,
          isSender: isSender,
          platform: platform,
          platformTheme: platformTheme,
          isBlockedMe: isBlockedMe,
        );
        break;
      case MessageType.video:
        bubbleContent = _VideoPlayerWidget(
          message: message,
          isSender: isSender,
          platform: platform,
          platformTheme: platformTheme,
          isBlockedMe: isBlockedMe,
        );
        break;
      case MessageType.voiceCall:
      case MessageType.videoCall:
        bubbleContent = _CallContent(
          message: message,
          isSender: isSender,
          platform: platform,
          platformTheme: platformTheme,
          isBlockedMe: isBlockedMe,
        );
        break;
      default:
        bubbleContent = _TextContent(
          message: message,
          isSender: isSender,
          platform: platform,
          platformTheme: platformTheme,
          isBlockedMe: isBlockedMe,
        );
    }

    var finalContent = hasReply
        ? IntrinsicWidth(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                _ReplyPreviewHeader(
                  repliedToText: message.repliedToText!,
                  repliedToSenderName: message.repliedToSenderName ?? 'Contact',
                  isSender: isSender,
                  platform: platform,
                  platformTheme: platformTheme,
                  bubbleIsRtl: isRtl,
                ),
                bubbleContent,
              ],
            ),
          )
        : bubbleContent;

    if (message.isForwarded) {
      finalContent = IntrinsicWidth(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            _ForwardedHeader(
              isSender: isSender,
              platformTheme: platformTheme,
            ),
            finalContent,
          ],
        ),
      );
    }

    if (message.type == MessageType.video && message.isVideoMessage) {
      return finalContent;
    }

    if (platform == Platform.whatsapp) {
      final clipper = WhatsAppBubbleClipper(
          isSender: effectiveSender, isFirstInGroup: isFirstInGroup);
      final bubbleColor =
          isSender ? platformTheme.senderBubble : platformTheme.receiverBubble;

      // Tail side padding: the WhatsApp tail eats ~6px on its side
      final double tailPad = isFirstInGroup ? 6.0 : 0.0;
      final EdgeInsets outerPad = effectiveSender
          ? EdgeInsets.fromLTRB(10, 6, 10 + tailPad, 6)
          : EdgeInsets.fromLTRB(10 + tailPad, 6, 10, 6);

      final waBubble = ClipPath(
        clipper: clipper,
        child: PhysicalShape(
          clipper: clipper,
          color: bubbleColor,
          elevation: 0.8,
          shadowColor: Colors.black.withOpacity(0.08),
          child: Padding(
            padding: outerPad,
            child: finalContent,
          ),
        ),
      );

      // Constrain max width so reply bubbles don't stretch full screen width.
      // Fixed cap of 260 works across the 280–390px phone frame range (~70%).
      if (hasReply) {
        return ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 260),
          child: waBubble,
        );
      }
      return waBubble;
    }

    return _BubbleContainer(
      isSender: isSender,
      borderRadius: borderRadius,
      platformTheme: platformTheme,
      child: finalContent,
    );
  }

  BorderRadius _getMessengerInstagramBorderRadius(
    bool isSender,
    bool isFirst,
    bool isLast,
    double radius,
  ) {
    const double smallRadius = 4.0;
    if (isSender) {
      if (isFirst && isLast) {
        return BorderRadius.only(
          topLeft: Radius.circular(radius),
          topRight: Radius.circular(radius),
          bottomLeft: Radius.circular(radius),
          bottomRight: Radius.circular(smallRadius),
        );
      }
      if (isFirst) {
        return BorderRadius.only(
          topLeft: Radius.circular(radius),
          topRight: Radius.circular(radius),
          bottomLeft: Radius.circular(radius),
          bottomRight: Radius.circular(smallRadius),
        );
      }
      if (isLast) {
        return BorderRadius.only(
          topLeft: Radius.circular(radius),
          topRight: Radius.circular(smallRadius),
          bottomLeft: Radius.circular(radius),
          bottomRight: Radius.circular(radius),
        );
      }
      return BorderRadius.only(
        topLeft: Radius.circular(radius),
        topRight: Radius.circular(smallRadius),
        bottomLeft: Radius.circular(radius),
        bottomRight: Radius.circular(smallRadius),
      );
    } else {
      if (isFirst && isLast) {
        return BorderRadius.only(
          topLeft: Radius.circular(radius),
          topRight: Radius.circular(radius),
          bottomLeft: Radius.circular(smallRadius),
          bottomRight: Radius.circular(radius),
        );
      }
      if (isFirst) {
        return BorderRadius.only(
          topLeft: Radius.circular(radius),
          topRight: Radius.circular(radius),
          bottomLeft: Radius.circular(smallRadius),
          bottomRight: Radius.circular(radius),
        );
      }
      if (isLast) {
        return BorderRadius.only(
          topLeft: Radius.circular(smallRadius),
          topRight: Radius.circular(radius),
          bottomLeft: Radius.circular(radius),
          bottomRight: Radius.circular(radius),
        );
      }
      return BorderRadius.only(
        topLeft: Radius.circular(smallRadius),
        topRight: Radius.circular(radius),
        bottomLeft: Radius.circular(smallRadius),
        bottomRight: Radius.circular(radius),
      );
    }
  }


  String _formatCallDurationLocal(Duration? d, bool isArabic) {
    if (d == null || d == Duration.zero) return '';
    if (d.inMinutes > 0) {
      final mins = d.inMinutes;
      final secs = d.inSeconds % 60;
      if (secs > 0) {
        if (isArabic) {
          return '$mins د $secs ث';
        }
        return '$mins min $secs sec';
      }
      if (isArabic) {
        return '$mins د';
      }
      return '$mins min';
    }
    if (isArabic) {
      return '${d.inSeconds} ث';
    }
    return '${d.inSeconds} sec';
  }

  Widget _buildNativeCallRecord(BuildContext context) {
    final isVideo = message.type == MessageType.videoCall;
    final isMissed = message.text.toLowerCase().contains('missed') ||
        message.text.toLowerCase().contains('declined') ||
        message.text.toLowerCase().contains('no answer');

    final isSender = message.isSender;

    // Use ThemeProvider to get isArabic preference
    final isArabic = Provider.of<ThemeProvider>(context).isArabic;

    final isDark = platformTheme.chatBg == Colors.black || 
        platformTheme.chatBg.value == 0xFF000000 || 
        platformTheme.chatBg.value == 0xFF0B0C0E ||
        platformTheme.chatBg.value == 0xFF0B141A;

    // Standard styling based on dark mode
    final Color textCol = isDark ? Colors.white : Colors.black;
    final Color subTextCol = isDark ? Colors.white54 : Colors.black54;

    // Dynamic Title / Subtitle with dynamic translations
    String callTitle = '';
    String callSubtitle = '';

    if (platform == Platform.instagram) {
      if (isMissed) {
        if (isArabic) {
          callTitle = isVideo ? 'دردشة فيديو فائتة' : 'مكالمة صوتية فائتة';
        } else {
          callTitle = isVideo ? 'Missed video chat' : 'Missed audio call';
        }
      } else {
        if (isArabic) {
          callTitle = isVideo ? 'انتهت دردشة الفيديو' : 'انتهت المكالمة الصوتية';
        } else {
          callTitle = isVideo ? 'Video chat ended' : 'Audio call ended';
        }
      }
      
      final String dur = _formatCallDurationLocal(message.audioDuration, isArabic);
      callSubtitle = dur.isNotEmpty ? '$dur • ${message.formattedTime}' : message.formattedTime;
    } else {
      // Messenger
      if (isMissed) {
        if (isArabic) {
          callTitle = isVideo ? 'مكالمة فيديو فائتة' : 'مكالمة صوتية فائتة';
        } else {
          callTitle = isVideo ? 'Missed video call' : 'Missed voice call';
        }
      } else {
        if (isArabic) {
          callTitle = isVideo ? 'انتهت مكالمة الفيديو' : 'انتهت المكالمة الصوتية';
        } else {
          callTitle = isVideo ? 'Video call ended' : 'Voice call ended';
        }
      }

      final String dur = _formatCallDurationLocal(message.audioDuration, isArabic);
      callSubtitle = dur.isNotEmpty ? '$dur • ${message.formattedTime}' : message.formattedTime;
    }

    Widget callBubbleCard;

    if (platform == Platform.instagram) {
      final circleBg = isDark ? const Color(0xFF262626) : const Color(0xFFF5F5F5);
      final iconCol = isMissed ? const Color(0xFFED4956) : (isDark ? Colors.white : Colors.black);

      callBubbleCard = Container(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
        child: Row(
          children: [
            // Circular Icon
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: circleBg,
              ),
              child: Icon(
                isMissed
                    ? (isVideo ? Icons.missed_video_call_rounded : Icons.phone_missed_rounded)
                    : (isVideo ? Icons.videocam_rounded : Icons.phone_rounded),
                color: iconCol,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            // Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    callTitle,
                    style: TextStyle(
                      color: textCol,
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    callSubtitle,
                    style: TextStyle(
                      color: subTextCol,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            // Call Back Action Text
            Text(
              isArabic ? 'معاودة الاتصال' : 'Call Back',
              style: const TextStyle(
                color: Color(0xFF0095F6),
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      );
    } else {
      // Messenger
      final cardBg = isDark ? const Color(0xFF242526) : const Color(0xFFF0F0F0);
      final circleBg = isDark ? const Color(0xFF3A3B3C) : Colors.white;
      final iconCol = isMissed ? const Color(0xFFFA3E3E) : (isDark ? Colors.white : const Color(0xFF0F0F0F));
      final btnBg = isDark ? const Color(0xFF3A3B3C) : Colors.white;

      callBubbleCard = Container(
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: _getMessengerInstagramBorderRadius(
            isArabic ? !isSender : isSender,
            isFirstInGroup,
            isLastInGroup,
            platformTheme.bubbleRadius,
          ),
        ),
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                // Circular Call Icon
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: circleBg,
                  ),
                  child: Icon(
                    isMissed
                        ? (isVideo ? Icons.missed_video_call_rounded : Icons.phone_missed_rounded)
                        : (isVideo ? Icons.videocam_rounded : Icons.phone_rounded),
                    color: iconCol,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                // Call details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        callTitle,
                        style: TextStyle(
                          color: textCol,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        callSubtitle,
                        style: TextStyle(
                          color: subTextCol,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Call Back button
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: btnBg,
                borderRadius: BorderRadius.circular(100),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  isArabic ? 'معاودة الاتصال' : 'Call Back',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: textCol,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: EdgeInsets.only(
        top: isFirstInGroup ? 6 : 2,
        bottom: isLastInGroup ? 6 : 2,
        left: 8,
        right: 8,
      ),
      child: Row(
        mainAxisAlignment: isSender ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isSender && platformTheme.showReceiverAvatar) ...[
            if (isLastInGroup)
              _AvatarWidget(user: contactUser, platform: platform)
            else
              const SizedBox(width: 28), // Standard CircleAvatar diameter is 28px
            const SizedBox(width: 6),
          ],
          Flexible(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: platform == Platform.instagram ? 280 : 250,
              ),
              child: callBubbleCard,
            ),
          ),
        ],
      ),
    );
  }

}

// ─── WhatsApp Bubble Clipper ──────────────────────────────────────────────────────

class WhatsAppBubbleClipper extends CustomClipper<Path> {
  final bool isSender;
  final bool isFirstInGroup;

  WhatsAppBubbleClipper({required this.isSender, required this.isFirstInGroup});

  @override
  Path getClip(Size size) {
    final path = Path();
    const double r = 8.0;

    if (!isFirstInGroup) {
      path.addRRect(RRect.fromLTRBAndCorners(
        0, 0, size.width, size.height,
        topLeft: const Radius.circular(r),
        topRight: const Radius.circular(r),
        bottomLeft: const Radius.circular(r),
        bottomRight: const Radius.circular(r),
      ));
      return path;
    }

    if (isSender) {
      path.moveTo(r, 0);
      path.lineTo(size.width - 10, 0);
      path.lineTo(size.width, 0); // Point of tail
      path.quadraticBezierTo(size.width - 3, 6, size.width - 8, 9);
      path.lineTo(size.width - 8, size.height - r);
      path.quadraticBezierTo(size.width - 8, size.height, size.width - 8 - r, size.height);
      path.lineTo(r, size.height);
      path.quadraticBezierTo(0, size.height, 0, size.height - r);
      path.lineTo(0, r);
      path.quadraticBezierTo(0, 0, r, 0);
    } else {
      path.moveTo(8 + r, 0);
      path.lineTo(size.width - r, 0);
      path.quadraticBezierTo(size.width, 0, size.width, r);
      path.lineTo(size.width, size.height - r);
      path.quadraticBezierTo(size.width, size.height, size.width - r, size.height);
      path.lineTo(8 + r, size.height);
      path.quadraticBezierTo(8, size.height, 8, size.height - r);
      path.lineTo(8, 9);
      path.quadraticBezierTo(3, 6, 0, 0); // Point of tail
      path.lineTo(8, 0);
    }
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant WhatsAppBubbleClipper oldClipper) {
    return oldClipper.isSender != isSender || oldClipper.isFirstInGroup != isFirstInGroup;
  }
}

// ─── Bubble Container (solid vs gradient) ──────────────────────────────────────

class _BubbleContainer extends StatelessWidget {
  final bool isSender;
  final BorderRadius borderRadius;
  final PlatformTheme platformTheme;
  final Widget child;

  const _BubbleContainer({
    required this.isSender,
    required this.borderRadius,
    required this.platformTheme,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    if (isSender && platformTheme.gradientSenderBubble && platformTheme.senderGradient != null) {
      return Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: platformTheme.senderGradient!,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: borderRadius,
        ),
        child: child,
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: isSender ? platformTheme.senderBubble : platformTheme.receiverBubble,
        borderRadius: borderRadius,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: child,
    );
  }
}

// ─── Text Content ─────────────────────────────────────────────────────────────

class _TextContent extends StatelessWidget {
  final ChatMessage message;
  final bool isSender;
  final Platform platform;
  final PlatformTheme platformTheme;
  final bool hasReply;
  final bool isBlockedMe;

  const _TextContent({
    required this.message,
    required this.isSender,
    required this.platform,
    required this.platformTheme,
    this.hasReply = false,
    this.isBlockedMe = false,
  });

  @override
  Widget build(BuildContext context) {
    final textColor = isSender ? platformTheme.senderText : platformTheme.receiverText;
    final bool isRtl = _isArabic(message.text);

    if (platform == Platform.whatsapp) {
      return Stack(
        children: [
          Padding(
            padding: EdgeInsets.only(
              bottom: 10,
              left: isRtl ? (isSender ? 55 : 38) : 0,
              right: isRtl ? 0 : (isSender ? 55 : 38),
            ),
            child: Text(
              message.text,
              textAlign: isRtl ? TextAlign.right : TextAlign.left,
              style: platformTheme.messageStyle.copyWith(color: textColor),
              textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
            ),
          ),
          Positioned(
            bottom: -2,
            left: isRtl ? 0 : null,
            right: isRtl ? null : 0,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                if (isRtl && isSender) ...[
                  _StatusTick(
                      status: message.status, platformTheme: platformTheme, forceSentTick: isBlockedMe),
                  const SizedBox(width: 3),
                ],
                Text(
                  message.formattedTime,
                  style: platformTheme.timestampStyle.copyWith(
                    color: platformTheme.chatBg == Colors.black ||
                            platformTheme.chatBg.value == 0xFF0B141A
                        ? const Color(0xFF8696A0)
                        : const Color(0xFF667781),
                    fontSize: 10.5,
                  ),
                ),
                if (!isRtl && isSender) ...[
                  const SizedBox(width: 3),
                  _StatusTick(
                      status: message.status, platformTheme: platformTheme, forceSentTick: isBlockedMe),
                ],
              ],
            ),
          ),
        ],
      );
    }

    if (platform == Platform.messenger || platform == Platform.instagram) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
        child: Text(
          message.text,
          textAlign: isRtl ? TextAlign.right : TextAlign.left,
          style: platformTheme.messageStyle.copyWith(color: textColor),
          textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 6),
      child: Column(
        crossAxisAlignment:
            isRtl ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Text(
            message.text,
            textAlign: isRtl ? TextAlign.right : TextAlign.left,
            style: platformTheme.messageStyle.copyWith(color: textColor),
            textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
          ),
          const SizedBox(height: 2),
          Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment:
                isRtl ? MainAxisAlignment.start : MainAxisAlignment.end,
            children: [
              Text(
                message.formattedTime,
                style: platformTheme.timestampStyle.copyWith(
                  color: isSender
                      ? (platformTheme.senderText == Colors.white
                          ? Colors.white.withOpacity(0.7)
                          : platformTheme.timestampColor)
                      : platformTheme.timestampColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Image Content ────────────────────────────────────────────────────────────

class _ImageContent extends StatelessWidget {
  final ChatMessage message;
  final bool isSender;
  final Platform platform;
  final PlatformTheme platformTheme;
  final bool isBlockedMe;

  const _ImageContent({
    required this.message,
    required this.isSender,
    required this.platform,
    required this.platformTheme,
    this.isBlockedMe = false,
  });

  @override
  Widget build(BuildContext context) {
    final double innerRadius = platform == Platform.whatsapp ? 6.0 : platformTheme.bubbleRadius;

    return ClipRRect(
      borderRadius: BorderRadius.circular(innerRadius),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (message.imageBytes != null)
            SizedBox(
              width: 220,
              height: 160,
              child: Image.memory(
                message.imageBytes!,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  width: 220,
                  height: 160,
                  color: Colors.grey[300],
                  child: const Icon(Icons.broken_image, size: 40, color: Colors.grey),
                ),
              ),
            )
          else
            Container(
              width: 220,
              height: 160,
              color: Colors.grey[300],
              child: const Icon(Icons.image, size: 40, color: Colors.grey),
            ),
          if (message.text.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 6, 10, 4),
              child: Text(
                message.text,
                style: platformTheme.messageStyle.copyWith(
                  color: isSender ? platformTheme.senderText : platformTheme.receiverText,
                ),
              ),
            ),
          if (platform != Platform.messenger && platform != Platform.instagram)
            Padding(
              padding: EdgeInsets.fromLTRB(10, message.text.isNotEmpty ? 0 : 6, 10, 6),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    message.formattedTime,
                    style: platformTheme.timestampStyle,
                  ),
                  if (platform == Platform.whatsapp && isSender) ...[
                    const SizedBox(width: 4),
                    _StatusTick(status: message.status, platformTheme: platformTheme, forceSentTick: isBlockedMe),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }
}

// ─── Audio Content ────────────────────────────────────────────────────────────

// ─── Custom Progress Ring Painter ────────────────────────────────────────────

class ProgressRingPainter extends CustomPainter {
  final double progress; // 0.0 to 1.0
  final Color color;

  ProgressRingPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withOpacity(0.15)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - 3) / 2;

    // Draw background track
    canvas.drawCircle(center, radius, paint);

    // Draw active arc
    if (progress > 0) {
      paint.color = color;
      paint.strokeCap = StrokeCap.round;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -3.14159265 / 2, // start from top center
        progress * 2 * 3.14159265, // sweep angle
        false,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant ProgressRingPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.color != color;
  }
}

// ─── Interactive Audio Player Widget ─────────────────────────────────────────

class _AudioPlayerWidget extends StatefulWidget {
  final ChatMessage message;
  final bool isSender;
  final Platform platform;
  final PlatformTheme platformTheme;
  final bool isBlockedMe;

  const _AudioPlayerWidget({
    required this.message,
    required this.isSender,
    required this.platform,
    required this.platformTheme,
    required this.isBlockedMe,
  });

  @override
  State<_AudioPlayerWidget> createState() => _AudioPlayerWidgetState();
}

class _AudioPlayerWidgetState extends State<_AudioPlayerWidget> {
  bool _isPlaying = false;
  double _playbackSpeed = 1.0;
  Duration _currentPosition = Duration.zero;
  Duration _totalDuration = Duration.zero;

  // Real audio player
  AudioPlayer? _audioPlayer;
  StreamSubscription? _posSub;
  StreamSubscription? _durSub;
  StreamSubscription? _stateSub;

  String? _resolvedAudioPath;
  bool _isInitializing = false;

  // Timer for fallback/simulation
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _totalDuration = widget.message.audioDuration ?? const Duration(seconds: 30);
    _resolveSource();
  }

  Future<void> _resolveSource() async {
    if (widget.message.audioBytes != null) {
      if (mounted) {
        setState(() {
          _isInitializing = true;
        });
      }
      final path = await AudioHelper.prepareAudioSource(widget.message.audioBytes!);
      if (mounted) {
        setState(() {
          _resolvedAudioPath = path;
          _isInitializing = false;
        });
        _initAudioPlayer();
      }
    }
  }

  void _initAudioPlayer() {
    _audioPlayer = AudioPlayer();
    _posSub = _audioPlayer!.onPositionChanged.listen((p) {
      if (mounted) {
        setState(() {
          _currentPosition = p;
        });
      }
    });
    _durSub = _audioPlayer!.onDurationChanged.listen((d) {
      if (mounted) {
        setState(() {
          _totalDuration = d;
        });
      }
    });
    _stateSub = _audioPlayer!.onPlayerStateChanged.listen((state) {
      if (mounted) {
        setState(() {
          _isPlaying = state == PlayerState.playing;
        });
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _posSub?.cancel();
    _durSub?.cancel();
    _stateSub?.cancel();
    _audioPlayer?.dispose();
    super.dispose();
  }

  Future<void> _togglePlay() async {
    if (widget.message.audioBytes != null) {
      if (_isInitializing) return;
      if (_resolvedAudioPath == null) {
        await _resolveSource();
      }
      if (_resolvedAudioPath == null) return;

      if (_audioPlayer == null) {
        _initAudioPlayer();
      }
      if (_isPlaying) {
        await _audioPlayer!.pause();
      } else {
        await _audioPlayer!.setPlaybackRate(_playbackSpeed);
        if (kIsWeb) {
          await _audioPlayer!.play(UrlSource(_resolvedAudioPath!));
        } else {
          await _audioPlayer!.play(DeviceFileSource(_resolvedAudioPath!));
        }
      }
    } else {
      // Simulation
      if (_isPlaying) {
        _timer?.cancel();
        setState(() {
          _isPlaying = false;
        });
      } else {
        if (_currentPosition >= _totalDuration) {
          _currentPosition = Duration.zero;
        }
        setState(() {
          _isPlaying = true;
        });
        _timer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
          if (!mounted) return;
          setState(() {
            final step = (100 * _playbackSpeed).toInt();
            _currentPosition += Duration(milliseconds: step);
            if (_currentPosition >= _totalDuration) {
              _currentPosition = _totalDuration;
              _isPlaying = false;
              _timer?.cancel();
            }
          });
        });
      }
    }
  }

  Future<void> _toggleSpeed() async {
    double newSpeed;
    if (_playbackSpeed == 1.0) {
      newSpeed = 1.5;
    } else if (_playbackSpeed == 1.5) {
      newSpeed = 2.0;
    } else {
      newSpeed = 1.0;
    }

    setState(() {
      _playbackSpeed = newSpeed;
    });

    if (widget.message.audioBytes != null && _audioPlayer != null) {
      await _audioPlayer!.setPlaybackRate(newSpeed);
    }
  }

  Future<void> _onSeek(double milliseconds) async {
    final newPos = Duration(milliseconds: milliseconds.toInt());
    if (widget.message.audioBytes != null && _audioPlayer != null) {
      await _audioPlayer!.seek(newPos);
    } else {
      setState(() {
        _currentPosition = newPos;
      });
    }
  }

  String _formatDuration(Duration d) {
    final m = d.inMinutes.toString();
    final s = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final total = _totalDuration;
    final double progressPct = total.inMilliseconds > 0 
        ? _currentPosition.inMilliseconds / total.inMilliseconds 
        : 0.0;

    final textColor = widget.isSender ? widget.platformTheme.senderText : widget.platformTheme.receiverText;
    final isWhatsApp = widget.platform == Platform.whatsapp;

    if (isWhatsApp) {
      // WhatsApp Voice Note Layout
      if (widget.message.isVoiceNote) {
        final bool isRead = widget.message.status == MessageStatus.read;
        final Color playBtnColor = isRead ? const Color(0xFF34B7F1) : (widget.isSender ? textColor.withOpacity(0.8) : const Color(0xFF54656F));
        final Color micIconColor = isRead ? const Color(0xFF34B7F1) : const Color(0xFF00A884);

        return Container(
          width: 250,
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
          child: Row(
            children: [
              // Play/Pause button
              GestureDetector(
                onTap: _togglePlay,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Icon(
                    _isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                    color: playBtnColor,
                    size: 34,
                  ),
                ),
              ),
              // Waveform & Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Simulated waveform (22 vertical lines)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: List.generate(22, (i) {
                        final h = 4.0 + (i % 4) * 4.0 + ((i * 2) % 6);
                        final isPlayed = (i / 22.0) <= progressPct;
                        final Color barColor = isPlayed
                            ? (isRead ? const Color(0xFF34B7F1) : const Color(0xFF00A884))
                            : textColor.withOpacity(0.25);
                        return Container(
                          width: 2.2,
                          height: h,
                          decoration: BoxDecoration(
                            color: barColor,
                            borderRadius: BorderRadius.circular(1),
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: 6),
                    // Duration, Timestamp & Speed Toggle
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _formatDuration(total - _currentPosition),
                          style: TextStyle(color: textColor.withOpacity(0.55), fontSize: 10.5),
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(widget.message.formattedTime, style: widget.platformTheme.timestampStyle),
                            if (widget.isSender) ...[
                              const SizedBox(width: 4),
                              _StatusTick(
                                status: widget.message.status,
                                platformTheme: widget.platformTheme,
                                forceSentTick: widget.isBlockedMe,
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Avatar + Speed Pill
              Stack(
                alignment: Alignment.center,
                clipBehavior: Clip.none,
                children: [
                  // Circular Speaker Avatar
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: textColor.withOpacity(0.12),
                    ),
                    child: ClipOval(
                      child: widget.isSender
                          ? (widget.platformTheme.showReceiverAvatar // Outgoing
                              ? const Icon(Icons.person_rounded, color: Colors.grey)
                              : const Icon(Icons.person_rounded, color: Colors.grey))
                          : (const Icon(Icons.person_rounded, color: Colors.grey)),
                    ),
                  ),
                  // Mic icon badge
                  Positioned(
                    bottom: -2,
                    left: -2,
                    child: Container(
                      padding: const EdgeInsets.all(2.5),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: Container(
                        padding: const EdgeInsets.all(1),
                        decoration: BoxDecoration(
                          color: micIconColor.withOpacity(0.15),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.mic_rounded,
                          color: micIconColor,
                          size: 11,
                        ),
                      ),
                    ),
                  ),
                  // Playback Speed Pill
                  Positioned(
                    top: -14,
                    right: -4,
                    child: GestureDetector(
                      onTap: _toggleSpeed,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '${_playbackSpeed.toStringAsFixed(1).replaceAll('.0', '')}x',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            color: textColor.withOpacity(0.7),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      } else {
        // WhatsApp Audio File Layout (Screenshot 2 style)
        final Color sliderColor = widget.isSender ? const Color(0xFF00A884) : const Color(0xFF007FF5);

        return Container(
          width: 250,
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Play/Pause button
              GestureDetector(
                onTap: _togglePlay,
                child: Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Icon(
                    _isPlaying ? Icons.pause_circle_filled_rounded : Icons.play_circle_filled_rounded,
                    color: widget.isSender ? const Color(0xFF00A884) : const Color(0xFF54656F),
                    size: 38,
                  ),
                ),
              ),
              const SizedBox(width: 4),
              // Slider & File Metadata
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Dynamic Seekbar/Slider
                    SizedBox(
                      height: 18,
                      child: SliderTheme(
                        data: SliderTheme.of(context).copyWith(
                          trackHeight: 2.5,
                          thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                          overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
                          activeTrackColor: sliderColor,
                          inactiveTrackColor: textColor.withOpacity(0.18),
                          thumbColor: sliderColor,
                        ),
                        child: Slider(
                          value: progressPct,
                          onChanged: (val) {
                            _onSeek(total.inMilliseconds * val);
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 2),
                    // File Name & Duration
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Text(
                        widget.message.fileName ?? 'AUD-20260614-WA0001.mp3',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: textColor,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    // Size/Duration & Timestamp Row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${widget.message.fileSize ?? '1.2 MB'} • ${_formatDuration(_currentPosition)}',
                          style: TextStyle(color: textColor.withOpacity(0.55), fontSize: 10),
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(widget.message.formattedTime, style: widget.platformTheme.timestampStyle),
                            if (widget.isSender) ...[
                              const SizedBox(width: 4),
                              _StatusTick(
                                status: widget.message.status,
                                platformTheme: widget.platformTheme,
                                forceSentTick: widget.isBlockedMe,
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              // Large Orange File Badge
              Container(
                width: 36,
                height: 36,
                margin: const EdgeInsets.only(top: 4),
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0xFFF27B13),
                ),
                child: const Center(
                  child: Icon(
                    Icons.audiotrack_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
            ],
          ),
        );
      }
    }

    // Generic fallbacks for Messenger / Instagram / Snapchat
    final primaryColor = widget.isSender ? widget.platformTheme.sendButtonColor : const Color(0xFF8E8E93);

    return Container(
      width: 230,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      child: Row(
        children: [
          GestureDetector(
            onTap: _togglePlay,
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: textColor.withOpacity(0.15),
              ),
              child: Icon(
                _isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                color: textColor,
                size: 24,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (!widget.message.isVoiceNote) ...[
                  Text(
                    widget.message.fileName ?? 'Audio file',
                    style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 12),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                ],
                // Seekbar Progress
                Container(
                  height: 3,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: textColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(2),
                  ),
                  child: FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: progressPct,
                    child: Container(
                      color: primaryColor,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${_formatDuration(_currentPosition)} / ${_formatDuration(total)}',
                      style: TextStyle(color: textColor.withOpacity(0.6), fontSize: 10.5),
                    ),
                    if (widget.platform != Platform.messenger && widget.platform != Platform.instagram)
                      Text(widget.message.formattedTime, style: widget.platformTheme.timestampStyle),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Stateful Video Player Widget ────────────────────────────────────────────

class _VideoPlayerWidget extends StatefulWidget {
  final ChatMessage message;
  final bool isSender;
  final Platform platform;
  final PlatformTheme platformTheme;
  final bool isBlockedMe;

  const _VideoPlayerWidget({
    required this.message,
    required this.isSender,
    required this.platform,
    required this.platformTheme,
    required this.isBlockedMe,
  });

  @override
  State<_VideoPlayerWidget> createState() => _VideoPlayerWidgetState();
}

class _VideoPlayerWidgetState extends State<_VideoPlayerWidget> {
  VideoPlayerController? _controller;
  bool _isInitialized = false;
  bool _isPlaying = false;
  Duration _currentPosition = Duration.zero;
  Duration _totalDuration = Duration.zero;
  String? _resolvedVideoPath;
  bool _isInitializing = false;

  // Timer for fallback/simulation when videoBytes is null
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _totalDuration = widget.message.audioDuration ?? const Duration(seconds: 15);
    _resolveSource();
  }

  Future<void> _resolveSource() async {
    if (widget.message.videoBytes != null) {
      if (mounted) {
        setState(() {
          _isInitializing = true;
        });
      }
      final path = await VideoHelper.prepareVideoSource(widget.message.videoBytes!);
      if (mounted && path != null) {
        setState(() {
          _resolvedVideoPath = path;
        });
        await _initVideoPlayer();
      }
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

        // Listen to position changes
        controller.addListener(() {
          if (mounted) {
            setState(() {
              _currentPosition = controller.value.position;
              _isPlaying = controller.value.isPlaying;
            });
          }
        });
      }
    } catch (e) {
      debugPrint('Error initializing video player: $e');
      if (mounted) {
        setState(() {
          _isInitializing = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _togglePlay() async {
    if (widget.message.videoBytes != null) {
      if (_isInitializing) return;
      if (_controller == null || !_isInitialized) {
        await _resolveSource();
      }
      if (_controller == null || !_isInitialized) return;

      if (_isPlaying) {
        await _controller!.pause();
      } else {
        await _controller!.play();
      }
    } else {
      // Simulation
      if (_isPlaying) {
        _timer?.cancel();
        setState(() {
          _isPlaying = false;
        });
      } else {
        final total = _totalDuration;
        if (_currentPosition >= total) {
          _currentPosition = Duration.zero;
        }
        setState(() {
          _isPlaying = true;
        });
        _timer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
          if (!mounted) return;
          setState(() {
            _currentPosition += const Duration(milliseconds: 100);
            if (_currentPosition >= total) {
              _currentPosition = total;
              _isPlaying = false;
              _timer?.cancel();
            }
          });
        });
      }
    }
  }

  String _formatDuration(Duration d) {
    final m = d.inMinutes.toString();
    final s = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final total = _totalDuration;
    final double progressPct = total.inMilliseconds > 0 
        ? _currentPosition.inMilliseconds / total.inMilliseconds 
        : 0.0;

    final isWhatsApp = widget.platform == Platform.whatsapp;

    if (widget.message.isVideoMessage) {
      // Circular Video Note layout (Screenshot 1 & 2)
      final Color activeRingColor = isWhatsApp 
          ? const Color(0xFF25D366) // Green progress circle for WhatsApp
          : (widget.platformTheme.sendButtonColor);

      // Render circular preview
      Widget circleBody = GestureDetector(
        onTap: _togglePlay,
        child: Container(
          width: 200,
          height: 200,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: Color(0xFF2A2A2A),
          ),
          child: CustomPaint(
            painter: ProgressRingPainter(progress: progressPct, color: activeRingColor),
            child: Padding(
              padding: const EdgeInsets.all(5),
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
                                  width: 32,
                                  height: 32,
                                  child: CircularProgressIndicator(
                                    color: Colors.white24,
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.videocam_rounded, color: Colors.white24, size: 48),
                        ),
                      ),

                    // Play button overlay when paused and not initializing
                    if (!_isPlaying && !_isInitializing)
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.4),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.play_arrow_rounded,
                          color: Colors.white,
                          size: 32,
                        ),
                      ),

                    // Bottom duration text badge
                    Positioned(
                      bottom: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2.5),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.6),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          _formatDuration(total - _currentPosition),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
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
      );

      // Wrapper Row containing forward share icon & timestamp pill underneath
      return Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        child: Column(
          crossAxisAlignment: widget.isSender ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                if (!widget.isSender) ...[
                  circleBody,
                  const SizedBox(width: 8),
                  // Translucent share arrow for incoming
                  _buildShareArrow(),
                ] else ...[
                  // Translucent share arrow for outgoing
                  _buildShareArrow(),
                  const SizedBox(width: 8),
                  circleBody,
                ],
              ],
            ),
            const SizedBox(height: 6),
            // Tiny green/translucent bubble for the time & checkmarks (under the circle)
            Padding(
              padding: EdgeInsets.only(
                right: widget.isSender ? 16 : 0,
                left: widget.isSender ? 0 : 16,
              ),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isWhatsApp 
                      ? (widget.isSender ? const Color(0xFF202C33) : const Color(0xFF202C33)) 
                      : Colors.black54,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      widget.message.formattedTime,
                      style: const TextStyle(color: Colors.white70, fontSize: 10),
                    ),
                    if (widget.isSender) ...[
                      const SizedBox(width: 4),
                      _StatusTick(
                        status: widget.message.status,
                        platformTheme: widget.platformTheme,
                        forceSentTick: widget.isBlockedMe,
                        colorOverride: const Color(0xFF34B7F1), // blue ticks
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    } else {
      // Standard Video message layout (Rectangular attachment)
      return Container(
        width: 240,
        height: 160,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: const Color(0xFF1E1E1E),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Frame image or video player
            if (_isInitialized && _controller != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: SizedBox.expand(
                  child: FittedBox(
                    fit: BoxFit.cover,
                    clipBehavior: Clip.hardEdge,
                    child: SizedBox(
                      width: _controller!.value.size.width,
                      height: _controller!.value.size.height,
                      child: VideoPlayer(_controller!),
                    ),
                  ),
                ),
              )
            else if (widget.message.imageBytes != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.memory(
                  widget.message.imageBytes!,
                  width: double.infinity,
                  height: double.infinity,
                  fit: BoxFit.cover,
                ),
              )
            else
              Center(
                child: _isInitializing 
                    ? const SizedBox(
                        width: 32,
                        height: 32,
                        child: CircularProgressIndicator(
                          color: Colors.white24,
                          strokeWidth: 2,
                        ),
                      )
                    : const Icon(Icons.videocam_rounded, color: Colors.white24, size: 48),
              ),

            // Play overlay button
            GestureDetector(
              onTap: _togglePlay,
              child: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.5),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                  color: Colors.white,
                  size: 32,
                ),
              ),
            ),

            // Duration badge in bottom corner
            Positioned(
              bottom: 8,
              left: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  _formatDuration(total - _currentPosition),
                  style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ),
            ),

            // Timestamp and ticks badge in bottom corner
            Positioned(
              bottom: 8,
              right: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      widget.message.formattedTime,
                      style: const TextStyle(color: Colors.white, fontSize: 10),
                    ),
                    if (widget.isSender) ...[
                      const SizedBox(width: 4),
                      _StatusTick(
                        status: widget.message.status,
                        platformTheme: widget.platformTheme,
                        forceSentTick: widget.isBlockedMe,
                      ),
                    ],
                  ],
                ),
              ),
            ),

            // Linear Progress Ticker overlay at the very bottom
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(12)),
                child: LinearProgressIndicator(
                  value: progressPct,
                  minHeight: 3,
                  backgroundColor: Colors.transparent,
                  valueColor: AlwaysStoppedAnimation<Color>(widget.platformTheme.sendButtonColor),
                ),
              ),
            ),
          ],
        ),
      );
    }
  }

  Widget _buildShareArrow() {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.06),
        shape: BoxShape.circle,
      ),
      child: const Center(
        child: Icon(
          Icons.reply_rounded, // matches the share arrow look
          color: Colors.white70,
          size: 18,
        ),
      ),
    );
  }
}

// ─── Call Content (Standard Bubble Style) ──────────────────────────────────────

class _CallContent extends StatelessWidget {
  final ChatMessage message;
  final bool isSender;
  final Platform platform;
  final PlatformTheme platformTheme;
  final bool isBlockedMe;

  const _CallContent({
    required this.message,
    required this.isSender,
    required this.platform,
    required this.platformTheme,
    this.isBlockedMe = false,
  });

  String _formatCallDuration(Duration? d, bool isArabic) {
    if (d == null || d == Duration.zero) return '';
    if (d.inMinutes > 0) {
      final mins = d.inMinutes;
      final secs = d.inSeconds % 60;
      if (secs > 0) {
        if (isArabic) {
          return '$mins د $secs ث';
        }
        return '$mins min $secs sec';
      }
      if (isArabic) {
        return '$mins د';
      }
      return '$mins min';
    }
    if (isArabic) {
      return '${d.inSeconds} ث';
    }
    return '${d.inSeconds} sec';
  }

  @override
  Widget build(BuildContext context) {
    final bool isArabic = Provider.of<ThemeProvider>(context).isArabic;
    final isVideo = message.type == MessageType.videoCall;
    final isMissed = message.text.toLowerCase().contains('missed') ||
        message.text.toLowerCase().contains('declined') ||
        message.text.toLowerCase().contains('no answer');

    // Typography colors
    final textColor = isSender ? platformTheme.senderText : platformTheme.receiverText;

    // Circle background color inside the bubble
    final circleColor = isSender
        ? (platformTheme.senderText == Colors.white ? Colors.white.withOpacity(0.12) : const Color(0xFFE9EDEF))
        : const Color(0xFFE9EDEF);

    final iconColor = isMissed
        ? Colors.redAccent
        : (isSender && platformTheme.senderText == Colors.white ? Colors.white : const Color(0xFF54656F));

    // Dynamic title and details
    String callTitle = '';
    if (isArabic) {
      callTitle = isVideo ? 'مكالمة فيديو' : 'مكالمة صوتية';
    } else {
      callTitle = isVideo ? 'Video Call' : 'Voice Call';
    }

    String callSubtitle = '';

    if (message.text == 'Answered' || message.text.isEmpty) {
      final dur = _formatCallDuration(message.audioDuration, isArabic);
      if (isArabic) {
        callSubtitle = dur.isNotEmpty ? 'تم الرد عليها • $dur' : 'تم الرد عليها';
      } else {
        callSubtitle = dur.isNotEmpty ? 'Answered • $dur' : 'Answered';
      }
    } else {
      final textLower = message.text.toLowerCase();
      if (isArabic) {
        if (textLower == 'missed') {
          callSubtitle = 'فائتة';
        } else if (textLower == 'declined') {
          callSubtitle = 'مرفوضة';
        } else if (textLower == 'no answer') {
          callSubtitle = 'لم يتم الرد';
        } else {
          callSubtitle = message.text;
        }
      } else {
        callSubtitle = message.text; // "Missed", "Declined", "No Answer"
      }
    }

    if (platform == Platform.whatsapp) {
      return Stack(
        children: [
          Padding(
            padding: EdgeInsets.only(bottom: 12, right: isArabic ? 0 : 40, left: isArabic ? 40 : 0),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: circleColor,
                  ),
                  child: Icon(
                    isMissed
                        ? (isVideo ? Icons.missed_video_call : Icons.phone_missed)
                        : (isVideo ? Icons.videocam_rounded : Icons.phone_rounded),
                    color: iconColor,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      callTitle,
                      style: TextStyle(
                        color: textColor,
                        fontSize: 14.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      callSubtitle,
                      style: TextStyle(
                        color: isMissed ? Colors.redAccent[100] : const Color(0xFF667781),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Positioned(
            bottom: -2,
            left: isArabic ? 0 : null,
            right: isArabic ? null : 0,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                if (isArabic && isSender) ...[
                  _StatusTick(status: message.status, platformTheme: platformTheme, forceSentTick: isBlockedMe),
                  const SizedBox(width: 3),
                ],
                Text(
                  message.formattedTime,
                  style: platformTheme.timestampStyle.copyWith(
                    color: const Color(0xFF667781),
                    fontSize: 10.5,
                  ),
                ),
                if (!isArabic && isSender) ...[
                  const SizedBox(width: 3),
                  _StatusTick(status: message.status, platformTheme: platformTheme, forceSentTick: isBlockedMe),
                ],
              ],
            ),
          ),
        ],
      );
    }

    // Generic standard bubble styling for Messenger/Instagram/Snapchat calls
    final subTextColor = isSender
        ? (platformTheme.senderText == Colors.white ? Colors.white.withOpacity(0.7) : platformTheme.timestampColor)
        : platformTheme.timestampColor;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          isVideo ? Icons.videocam : Icons.phone,
          color: isMissed ? Colors.redAccent : textColor.withOpacity(0.8),
          size: 18,
        ),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              callTitle,
              style: TextStyle(
                color: textColor,
                fontSize: 13.5,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 1),
            Text(
              callSubtitle,
              style: TextStyle(
                color: isMissed ? Colors.redAccent[100] : subTextColor,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ─── Avatar Widget ────────────────────────────────────────────────────────────

class _AvatarWidget extends StatelessWidget {
  final ChatUser user;
  final Platform platform;

  const _AvatarWidget({required this.user, required this.platform});

  Color _platformColor() {
    switch (platform) {
      case Platform.whatsapp:
        return const Color(0xFF25D366);
      case Platform.messenger:
        return const Color(0xFF0084FF);
      case Platform.instagram:
        return const Color(0xFFE1306C);
      case Platform.snapchat:
        return const Color(0xFFFFFC00);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (user.avatarBytes != null) {
      return CircleAvatar(
        radius: 14,
        backgroundImage: MemoryImage(user.avatarBytes!),
      );
    }
    return CircleAvatar(
      radius: 14,
      backgroundColor: _platformColor().withOpacity(0.18),
      child: Text(
        user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
        style: TextStyle(
          color: _platformColor(),
          fontWeight: FontWeight.w800,
          fontSize: 12,
        ),
      ),
    );
  }
}

// ─── Messenger-Style Status Ticks ──────────────────────────────────────────────

class _MessengerStatusIndicator extends StatelessWidget {
  final MessageStatus status;
  final ChatUser contactUser;
  final PlatformTheme theme;

  const _MessengerStatusIndicator({
    required this.status,
    required this.contactUser,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    switch (status) {
      case MessageStatus.sending:
        return Container(
          width: 14,
          height: 14,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: const Color(0xFFCCD0D5), width: 1.2),
          ),
        );
      case MessageStatus.sent:
        return Container(
          width: 14,
          height: 14,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: const Color(0xFFCCD0D5), width: 1.2),
          ),
          child: const Center(
            child: Icon(Icons.check_rounded, size: 9, color: Color(0xFFCCD0D5)),
          ),
        );
      case MessageStatus.delivered:
        return Container(
          width: 14,
          height: 14,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: Color(0xFFCCD0D5),
          ),
          child: const Center(
            child: Icon(Icons.check_rounded, size: 9, color: Colors.white),
          ),
        );
      case MessageStatus.read:
        if (contactUser.avatarBytes != null) {
          return Container(
            width: 14,
            height: 14,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              image: DecorationImage(
                image: MemoryImage(contactUser.avatarBytes!),
                fit: BoxFit.cover,
              ),
            ),
          );
        }
        return Container(
          width: 14,
          height: 14,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: theme.sendButtonColor.withOpacity(0.2),
          ),
          child: Center(
            child: Text(
              contactUser.name.isNotEmpty ? contactUser.name[0].toUpperCase() : '?',
              style: TextStyle(
                fontSize: 7.5,
                fontWeight: FontWeight.bold,
                color: theme.sendButtonColor,
              ),
            ),
          ),
        );
    }
  }
}

// ─── Status Tick ──────────────────────────────────────────────────────────────

class _StatusTick extends StatelessWidget {
  final MessageStatus status;
  final PlatformTheme platformTheme;
  final bool forceSentTick;
  final Color? colorOverride;

  const _StatusTick({
    required this.status,
    required this.platformTheme,
    this.forceSentTick = false,
    this.colorOverride,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveStatus = forceSentTick ? MessageStatus.sent : status;
    final tickColor = colorOverride ?? platformTheme.tickColor;
    final readTickColor = colorOverride ?? platformTheme.readTickColor;

    switch (effectiveStatus) {
      case MessageStatus.sending:
        return Icon(Icons.access_time_rounded, size: 12, color: tickColor);
      case MessageStatus.sent:
        return Icon(Icons.check_rounded, size: 12, color: tickColor);
      case MessageStatus.delivered:
        return _DoubleTick(color: tickColor);
      case MessageStatus.read:
        return _DoubleTick(color: readTickColor);
    }
  }
}

class _DoubleTick extends StatelessWidget {
  final Color color;
  const _DoubleTick({required this.color});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 15,
      height: 12,
      child: Stack(
        children: [
          Positioned(
            left: 0,
            bottom: 0,
            child: Icon(Icons.check_rounded, size: 12, color: color),
          ),
          Positioned(
            left: 3.5,
            bottom: 0,
            child: Icon(Icons.check_rounded, size: 12, color: color),
          ),
        ],
      ),
    );
  }
}

class _ReplyPreviewHeader extends StatelessWidget {
  final String repliedToText;
  final String repliedToSenderName;
  final bool isSender;
  final Platform platform;
  final PlatformTheme platformTheme;
  final bool bubbleIsRtl;

  const _ReplyPreviewHeader({
    required this.repliedToText,
    required this.repliedToSenderName,
    required this.isSender,
    required this.platform,
    required this.platformTheme,
    required this.bubbleIsRtl,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = platformTheme.chatBg == Colors.black ||
        platformTheme.chatBg.value == 0xFF0B141A ||
        platformTheme.chatBg.value == 0xFF000000 ||
        platformTheme.chatBg.value == 0xFF0B0C0E;

    final bool isArabicLocale = Provider.of<ThemeProvider>(context).isArabic;
    String displayName = repliedToSenderName;
    if (isArabicLocale) {
      if (displayName == 'You') {
        displayName = 'أنت';
      } else if (displayName == 'Contact') {
        displayName = 'الطرف الآخر';
      }
    } else {
      if (displayName == 'أنت') {
        displayName = 'You';
      } else if (displayName == 'الطرف الآخر') {
        displayName = 'Contact';
      }
    }

    // Detect RTL from the quoted content itself
    final bool isTextRtl =
        _isArabic(repliedToText) || _isArabic(displayName);

    // ── Per-platform colours ──────────────────────────────────────────────────
    Color barColor;
    Color bgColor;
    Color textColor;

    switch (platform) {
      case Platform.whatsapp:
        final bool isQuotedMe =
            repliedToSenderName == 'You' || repliedToSenderName == 'أنت';
        barColor =
            isQuotedMe ? const Color(0xFF00A884) : const Color(0xFF53BDEB);
        bgColor = isDark
            ? Colors.black.withOpacity(0.25)
            : Colors.black.withOpacity(0.08);
        textColor = isDark ? const Color(0xFFB0BEC5) : const Color(0xFF546E7A);
        break;
      case Platform.messenger:
        barColor = isSender ? Colors.white70 : const Color(0xFF0084FF);
        bgColor = isSender
            ? Colors.white.withOpacity(0.18)
            : (isDark
                ? Colors.white.withOpacity(0.10)
                : Colors.black.withOpacity(0.06));
        textColor = isSender
            ? Colors.white.withOpacity(0.8)
            : (isDark ? Colors.white70 : Colors.black54);
        break;
      case Platform.instagram:
        barColor = isSender ? Colors.white60 : const Color(0xFFE1306C);
        bgColor = isSender
            ? Colors.white.withOpacity(0.18)
            : (isDark
                ? Colors.white.withOpacity(0.10)
                : Colors.black.withOpacity(0.06));
        textColor = isSender
            ? Colors.white.withOpacity(0.8)
            : (isDark ? Colors.white70 : Colors.black54);
        break;
      case Platform.snapchat:
        barColor = isSender ? const Color(0xFF00BFFF) : const Color(0xFFFF0000);
        bgColor = isDark
            ? Colors.white.withOpacity(0.07)
            : Colors.black.withOpacity(0.05);
        textColor = isDark ? Colors.white70 : Colors.black87;
        break;
    }

    // ── Margins & radius ──────────────────────────────────────────────────────
    // Real WhatsApp: the quote block has ~6px margin on all sides INSIDE the
    // bubble's own padding. All corners rounded (6px). It's NOT edge-to-edge.
    const double qRadius = 6.0;
    const double qMarginH = 0.0; // bubble already has its own side padding
    const double qMarginTop = 0.0;
    const double qMarginBottom = 4.0; // small gap before message text

    // In Arabic/RTL, the accent bar moves to the RIGHT side
    final bool barOnRight = isTextRtl;

    return Directionality(
      // Force layout direction based on bubble content, not app locale
      textDirection: isTextRtl ? TextDirection.rtl : TextDirection.ltr,
      child: Container(
        margin: const EdgeInsets.only(
          top: qMarginTop,
          left: qMarginH,
          right: qMarginH,
          bottom: qMarginBottom,
        ),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(qRadius),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(qRadius),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Left accent bar (LTR)
                if (!barOnRight) Container(width: 4, color: barColor),

                // Quoted text
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(8, 5, 8, 5),
                    child: Column(
                      crossAxisAlignment: isTextRtl
                          ? CrossAxisAlignment.end
                          : CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Quoted sender name
                        Text(
                          displayName,
                          textAlign:
                              isTextRtl ? TextAlign.right : TextAlign.left,
                          style: TextStyle(
                            color:
                                barColor, // name always uses bar accent color
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                            height: 1.2,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 1),
                        // Quoted message text (1 line like real WhatsApp)
                        Text(
                          repliedToText,
                          textAlign:
                              isTextRtl ? TextAlign.right : TextAlign.left,
                          style: TextStyle(
                            color: textColor,
                            fontSize: 12,
                            height: 1.3,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ),

                // Right accent bar (RTL)
                if (barOnRight) Container(width: 4, color: barColor),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ForwardedHeader extends StatelessWidget {
  final bool isSender;
  final PlatformTheme platformTheme;

  const _ForwardedHeader({
    required this.isSender,
    required this.platformTheme,
  });

  @override
  Widget build(BuildContext context) {
    final isArabic = Provider.of<ThemeProvider>(context).isArabic;
    final textColor = isSender ? platformTheme.senderText : platformTheme.receiverText;
    final greyColor = textColor.withOpacity(0.45);

    return Padding(
      padding: const EdgeInsets.only(bottom: 4, left: 4, right: 4, top: 2),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Transform.flip(
            flipX: !isArabic, // point right if LTR, point left if RTL
            child: Icon(
              Icons.reply_rounded,
              size: 13,
              color: greyColor,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            isArabic ? 'مُحوّلة' : 'Forwarded',
            style: TextStyle(
              color: greyColor,
              fontSize: 11,
              fontStyle: FontStyle.italic,
              fontWeight: FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}
