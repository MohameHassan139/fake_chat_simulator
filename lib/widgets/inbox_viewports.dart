import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/chat_models.dart';
import '../providers/chat_provider.dart';
import '../providers/theme_provider.dart';
import '../themes/platform_themes.dart';
import '../widgets/fake_status_bar.dart';

class PlatformInboxViewport extends StatelessWidget {
  final ChatSession session;
  final PlatformTheme platformTheme;

  const PlatformInboxViewport({
    super.key,
    required this.session,
    required this.platformTheme,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = session.isDarkMode;

    Color statusBarBg;
    bool isLightStatus;

    switch (session.platform) {
      case Platform.whatsapp:
        statusBarBg = isDark ? const Color(0xFF1F2C34) : const Color(0xFF008069);
        isLightStatus = true;
        break;
      case Platform.messenger:
      case Platform.instagram:
      case Platform.snapchat:
        statusBarBg = isDark ? Colors.black : Colors.white;
        isLightStatus = isDark;
        break;
    }

    return Container(
      color: isDark ? Colors.black : Colors.white,
      child: Column(
        children: [
          // Simulated native System Status Bar
          FakeStatusBar(
            time: session.fakeTime,
            battery: session.fakeBattery,
            hasWifi: session.fakeWifi,
            backgroundColor: statusBarBg,
            isLight: isLightStatus,
          ),
          Expanded(
            child: _buildInboxBody(context),
          ),
        ],
      ),
    );
  }

  Widget _buildInboxBody(BuildContext context) {
    switch (session.platform) {
      case Platform.whatsapp:
        return _WhatsAppInbox(session: session, theme: platformTheme);
      case Platform.messenger:
        return _MessengerInbox(session: session, theme: platformTheme);
      case Platform.instagram:
        return _InstagramInbox(session: session, theme: platformTheme);
      case Platform.snapchat:
        return _SnapchatInbox(session: session, theme: platformTheme);
    }
  }
}

// ─── Avatar Helper Widget ──────────────────────────────────────────────────────
class _InboxAvatar extends StatelessWidget {
  final String name;
  final dynamic avatar; // Uint8List or null
  final double size;
  final Color fallbackBg;
  final Color fallbackText;
  final bool isOnline;
  final bool showOnlineDot;
  final bool isGroup;

  const _InboxAvatar({
    required this.name,
    this.avatar,
    required this.size,
    required this.fallbackBg,
    required this.fallbackText,
    this.isOnline = false,
    this.showOnlineDot = false,
    this.isGroup = false,
  });

  @override
  Widget build(BuildContext context) {
    if (isGroup) {
      return CircleAvatar(
        radius: size / 2,
        backgroundColor: fallbackBg,
        child: Icon(Icons.group_rounded, color: fallbackText, size: size * 0.55),
      );
    }

    Widget avatarChild;
    if (avatar is Uint8List) {
      avatarChild = CircleAvatar(
        radius: size / 2,
        backgroundImage: MemoryImage(avatar),
      );
    } else {
      avatarChild = CircleAvatar(
        radius: size / 2,
        backgroundColor: fallbackBg,
        child: Text(
          name.isNotEmpty ? name[0].toUpperCase() : '?',
          style: TextStyle(
            color: fallbackText,
            fontWeight: FontWeight.w700,
            fontSize: size * 0.42,
          ),
        ),
      );
    }

    if (!showOnlineDot) return avatarChild;

    return Stack(
      children: [
        avatarChild,
        if (isOnline)
          Positioned(
            bottom: 0,
            right: 0,
            child: Container(
              width: size * 0.28,
              height: size * 0.28,
              decoration: BoxDecoration(
                color: const Color(0xFF31A24C),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
            ),
          ),
      ],
    );
  }
}

// ─── WhatsApp Inbox ────────────────────────────────────────────────────────────
class _WhatsAppInbox extends StatelessWidget {
  final ChatSession session;
  final PlatformTheme theme;

  const _WhatsAppInbox({required this.session, required this.theme});

  @override
  Widget build(BuildContext context) {
    final isDark = session.isDarkMode;
    final isAr = Provider.of<ThemeProvider>(context).isArabic;
    final chatProvider = Provider.of<ChatProvider>(context);

    // Filter sessions belonging to WhatsApp
    final realSessions = chatProvider.sessions.where((s) => s.platform == Platform.whatsapp).toList();

    // Default mock data to populate list
    final List<Map<String, dynamic>> mockChats = [
      {
        'name': 'Sarah ☕',
        'message': 'Are we still on for lunch?',
        'time': '10:42 AM',
        'unread': 2,
        'online': true,
        'typing': false,
      },
      {
        'name': 'Family Group 🏡',
        'message': 'Dad: Check out this photo!',
        'time': 'Yesterday',
        'unread': 0,
        'online': false,
        'typing': false,
      },
      {
        'name': 'Elon Musk 🚀',
        'message': 'Mars is looking great today.',
        'time': 'Wednesday',
        'unread': 0,
        'online': false,
        'typing': false,
      },
      {
        'name': 'Dev Collaboration',
        'message': 'PR reviewed and merged successfully.',
        'time': '24/05/2026',
        'unread': 0,
        'online': false,
        'typing': false,
      }
    ];

    final Color primaryBg = isDark ? const Color(0xFF0B141A) : Colors.white;
    final Color headerBg = isDark ? const Color(0xFF1F2C34) : const Color(0xFF008069);
    final Color titleColor = Colors.white;
    final Color iconColor = Colors.white;
    final Color textPrimary = isDark ? Colors.white : Colors.black;
    final Color textSecondary = isDark ? const Color(0xFF8696A0) : const Color(0xFF667781);
    final Color activeGreen = isDark ? const Color(0xFF00A884) : const Color(0xFF25D366);

    return Scaffold(
      backgroundColor: primaryBg,
      body: Column(
        children: [
          // WhatsApp Green AppBar Header
          Container(
            color: headerBg,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                Text(
                  isAr ? 'واتساب' : 'WhatsApp',
                  style: TextStyle(
                    color: titleColor,
                    fontSize: 20.5,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Icon(Icons.camera_alt_outlined, color: iconColor, size: 21),
                const SizedBox(width: 20),
                Icon(Icons.search, color: iconColor, size: 21),
                const SizedBox(width: 14),
                Icon(Icons.more_vert, color: iconColor, size: 21),
              ],
            ),
          ),
          // WhatsApp Sub Tabs Row
          Container(
            color: headerBg,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildTab('Chats', isActive: true, activeColor: activeGreen),
                _buildTab('Updates', isActive: false, activeColor: activeGreen),
                _buildTab('Calls', isActive: false, activeColor: activeGreen),
              ],
            ),
          ),
          // Chats list
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                ...realSessions.map((s) {
                  final hasMessages = s.messages.isNotEmpty;
                  final defaultLastMsgText = s.isGroup && s.groupMembers.isNotEmpty ? s.groupMembers : 'No messages yet';
                  final lastMsgText = s.customLastMessage ?? (hasMessages ? s.messages.last.text : defaultLastMsgText);
                  final lastMsgTime = s.customLastMessageTime ?? (hasMessages ? s.messages.last.formattedTime : s.fakeTime);
                  final isMe = s.lastMessageIsSender ?? (hasMessages && s.messages.last.isSender);

                  final isBlocked = s.isBlocked || s.isBlockedMe;
                  final isOnline = !isBlocked && !s.isGroup && (s.contactUser.onlineStatus == UserOnlineStatus.online || s.contactUser.onlineStatus == UserOnlineStatus.typing);
                  final isTyping = !isBlocked && s.contactUser.onlineStatus == UserOnlineStatus.typing;

                  return _WhatsAppRow(
                    name: s.contactUser.name,
                    avatarBytes: s.contactUser.avatarBytes,
                    message: isTyping ? 'typing...' : lastMsgText,
                    time: lastMsgTime,
                    unreadCount: s.unreadCount,
                    isOnline: isOnline,
                    isTyping: isTyping,
                    isLastSenderMe: isMe,
                    isGroup: s.isGroup,
                    textPrimary: textPrimary,
                    textSecondary: textSecondary,
                    activeGreen: activeGreen,
                    onTap: () {
                      chatProvider.setActiveSession(s);
                    },
                  );
                }),
                // Render Mock chats to look complete
                ...mockChats.map((m) {
                  // Skip displaying mock if name already matches a real session
                  if (realSessions.any((s) => s.contactUser.name == m['name'])) {
                    return const SizedBox.shrink();
                  }

                  return _WhatsAppRow(
                    name: m['name'],
                    avatarBytes: null,
                    message: m['message'],
                    time: m['time'],
                    unreadCount: m['unread'],
                    isOnline: m['online'],
                    isTyping: m['typing'],
                    isLastSenderMe: false,
                    textPrimary: textPrimary,
                    textSecondary: textSecondary,
                    activeGreen: activeGreen,
                    onTap: () {
                      // Dynamically bootstrap a new active chat session for this mock contact!
                      chatProvider.createSessionCustom(
                        platform: Platform.whatsapp,
                        contactName: m['name'],
                        initialMessages: [
                          ChatMessage(
                            id: 'init-mock',
                            text: m['message'],
                            isSender: false,
                            timestamp: DateTime.now().subtract(const Duration(minutes: 5)),
                          ),
                        ],
                      );
                    },
                  );
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTab(String label, {required bool isActive, required Color activeColor}) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: isActive ? Colors.white : Colors.transparent,
              width: 3,
            ),
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            color: isActive ? Colors.white : Colors.white70,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}

class _WhatsAppRow extends StatelessWidget {
  final String name;
  final Uint8List? avatarBytes;
  final String message;
  final String time;
  final int unreadCount;
  final bool isOnline;
  final bool isTyping;
  final bool isLastSenderMe;
  final bool isGroup;
  final Color textPrimary;
  final Color textSecondary;
  final Color activeGreen;
  final VoidCallback onTap;

  const _WhatsAppRow({
    required this.name,
    this.avatarBytes,
    required this.message,
    required this.time,
    required this.unreadCount,
    required this.isOnline,
    required this.isTyping,
    required this.isLastSenderMe,
    this.isGroup = false,
    required this.textPrimary,
    required this.textSecondary,
    required this.activeGreen,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final showGreenText = unreadCount > 0 || isTyping;

    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
      leading: _InboxAvatar(
        name: name,
        avatar: avatarBytes,
        size: 48,
        fallbackBg: activeGreen.withValues(alpha: 0.15),
        fallbackText: activeGreen,
        isOnline: isOnline,
        showOnlineDot: !isGroup,
        isGroup: isGroup,
      ),
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            name,
            style: TextStyle(
              color: textPrimary,
              fontWeight: FontWeight.w600,
              fontSize: 16,
            ),
          ),
          Text(
            time,
            style: TextStyle(
              color: showGreenText ? activeGreen : textSecondary,
              fontSize: 12.5,
              fontWeight: showGreenText ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 4.0),
        child: Row(
          children: [
            if (isLastSenderMe && !isTyping) ...[
              Icon(Icons.done_all, color: activeGreen, size: 16.5),
              const SizedBox(width: 4),
            ],
            Expanded(
              child: Text(
                message,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: isTyping ? activeGreen : textSecondary,
                  fontSize: 14,
                  fontWeight: isTyping ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),
            if (unreadCount > 0)
              Container(
                margin: const EdgeInsets.only(left: 8),
                padding: const EdgeInsets.all(5.5),
                decoration: BoxDecoration(
                  color: activeGreen,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  unreadCount.toString(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ─── Messenger Inbox ───────────────────────────────────────────────────────────
class _MessengerInbox extends StatelessWidget {
  final ChatSession session;
  final PlatformTheme theme;

  const _MessengerInbox({required this.session, required this.theme});

  @override
  Widget build(BuildContext context) {
    final isDark = session.isDarkMode;
    final isAr = Provider.of<ThemeProvider>(context).isArabic;
    final chatProvider = Provider.of<ChatProvider>(context);

    final realSessions = chatProvider.sessions.where((s) => s.platform == Platform.messenger).toList();

    // Default mock data for Messenger
    final List<Map<String, dynamic>> mockChats = [
      {
        'name': 'Emma Watson',
        'message': 'Let\'s catch up later today',
        'time': '9:15 AM',
        'unread': true,
        'online': true,
        'typing': true,
        'me': false,
      },
      {
        'name': 'David Miller',
        'message': 'Haha that was so funny!',
        'time': '10:35 AM',
        'unread': false,
        'online': true,
        'typing': false,
        'me': true,
      },
      {
        'name': 'Sophia Loren',
        'message': 'PR merged successfully.',
        'time': 'Yesterday',
        'unread': false,
        'online': false,
        'typing': false,
        'me': true,
      }
    ];

    final Color primaryBg = isDark ? Colors.black : Colors.white;
    final Color textPrimary = isDark ? Colors.white : Colors.black;
    final Color textSecondary = isDark ? Colors.white60 : Colors.black54;
    final Color searchBg = isDark ? const Color(0xFF1C1B1F) : const Color(0xFFF0F2F5);
    final Color activeBlue = const Color(0xFF0084FF);

    return Scaffold(
      backgroundColor: primaryBg,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Row(
              children: [
                _InboxAvatar(
                  name: session.fakeName,
                  avatar: session.fakeAvatarBytes,
                  size: 32,
                  fallbackBg: activeBlue.withValues(alpha: 0.15),
                  fallbackText: activeBlue,
                ),
                const SizedBox(width: 12),
                Text(
                  isAr ? 'الدردشات' : 'Chats',
                  style: TextStyle(
                    color: textPrimary,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: searchBg,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.camera_alt, color: textPrimary, size: 20),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: searchBg,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.edit, color: textPrimary, size: 20),
                ),
              ],
            ),
          ),
          // Search Bar
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: searchBg,
              borderRadius: BorderRadius.circular(100),
            ),
            child: Row(
              children: [
                Icon(Icons.search, color: textSecondary, size: 18),
                const SizedBox(width: 8),
                Text(
                  isAr ? 'بحث' : 'Search',
                  style: TextStyle(color: textSecondary, fontSize: 14),
                ),
              ],
            ),
          ),
          // Active Contacts Row (Horizontal Row of stories)
          SizedBox(
            height: 85,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                // Real contacts
                ...realSessions.map((s) {
                  return _buildActiveFriendBubble(
                    s.contactUser.name,
                    s.contactUser.avatarBytes,
                    s.contactUser.onlineStatus == UserOnlineStatus.online || s.contactUser.onlineStatus == UserOnlineStatus.typing,
                    textPrimary,
                    activeBlue,
                  );
                }),
                // Mock contacts
                ...mockChats.map((m) {
                  if (realSessions.any((s) => s.contactUser.name == m['name'])) {
                    return const SizedBox.shrink();
                  }
                  return _buildActiveFriendBubble(
                    m['name'],
                    null,
                    m['online'],
                    textPrimary,
                    activeBlue,
                  );
                }),
              ],
            ),
          ),
          const SizedBox(height: 8),
          // Vertical Chat List
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                ...realSessions.map((s) {
                  final hasMessages = s.messages.isNotEmpty;
                  final defaultLastMsgText = s.isGroup && s.groupMembers.isNotEmpty ? s.groupMembers : 'No messages yet';
                  final lastMsgText = s.customLastMessage ?? (hasMessages ? s.messages.last.text : defaultLastMsgText);
                  final lastMsgTime = s.customLastMessageTime ?? (hasMessages ? s.messages.last.formattedTime : s.fakeTime);
                  final isMe = s.lastMessageIsSender ?? (hasMessages && s.messages.last.isSender);

                  final isBlocked = s.isBlocked || s.isBlockedMe;
                  final isOnline = !isBlocked && !s.isGroup && (s.contactUser.onlineStatus == UserOnlineStatus.online || s.contactUser.onlineStatus == UserOnlineStatus.typing);
                  final isTyping = !isBlocked && s.contactUser.onlineStatus == UserOnlineStatus.typing;

                  return _MessengerRow(
                    name: s.contactUser.name,
                    avatarBytes: s.contactUser.avatarBytes,
                    message: isTyping ? 'typing...' : lastMsgText,
                    time: lastMsgTime,
                    isUnread: s.unreadCount > 0,
                    isOnline: isOnline,
                    isTyping: isTyping,
                    isLastSenderMe: isMe,
                    isGroup: s.isGroup,
                    textPrimary: textPrimary,
                    textSecondary: textSecondary,
                    activeBlue: activeBlue,
                    onTap: () {
                      chatProvider.setActiveSession(s);
                    },
                  );
                }),
                // Mock Messenger Chats
                ...mockChats.map((m) {
                  if (realSessions.any((s) => s.contactUser.name == m['name'])) {
                    return const SizedBox.shrink();
                  }

                  return _MessengerRow(
                    name: m['name'],
                    avatarBytes: null,
                    message: m['message'],
                    time: m['time'],
                    isUnread: m['unread'],
                    isOnline: m['online'],
                    isTyping: m['typing'],
                    isLastSenderMe: m['me'],
                    textPrimary: textPrimary,
                    textSecondary: textSecondary,
                    activeBlue: activeBlue,
                    onTap: () {
                      chatProvider.createSessionCustom(
                        platform: Platform.messenger,
                        contactName: m['name'],
                        initialMessages: [
                          ChatMessage(
                            id: 'init-mock',
                            text: m['message'],
                            isSender: m['me'],
                            timestamp: DateTime.now().subtract(const Duration(minutes: 10)),
                          ),
                        ],
                      );
                    },
                  );
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveFriendBubble(String name, Uint8List? avatarBytes, bool isOnline, Color textColor, Color activeColor) {
    final firstName = name.split(' ')[0];
    return Container(
      margin: const EdgeInsets.only(right: 14),
      child: Column(
        children: [
          _InboxAvatar(
            name: name,
            avatar: avatarBytes,
            size: 52,
            fallbackBg: activeColor.withValues(alpha: 0.15),
            fallbackText: activeColor,
            isOnline: isOnline,
            showOnlineDot: true,
          ),
          const SizedBox(height: 6),
          Text(
            firstName,
            style: TextStyle(color: textColor, fontSize: 11.5),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _MessengerRow extends StatelessWidget {
  final String name;
  final Uint8List? avatarBytes;
  final String message;
  final String time;
  final bool isUnread;
  final bool isOnline;
  final bool isTyping;
  final bool isLastSenderMe;
  final bool isGroup;
  final Color textPrimary;
  final Color textSecondary;
  final Color activeBlue;
  final VoidCallback onTap;

  const _MessengerRow({
    required this.name,
    this.avatarBytes,
    required this.message,
    required this.time,
    required this.isUnread,
    required this.isOnline,
    required this.isTyping,
    required this.isLastSenderMe,
    this.isGroup = false,
    required this.textPrimary,
    required this.textSecondary,
    required this.activeBlue,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final boldText = isUnread || isTyping;

    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 1),
      leading: _InboxAvatar(
        name: name,
        avatar: avatarBytes,
        size: 52,
        fallbackBg: activeBlue.withValues(alpha: 0.15),
        fallbackText: activeBlue,
        isOnline: isOnline,
        showOnlineDot: !isGroup,
        isGroup: isGroup,
      ),
      title: Text(
        name,
        style: TextStyle(
          color: textPrimary,
          fontWeight: boldText ? FontWeight.bold : FontWeight.w500,
          fontSize: 15.5,
        ),
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 2.0),
        child: Row(
          children: [
            Expanded(
              child: Text(
                isLastSenderMe && !isTyping ? 'You: $message' : message,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: boldText ? textPrimary : textSecondary,
                  fontWeight: boldText ? FontWeight.bold : FontWeight.normal,
                  fontSize: 13.5,
                ),
              ),
            ),
            const SizedBox(width: 4),
            Text(
              '· $time',
              style: TextStyle(
                color: boldText ? textPrimary : textSecondary,
                fontWeight: boldText ? FontWeight.bold : FontWeight.normal,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
      trailing: isUnread
          ? Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: activeBlue,
                shape: BoxShape.circle,
              ),
            )
          : (isLastSenderMe
              ? Container(
                  width: 14,
                  height: 14,
                  decoration: const BoxDecoration(
                    color: Color(0xFFCCD0D5),
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: Icon(Icons.check, size: 9, color: Colors.white),
                  ),
                )
              : null),
    );
  }
}

// ─── Instagram DM Inbox ────────────────────────────────────────────────────────
class _InstagramInbox extends StatelessWidget {
  final ChatSession session;
  final PlatformTheme theme;

  const _InstagramInbox({required this.session, required this.theme});

  @override
  Widget build(BuildContext context) {
    final isDark = session.isDarkMode;
    final isAr = Provider.of<ThemeProvider>(context).isArabic;
    final chatProvider = Provider.of<ChatProvider>(context);

    final realSessions = chatProvider.sessions.where((s) => s.platform == Platform.instagram).toList();

    // Default mock data for Instagram
    final List<Map<String, dynamic>> mockChats = [
      {
        'name': 'charlie_design',
        'message': 'Loved your latest post!',
        'time': '10:30 AM',
        'unread': true,
        'online': true,
        'note': 'Working... 💻',
      },
      {
        'name': 'travel_explorer',
        'message': 'Sent a reel',
        'time': '2h',
        'unread': false,
        'online': true,
        'note': 'In Tokyo! 🇯🇵',
      },
      {
        'name': 'culinary_arts',
        'message': 'Check out this recipe!',
        'time': 'Yesterday',
        'unread': false,
        'online': false,
        'note': '',
      }
    ];

    final Color primaryBg = isDark ? Colors.black : Colors.white;
    final Color textPrimary = isDark ? Colors.white : Colors.black;
    final Color textSecondary = isDark ? Colors.grey[400]! : Colors.grey[600]!;
    final Color searchBg = isDark ? const Color(0xFF262626) : const Color(0xFFEFEFEF);
    final Color activePink = const Color(0xFFE1306C);
    final Color noteBubbleBg = isDark ? const Color(0xFF262626) : const Color(0xFFF2F2F2);

    return Scaffold(
      backgroundColor: primaryBg,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Row(
              children: [
                Icon(Icons.arrow_back, color: textPrimary, size: 24),
                const SizedBox(width: 14),
                Text(
                  session.fakeName,
                  style: TextStyle(
                    color: textPrimary,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Icon(Icons.keyboard_arrow_down, color: textPrimary, size: 18),
                const Spacer(),
                Icon(Icons.videocam_outlined, color: textPrimary, size: 26),
                const SizedBox(width: 16),
                Icon(Icons.edit_square, color: textPrimary, size: 22),
              ],
            ),
          ),
          // Search Bar
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: searchBg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Icon(Icons.search, color: textSecondary, size: 18),
                const SizedBox(width: 8),
                Text(
                  isAr ? 'بحث' : 'Search',
                  style: TextStyle(color: textSecondary, fontSize: 14),
                ),
              ],
            ),
          ),
          // Instagram Notes Horizontal bubbles row
          SizedBox(
            height: 105,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                // Real contacts notes
                ...realSessions.map((s) {
                  final isBlocked = s.isBlocked || s.isBlockedMe;
                  return _buildInstagramNoteBubble(
                    s.contactUser.name,
                    s.contactUser.avatarBytes,
                    !isBlocked && (s.contactUser.onlineStatus == UserOnlineStatus.online || s.contactUser.onlineStatus == UserOnlineStatus.typing),
                    isBlocked ? '' : 'Online',
                    textPrimary,
                    activePink,
                    noteBubbleBg,
                  );
                }),
                // Mock contacts notes
                ...mockChats.map((m) {
                  if (realSessions.any((s) => s.contactUser.name == m['name'])) {
                    return const SizedBox.shrink();
                  }
                  return _buildInstagramNoteBubble(
                    m['name'],
                    null,
                    m['online'],
                    m['note'],
                    textPrimary,
                    activePink,
                    noteBubbleBg,
                  );
                }),
              ],
            ),
          ),
          // Vertical Chat List
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                // Real Instagram Sessions
                ...realSessions.map((s) {
                  final hasMessages = s.messages.isNotEmpty;
                  final defaultLastMsgText = s.isGroup && s.groupMembers.isNotEmpty ? s.groupMembers : 'No messages yet';
                  final lastMsgText = s.customLastMessage ?? (hasMessages ? s.messages.last.text : defaultLastMsgText);
                  final lastMsgTime = s.customLastMessageTime ?? (hasMessages ? s.messages.last.formattedTime : s.fakeTime);
                  final isMe = s.lastMessageIsSender ?? (hasMessages && s.messages.last.isSender);

                  final isBlocked = s.isBlocked || s.isBlockedMe;
                  final isOnline = !isBlocked && !s.isGroup && (s.contactUser.onlineStatus == UserOnlineStatus.online || s.contactUser.onlineStatus == UserOnlineStatus.typing);
                  final isTyping = !isBlocked && s.contactUser.onlineStatus == UserOnlineStatus.typing;

                  return _InstagramRow(
                    name: s.contactUser.name,
                    avatarBytes: s.contactUser.avatarBytes,
                    message: isTyping ? 'typing...' : lastMsgText,
                    time: lastMsgTime,
                    isUnread: s.unreadCount > 0,
                    isOnline: isOnline,
                    isTyping: isTyping,
                    isLastSenderMe: isMe,
                    isGroup: s.isGroup,
                    textPrimary: textPrimary,
                    textSecondary: textSecondary,
                    activePink: activePink,
                    onTap: () {
                      chatProvider.setActiveSession(s);
                    },
                  );
                }),
                // Mock Instagram Chats
                ...mockChats.map((m) {
                  if (realSessions.any((s) => s.contactUser.name == m['name'])) {
                    return const SizedBox.shrink();
                  }

                  return _InstagramRow(
                    name: m['name'],
                    avatarBytes: null,
                    message: m['message'],
                    time: m['time'],
                    isUnread: m['unread'],
                    isOnline: m['online'],
                    isTyping: false,
                    isLastSenderMe: false,
                    textPrimary: textPrimary,
                    textSecondary: textSecondary,
                    activePink: activePink,
                    onTap: () {
                      chatProvider.createSessionCustom(
                        platform: Platform.instagram,
                        contactName: m['name'],
                        initialMessages: [
                          ChatMessage(
                            id: 'init-mock',
                            text: m['message'],
                            isSender: false,
                            timestamp: DateTime.now().subtract(const Duration(hours: 1)),
                          ),
                        ],
                      );
                    },
                  );
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInstagramNoteBubble(String name, Uint8List? avatarBytes, bool isOnline, String noteText, Color textColor, Color activeColor, Color bubbleBg) {
    final firstName = name.split('_')[0];
    final hasNote = noteText.isNotEmpty;

    return Container(
      margin: const EdgeInsets.only(right: 16),
      child: Column(
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              _InboxAvatar(
                name: name,
                avatar: avatarBytes,
                size: 56,
                fallbackBg: activeColor.withValues(alpha: 0.15),
                fallbackText: activeColor,
                isOnline: isOnline,
                showOnlineDot: !hasNote, // Only show green dot if note bubble is not taking up the space
              ),
              if (hasNote)
                Positioned(
                  top: -8,
                  left: 4,
                  right: 4,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                    decoration: BoxDecoration(
                      color: bubbleBg,
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.08),
                          blurRadius: 3,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                    child: Text(
                      noteText,
                      style: TextStyle(color: textColor, fontSize: 8.5, fontWeight: FontWeight.w600),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            firstName,
            style: TextStyle(color: textColor, fontSize: 11),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _InstagramRow extends StatelessWidget {
  final String name;
  final Uint8List? avatarBytes;
  final String message;
  final String time;
  final bool isUnread;
  final bool isOnline;
  final bool isTyping;
  final bool isLastSenderMe;
  final bool isGroup;
  final Color textPrimary;
  final Color textSecondary;
  final Color activePink;
  final VoidCallback onTap;

  const _InstagramRow({
    required this.name,
    this.avatarBytes,
    required this.message,
    required this.time,
    required this.isUnread,
    required this.isOnline,
    required this.isTyping,
    required this.isLastSenderMe,
    this.isGroup = false,
    required this.textPrimary,
    required this.textSecondary,
    required this.activePink,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final boldText = isUnread || isTyping;

    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 1),
      leading: _InboxAvatar(
        name: name,
        avatar: avatarBytes,
        size: 56,
        fallbackBg: activePink.withValues(alpha: 0.15),
        fallbackText: activePink,
        isOnline: isOnline,
        showOnlineDot: !isGroup,
        isGroup: isGroup,
      ),
      title: Text(
        name,
        style: TextStyle(
          color: textPrimary,
          fontWeight: boldText ? FontWeight.bold : FontWeight.w500,
          fontSize: 14.5,
        ),
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 2.0),
        child: Row(
          children: [
            Expanded(
              child: Text(
                isLastSenderMe && !isTyping ? 'Sent $message' : message,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: boldText ? textPrimary : textSecondary,
                  fontWeight: boldText ? FontWeight.bold : FontWeight.normal,
                  fontSize: 13.5,
                ),
              ),
            ),
            const SizedBox(width: 4),
            Text(
              '· $time',
              style: TextStyle(
                color: boldText ? textPrimary : textSecondary,
                fontWeight: boldText ? FontWeight.bold : FontWeight.normal,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
      trailing: isUnread
          ? Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: Color(0xFF0095F6),
                shape: BoxShape.circle,
              ),
            )
          : Icon(Icons.camera_alt_outlined, color: textSecondary, size: 22),
    );
  }
}

// ─── Snapchat Inbox ────────────────────────────────────────────────────────────
class _SnapchatInbox extends StatelessWidget {
  final ChatSession session;
  final PlatformTheme theme;

  const _SnapchatInbox({required this.session, required this.theme});

  @override
  Widget build(BuildContext context) {
    final isDark = session.isDarkMode;
    final isAr = Provider.of<ThemeProvider>(context).isArabic;
    final chatProvider = Provider.of<ChatProvider>(context);

    final realSessions = chatProvider.sessions.where((s) => s.platform == Platform.snapchat).toList();

    // Default mock data for Snapchat
    final List<Map<String, dynamic>> mockChats = [
      {
        'name': 'Sophia ✨',
        'message': 'New Snap',
        'time': '9:05 AM',
        'streak': 12,
        'status': 'received_snap_unread',
        'online': true,
      },
      {
        'name': 'Liam (Streaks)',
        'message': 'Opened',
        'time': '10:22 AM',
        'streak': 34,
        'status': 'sent_snap_read',
        'online': true,
      },
      {
        'name': 'Noah',
        'message': 'New Chat',
        'time': 'Yesterday',
        'streak': 0,
        'status': 'received_chat_unread',
        'online': false,
      }
    ];

    final Color primaryBg = isDark ? const Color(0xFF0B0C0E) : Colors.white;
    final Color textPrimary = isDark ? Colors.white : Colors.black;
    final Color textSecondary = isDark ? Colors.white60 : Colors.black54;
    final Color searchBg = isDark ? const Color(0xFF242528) : const Color(0xFFF0F1F2);
    final Color activeYellow = const Color(0xFFFFFC00);

    return Scaffold(
      backgroundColor: primaryBg,
      body: Column(
        children: [
          // Snapchat Header
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
            child: Row(
              children: [
                _InboxAvatar(
                  name: session.fakeName,
                  avatar: session.fakeAvatarBytes,
                  size: 38,
                  fallbackBg: activeYellow.withValues(alpha: 0.2),
                  fallbackText: Colors.black,
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: searchBg,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.search, color: textPrimary, size: 20),
                ),
                const Spacer(),
                Text(
                  isAr ? 'دردشة' : 'Chat',
                  style: TextStyle(
                    color: textPrimary,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: searchBg,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.person_add_outlined, color: textPrimary, size: 20),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: searchBg,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.chat_bubble_outline_rounded, color: textPrimary, size: 20),
                ),
              ],
            ),
          ),
          // Divider
          Container(height: 0.8, color: searchBg),
          // Vertical Feed List
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                // Real Snapchat Sessions
                ...realSessions.map((s) {
                  final hasMessages = s.messages.isNotEmpty;
                  final isMe = s.lastMessageIsSender ?? (hasMessages && s.messages.last.isSender);
                  
                  final defaultLastMsgText = s.isGroup && s.groupMembers.isNotEmpty ? s.groupMembers : 'New Chat';
                  final msg = s.customLastMessage ?? (hasMessages ? s.messages.last.text : defaultLastMsgText);
                  
                  String snapStatus;
                  final isSnap = msg.toLowerCase().contains('snap') || (hasMessages && s.messages.last.type == MessageType.image);
                  
                  if (s.unreadCount > 0) {
                    snapStatus = isSnap ? 'received_snap_unread' : 'received_chat_unread';
                  } else {
                    if (isMe) {
                      snapStatus = isSnap ? 'sent_snap_read' : 'sent_chat_read';
                    } else {
                      snapStatus = isSnap ? 'received_snap_read' : 'received_chat_read';
                    }
                  }

                  final isBlocked = s.isBlocked || s.isBlockedMe;
                  final isOnline = !isBlocked && !s.isGroup && (s.contactUser.onlineStatus == UserOnlineStatus.online || s.contactUser.onlineStatus == UserOnlineStatus.typing);

                  return _SnapchatRow(
                    name: s.contactUser.name,
                    avatarBytes: s.contactUser.avatarBytes,
                    message: msg,
                    time: s.customLastMessageTime ?? (hasMessages ? s.messages.last.formattedTime : s.fakeTime),
                    streak: 0,
                    statusType: snapStatus,
                    isOnline: isOnline,
                    isGroup: s.isGroup,
                    textPrimary: textPrimary,
                    textSecondary: textSecondary,
                    onTap: () {
                      chatProvider.setActiveSession(s);
                    },
                  );
                }),
                // Mock Snapchat Chats
                ...mockChats.map((m) {
                  if (realSessions.any((s) => s.contactUser.name == m['name'])) {
                    return const SizedBox.shrink();
                  }

                  return _SnapchatRow(
                    name: m['name'],
                    avatarBytes: null,
                    message: m['message'],
                    time: m['time'],
                    streak: m['streak'],
                    statusType: m['status'],
                    isOnline: m['online'],
                    textPrimary: textPrimary,
                    textSecondary: textSecondary,
                    onTap: () {
                      chatProvider.createSessionCustom(
                        platform: Platform.snapchat,
                        contactName: m['name'],
                        initialMessages: [
                          ChatMessage(
                            id: 'init-mock',
                            text: 'Hey!',
                            isSender: false,
                            timestamp: DateTime.now().subtract(const Duration(hours: 2)),
                          ),
                        ],
                      );
                    },
                  );
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SnapchatRow extends StatelessWidget {
  final String name;
  final Uint8List? avatarBytes;
  final String message;
  final String time;
  final int streak;
  final String statusType;
  final bool isOnline;
  final bool isGroup;
  final Color textPrimary;
  final Color textSecondary;
  final VoidCallback onTap;

  const _SnapchatRow({
    required this.name,
    this.avatarBytes,
    required this.message,
    required this.time,
    required this.streak,
    required this.statusType,
    required this.isOnline,
    this.isGroup = false,
    required this.textPrimary,
    required this.textSecondary,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final showBold = statusType.contains('unread');

    return Container(
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: textPrimary.withValues(alpha: 0.04), width: 0.8)),
      ),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
        leading: _InboxAvatar(
          name: name,
          avatar: avatarBytes,
          size: 42,
          fallbackBg: const Color(0xFFFFFC00).withValues(alpha: 0.18),
          fallbackText: Colors.black87,
          isOnline: isOnline,
          showOnlineDot: false,
          isGroup: isGroup,
        ),
        title: Row(
          children: [
            Text(
              name,
              style: TextStyle(
                color: textPrimary,
                fontWeight: FontWeight.bold,
                fontSize: 15.5,
              ),
            ),
            if (streak > 0) ...[
              const SizedBox(width: 6),
              Text(
                '🔥 $streak',
                style: TextStyle(color: textPrimary, fontSize: 13, fontWeight: FontWeight.bold),
              ),
            ],
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4.0),
          child: Row(
            children: [
              _buildSnapchatStatusIcon(),
              const SizedBox(width: 6),
              Text(
                message,
                style: TextStyle(
                  color: _statusColor(statusType),
                  fontWeight: showBold ? FontWeight.w900 : FontWeight.bold,
                  fontSize: 12.5,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                '· $time',
                style: TextStyle(
                  color: textSecondary,
                  fontSize: 12.5,
                  fontWeight: showBold ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
        trailing: Container(
          padding: const EdgeInsets.only(left: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 0.8,
                height: 24,
                color: textPrimary.withValues(alpha: 0.1),
              ),
              const SizedBox(width: 14),
              Icon(
                Icons.chat_bubble_outline_rounded,
                color: const Color(0xFF00BFFF),
                size: 21,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSnapchatStatusIcon() {
    final double iconSize = 13.0;

    switch (statusType) {
      case 'received_snap_unread':
        return Container(
          width: iconSize,
          height: iconSize,
          decoration: BoxDecoration(
            color: const Color(0xFFFF0000), // Solid red square for unread snap
            borderRadius: BorderRadius.circular(2),
          ),
        );
      case 'received_chat_unread':
        return Container(
          width: iconSize,
          height: iconSize,
          decoration: BoxDecoration(
            color: const Color(0xFF00BFFF), // Solid blue square for unread chat
            borderRadius: BorderRadius.circular(2),
          ),
        );
      case 'received_snap_read':
        return Container(
          width: iconSize,
          height: iconSize,
          decoration: BoxDecoration(
            color: Colors.transparent,
            border: Border.all(color: const Color(0xFFFF0000), width: 1.5),
            borderRadius: BorderRadius.circular(2),
          ),
        );
      case 'received_chat_read':
        return Container(
          width: iconSize,
          height: iconSize,
          decoration: BoxDecoration(
            color: Colors.transparent,
            border: Border.all(color: const Color(0xFF00BFFF), width: 1.5),
            borderRadius: BorderRadius.circular(2),
          ),
        );
      case 'sent_snap_read':
        return SizedBox(
          width: iconSize + 2,
          height: iconSize + 2,
          child: const Center(
            child: Icon(Icons.send_rounded, color: Color(0xFFFF0000), size: 13), // Empty/hollow red arrow
          ),
        );
      case 'sent_chat_read':
        return SizedBox(
          width: iconSize + 2,
          height: iconSize + 2,
          child: const Center(
            child: Icon(Icons.send_rounded, color: Color(0xFF00BFFF), size: 13), // Empty/hollow blue arrow
          ),
        );
      default:
        return Container(
          width: iconSize,
          height: iconSize,
          decoration: BoxDecoration(
            color: const Color(0xFFCCD0D5),
            borderRadius: BorderRadius.circular(2),
          ),
        );
    }
  }

  Color _statusColor(String type) {
    if (type.contains('snap')) {
      return const Color(0xFFFF0000); // Red for Snapchat snaps
    }
    return const Color(0xFF00BFFF); // Blue for Snapchat chats
  }
}
