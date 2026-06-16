import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../models/chat_models.dart';

const _uuid = Uuid();

class ChatProvider extends ChangeNotifier {
  final List<ChatSession> _sessions = [];
  ChatSession? _activeSession;
  bool _isSenderMode = true; // true = composing as "me" (right side)
  bool _viewChatList = false;

  List<ChatSession> get sessions => List.unmodifiable(_sessions);
  ChatSession? get activeSession => _activeSession;
  bool get isSenderMode => _isSenderMode;
  bool get viewChatList => _viewChatList;

  void setViewChatList(bool value) {
    _viewChatList = value;
    notifyListeners();
  }

  // ─── Session Management ────────────────────────────────────────────────────

  void createSession(Platform platform) {
    final contact = ChatUser(
      id: _uuid.v4(),
      name: _defaultName(platform),
      onlineStatus: UserOnlineStatus.online,
    );

    final session = ChatSession(
      id: _uuid.v4(),
      platform: platform,
      contactUser: contact,
      messages: _sampleMessages(platform),
    );

    _sessions.add(session);
    _activeSession = session;
    _viewChatList = false;
    notifyListeners();
  }

  void createSessionCustom({
    required Platform platform,
    required String contactName,
    Uint8List? avatarBytes,
    List<ChatMessage>? initialMessages,
  }) {
    final contact = ChatUser(
      id: _uuid.v4(),
      name: contactName,
      avatarBytes: avatarBytes,
      onlineStatus: UserOnlineStatus.online,
    );

    final session = ChatSession(
      id: _uuid.v4(),
      platform: platform,
      contactUser: contact,
      messages: initialMessages ?? [],
    );

    _sessions.add(session);
    _activeSession = session;
    _viewChatList = false;
    notifyListeners();
  }

  void setActiveSession(ChatSession session) {
    _activeSession = session;
    _viewChatList = false;
    notifyListeners();
  }

  void deleteSession(String sessionId) {
    _sessions.removeWhere((s) => s.id == sessionId);
    if (_activeSession?.id == sessionId) {
      _activeSession = _sessions.isNotEmpty ? _sessions.last : null;
    }
    notifyListeners();
  }

  // ─── Message Operations ────────────────────────────────────────────────────

  void addTextMessage({
    required String text,
    required bool isSender,
    required DateTime timestamp,
    MessageStatus status = MessageStatus.read,
  }) {
    if (_activeSession == null) return;
    final msg = ChatMessage(
      id: _uuid.v4(),
      text: text,
      type: MessageType.text,
      isSender: isSender,
      timestamp: timestamp,
      status: status,
    );
    _activeSession!.messages.add(msg);
    notifyListeners();
  }

  void addImageMessage({
    required Uint8List imageBytes,
    String caption = '',
    required bool isSender,
    required DateTime timestamp,
    MessageStatus status = MessageStatus.read,
  }) {
    if (_activeSession == null) return;
    final msg = ChatMessage(
      id: _uuid.v4(),
      text: caption,
      type: MessageType.image,
      isSender: isSender,
      timestamp: timestamp,
      status: status,
      imageBytes: imageBytes,
    );
    _activeSession!.messages.add(msg);
    notifyListeners();
  }

  void addAudioMessage({
    required Duration duration,
    required bool isSender,
    required DateTime timestamp,
    MessageStatus status = MessageStatus.read,
  }) {
    if (_activeSession == null) return;
    final msg = ChatMessage(
      id: _uuid.v4(),
      text: '',
      type: MessageType.audio,
      isSender: isSender,
      timestamp: timestamp,
      status: status,
      audioDuration: duration,
    );
    _activeSession!.messages.add(msg);
    notifyListeners();
  }

  void addCallMessage({
    required bool isVideo,
    required bool isSender,
    required DateTime timestamp,
  }) {
    if (_activeSession == null) return;
    final msg = ChatMessage(
      id: _uuid.v4(),
      text: isVideo ? 'Video call' : 'Voice call',
      type: isVideo ? MessageType.videoCall : MessageType.voiceCall,
      isSender: isSender,
      timestamp: timestamp,
      status: MessageStatus.read,
    );
    _activeSession!.messages.add(msg);
    notifyListeners();
  }

  void addMessage(ChatMessage message) {
    if (_activeSession == null) return;
    _activeSession!.messages.add(message);
    notifyListeners();
  }

  void updateMessage(String messageId, ChatMessage updated) {
    if (_activeSession == null) return;
    final idx = _activeSession!.messages.indexWhere((m) => m.id == messageId);
    if (idx >= 0) {
      _activeSession!.messages[idx] = updated;
      notifyListeners();
    }
  }

  void deleteMessage(String messageId) {
    if (_activeSession == null) return;
    _activeSession!.messages.removeWhere((m) => m.id == messageId);
    notifyListeners();
  }

  void reorderMessages(int oldIdx, int newIdx) {
    if (_activeSession == null) return;
    if (newIdx > oldIdx) newIdx -= 1;
    final item = _activeSession!.messages.removeAt(oldIdx);
    _activeSession!.messages.insert(newIdx, item);
    notifyListeners();
  }

  // ─── Contact / Session Settings ───────────────────────────────────────────

  void updateContact(ChatUser updated) {
    if (_activeSession == null) return;
    _activeSession = _activeSession!.copyWith(contactUser: updated);
    final idx = _sessions.indexWhere((s) => s.id == _activeSession!.id);
    if (idx >= 0) _sessions[idx] = _activeSession!;
    notifyListeners();
  }

  void updateSessionSettings({
    String? fakeTime,
    int? fakeBattery,
    bool? fakeWifi,
    String? fakeName,
    Uint8List? fakeAvatarBytes,
    Platform? platform,
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
    if (_activeSession == null) return;
    _activeSession = _activeSession!.copyWith(
      fakeTime: fakeTime,
      fakeBattery: fakeBattery,
      fakeWifi: fakeWifi,
      fakeName: fakeName,
      fakeAvatarBytes: fakeAvatarBytes,
      platform: platform,
      isDarkMode: isDarkMode,
      contactBio: contactBio,
      contactSubBio: contactSubBio,
      unreadCount: unreadCount,
      customLastMessage: customLastMessage,
      customLastMessageTime: customLastMessageTime,
      lastMessageIsSender: lastMessageIsSender,
      isGroup: isGroup,
      groupMembers: groupMembers,
      isBlocked: isBlocked,
      isBlockedMe: isBlockedMe,
      clearCustomLastMessage: clearCustomLastMessage,
      clearCustomLastMessageTime: clearCustomLastMessageTime,
      clearLastMessageIsSender: clearLastMessageIsSender,
    );
    final idx = _sessions.indexWhere((s) => s.id == _activeSession!.id);
    if (idx >= 0) _sessions[idx] = _activeSession!;
    notifyListeners();
  }

  // ─── Sender Toggle ─────────────────────────────────────────────────────────

  void toggleSenderMode() {
    _isSenderMode = !_isSenderMode;
    notifyListeners();
  }

  void setSenderMode(bool value) {
    _isSenderMode = value;
    notifyListeners();
  }

  // ─── Helpers ───────────────────────────────────────────────────────────────

  String _defaultName(Platform p) {
    switch (p) {
      case Platform.whatsapp:
        return 'Alex';
      case Platform.messenger:
        return 'Jordan';
      case Platform.instagram:
        return 'sam.official';
      case Platform.snapchat:
        return 'snapfriend';
    }
  }

  List<ChatMessage> _sampleMessages(Platform p) {
    return [];
  }
}
