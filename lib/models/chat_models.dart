import 'dart:typed_data';
import 'package:flutter/material.dart';

enum Platform { whatsapp, messenger, instagram, snapchat }

enum MessageType { text, image, audio, voiceCall, videoCall, dateDivider }

enum MessageStatus { sending, sent, delivered, read }

enum UserOnlineStatus { online, offline, typing, lastSeen }

class ChatUser {
  final String id;
  String name;
  Uint8List? avatarBytes; // image bytes (works on web + mobile)
  UserOnlineStatus onlineStatus;
  DateTime? lastSeen;
  bool isTyping;

  ChatUser({
    required this.id,
    required this.name,
    this.avatarBytes,
    this.onlineStatus = UserOnlineStatus.online,
    this.lastSeen,
    this.isTyping = false,
  });

  ChatUser copyWith({
    String? name,
    Uint8List? avatarBytes,
    UserOnlineStatus? onlineStatus,
    DateTime? lastSeen,
    bool? isTyping,
    bool clearAvatar = false,
  }) {
    return ChatUser(
      id: id,
      name: name ?? this.name,
      avatarBytes: clearAvatar ? null : (avatarBytes ?? this.avatarBytes),
      onlineStatus: onlineStatus ?? this.onlineStatus,
      lastSeen: lastSeen ?? this.lastSeen,
      isTyping: isTyping ?? this.isTyping,
    );
  }

  String get statusText {
    switch (onlineStatus) {
      case UserOnlineStatus.online:
        return 'online';
      case UserOnlineStatus.typing:
        return 'typing...';
      case UserOnlineStatus.offline:
        if (lastSeen != null) {
          return 'last seen ${_formatLastSeen(lastSeen!)}';
        }
        return 'offline';
      case UserOnlineStatus.lastSeen:
        if (lastSeen != null) {
          return 'last seen ${_formatLastSeen(lastSeen!)}';
        }
        return 'last seen recently';
    }
  }

  String _formatLastSeen(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes} minutes ago';
    if (diff.inHours < 24) return 'today at ${_time(dt)}';
    if (diff.inDays == 1) return 'yesterday at ${_time(dt)}';
    return '${dt.day}/${dt.month}/${dt.year}';
  }

  String _time(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }
}

class ChatMessage {
  final String id;
  String text;
  MessageType type;
  bool isSender; // true = right side (me), false = left side (other)
  DateTime timestamp;
  MessageStatus status;
  String? imagePath;   // kept for reference but unused on web
  Uint8List? imageBytes; // actual image data (cross-platform)
  Duration? audioDuration;
  String? reaction; // The hovered emoji reaction (e.g. "❤️", "👍")
  String? repliedToId;
  String? repliedToText;
  String? repliedToSenderName;

  ChatMessage({
    required this.id,
    required this.text,
    this.type = MessageType.text,
    required this.isSender,
    required this.timestamp,
    this.status = MessageStatus.read,
    this.imagePath,
    this.imageBytes,
    this.audioDuration,
    this.reaction,
    this.repliedToId,
    this.repliedToText,
    this.repliedToSenderName,
  });

  ChatMessage copyWith({
    String? text,
    MessageType? type,
    bool? isSender,
    DateTime? timestamp,
    MessageStatus? status,
    String? imagePath,
    Uint8List? imageBytes,
    Duration? audioDuration,
    String? reaction,
    bool clearReaction = false,
    String? repliedToId,
    String? repliedToText,
    String? repliedToSenderName,
    bool clearRepliedTo = false,
  }) {
    return ChatMessage(
      id: id,
      text: text ?? this.text,
      type: type ?? this.type,
      isSender: isSender ?? this.isSender,
      timestamp: timestamp ?? this.timestamp,
      status: status ?? this.status,
      imagePath: imagePath ?? this.imagePath,
      imageBytes: imageBytes ?? this.imageBytes,
      audioDuration: audioDuration ?? this.audioDuration,
      reaction: clearReaction ? null : (reaction ?? this.reaction),
      repliedToId: clearRepliedTo ? null : (repliedToId ?? this.repliedToId),
      repliedToText: clearRepliedTo ? null : (repliedToText ?? this.repliedToText),
      repliedToSenderName: clearRepliedTo ? null : (repliedToSenderName ?? this.repliedToSenderName),
    );
  }

  String get formattedTime {
    final h = timestamp.hour.toString().padLeft(2, '0');
    final m = timestamp.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }
}

class ChatSession {
  final String id;
  Platform platform;
  ChatUser contactUser;
  List<ChatMessage> messages;
  String fakeTime; // displayed in the status bar mock
  int fakeBattery; // 0-100
  bool fakeWifi;
  String fakeName; // The "my" profile name
  Uint8List? fakeAvatarBytes;
  bool isDarkMode; // Mock Dark Mode inside phone frames
  String? contactBio; // large banner details (e.g. 1.2M followers)
  String? contactSubBio; // large banner details 2 (e.g. You follow each other)
  int unreadCount;
  String? customLastMessage;
  String? customLastMessageTime;
  bool? lastMessageIsSender;
  bool isGroup;
  String groupMembers;
  bool isBlocked;
  bool isBlockedMe;

  ChatSession({
    required this.id,
    required this.platform,
    required this.contactUser,
    List<ChatMessage>? messages,
    this.fakeTime = '9:41',
    this.fakeBattery = 87,
    this.fakeWifi = true,
    this.fakeName = 'You',
    this.fakeAvatarBytes,
    this.isDarkMode = false,
    this.contactBio,
    this.contactSubBio,
    this.unreadCount = 0,
    this.customLastMessage,
    this.customLastMessageTime,
    this.lastMessageIsSender,
    this.isGroup = false,
    this.groupMembers = '',
    this.isBlocked = false,
    this.isBlockedMe = false,
  }) : messages = messages ?? [];

  ChatSession copyWith({
    Platform? platform,
    ChatUser? contactUser,
    List<ChatMessage>? messages,
    String? fakeTime,
    int? fakeBattery,
    bool? fakeWifi,
    String? fakeName,
    Uint8List? fakeAvatarBytes,
    bool? isDarkMode,
    String? contactBio,
    String? contactSubBio,
    int? unreadCount,
    String? customLastMessage,
    String? customLastMessageTime,
    bool? lastMessageIsSender,
    bool? isGroup,
    String? groupMembers,
    bool? isBlocked,
    bool? isBlockedMe,
    bool clearCustomLastMessage = false,
    bool clearCustomLastMessageTime = false,
    bool clearLastMessageIsSender = false,
  }) {
    return ChatSession(
      id: id,
      platform: platform ?? this.platform,
      contactUser: contactUser ?? this.contactUser,
      messages: messages ?? this.messages,
      fakeTime: fakeTime ?? this.fakeTime,
      fakeBattery: fakeBattery ?? this.fakeBattery,
      fakeWifi: fakeWifi ?? this.fakeWifi,
      fakeName: fakeName ?? this.fakeName,
      fakeAvatarBytes: fakeAvatarBytes ?? this.fakeAvatarBytes,
      isDarkMode: isDarkMode ?? this.isDarkMode,
      contactBio: contactBio ?? this.contactBio,
      contactSubBio: contactSubBio ?? this.contactSubBio,
      unreadCount: unreadCount ?? this.unreadCount,
      customLastMessage: clearCustomLastMessage ? null : (customLastMessage ?? this.customLastMessage),
      customLastMessageTime: clearCustomLastMessageTime ? null : (customLastMessageTime ?? this.customLastMessageTime),
      lastMessageIsSender: clearLastMessageIsSender ? null : (lastMessageIsSender ?? this.lastMessageIsSender),
      isGroup: isGroup ?? this.isGroup,
      groupMembers: groupMembers ?? this.groupMembers,
      isBlocked: isBlocked ?? this.isBlocked,
      isBlockedMe: isBlockedMe ?? this.isBlockedMe,
    );
  }

  String get platformName {
    switch (platform) {
      case Platform.whatsapp:
        return 'WhatsApp';
      case Platform.messenger:
        return 'Messenger';
      case Platform.instagram:
        return 'Instagram';
      case Platform.snapchat:
        return 'Snapchat';
    }
  }

  Color get platformColor {
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
}
