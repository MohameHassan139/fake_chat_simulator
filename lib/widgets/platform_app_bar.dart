import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/chat_models.dart';
import '../themes/platform_themes.dart';
import '../providers/chat_provider.dart';

class PlatformAppBar extends StatelessWidget {
  final ChatSession session;
  final PlatformTheme platformTheme;

  const PlatformAppBar({
    super.key,
    required this.session,
    required this.platformTheme,
  });

  @override
  Widget build(BuildContext context) {
    switch (session.platform) {
      case Platform.whatsapp:
        return _WhatsAppBar(session: session, theme: platformTheme);
      case Platform.messenger:
        return _MessengerBar(session: session, theme: platformTheme);
      case Platform.instagram:
        return _InstagramBar(session: session, theme: platformTheme);
      case Platform.snapchat:
        return _SnapchatBar(session: session, theme: platformTheme);
    }
  }
}

// ─── Avatar Helper ─────────────────────────────────────────────────────────────

class _Avatar extends StatelessWidget {
  final ChatUser user;
  final double size;
  final Color fallbackColor;

  const _Avatar({
    required this.user,
    required this.size,
    required this.fallbackColor,
  });

  @override
  Widget build(BuildContext context) {
    if (user.avatarBytes != null) {
      return CircleAvatar(
        radius: size / 2,
        backgroundImage: MemoryImage(user.avatarBytes!),
      );
    }
    return CircleAvatar(
      radius: size / 2,
      backgroundColor: fallbackColor.withOpacity(0.18),
      child: Text(
        user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
        style: TextStyle(
          color: fallbackColor,
          fontWeight: FontWeight.w800,
          fontSize: size * 0.42,
        ),
      ),
    );
  }
}

// ─── WhatsApp ──────────────────────────────────────────────────────────────────

class _WhatsAppBar extends StatelessWidget {
  final ChatSession session;
  final PlatformTheme theme;

  const _WhatsAppBar({required this.session, required this.theme});

  @override
  Widget build(BuildContext context) {
    final String statusText = session.contactUser.onlineStatus == UserOnlineStatus.typing
        ? 'typing...'
        : session.contactUser.statusText;

    return Container(
      height: 58,
      color: theme.appBarBg,
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        children: [
          const SizedBox(width: 2),
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white, size: 23),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            onPressed: () => Provider.of<ChatProvider>(context, listen: false).setViewChatList(true),
          ),
          const SizedBox(width: 2),
          _Avatar(user: session.contactUser, size: 36, fallbackColor: Colors.white),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  session.contactUser.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 1),
                Text(
                  statusText,
                  style: TextStyle(
                    color: statusText == 'typing...'
                        ? const Color(0xFF25D366)
                        : Colors.white.withOpacity(0.85),
                    fontSize: 11.5,
                    fontWeight: statusText == 'typing...' ? FontWeight.bold : FontWeight.normal,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.videocam, color: Colors.white, size: 22),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.call, color: Colors.white, size: 20),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.more_vert, color: Colors.white, size: 21),
            onPressed: () {},
          ),
        ],
      ),
    );
  }
}

// ─── Messenger ─────────────────────────────────────────────────────────────────

class _MessengerBar extends StatelessWidget {
  final ChatSession session;
  final PlatformTheme theme;

  const _MessengerBar({required this.session, required this.theme});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: theme.appBarBg,
        border: const Border(bottom: BorderSide(color: Color(0xFFECECEC), width: 0.8)),
      ),
      child: Row(
        children: [
          IconButton(
            icon: Icon(Icons.arrow_back_ios_new, color: theme.appBarIcon, size: 19),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            onPressed: () => Provider.of<ChatProvider>(context, listen: false).setViewChatList(true),
          ),
          const SizedBox(width: 8),
          Stack(
            children: [
              _Avatar(user: session.contactUser, size: 36, fallbackColor: theme.appBarIcon),
              if (session.contactUser.onlineStatus == UserOnlineStatus.online ||
                  session.contactUser.onlineStatus == UserOnlineStatus.typing)
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: const Color(0xFF31A24C),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  session.contactUser.name,
                  style: TextStyle(
                    color: theme.appBarText,
                    fontSize: 15.5,
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.2,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 1),
                Text(
                  session.contactUser.onlineStatus == UserOnlineStatus.typing
                      ? 'typing...'
                      : session.contactUser.statusText,
                  style: const TextStyle(
                    color: Color(0xFF65676B),
                    fontSize: 11.5,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(Icons.phone, color: theme.appBarIcon, size: 21),
            onPressed: () {},
          ),
          IconButton(
            icon: Icon(Icons.videocam, color: theme.appBarIcon, size: 22),
            onPressed: () {},
          ),
          IconButton(
            icon: Icon(Icons.info_outline, color: theme.appBarIcon, size: 21),
            onPressed: () {},
          ),
        ],
      ),
    );
  }
}

// ─── Instagram ─────────────────────────────────────────────────────────────────

class _InstagramBar extends StatelessWidget {
  final ChatSession session;
  final PlatformTheme theme;

  const _InstagramBar({required this.session, required this.theme});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: theme.appBarBg,
        border: const Border(bottom: BorderSide(color: Color(0xFFF2F2F2), width: 0.8)),
      ),
      child: Row(
        children: [
          IconButton(
            icon: Icon(Icons.arrow_back_ios_new, color: theme.appBarIcon, size: 19),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            onPressed: () => Provider.of<ChatProvider>(context, listen: false).setViewChatList(true),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.all(1.5),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFFC32E96), Color(0xFFFCAF45)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
            ),
            child: Container(
              padding: const EdgeInsets.all(1.5),
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: _Avatar(user: session.contactUser, size: 30, fallbackColor: const Color(0xFFE1306C)),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  session.contactUser.name,
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: 14.5,
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.1,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 1),
                Text(
                  session.contactUser.onlineStatus == UserOnlineStatus.typing
                      ? 'typing...'
                      : session.contactUser.statusText,
                  style: const TextStyle(
                    color: Color(0xFF999999),
                    fontSize: 11,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(Icons.phone_outlined, color: theme.appBarIcon, size: 22),
            onPressed: () {},
          ),
          IconButton(
            icon: Icon(Icons.videocam_outlined, color: theme.appBarIcon, size: 23),
            onPressed: () {},
          ),
          IconButton(
            icon: Icon(Icons.info_outline, color: theme.appBarIcon, size: 22),
            onPressed: () {},
          ),
        ],
      ),
    );
  }
}

// ─── Snapchat ──────────────────────────────────────────────────────────────────

class _SnapchatBar extends StatelessWidget {
  final ChatSession session;
  final PlatformTheme theme;

  const _SnapchatBar({required this.session, required this.theme});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 56,
      decoration: const BoxDecoration(
        color: Colors.white, // Real Snapchat chat screen has a clean white top bar
        border: Border(bottom: BorderSide(color: Color(0xFFF2F2F2), width: 0.8)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black, size: 19),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            onPressed: () => Provider.of<ChatProvider>(context, listen: false).setViewChatList(true),
          ),
          const SizedBox(width: 8),
          _Avatar(user: session.contactUser, size: 34, fallbackColor: Colors.black),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  session.contactUser.name,
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: 15.5,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (session.contactUser.onlineStatus == UserOnlineStatus.online ||
                    session.contactUser.onlineStatus == UserOnlineStatus.typing) ...[
                  const SizedBox(height: 1),
                  Row(
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          color: Color(0xFF00FF00),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        session.contactUser.onlineStatus == UserOnlineStatus.typing
                            ? 'typing...'
                            : 'Active now',
                        style: const TextStyle(
                          color: Color(0xFF666666),
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ] else ...[
                  const SizedBox(height: 1),
                  Text(
                    session.contactUser.statusText,
                    style: const TextStyle(
                      color: Color(0xFF666666),
                      fontSize: 11,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.phone_outlined, color: Colors.black, size: 21),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.videocam_outlined, color: Colors.black, size: 22),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.more_horiz, color: Colors.black, size: 21),
            onPressed: () {},
          ),
        ],
      ),
    );
  }
}
