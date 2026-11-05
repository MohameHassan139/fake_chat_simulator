import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../utils/language_helper.dart';
import '../utils/media_store.dart';

enum Platform { whatsapp, messenger, instagram, snapchat }

enum MessageType { text, image, audio, voiceCall, videoCall, dateDivider, video, sticker }

enum MessageStatus { sending, sent, delivered, read }

enum UserOnlineStatus { online, offline, typing, lastSeen }

/// Real-app capability rules for the "Deleted" and "View Once" (one-time)
/// message features. Kept in one place so the editor UI and the bubble
/// renderer can never drift apart on what each platform actually supports.
class MessageFeatureRules {
  MessageFeatureRules._();

  /// Media types that can be marked "View Once" per platform.
  /// - WhatsApp: photo, video, voice notes (added Dec 2023).
  /// - Instagram: photo, video only (camera-captured DM media); voice notes
  ///   always persist and replay freely.
  /// - Messenger: photo, video only; voice notes are never one-time.
  /// - Snapchat: photo, video, and audio notes are all ephemeral-by-default
  ///   chat content.
  /// Plain text, stickers, calls, and date dividers are never eligible
  /// anywhere - view once is strictly a media feature in every real app.
  static const Map<Platform, Set<MessageType>> _oneTimeEligibleTypes = {
    Platform.whatsapp: {MessageType.image, MessageType.video, MessageType.audio},
    Platform.instagram: {MessageType.image, MessageType.video},
    Platform.messenger: {MessageType.image, MessageType.video},
    Platform.snapchat: {MessageType.image, MessageType.video, MessageType.audio},
  };

  static bool canBeOneTime(Platform platform, MessageType type) {
    return _oneTimeEligibleTypes[platform]?.contains(type) ?? false;
  }

  /// Whether the one-time toggle should even be offered for this type,
  /// regardless of platform (calls/dividers/stickers/text are never
  /// "view once" content in any real chat app).
  static bool isOneTimeCapableType(MessageType type) {
    return type == MessageType.image || type == MessageType.video || type == MessageType.audio;
  }

  /// Whether the "Deleted / Unsent" toggle should be offered for this type.
  /// Every real message type can be deleted/unsent except the synthetic
  /// date-divider row, which isn't an actual message.
  static bool canBeDeleted(MessageType type) {
    return type != MessageType.dateDivider;
  }
}

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
      'avatarBytes': MediaStore.ref(avatarBytes),
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

  String statusText(bool isArabic) {
    switch (onlineStatus) {
      case UserOnlineStatus.online:
        return LanguageHelper.pick(isArabic, 'متصل الآن', 'online');
      case UserOnlineStatus.typing:
        return LanguageHelper.pick(isArabic, 'يكتب الآن...', 'typing...');
      case UserOnlineStatus.offline:
        if (lastSeen != null) {
          return '${LanguageHelper.pick(isArabic, 'آخر ظهور', 'last seen')} ${_formatLastSeen(lastSeen!, isArabic)}';
        }
        return LanguageHelper.pick(isArabic, 'غير متصل', 'offline');
      case UserOnlineStatus.lastSeen:
        if (lastSeen != null) {
          return '${LanguageHelper.pick(isArabic, 'آخر ظهور', 'last seen')} ${_formatLastSeen(lastSeen!, isArabic)}';
        }
        return LanguageHelper.pick(isArabic, 'آخر ظهور كان قريبًا', 'last seen recently');
    }
  }

  String _formatLastSeen(DateTime dt, bool isArabic) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1) {
      return LanguageHelper.pick(isArabic, 'الآن', 'just now');
    }
    if (diff.inMinutes < 60) {
      if (isArabic) {
        if (diff.inMinutes == 1) return 'منذ دقيقة';
        if (diff.inMinutes == 2) return 'منذ دقيقتين';
        if (diff.inMinutes >= 3 && diff.inMinutes <= 10) return 'منذ ${diff.inMinutes} دقائق';
        return 'منذ ${diff.inMinutes} دقيقة';
      }
      return '${diff.inMinutes} minutes ago';
    }
    if (diff.inHours < 24) {
      return LanguageHelper.pick(isArabic, 'اليوم في ${_time(dt)}', 'today at ${_time(dt)}');
    }
    if (diff.inDays == 1) {
      return LanguageHelper.pick(isArabic, 'أمس في ${_time(dt)}', 'yesterday at ${_time(dt)}');
    }
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
  bool isVoiceNote;
  bool isVideoMessage;
  String? fileName;
  String? fileSize;
  Uint8List? videoBytes;
  Uint8List? audioBytes;
  bool isForwarded;
  bool isEdited; // shows the platform's "Edited" label
  bool isDeleted;
  bool isOneTime;
  bool isOneTimeOpened;

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
    this.isVoiceNote = false,
    this.isVideoMessage = false,
    this.fileName,
    this.fileSize,
    this.videoBytes,
    this.audioBytes,
    this.isForwarded = false,
    this.isEdited = false,
    this.isDeleted = false,
    this.isOneTime = false,
    this.isOneTimeOpened = false,
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
    bool? isVoiceNote,
    bool? isVideoMessage,
    String? fileName,
    String? fileSize,
    Uint8List? videoBytes,
    bool clearVideoBytes = false,
    Uint8List? audioBytes,
    bool clearAudioBytes = false,
    bool? isForwarded,
    bool? isEdited,
    bool? isDeleted,
    bool? isOneTime,
    bool? isOneTimeOpened,
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
      isVoiceNote: isVoiceNote ?? this.isVoiceNote,
      isVideoMessage: isVideoMessage ?? this.isVideoMessage,
      fileName: fileName ?? this.fileName,
      fileSize: fileSize ?? this.fileSize,
      videoBytes: clearVideoBytes ? null : (videoBytes ?? this.videoBytes),
      audioBytes: clearAudioBytes ? null : (audioBytes ?? this.audioBytes),
      isForwarded: isForwarded ?? this.isForwarded,
      isEdited: isEdited ?? this.isEdited,
      isDeleted: isDeleted ?? this.isDeleted,
      isOneTime: isOneTime ?? this.isOneTime,
      isOneTimeOpened: isOneTimeOpened ?? this.isOneTimeOpened,
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
      'imageBytes': MediaStore.ref(imageBytes),
      'audioDuration': audioDuration?.inMilliseconds,
      'reaction': reaction,
      'repliedToId': repliedToId,
      'repliedToText': repliedToText,
      'repliedToSenderName': repliedToSenderName,
      'isVoiceNote': isVoiceNote,
      'isVideoMessage': isVideoMessage,
      'fileName': fileName,
      'fileSize': fileSize,
      'videoBytes': MediaStore.ref(videoBytes),
      'audioBytes': MediaStore.ref(audioBytes),
      'isForwarded': isForwarded,
      'isEdited': isEdited,
      'isDeleted': isDeleted,
      'isOneTime': isOneTime,
      'isOneTimeOpened': isOneTimeOpened,
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
      isVoiceNote: map['isVoiceNote'] as bool? ?? false,
      isVideoMessage: map['isVideoMessage'] as bool? ?? false,
      fileName: map['fileName'] as String?,
      fileSize: map['fileSize'] as String?,
      videoBytes: _parseBytes(map['videoBytes']),
      audioBytes: _parseBytes(map['audioBytes']),
      isForwarded: map['isForwarded'] as bool? ?? false,
      isEdited: map['isEdited'] as bool? ?? false,
      isDeleted: map['isDeleted'] as bool? ?? false,
      isOneTime: map['isOneTime'] as bool? ?? false,
      isOneTimeOpened: map['isOneTimeOpened'] as bool? ?? false,
    );
  }

  String get formattedTime {
    final h = timestamp.hour.toString().padLeft(2, '0');
    final m = timestamp.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }
}

/// Platform-accurate copy for "Deleted" / "View Once" messages, shared by
/// the chat bubble renderer and any inbox/last-message preview so the
/// wording can never drift between the two surfaces.
extension ChatMessagePreviewText on ChatMessage {
  String deletedPreviewText(Platform platform, String contactName, bool isArabic) {
    switch (platform) {
      case Platform.whatsapp:
        return isSender
            ? LanguageHelper.translate('deleted_msg_wa_sender', isArabic)
            : LanguageHelper.translate('deleted_msg_wa_receiver', isArabic);
      case Platform.messenger:
        return isSender
            ? LanguageHelper.translate('deleted_msg_messenger_sender', isArabic)
            : '$contactName ${LanguageHelper.translate('deleted_msg_messenger_receiver_verb', isArabic)}';
      case Platform.instagram:
        return isSender
            ? LanguageHelper.translate('deleted_msg_instagram_sender', isArabic)
            : '$contactName ${LanguageHelper.translate('deleted_msg_instagram_receiver_verb', isArabic)}';
      case Platform.snapchat:
        return isSender
            ? LanguageHelper.translate('deleted_msg_snapchat_sender', isArabic)
            : LanguageHelper.translate('deleted_msg_snapchat_receiver', isArabic);
    }
  }

  /// Label for the still-media-type portion of a one-time message (e.g.
  /// "Photo" / "New Snap"). Does not account for the "Opened" state -
  /// callers that need that should check `isOneTimeOpened` themselves.
  String oneTimeMediaLabel(Platform platform, bool isArabic) {
    final isVideo = type == MessageType.video;
    final isAudio = type == MessageType.audio;
    switch (platform) {
      case Platform.whatsapp:
        if (isAudio) return LanguageHelper.translate('one_time_voice', isArabic);
        return LanguageHelper.translate(isVideo ? 'one_time_video' : 'one_time_photo', isArabic);
      case Platform.instagram:
        return LanguageHelper.translate(isVideo ? 'one_time_video' : 'one_time_photo', isArabic);
      case Platform.messenger:
        return LanguageHelper.translate(isVideo ? 'one_time_messenger_video' : 'one_time_messenger_photo', isArabic);
      case Platform.snapchat:
        if (isAudio) return LanguageHelper.translate('one_time_new_audio_note', isArabic);
        return LanguageHelper.translate(isVideo ? 'one_time_new_video_snap' : 'one_time_new_snap', isArabic);
    }
  }

  /// Full one-time preview text, accounting for the opened/unopened state -
  /// what an inbox/last-message row should show.
  String oneTimePreviewText(Platform platform, bool isArabic) {
    if (isOneTimeOpened) return LanguageHelper.translate('one_time_opened_text', isArabic);
    return oneTimeMediaLabel(platform, isArabic);
  }

  /// Short preview string suitable for an inbox/chat-list last-message row,
  /// accounting for deleted/one-time state before falling back to raw text.
  String previewText(Platform platform, String contactName, bool isArabic) {
    if (isDeleted) return deletedPreviewText(platform, contactName, isArabic);
    if (isOneTime) return oneTimePreviewText(platform, isArabic);
    return text;
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
      'fakeAvatarBytes': MediaStore.ref(fakeAvatarBytes),
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

Uint8List? _parseBytes(dynamic val) => MediaStore.load(val);
