import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/chat_models.dart';

const _uuid = Uuid();

class ChatProvider extends ChangeNotifier {
  final List<ChatSession> _sessions = [];
  ChatSession? _activeSession;
  bool _isSenderMode = true; // true = composing as "me" (right side)
  bool _viewChatList = false;

  // Simulated playback states for screen recording presentation mode
  bool _isPlayingConversation = false;
  List<ChatMessage>? _simulatedMessages;
  String? _simulatedTypingText;
  String? _simulatedContactStatus;
  bool _showSimulatedTypingIndicator = false;
  bool _shouldStopPlayback = false;

  List<ChatSession> get sessions => List.unmodifiable(_sessions);
  ChatSession? get activeSession => _activeSession;
  bool get isSenderMode => _isSenderMode;
  bool get viewChatList => _viewChatList;

  bool get isPlayingConversation => _isPlayingConversation;
  List<ChatMessage> get activeMessages => _simulatedMessages ?? _activeSession?.messages ?? [];
  String? get simulatedTypingText => _simulatedTypingText;
  String? get simulatedContactStatus => _simulatedContactStatus;
  bool get showSimulatedTypingIndicator => _showSimulatedTypingIndicator;

  ChatProvider() {
    _loadFromDatabase();
  }

  // ─── Database Operations ───────────────────────────────────────────────────

  void _loadFromDatabase() {
    try {
      final sessionsBox = Hive.box('sessions_box');
      final settingsBox = Hive.box('settings_box');

      _sessions.clear();
      for (final key in sessionsBox.keys) {
        final val = sessionsBox.get(key);
        if (val is Map) {
          try {
            _sessions.add(ChatSession.fromMap(val));
          } catch (e) {
            debugPrint('Error loading session $key: $e');
          }
        }
      }

      _isSenderMode = settingsBox.get('isSenderMode', defaultValue: true) as bool;
      _viewChatList = settingsBox.get('viewChatList', defaultValue: false) as bool;
      
      final activeId = settingsBox.get('activeSessionId') as String?;
      if (activeId != null && _sessions.any((s) => s.id == activeId)) {
        _activeSession = _sessions.firstWhere((s) => s.id == activeId);
      } else if (_sessions.isNotEmpty) {
        _activeSession = _sessions.first;
      }
    } catch (e) {
      debugPrint('Error initializing Hive in ChatProvider: $e');
    }
  }

  void _saveSession(ChatSession session) {
    try {
      final sessionsBox = Hive.box('sessions_box');
      sessionsBox.put(session.id, session.toMap());
    } catch (e) {
      debugPrint('Error saving session ${session.id}: $e');
    }
  }

  void _deleteSessionFromDb(String sessionId) {
    try {
      final sessionsBox = Hive.box('sessions_box');
      sessionsBox.delete(sessionId);
    } catch (e) {
      debugPrint('Error deleting session $sessionId: $e');
    }
  }

  void _saveSettings() {
    try {
      final settingsBox = Hive.box('settings_box');
      settingsBox.put('isSenderMode', _isSenderMode);
      settingsBox.put('viewChatList', _viewChatList);
      settingsBox.put('activeSessionId', _activeSession?.id);
    } catch (e) {
      debugPrint('Error saving settings: $e');
    }
  }

  // ─── Session Management ────────────────────────────────────────────────────

  void setViewChatList(bool value) {
    _viewChatList = value;
    _saveSettings();
    notifyListeners();
  }

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
    _saveSession(session);
    _saveSettings();
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
    _saveSession(session);
    _saveSettings();
    notifyListeners();
  }

  void setActiveSession(ChatSession session) {
    _activeSession = session;
    _viewChatList = false;
    _saveSettings();
    notifyListeners();
  }

  void deleteSession(String sessionId) {
    _sessions.removeWhere((s) => s.id == sessionId);
    _deleteSessionFromDb(sessionId);
    if (_activeSession?.id == sessionId) {
      _activeSession = _sessions.isNotEmpty ? _sessions.last : null;
    }
    _saveSettings();
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
    _saveSession(_activeSession!);
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
    _saveSession(_activeSession!);
    notifyListeners();
  }

  void addAudioMessage({
    required Duration duration,
    required bool isSender,
    required DateTime timestamp,
    MessageStatus status = MessageStatus.read,
    bool isVoiceNote = false,
    String? fileName,
    String? fileSize,
    Uint8List? audioBytes,
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
      isVoiceNote: isVoiceNote,
      fileName: fileName,
      fileSize: fileSize,
      audioBytes: audioBytes,
    );
    _activeSession!.messages.add(msg);
    _saveSession(_activeSession!);
    notifyListeners();
  }

  void addVideoMessage({
    required Uint8List? videoBytes,
    required bool isVideoMessage,
    required Duration duration,
    required bool isSender,
    required DateTime timestamp,
    MessageStatus status = MessageStatus.read,
    String? fileName,
    String? fileSize,
  }) {
    if (_activeSession == null) return;
    final msg = ChatMessage(
      id: _uuid.v4(),
      text: '',
      type: MessageType.video,
      isSender: isSender,
      timestamp: timestamp,
      status: status,
      audioDuration: duration,
      isVideoMessage: isVideoMessage,
      fileName: fileName,
      fileSize: fileSize,
      videoBytes: videoBytes,
    );
    _activeSession!.messages.add(msg);
    _saveSession(_activeSession!);
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
    _saveSession(_activeSession!);
    notifyListeners();
  }

  void addMessage(ChatMessage message) {
    if (_activeSession == null) return;
    _activeSession!.messages.add(message);
    _saveSession(_activeSession!);
    notifyListeners();
  }

  void updateMessage(String messageId, ChatMessage updated) {
    if (_activeSession == null) return;
    final idx = _activeSession!.messages.indexWhere((m) => m.id == messageId);
    if (idx >= 0) {
      _activeSession!.messages[idx] = updated;
      _saveSession(_activeSession!);
      notifyListeners();
    }
  }

  void deleteMessage(String messageId) {
    if (_activeSession == null) return;
    _activeSession!.messages.removeWhere((m) => m.id == messageId);
    _saveSession(_activeSession!);
    notifyListeners();
  }

  void reorderMessages(int oldIdx, int newIdx) {
    if (_activeSession == null) return;
    if (newIdx > oldIdx) newIdx -= 1;
    final item = _activeSession!.messages.removeAt(oldIdx);
    _activeSession!.messages.insert(newIdx, item);
    _saveSession(_activeSession!);
    notifyListeners();
  }

  // ─── Contact / Session Settings ───────────────────────────────────────────

  void updateContact(ChatUser updated) {
    if (_activeSession == null) return;
    _activeSession = _activeSession!.copyWith(contactUser: updated);
    final idx = _sessions.indexWhere((s) => s.id == _activeSession!.id);
    if (idx >= 0) {
      _sessions[idx] = _activeSession!;
      _saveSession(_activeSession!);
    }
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
    bool? isDisappearing,
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
      isDisappearing: isDisappearing,
      clearCustomLastMessage: clearCustomLastMessage,
      clearCustomLastMessageTime: clearCustomLastMessageTime,
      clearLastMessageIsSender: clearLastMessageIsSender,
    );
    final idx = _sessions.indexWhere((s) => s.id == _activeSession!.id);
    if (idx >= 0) {
      _sessions[idx] = _activeSession!;
      _saveSession(_activeSession!);
    }
    notifyListeners();
  }

  // ─── Sender Toggle ─────────────────────────────────────────────────────────

  void toggleSenderMode() {
    _isSenderMode = !_isSenderMode;
    _saveSettings();
    notifyListeners();
  }

  void setSenderMode(bool value) {
    _isSenderMode = value;
    _saveSettings();
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

  // ─── Automated Playback Simulator ──────────────────────────────────────────

  Future<void> startConversationPlayback(VoidCallback onDone) async {
    if (_activeSession == null || _isPlayingConversation) return;
    _isPlayingConversation = true;
    _shouldStopPlayback = false;
    _simulatedMessages = [];
    _simulatedTypingText = null;
    _simulatedContactStatus = null;
    _showSimulatedTypingIndicator = false;
    notifyListeners();

    // Copy original messages
    final originalMessages = List<ChatMessage>.from(_activeSession!.messages);

    for (final msg in originalMessages) {
      if (_shouldStopPlayback) break;

      // Skip date dividers during animated typing simulation
      if (msg.type == MessageType.dateDivider) {
        _simulatedMessages!.add(msg);
        notifyListeners();
        continue;
      }

      // Typing speed based on message length
      final typingDelayMs = msg.text.isNotEmpty 
          ? (msg.text.length * 50).clamp(800, 2500)
          : 1200;

      if (!msg.isSender) {
        // RECEIVER: Shows typing indicator and adds message
        _simulatedContactStatus = 'typing...';
        _showSimulatedTypingIndicator = true;
        notifyListeners();

        await Future.delayed(Duration(milliseconds: typingDelayMs));
        if (_shouldStopPlayback) break;

        _simulatedContactStatus = 'online';
        _showSimulatedTypingIndicator = false;
        _simulatedMessages!.add(msg);
        notifyListeners();

      } else {
        // SENDER: Animates character typing, then displays bubble with status ticks
        final fullText = msg.text.isNotEmpty ? msg.text : 'Attachment';
        _simulatedTypingText = '';
        notifyListeners();

        for (int i = 0; i < fullText.length; i++) {
          if (_shouldStopPlayback) break;
          await Future.delayed(const Duration(milliseconds: 50));
          _simulatedTypingText = fullText.substring(0, i + 1);
          notifyListeners();
        }

        if (_shouldStopPlayback) break;
        await Future.delayed(const Duration(milliseconds: 200));

        _simulatedTypingText = null;
        final sendingMsg = msg.copyWith(status: MessageStatus.sending);
        _simulatedMessages!.add(sendingMsg);
        notifyListeners();

        // Tick Progression
        await Future.delayed(const Duration(milliseconds: 400));
        if (_shouldStopPlayback) break;
        _updateSimulatedMessageStatus(msg.id, MessageStatus.sent);

        await Future.delayed(const Duration(milliseconds: 500));
        if (_shouldStopPlayback) break;
        _updateSimulatedMessageStatus(msg.id, MessageStatus.delivered);

        await Future.delayed(const Duration(milliseconds: 500));
        if (_shouldStopPlayback) break;
        _updateSimulatedMessageStatus(msg.id, MessageStatus.read);
      }

      // Read interval
      await Future.delayed(const Duration(milliseconds: 1200));
    }

    _isPlayingConversation = false;
    _simulatedMessages = null;
    _simulatedTypingText = null;
    _simulatedContactStatus = null;
    _showSimulatedTypingIndicator = false;
    notifyListeners();
    onDone();
  }

  void _updateSimulatedMessageStatus(String id, MessageStatus status) {
    final list = _simulatedMessages;
    if (list == null) return;
    final idx = list.indexWhere((m) => m.id == id);
    if (idx >= 0) {
      list[idx] = list[idx].copyWith(status: status);
      notifyListeners();
    }
  }

  void stopConversationPlayback() {
    _shouldStopPlayback = true;
    _isPlayingConversation = false;
    _simulatedMessages = null;
    _simulatedTypingText = null;
    _simulatedContactStatus = null;
    _showSimulatedTypingIndicator = false;
    notifyListeners();
  }
}
