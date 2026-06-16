import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/chat_models.dart';
import '../themes/platform_themes.dart';
import '../providers/chat_provider.dart';
import '../providers/theme_provider.dart';

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
  final bool forcePlaceholder;

  const _Avatar({
    required this.user,
    required this.size,
    required this.fallbackColor,
    this.forcePlaceholder = false,
  });

  @override
  Widget build(BuildContext context) {
    if (forcePlaceholder) {
      return CircleAvatar(
        radius: size / 2,
        backgroundColor: const Color(0xFF65676B).withOpacity(0.18),
        child: Icon(
          Icons.person,
          color: const Color(0xFF8696A0),
          size: size * 0.6,
        ),
      );
    }
    if (user.avatarBytes != null) {
      return CircleAvatar(
        radius: size / 2,
        backgroundImage: MemoryImage(user.avatarBytes!),
      );
    }
    return CircleAvatar(
      radius: size / 2,
      backgroundColor: fallbackColor.withValues(alpha: 0.18),
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
    final String statusText = (session.isBlocked || session.isBlockedMe)
        ? ''
        : (session.contactUser.onlineStatus == UserOnlineStatus.typing
            ? 'typing...'
            : session.contactUser.statusText);

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
          _Avatar(
            user: session.contactUser,
            size: 36,
            fallbackColor: Colors.white,
            forcePlaceholder: session.isBlocked || session.isBlockedMe,
          ),
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
                if (statusText.isNotEmpty) ...[
                  const SizedBox(height: 1),
                  Text(
                    statusText,
                    style: TextStyle(
                      color: statusText == 'typing...'
                          ? const Color(0xFF25D366)
                          : Colors.white.withValues(alpha: 0.85),
                      fontSize: 11.5,
                      fontWeight: statusText == 'typing...' ? FontWeight.bold : FontWeight.normal,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
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
          Theme(
            data: Theme.of(context).copyWith(
              cardColor: session.isDarkMode ? const Color(0xFF2B373E) : Colors.white,
            ),
            child: PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert, color: Colors.white, size: 21),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              onSelected: (value) {
                if (value == 'block') {
                  if (session.isBlocked) {
                    _showUnblockDialog(context, session);
                  } else {
                    _showBlockDialog(context, session);
                  }
                }
              },
              itemBuilder: (BuildContext context) {
                final isAr = context.read<ThemeProvider>().isArabic;
                final Color popTextColor = session.isDarkMode ? Colors.white : Colors.black87;
                final blockText = session.isBlocked 
                    ? (isAr ? 'إلغاء حظر جهة الاتصال' : 'Unblock') 
                    : (isAr ? 'حظر جهة الاتصال' : 'Block');
                return [
                  PopupMenuItem(
                    value: 'view',
                    child: Text(isAr ? 'عرض جهة الاتصال' : 'View contact', style: TextStyle(color: popTextColor)),
                  ),
                  PopupMenuItem(
                    value: 'media',
                    child: Text(isAr ? 'الوسائط والمستندات' : 'Media, links, and docs', style: TextStyle(color: popTextColor)),
                  ),
                  PopupMenuItem(
                    value: 'search',
                    child: Text(isAr ? 'بحث' : 'Search', style: TextStyle(color: popTextColor)),
                  ),
                  PopupMenuItem(
                    value: 'mute',
                    child: Text(isAr ? 'كتم الإشعارات' : 'Mute notifications', style: TextStyle(color: popTextColor)),
                  ),
                  PopupMenuItem(
                    value: 'block',
                    child: Text(blockText, style: TextStyle(color: popTextColor)),
                  ),
                ];
              },
            ),
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
              if (!session.isBlocked && !session.isBlockedMe &&
                  (session.contactUser.onlineStatus == UserOnlineStatus.online ||
                  session.contactUser.onlineStatus == UserOnlineStatus.typing))
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
                if (!session.isBlocked && !session.isBlockedMe) ...[
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
          Theme(
            data: Theme.of(context).copyWith(
              cardColor: session.isDarkMode ? const Color(0xFF242526) : Colors.white,
            ),
            child: PopupMenuButton<String>(
              icon: Icon(Icons.info_outline, color: theme.appBarIcon, size: 21),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              onSelected: (value) {
                if (value == 'block') {
                  if (session.isBlocked) {
                    _showUnblockDialog(context, session);
                  } else {
                    _showBlockDialog(context, session);
                  }
                }
              },
              itemBuilder: (BuildContext context) {
                final isAr = context.read<ThemeProvider>().isArabic;
                final popTextColor = session.isDarkMode ? Colors.white : Colors.black87;
                final blockText = session.isBlocked 
                    ? (isAr ? 'إلغاء الحظر' : 'Unblock') 
                    : (isAr ? 'حظر' : 'Block');
                return [
                  PopupMenuItem(
                    value: 'block',
                    child: Text(blockText, style: TextStyle(color: popTextColor)),
                  ),
                  PopupMenuItem(
                    value: 'mute',
                    child: Text(isAr ? 'كتم الإشعارات' : 'Mute notifications', style: TextStyle(color: popTextColor)),
                  ),
                  PopupMenuItem(
                    value: 'group',
                    child: Text(isAr ? 'إنشاء مجموعة' : 'Create group', style: TextStyle(color: popTextColor)),
                  ),
                ];
              },
            ),
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
                if (!session.isBlocked && !session.isBlockedMe) ...[
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
          Theme(
            data: Theme.of(context).copyWith(
              cardColor: session.isDarkMode ? const Color(0xFF262626) : Colors.white,
            ),
            child: PopupMenuButton<String>(
              icon: Icon(Icons.info_outline, color: theme.appBarIcon, size: 22),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              onSelected: (value) {
                if (value == 'block') {
                  if (session.isBlocked) {
                    _showUnblockDialog(context, session);
                  } else {
                    _showBlockDialog(context, session);
                  }
                }
              },
              itemBuilder: (BuildContext context) {
                final isAr = context.read<ThemeProvider>().isArabic;
                final popTextColor = session.isDarkMode ? Colors.white : Colors.black87;
                final blockText = session.isBlocked 
                    ? (isAr ? 'إلغاء الحظر' : 'Unblock') 
                    : (isAr ? 'حظر' : 'Block');
                return [
                  PopupMenuItem(
                    value: 'block',
                    child: Text(blockText, style: TextStyle(color: popTextColor)),
                  ),
                  PopupMenuItem(
                    value: 'mute_msg',
                    child: Text(isAr ? 'كتم الرسائل' : 'Mute messages', style: TextStyle(color: popTextColor)),
                  ),
                  PopupMenuItem(
                    value: 'mute_calls',
                    child: Text(isAr ? 'كتم المكالمات' : 'Mute calls', style: TextStyle(color: popTextColor)),
                  ),
                ];
              },
            ),
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
                if (!session.isBlocked && !session.isBlockedMe) ...[
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
          Theme(
            data: Theme.of(context).copyWith(
              cardColor: Colors.white,
            ),
            child: PopupMenuButton<String>(
              icon: const Icon(Icons.more_horiz, color: Colors.black, size: 21),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              onSelected: (value) {
                if (value == 'block') {
                  if (session.isBlocked) {
                    _showUnblockDialog(context, session);
                  } else {
                    _showBlockDialog(context, session);
                  }
                }
              },
              itemBuilder: (BuildContext context) {
                final isAr = context.read<ThemeProvider>().isArabic;
                return [
                  PopupMenuItem(
                    value: 'friendship',
                    child: Text(isAr ? 'إدارة الصداقة' : 'Manage Friendship', style: const TextStyle(color: Colors.black87)),
                  ),
                  PopupMenuItem(
                    value: 'settings',
                    child: Text(isAr ? 'إعدادات الدردشة' : 'Chat Settings', style: const TextStyle(color: Colors.black87)),
                  ),
                  PopupMenuItem(
                    value: 'block',
                    child: Text(
                      session.isBlocked 
                          ? (isAr ? 'إلغاء الحظر' : 'Unblock') 
                          : (isAr ? 'حظر' : 'Block'),
                      style: const TextStyle(color: Colors.black87),
                    ),
                  ),
                ];
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Dialog Helpers ────────────────────────────────────────────────────────────

void _showUnblockDialog(BuildContext context, ChatSession session) {
  final isAr = context.read<ThemeProvider>().isArabic;
  final chatProvider = Provider.of<ChatProvider>(context, listen: false);

  showDialog(
    context: context,
    builder: (ctx) {
      switch (session.platform) {
        case Platform.whatsapp:
          final isDark = session.isDarkMode;
          final Color bg = isDark ? const Color(0xFF2B373E) : Colors.white;
          final Color textCol = isDark ? Colors.white : const Color(0xFF1F2C34);
          final Color actionCol = isDark ? const Color(0xFF00A884) : const Color(0xFF008069);

          return AlertDialog(
            backgroundColor: bg,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
            content: Text(
              isAr ? 'هل تريد إلغاء حظر ${session.contactUser.name}؟' : 'Unblock ${session.contactUser.name}?',
              style: TextStyle(color: textCol, fontSize: 16),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text(
                  isAr ? 'إلغاء' : 'CANCEL',
                  style: TextStyle(color: actionCol, fontWeight: FontWeight.bold),
                ),
              ),
              TextButton(
                onPressed: () {
                  chatProvider.updateSessionSettings(isBlocked: false);
                  Navigator.pop(ctx);
                },
                child: Text(
                  isAr ? 'إلغاء الحظر' : 'UNBLOCK',
                  style: TextStyle(color: actionCol, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          );
        
        case Platform.messenger:
          final isDark = session.isDarkMode;
          final Color bg = isDark ? const Color(0xFF242526) : Colors.white;
          final Color textCol = isDark ? Colors.white : Colors.black;
          final Color subTextCol = isDark ? Colors.white54 : Colors.black54;

          return AlertDialog(
            backgroundColor: bg,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Center(
              child: Text(
                isAr ? 'إلغاء حظر ${session.contactUser.name}؟' : 'Unblock ${session.contactUser.name}?',
                style: TextStyle(color: textCol, fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            content: Text(
              isAr
                  ? 'ستتمكنان من مراسلة والاتصال ببعضكما البعض مجددًا.'
                  : 'You will be able to message and call each other again in this chat.',
              textAlign: TextAlign.center,
              style: TextStyle(color: subTextCol, fontSize: 14),
            ),
            actionsAlignment: MainAxisAlignment.spaceEvenly,
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text(
                  isAr ? 'إلغاء' : 'Cancel',
                  style: const TextStyle(color: Color(0xFF0084FF), fontWeight: FontWeight.w600),
                ),
              ),
              TextButton(
                onPressed: () {
                  chatProvider.updateSessionSettings(isBlocked: false);
                  Navigator.pop(ctx);
                },
                child: Text(
                  isAr ? 'إلغاء الحظر' : 'Unblock',
                  style: const TextStyle(color: Color(0xFF0084FF), fontWeight: FontWeight.bold),
                ),
              ),
            ],
          );

        case Platform.instagram:
          final isDark = session.isDarkMode;
          final Color bg = isDark ? const Color(0xFF262626) : Colors.white;
          final Color textCol = isDark ? Colors.white : Colors.black;
          final Color subTextCol = isDark ? Colors.white54 : Colors.black54;

          return Dialog(
            backgroundColor: bg,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
                  child: Column(
                    children: [
                      Text(
                        isAr ? 'إلغاء حظر ${session.contactUser.name}؟' : 'Unblock ${session.contactUser.name}?',
                        style: TextStyle(color: textCol, fontSize: 18, fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        isAr
                            ? 'سيتمكنون الآن من رؤية منشوراتك ومتابعتك ومراسلتك.'
                            : 'They will now be able to see your posts, follow you, and message you.',
                        style: TextStyle(color: subTextCol, fontSize: 13),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                const Divider(color: Colors.white12, height: 1),
                InkWell(
                  onTap: () {
                    chatProvider.updateSessionSettings(isBlocked: false);
                    Navigator.pop(ctx);
                  },
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    alignment: Alignment.center,
                    child: Text(
                      isAr ? 'إلغاء الحظر' : 'Unblock',
                      style: const TextStyle(color: Color(0xFF0095F6), fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                  ),
                ),
                const Divider(color: Colors.white12, height: 1),
                InkWell(
                  onTap: () => Navigator.pop(ctx),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    alignment: Alignment.center,
                    child: Text(
                      isAr ? 'إلغاء' : 'Cancel',
                      style: TextStyle(color: textCol, fontSize: 14),
                    ),
                  ),
                ),
              ],
            ),
          );

        case Platform.snapchat:
          return AlertDialog(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Center(
              child: Text(
                isAr ? 'إلغاء حظر ${session.contactUser.name}؟' : 'Unblock ${session.contactUser.name}?',
                style: const TextStyle(color: Colors.black, fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            content: Text(
              isAr
                  ? 'هل أنت متأكد أنك تريد إلغاء حظر مستخدم Snapchat هذا؟'
                  : 'Are you sure you want to unblock this Snapchatter?',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.black54, fontSize: 14),
            ),
            actionsAlignment: MainAxisAlignment.spaceEvenly,
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text(
                  isAr ? 'إلغاء' : 'Cancel',
                  style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.w600),
                ),
              ),
              TextButton(
                onPressed: () {
                  chatProvider.updateSessionSettings(isBlocked: false);
                  Navigator.pop(ctx);
                },
                child: Text(
                  isAr ? 'نعم' : 'Yes',
                  style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          );
      }
    },
  );
}

void _showBlockDialog(BuildContext context, ChatSession session) {
  final isAr = context.read<ThemeProvider>().isArabic;
  final chatProvider = Provider.of<ChatProvider>(context, listen: false);

  showDialog(
    context: context,
    builder: (ctx) {
      switch (session.platform) {
        case Platform.whatsapp:
          final isDark = session.isDarkMode;
          final Color bg = isDark ? const Color(0xFF2B373E) : Colors.white;
          final Color textCol = isDark ? Colors.white : const Color(0xFF1F2C34);
          final Color actionCol = isDark ? const Color(0xFF00A884) : const Color(0xFF008069);

          return AlertDialog(
            backgroundColor: bg,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
            title: Text(
              isAr ? 'حظر ${session.contactUser.name}؟' : 'Block ${session.contactUser.name}?',
              style: TextStyle(color: textCol, fontSize: 18, fontWeight: FontWeight.bold),
            ),
            content: Text(
              isAr
                  ? 'لن تتمكن جهة الاتصال المحظورة من الاتصال بك أو إرسال رسائل إليك.'
                  : 'Blocked contacts will no longer be able to call you or send you messages.',
              style: TextStyle(color: isDark ? Colors.white60 : Colors.black54, fontSize: 14),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text(
                  isAr ? 'إلغاء' : 'CANCEL',
                  style: TextStyle(color: actionCol, fontWeight: FontWeight.bold),
                ),
              ),
              TextButton(
                onPressed: () {
                  chatProvider.updateSessionSettings(isBlocked: true);
                  Navigator.pop(ctx);
                },
                child: Text(
                  isAr ? 'حظر' : 'BLOCK',
                  style: TextStyle(color: actionCol, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          );

        case Platform.messenger:
          final isDark = session.isDarkMode;
          final Color bg = isDark ? const Color(0xFF242526) : Colors.white;
          final Color textCol = isDark ? Colors.white : Colors.black;
          final Color subTextCol = isDark ? Colors.white54 : Colors.black54;

          return AlertDialog(
            backgroundColor: bg,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Center(
              child: Text(
                isAr ? 'حظر ${session.contactUser.name}؟' : 'Block ${session.contactUser.name}?',
                style: TextStyle(color: textCol, fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            content: Text(
              isAr
                  ? 'لن تتمكنا من مراسلة أو الاتصال ببعضكما البعض.'
                  : 'You will not be able to message or call each other.',
              textAlign: TextAlign.center,
              style: TextStyle(color: subTextCol, fontSize: 14),
            ),
            actionsAlignment: MainAxisAlignment.spaceEvenly,
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text(
                  isAr ? 'إلغاء' : 'Cancel',
                  style: const TextStyle(color: Color(0xFF0084FF), fontWeight: FontWeight.w600),
                ),
              ),
              TextButton(
                onPressed: () {
                  chatProvider.updateSessionSettings(isBlocked: true);
                  Navigator.pop(ctx);
                },
                child: Text(
                  isAr ? 'حظر' : 'Block',
                  style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          );

        case Platform.instagram:
          final isDark = session.isDarkMode;
          final Color bg = isDark ? const Color(0xFF262626) : Colors.white;
          final Color textCol = isDark ? Colors.white : Colors.black;
          final Color subTextCol = isDark ? Colors.white54 : Colors.black54;

          return Dialog(
            backgroundColor: bg,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
                  child: Column(
                    children: [
                      Text(
                        isAr ? 'حظر ${session.contactUser.name}؟' : 'Block ${session.contactUser.name}?',
                        style: TextStyle(color: textCol, fontSize: 18, fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        isAr
                            ? 'لن يتمكنوا من مراسلتك أو العثور على ملفك الشخصي أو محتواك.'
                            : 'They won\'t be able to message you, or find your profile or content on Instagram.',
                        style: TextStyle(color: subTextCol, fontSize: 13),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                const Divider(color: Colors.white12, height: 1),
                InkWell(
                  onTap: () {
                    chatProvider.updateSessionSettings(isBlocked: true);
                    Navigator.pop(ctx);
                  },
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    alignment: Alignment.center,
                    child: Text(
                      isAr ? 'حظر' : 'Block',
                      style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                  ),
                ),
                const Divider(color: Colors.white12, height: 1),
                InkWell(
                  onTap: () => Navigator.pop(ctx),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    alignment: Alignment.center,
                    child: Text(
                      isAr ? 'إلغاء' : 'Cancel',
                      style: TextStyle(color: textCol, fontSize: 14),
                    ),
                  ),
                ),
              ],
            ),
          );

        case Platform.snapchat:
          return AlertDialog(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Center(
              child: Text(
                isAr ? 'حظر ${session.contactUser.name}؟' : 'Block ${session.contactUser.name}?',
                style: const TextStyle(color: Colors.black, fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            content: Text(
              isAr
                  ? 'هل أنت متأكد أنك تريد حظر مستخدم Snapchat هذا؟'
                  : 'Are you sure you want to block this Snapchatter?',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.black54, fontSize: 14),
            ),
            actionsAlignment: MainAxisAlignment.spaceEvenly,
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text(
                  isAr ? 'إلغاء' : 'Cancel',
                  style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.w600),
                ),
              ),
              TextButton(
                onPressed: () {
                  chatProvider.updateSessionSettings(isBlocked: true);
                  Navigator.pop(ctx);
                },
                child: Text(
                  isAr ? 'حظر' : 'Block',
                  style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          );
      }
    },
  );
}
