import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/chat_models.dart';
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
        bubbleContent = _AudioContent(
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

    final finalContent = hasReply
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

class _AudioContent extends StatelessWidget {
  final ChatMessage message;
  final bool isSender;
  final Platform platform;
  final PlatformTheme platformTheme;
  final bool isBlockedMe;

  const _AudioContent({
    required this.message,
    required this.isSender,
    required this.platform,
    required this.platformTheme,
    this.isBlockedMe = false,
  });

  String _formatDuration(Duration? d) {
    if (d == null) return '0:00';
    final m = d.inMinutes.toString().padLeft(1, '0');
    final s = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final textColor = isSender ? platformTheme.senderText : platformTheme.receiverText;

    return Container(
      width: 230,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: textColor.withOpacity(0.15),
            ),
            child: Icon(Icons.play_arrow_rounded, color: textColor, size: 24),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: List.generate(20, (i) {
                    final h = 4.0 + (i % 5) * 4.0;
                    return Container(
                      width: 2.8,
                      height: h,
                      margin: const EdgeInsets.only(right: 2),
                      decoration: BoxDecoration(
                        color: textColor.withOpacity(0.5 + (i % 3) * 0.25),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _formatDuration(message.audioDuration),
                      style: TextStyle(color: textColor.withOpacity(0.7), fontSize: 11),
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (platform != Platform.messenger && platform != Platform.instagram)
                          Text(message.formattedTime, style: platformTheme.timestampStyle),
                        if (platform == Platform.whatsapp && isSender) ...[
                          const SizedBox(width: 4),
                          _StatusTick(status: message.status, platformTheme: platformTheme, forceSentTick: isBlockedMe),
                        ],
                      ],
                    ),
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

  const _StatusTick({
    required this.status,
    required this.platformTheme,
    this.forceSentTick = false,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveStatus = forceSentTick ? MessageStatus.sent : status;
    switch (effectiveStatus) {
      case MessageStatus.sending:
        return Icon(Icons.access_time_rounded, size: 12, color: platformTheme.tickColor);
      case MessageStatus.sent:
        return Icon(Icons.check_rounded, size: 12, color: platformTheme.tickColor);
      case MessageStatus.delivered:
        return _DoubleTick(color: platformTheme.tickColor);
      case MessageStatus.read:
        return _DoubleTick(color: platformTheme.readTickColor);
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
