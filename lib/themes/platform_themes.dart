import 'package:flutter/material.dart';
import '../models/chat_models.dart';

class PlatformTheme {
  final Color statusBarBg;
  final Color appBarBg;
  final Color appBarText;
  final Color appBarIcon;
  final Color chatBg;
  final Color senderBubble;
  final Color senderText;
  final Color receiverBubble;
  final Color receiverText;
  final Color inputBarBg;
  final Color inputFieldBg;
  final Color sendButtonColor;
  final Color timestampColor;
  final Color tickColor;
  final Color readTickColor;
  final double bubbleRadius;
  final double senderBubbleRadiusTR;
  final bool showReceiverAvatar;
  final bool gradientSenderBubble;
  final List<Color>? senderGradient;
  final TextStyle timestampStyle;
  final TextStyle messageStyle;

  const PlatformTheme({
    required this.statusBarBg,
    required this.appBarBg,
    required this.appBarText,
    required this.appBarIcon,
    required this.chatBg,
    required this.senderBubble,
    required this.senderText,
    required this.receiverBubble,
    required this.receiverText,
    required this.inputBarBg,
    required this.inputFieldBg,
    required this.sendButtonColor,
    required this.timestampColor,
    required this.tickColor,
    required this.readTickColor,
    this.bubbleRadius = 18,
    this.senderBubbleRadiusTR = 4,
    this.showReceiverAvatar = false,
    this.gradientSenderBubble = false,
    this.senderGradient,
    required this.timestampStyle,
    required this.messageStyle,
  });

  static PlatformTheme of(Platform platform, {bool isDark = false}) {
    if (isDark) {
      switch (platform) {
        case Platform.whatsapp:
          return whatsappDark;
        case Platform.messenger:
          return messengerDark;
        case Platform.instagram:
          return instagramDark;
        case Platform.snapchat:
          return snapchatDark;
      }
    }
    switch (platform) {
      case Platform.whatsapp:
        return whatsapp;
      case Platform.messenger:
        return messenger;
      case Platform.instagram:
        return instagram;
      case Platform.snapchat:
        return snapchat;
    }
  }

  // ─── WhatsApp Light ──────────────────────────────────────────────────────────
  static const PlatformTheme whatsapp = PlatformTheme(
    statusBarBg: Color(0xFF008069), // Modern WhatsApp Green
    appBarBg: Color(0xFF008069),    // Modern WhatsApp Green
    appBarText: Colors.white,
    appBarIcon: Colors.white,
    chatBg: Color(0xFFECE5DD),
    senderBubble: Color(0xFFE2F9C3), // Exact modern light-mode green
    senderText: Color(0xFF111111),
    receiverBubble: Color(0xFFFFFFFF),
    receiverText: Color(0xFF111111),
    inputBarBg: Color(0xFFF0F0F0),
    inputFieldBg: Color(0xFFFFFFFF),
    sendButtonColor: Color(0xFF008069),
    timestampColor: Color(0xFF888888),
    tickColor: Color(0xFF8696A0),     // Accurate grey for sent/delivered
    readTickColor: Color(0xFF53BDEB), // Accurate blue for read receipt
    bubbleRadius: 8,
    senderBubbleRadiusTR: 0,
    showReceiverAvatar: false,
    gradientSenderBubble: false,
    timestampStyle: TextStyle(fontSize: 10.5, color: Color(0xFF667781)),
    messageStyle: TextStyle(fontSize: 15.5, color: Color(0xFF111111), height: 1.3),
  );

  // ─── WhatsApp Dark ──────────────────────────────────────────────────────────
  static const PlatformTheme whatsappDark = PlatformTheme(
    statusBarBg: Color(0xFF1F2C34),
    appBarBg: Color(0xFF1F2C34),
    appBarText: Color(0xFFE9EDEF),
    appBarIcon: Color(0xFF8696A0),
    chatBg: Color(0xFF0B141A),
    senderBubble: Color(0xFF005C4B),
    senderText: Color(0xFFE9EDEF),
    receiverBubble: Color(0xFF1F2C34),
    receiverText: Color(0xFFE9EDEF),
    inputBarBg: Color(0xFF1F2C34),
    inputFieldBg: const Color(0xFF1F2C34),
    sendButtonColor: Color(0xFF00A884),
    timestampColor: Color(0xFF8696A0),
    tickColor: Color(0xFF8696A0),
    readTickColor: Color(0xFF53BDEB),
    bubbleRadius: 8,
    senderBubbleRadiusTR: 0,
    showReceiverAvatar: false,
    gradientSenderBubble: false,
    timestampStyle: TextStyle(fontSize: 10.5, color: Color(0xFF8696A0)),
    messageStyle: TextStyle(fontSize: 15.5, color: Color(0xFFE9EDEF), height: 1.3),
  );

  // ─── Messenger Light ─────────────────────────────────────────────────────────
  static const PlatformTheme messenger = PlatformTheme(
    statusBarBg: Color(0xFFFFFFFF),
    appBarBg: Color(0xFFFFFFFF),
    appBarText: Color(0xFF000000),
    appBarIcon: Color(0xFF0084FF),
    chatBg: Color(0xFFFFFFFF),
    senderBubble: Color(0xFF0084FF),
    senderText: Colors.white,
    receiverBubble: Color(0xFFF0F0F0), // Standard light receiver bubble grey
    receiverText: Color(0xFF000000),
    inputBarBg: Color(0xFFFFFFFF),
    inputFieldBg: Color(0xFFF0F0F0),
    sendButtonColor: Color(0xFF0084FF),
    timestampColor: Color(0xFF8E8E93),
    tickColor: Color(0xFF0084FF),
    readTickColor: Color(0xFF0084FF),
    bubbleRadius: 18,
    senderBubbleRadiusTR: 4,
    showReceiverAvatar: true,
    gradientSenderBubble: true,
    senderGradient: [Color(0xFF007AFF), Color(0xFF00C6FF)], // Smooth modern blue-cyan gradient
    timestampStyle: TextStyle(fontSize: 11, color: Color(0xFF8E8E93)),
    messageStyle: TextStyle(fontSize: 15, color: Color(0xFF000000), height: 1.3),
  );

  // ─── Messenger Dark ──────────────────────────────────────────────────────────
  static const PlatformTheme messengerDark = PlatformTheme(
    statusBarBg: Color(0xFF121212),
    appBarBg: Color(0xFF000000),
    appBarText: Colors.white,
    appBarIcon: Color(0xFF0A7CFF),
    chatBg: Color(0xFF000000),
    senderBubble: Color(0xFF0A7CFF),
    senderText: Colors.white,
    receiverBubble: Color(0xFF242526),
    receiverText: Colors.white,
    inputBarBg: Color(0xFF000000),
    inputFieldBg: Color(0xFF242526),
    sendButtonColor: Color(0xFF0A7CFF),
    timestampColor: Color(0xFF8E8E93),
    tickColor: Color(0xFF0A7CFF),
    readTickColor: Color(0xFF0A7CFF),
    bubbleRadius: 18,
    senderBubbleRadiusTR: 4,
    showReceiverAvatar: true,
    gradientSenderBubble: true,
    senderGradient: [Color(0xFF007AFF), Color(0xFF00C6FF)],
    timestampStyle: TextStyle(fontSize: 11, color: Color(0xFF8E8E93)),
    messageStyle: TextStyle(fontSize: 15, color: Colors.white, height: 1.3),
  );

  // ─── Instagram Light ─────────────────────────────────────────────────────────
  static const PlatformTheme instagram = PlatformTheme(
    statusBarBg: Color(0xFFFFFFFF),
    appBarBg: Color(0xFFFFFFFF),
    appBarText: Color(0xFF000000),
    appBarIcon: Color(0xFF000000),
    chatBg: Color(0xFFFFFFFF),
    senderBubble: Color(0xFF3897F0),
    senderText: Colors.white,
    receiverBubble: Color(0xFFEFEFEF),
    receiverText: Color(0xFF000000),
    inputBarBg: Color(0xFFFFFFFF),
    inputFieldBg: Color(0xFFFFFFFF),
    sendButtonColor: Color(0xFF3897F0),
    timestampColor: Color(0xFF999999),
    tickColor: Color(0xFF3897F0),
    readTickColor: Color(0xFF3897F0),
    bubbleRadius: 18,
    senderBubbleRadiusTR: 4,
    showReceiverAvatar: true,
    gradientSenderBubble: true,
    senderGradient: [
      Color(0xFFC32E96), // Authentic Instagram DM violet-pink
      Color(0xFF9035B9), // Violet
      Color(0xFF4A55D6), // Deep blue
    ],
    timestampStyle: TextStyle(fontSize: 11, color: Color(0xFF999999)),
    messageStyle: TextStyle(fontSize: 14.5, color: Color(0xFF000000), height: 1.3),
  );

  // ─── Instagram Dark ──────────────────────────────────────────────────────────
  static const PlatformTheme instagramDark = PlatformTheme(
    statusBarBg: Color(0xFF000000),
    appBarBg: Color(0xFF000000),
    appBarText: Colors.white,
    appBarIcon: Colors.white,
    chatBg: Color(0xFF000000),
    senderBubble: Color(0xFF3897F0),
    senderText: Colors.white,
    receiverBubble: Color(0xFF262626),
    receiverText: Colors.white,
    inputBarBg: Color(0xFF000000),
    inputFieldBg: Color(0xFF000000),
    sendButtonColor: Color(0xFF3897F0),
    timestampColor: Color(0xFF7F7F7F),
    tickColor: Color(0xFF3897F0),
    readTickColor: Color(0xFF3897F0),
    bubbleRadius: 18,
    senderBubbleRadiusTR: 4,
    showReceiverAvatar: true,
    gradientSenderBubble: true,
    senderGradient: [
      Color(0xFFC32E96),
      Color(0xFF9035B9),
      Color(0xFF4A55D6),
    ],
    timestampStyle: TextStyle(fontSize: 11, color: Color(0xFF7F7F7F)),
    messageStyle: TextStyle(fontSize: 14.5, color: Colors.white, height: 1.3),
  );

  // ─── Snapchat Light ──────────────────────────────────────────────────────────
  static const PlatformTheme snapchat = PlatformTheme(
    statusBarBg: Color(0xFFFFFC00),
    appBarBg: Color(0xFFFFFC00),
    appBarText: Color(0xFF000000),
    appBarIcon: Color(0xFF000000),
    chatBg: Color(0xFFFFFFFF),
    senderBubble: Color(0xFF0ADFF5), // Snapchat sender bubble cyan
    senderText: Colors.white,
    receiverBubble: Color(0xFFF5F5F5),
    receiverText: Color(0xFF000000),
    inputBarBg: Color(0xFFFFFFFF),
    inputFieldBg: Color(0xFFF5F5F5),
    sendButtonColor: Color(0xFF0AADFF),
    timestampColor: Color(0xFF999999),
    tickColor: Color(0xFF0AADFF),
    readTickColor: Color(0xFF0AADFF),
    bubbleRadius: 18,
    senderBubbleRadiusTR: 4,
    showReceiverAvatar: false,
    gradientSenderBubble: false,
    timestampStyle: TextStyle(fontSize: 10, color: Color(0xFF999999), fontWeight: FontWeight.w500),
    messageStyle: TextStyle(fontSize: 15, color: Color(0xFF000000), height: 1.3, fontWeight: FontWeight.w400),
  );

  // ─── Snapchat Dark ──────────────────────────────────────────────────────────
  static const PlatformTheme snapchatDark = PlatformTheme(
    statusBarBg: Color(0xFF1B1B1E),
    appBarBg: Color(0xFF1B1B1E),
    appBarText: Colors.white,
    appBarIcon: Colors.white,
    chatBg: Color(0xFF0B0C0E),
    senderBubble: Color(0xFF0AADFF),
    senderText: Colors.white,
    receiverBubble: Color(0xFF1F2024),
    receiverText: Colors.white,
    inputBarBg: Color(0xFF0B0C0E),
    inputFieldBg: Color(0xFF1F2024),
    sendButtonColor: Color(0xFF0AADFF),
    timestampColor: Color(0xFF999999),
    tickColor: Color(0xFF0AADFF),
    readTickColor: Color(0xFF0AADFF),
    bubbleRadius: 18,
    senderBubbleRadiusTR: 4,
    showReceiverAvatar: false,
    gradientSenderBubble: false,
    timestampStyle: TextStyle(fontSize: 10, color: Color(0xFF999999), fontWeight: FontWeight.w500),
    messageStyle: TextStyle(fontSize: 15, color: Colors.white, height: 1.3, fontWeight: FontWeight.w400),
  );
}
