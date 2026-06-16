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

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'avatarBytes': avatarBytes,
      'onlineStatus': onlineStatus.index,
      'lastSeen': lastSeen?.millisecondsSinceEpoch,
      'isTyping': isTyping,
    };
  }

  factory ChatUser.fromMap(Map<dynamic, dynamic> map) {
    return ChatUser(
      id: map['id'] as String,
      name: map['name'] as String,
      avatarBytes: _parseBytes(map['avatarBytes']),
      onlineStatus: UserOnlineStatus.values[map['onlineStatus'] as int? ?? 0],
      lastSeen: map['lastSeen'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['lastSeen'] as int)
          : null,
      isTyping: map['isTyping'] as bool? ?? false,
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

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'text': text,
      'type': type.index,
      'isSender': isSender,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'status': status.index,
      'imagePath': imagePath,
      'imageBytes': imageBytes,
      'audioDuration': audioDuration?.inMilliseconds,
      'reaction': reaction,
      'repliedToId': repliedToId,
      'repliedToText': repliedToText,
      'repliedToSenderName': repliedToSenderName,
    };
  }

  factory ChatMessage.fromMap(Map<dynamic, dynamic> map) {
    return ChatMessage(
      id: map['id'] as String,
      text: map['text'] as String? ?? '',
      type: MessageType.values[map['type'] as int? ?? 0],
      isSender: map['isSender'] as bool? ?? true,
      timestamp: map['timestamp'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['timestamp'] as int)
          : DateTime.now(),
      status: MessageStatus.values[map['status'] as int? ?? 3],
      imagePath: map['imagePath'] as String?,
      imageBytes: _parseBytes(map['imageBytes']),
      audioDuration: map['audioDuration'] != null
          ? Duration(milliseconds: map['audioDuration'] as int)
          : null,
      reaction: map['reaction'] as String?,
      repliedToId: map['repliedToId'] as String?,
      repliedToText: map['repliedToText'] as String?,
      repliedToSenderName: map['repliedToSenderName'] as String?,
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
  bool isDisappearing;

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
    this.isDisappearing = false,
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
    bool? isDisappearing,
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
      isDisappearing: isDisappearing ?? this.isDisappearing,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'platform': platform.index,
      'contactUser': contactUser.toMap(),
      'messages': messages.map((m) => m.toMap()).toList(),
      'fakeTime': fakeTime,
      'fakeBattery': fakeBattery,
      'fakeWifi': fakeWifi,
      'fakeName': fakeName,
      'fakeAvatarBytes': fakeAvatarBytes,
      'isDarkMode': isDarkMode,
      'contactBio': contactBio,
      'contactSubBio': contactSubBio,
      'unreadCount': unreadCount,
      'customLastMessage': customLastMessage,
      'customLastMessageTime': customLastMessageTime,
      'lastMessageIsSender': lastMessageIsSender,
      'isGroup': isGroup,
      'groupMembers': groupMembers,
      'isBlocked': isBlocked,
      'isBlockedMe': isBlockedMe,
      'isDisappearing': isDisappearing,
    };
  }

  factory ChatSession.fromMap(Map<dynamic, dynamic> map) {
    return ChatSession(
      id: map['id'] as String,
      platform: Platform.values[map['platform'] as int? ?? 0],
      contactUser: ChatUser.fromMap(map['contactUser'] as Map),
      messages: (map['messages'] as List? ?? [])
          .map((m) => ChatMessage.fromMap(m as Map))
          .toList(),
      fakeTime: map['fakeTime'] as String? ?? '9:41',
      fakeBattery: map['fakeBattery'] as int? ?? 87,
      fakeWifi: map['fakeWifi'] as bool? ?? true,
      fakeName: map['fakeName'] as String? ?? 'You',
      fakeAvatarBytes: _parseBytes(map['fakeAvatarBytes']),
      isDarkMode: map['isDarkMode'] as bool? ?? false,
      contactBio: map['contactBio'] as String?,
      contactSubBio: map['contactSubBio'] as String?,
      unreadCount: map['unreadCount'] as int? ?? 0,
      customLastMessage: map['customLastMessage'] as String?,
      customLastMessageTime: map['customLastMessageTime'] as String?,
      lastMessageIsSender: map['lastMessageIsSender'] as bool?,
      isGroup: map['isGroup'] as bool? ?? false,
      groupMembers: map['groupMembers'] as String? ?? '',
      isBlocked: map['isBlocked'] as bool? ?? false,
      isBlockedMe: map['isBlockedMe'] as bool? ?? false,
      isDisappearing: map['isDisappearing'] as bool? ?? false,
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

Uint8List? _parseBytes(dynamic val) {
  if (val == null) return null;
  if (val is Uint8List) return val;
  if (val is List) return Uint8List.fromList(List<int>.from(val));
  return null;
}
