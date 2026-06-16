import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/chat_models.dart';
import '../themes/platform_themes.dart';
import '../widgets/message_bubble.dart';
import '../widgets/fake_status_bar.dart';
import '../widgets/platform_app_bar.dart';
import '../widgets/platform_input_bar.dart';
import '../providers/theme_provider.dart';
import '../providers/chat_provider.dart';
import '../utils/language_helper.dart';

class ChatViewport extends StatelessWidget {
  final ChatSession session;
  final PlatformTheme platformTheme;

  const ChatViewport({
    super.key,
    required this.session,
    required this.platformTheme,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: platformTheme.chatBg,
      child: Column(
        children: [
          // Fake system status bar
          FakeStatusBar(
            time: session.fakeTime,
            battery: session.fakeBattery,
            hasWifi: session.fakeWifi,
            backgroundColor: platformTheme.statusBarBg,
            isLight: _isLightBar(session.platform, session.isDarkMode),
          ),
          // Platform-specific app bar
          PlatformAppBar(
            session: session,
            platformTheme: platformTheme,
          ),
          // Chat messages area
          Expanded(
            child: _buildChatArea(context),
          ),
          // Platform input bar (bottom)
          PlatformInputBar(
            platform: session.platform,
            platformTheme: platformTheme,
          ),
        ],
      ),
    );
  }

  bool _isLightBar(Platform p, bool isDark) {
    if (isDark) return true;
    return p == Platform.whatsapp;
  }

  Widget _buildChatArea(BuildContext context) {
    final messages = session.messages;
    final bool isAr = context.read<ThemeProvider>().isArabic;

    return _buildBackground(
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
        itemCount: _countWithDateDividers(messages, isAr),
        itemBuilder: (context, index) {
          return _buildListItem(context, index, messages, isAr);
        },
      ),
    );
  }

  Widget _buildBackground({required Widget child}) {
    if (session.platform == Platform.whatsapp) {
      final Color bg = session.isDarkMode ? const Color(0xFF0B141A) : const Color(0xFFECE5DD);
      final Color doodleColor = session.isDarkMode
          ? Colors.white.withValues(alpha: 0.018)
          : Colors.black.withValues(alpha: 0.038);

      return Container(
        color: bg,
        child: CustomPaint(
          painter: WhatsAppWallpaperPainter(color: doodleColor),
          child: child,
        ),
      );
    }
    return ColoredBox(
      color: platformTheme.chatBg,
      child: child,
    );
  }

  int _countWithDateDividers(List<ChatMessage> messages, bool isAr) {
    // Add 1 for the scrollable _ProfileHeaderCard at visualIndex 0!
    int count = 1;
    final bool hasWhatsAppBlockCard = session.platform == Platform.whatsapp && session.isBlocked;
    
    if (messages.isEmpty) return count + (hasWhatsAppBlockCard ? 1 : 0);

    final bool hasManualDateDividers = messages.any((m) => m.type == MessageType.dateDivider);
    if (hasManualDateDividers) {
      return count + messages.length + (hasWhatsAppBlockCard ? 1 : 0);
    }

    final bool isMessengerOrInstagram = session.platform == Platform.messenger || session.platform == Platform.instagram;

    count += messages.length;
    
    if (isMessengerOrInstagram) {
      // First message always has a time separator
      count++;
      for (int i = 1; i < messages.length; i++) {
        final prev = messages[i - 1];
        final curr = messages[i];
        if (curr.timestamp.difference(prev.timestamp).abs() > const Duration(minutes: 15)) {
          count++;
        }
      }
    } else {
      String? lastDate;
      for (final m in messages) {
        final dateStr = _dateLabel(m.timestamp, isAr);
        if (dateStr != lastDate) {
          count++;
          lastDate = dateStr;
        }
      }
    }
    return count + (hasWhatsAppBlockCard ? 1 : 0);
  }

  Widget _buildListItem(BuildContext context, int visualIndex, List<ChatMessage> messages, bool isAr) {
    // Index 0 is always the large profile chat banner header
    if (visualIndex == 0) {
      return _ProfileHeaderCard(session: session, platformTheme: platformTheme);
    }

    final bool hasWhatsAppBlockCard = session.platform == Platform.whatsapp && session.isBlocked;
    if (hasWhatsAppBlockCard && visualIndex == _countWithDateDividers(messages, isAr) - 1) {
      return _buildWhatsAppBlockedSystemCard(context);
    }

    // Offset standard message processing by -1
    final int adjustedIndex = visualIndex - 1;

    final bool hasManualDateDividers = messages.any((m) => m.type == MessageType.dateDivider);

    if (hasManualDateDividers) {
      final msg = messages[adjustedIndex];
      if (msg.type == MessageType.dateDivider) {
        return _DateDivider(
          label: msg.text,
          platform: session.platform,
          platformTheme: platformTheme,
        );
      }

      int prevRealIdx = adjustedIndex - 1;
      while (prevRealIdx >= 0 && messages[prevRealIdx].type == MessageType.dateDivider) {
        prevRealIdx--;
      }
      final prevMsg = prevRealIdx >= 0 ? messages[prevRealIdx] : null;

      int nextRealIdx = adjustedIndex + 1;
      while (nextRealIdx < messages.length && messages[nextRealIdx].type == MessageType.dateDivider) {
        nextRealIdx++;
      }
      final nextMsg = nextRealIdx < messages.length ? messages[nextRealIdx] : null;

      final bool isFirstInGroup = prevMsg == null || prevMsg.isSender != msg.isSender;
      final bool isLastInGroup = nextMsg == null || nextMsg.isSender != msg.isSender;

      return MessageBubble(
        message: msg,
        contactUser: session.contactUser,
        platform: session.platform,
        platformTheme: platformTheme,
        isFirstInGroup: isFirstInGroup,
        isLastInGroup: isLastInGroup,
        isBlockedMe: session.isBlockedMe,
      );
    }

    final bool isMessengerOrInstagram = session.platform == Platform.messenger || session.platform == Platform.instagram;
    int counter = 0;

    if (isMessengerOrInstagram) {
      for (int i = 0; i < messages.length; i++) {
        final msg = messages[i];
        final bool showSeparatorBefore = i == 0 || 
            msg.timestamp.difference(messages[i - 1].timestamp).abs() > const Duration(minutes: 15);

        if (showSeparatorBefore) {
          if (counter == adjustedIndex) {
            return _DateDivider(
              label: _formatDateTimeSeparator(msg.timestamp, isAr),
              platform: session.platform,
              platformTheme: platformTheme,
            );
          }
          counter++;
        }

        if (counter == adjustedIndex) {
          final prevMsg = i > 0 ? messages[i - 1] : null;
          final nextMsg = i < messages.length - 1 ? messages[i + 1] : null;

          // Split consecutive bubble grouping on >15 min time gaps
          final bool isNewTimeGroup = prevMsg == null || 
              msg.timestamp.difference(prevMsg.timestamp).abs() > const Duration(minutes: 15);
          final bool isNextTimeGroup = nextMsg == null || 
              nextMsg.timestamp.difference(msg.timestamp).abs() > const Duration(minutes: 15);

          final bool isFirstInGroup = isNewTimeGroup || prevMsg.isSender != msg.isSender;
          final bool isLastInGroup = isNextTimeGroup || nextMsg.isSender != msg.isSender;

          return MessageBubble(
            message: msg,
            contactUser: session.contactUser,
            platform: session.platform,
            platformTheme: platformTheme,
            isFirstInGroup: isFirstInGroup,
            isLastInGroup: isLastInGroup,
            isBlockedMe: session.isBlockedMe,
          );
        }
        counter++;
      }
    } else {
      String? lastDate;
      for (int i = 0; i < messages.length; i++) {
        final msg = messages[i];
        final dateStr = _dateLabel(msg.timestamp, isAr);

        if (dateStr != lastDate) {
          if (counter == adjustedIndex) {
            return _DateDivider(
              label: dateStr,
              platform: session.platform,
              platformTheme: platformTheme,
            );
          }
          counter++;
          lastDate = dateStr;
        }

        if (counter == adjustedIndex) {
          final prevMsg = i > 0 ? messages[i - 1] : null;
          final nextMsg = i < messages.length - 1 ? messages[i + 1] : null;

          final bool isNewDateGroup = prevMsg == null || _dateLabel(prevMsg.timestamp, isAr) != _dateLabel(msg.timestamp, isAr);
          final bool isNextDateGroup = nextMsg == null || _dateLabel(nextMsg.timestamp, isAr) != _dateLabel(msg.timestamp, isAr);

          final bool isFirstInGroup = isNewDateGroup || prevMsg.isSender != msg.isSender;
          final bool isLastInGroup = isNextDateGroup || nextMsg.isSender != msg.isSender;

          return MessageBubble(
            message: msg,
            contactUser: session.contactUser,
            platform: session.platform,
            platformTheme: platformTheme,
            isFirstInGroup: isFirstInGroup,
            isLastInGroup: isLastInGroup,
            isBlockedMe: session.isBlockedMe,
          );
        }
        counter++;
      }
    }

    return const SizedBox.shrink();
  }

  String _dateLabel(DateTime dt, bool isArabic) {
    final now = DateTime.now();
    final isToday = dt.year == now.year && dt.month == now.month && dt.day == now.day;
    if (isToday) return LanguageHelper.translate('today', isArabic);
    final yesterday = now.subtract(const Duration(days: 1));
    final isYesterday = dt.year == yesterday.year && dt.month == yesterday.month && dt.day == yesterday.day;
    if (isYesterday) return LanguageHelper.translate('yesterday', isArabic);
    return '${dt.day}/${dt.month}/${dt.year}';
  }

  String _formatDateTimeSeparator(DateTime dt, bool isArabic) {
    final now = DateTime.now();
    
    // Check if same day
    final isToday = dt.year == now.year && dt.month == now.month && dt.day == now.day;
    
    final yesterday = now.subtract(const Duration(days: 1));
    final isYesterday = dt.year == yesterday.year && dt.month == yesterday.month && dt.day == yesterday.day;
    
    final timeStr = _formatTimeOnly(dt, isArabic);
    
    if (isToday) {
      return timeStr;
    }
    
    final comma = isArabic ? '، ' : ', ';
    
    if (isYesterday) {
      return '${LanguageHelper.translate('yesterday', isArabic)}$comma$timeStr';
    }
    
    final diffDays = now.difference(dt).inDays;
    if (diffDays < 7) {
      final weekdays = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
      final weekday = weekdays[dt.weekday - 1];
      return '${LanguageHelper.translate(weekday.toLowerCase(), isArabic)}$comma$timeStr';
    }
    
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final month = months[dt.month - 1];
    if (isArabic) {
      return '${dt.day} ${LanguageHelper.translate(month.toLowerCase(), isArabic)}$comma${dt.year}$comma$timeStr';
    }
    return '$month ${dt.day}, ${dt.year}, $timeStr';
  }

  String _formatTimeOnly(DateTime dt, bool isArabic) {
    final hour = dt.hour;
    final minute = dt.minute.toString().padLeft(2, '0');
    final period = hour >= 12 
        ? (isArabic ? 'م' : 'PM') 
        : (isArabic ? 'ص' : 'AM');
    final formattedHour = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
    return '$formattedHour:$minute $period';
  }

  Widget _buildWhatsAppBlockedSystemCard(BuildContext context) {
    final isDark = session.isDarkMode;
    final isAr = context.read<ThemeProvider>().isArabic;
    final Color cardBg = isDark ? const Color(0xFF182229) : const Color(0xFFFFEECD);
    final Color textCol = isDark ? const Color(0xFF8696A0) : const Color(0xFF54656F);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: Center(
        child: InkWell(
          onTap: () => _showUnblockDialog(context, session),
          borderRadius: BorderRadius.circular(10),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: isDark ? Colors.transparent : const Color(0xFFF0E0C0), width: 0.8),
            ),
            child: Text(
              isAr ? 'لقد حظرت جهة الاتصال هذه. انقر لإلغاء الحظر.' : 'You blocked this contact. Tap to unblock.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: textCol,
                fontSize: 11.5,
                height: 1.35,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DateDivider extends StatelessWidget {
  final String label;
  final Platform platform;
  final PlatformTheme platformTheme;

  const _DateDivider({
    required this.label,
    required this.platform,
    required this.platformTheme,
  });

  @override
  Widget build(BuildContext context) {
    final isAr = Provider.of<ThemeProvider>(context).isArabic;
    final displayLabel = LanguageHelper.translateDate(label, isAr);

    if (platform == Platform.whatsapp) {
      final Color bg = platformTheme.chatBg == Colors.black ||
              platformTheme.chatBg.toARGB32() ==
                  const Color(0xFF0B141A).toARGB32()
          ? const Color(0xFF182229)
          : const Color(0xFFE1F3FC);
      final Color textCol = platformTheme.chatBg == Colors.black ||
              platformTheme.chatBg.toARGB32() ==
                  const Color(0xFF0B141A).toARGB32()
          ? const Color(0xFF8696A0)
          : const Color(0xFF536A75);

      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 1,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: Text(
              displayLabel.toUpperCase(),
              style: TextStyle(
                color: textCol,
                fontSize: 11,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ),
      );
    }

    // Messenger, Instagram, Snapchat minimal date text
    final double letterSpacing = platform == Platform.instagram ? 0.8 : 0.4;
    final fontWeight = platform == Platform.messenger ? FontWeight.w600 : FontWeight.w500;
    final isDarkBg = platformTheme.chatBg == Colors.black ||
        platformTheme.chatBg.toARGB32() == const Color(0xFF000000).toARGB32() ||
        platformTheme.chatBg.toARGB32() == const Color(0xFF0B0C0E).toARGB32();
    final textCol = isDarkBg ? Colors.white38 : Colors.grey[500];

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Center(
        child: Text(
          displayLabel.toUpperCase(),
          style: TextStyle(
            color: textCol,
            fontSize: 11.5,
            fontWeight: fontWeight,
            letterSpacing: letterSpacing,
          ),
        ),
      ),
    );
  }
}

// ─── First-Time Profile Header Banner Card ──────────────────────────────────────

class _ProfileHeaderCard extends StatelessWidget {
  final ChatSession session;
  final PlatformTheme platformTheme;

  const _ProfileHeaderCard({required this.session, required this.platformTheme});

  @override
  Widget build(BuildContext context) {
    final user = session.contactUser;
    final isDark = session.isDarkMode;

    if (session.platform == Platform.whatsapp) {
      // Centered WhatsApp encryption log pill card
      final String text = session.contactBio ?? 'Messages and calls are end-to-end encrypted. No one outside of this chat, not even WhatsApp, can read or listen to them. Tap to learn more.';
      final Color cardBg = isDark ? const Color(0xFF182229) : const Color(0xFFFFEECD);
      final Color textCol = isDark ? const Color(0xFF8696A0) : const Color(0xFF54656F);
      final Color lockCol = isDark ? const Color(0xFF00A884) : const Color(0xFF54656F);

      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: isDark ? Colors.transparent : const Color(0xFFF0E0C0), width: 0.8),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.lock, size: 13, color: lockCol),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  text,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: textCol,
                    fontSize: 11.5,
                    height: 1.35,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (session.platform == Platform.messenger) {
      // Centered Messenger Profile Card
      final String bioText = session.contactBio ?? 'Active on Facebook';
      final String subBioText = session.contactSubBio ?? "You're friends on Facebook";
      final textCol = isDark ? Colors.white : Colors.black;
      final descCol = isDark ? Colors.white38 : Colors.black38;
      final btnBg = isDark ? const Color(0xFF242526) : const Color(0xFFF0F0F0);
      final btnText = isDark ? Colors.white : Colors.black;

      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Column(
          children: [
            if (user.avatarBytes != null)
              CircleAvatar(radius: 40, backgroundImage: MemoryImage(user.avatarBytes!))
            else
              CircleAvatar(
                radius: 40,
                backgroundColor:
                    platformTheme.appBarIcon.withValues(alpha: 0.18),
                child: Text(
                  user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
                  style: TextStyle(color: platformTheme.appBarIcon, fontWeight: FontWeight.bold, fontSize: 32),
                ),
              ),
            const SizedBox(height: 12),
            Text(
              user.name,
              style: TextStyle(color: textCol, fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              bioText,
              style: TextStyle(color: descCol, fontSize: 13),
            ),
            const SizedBox(height: 2),
            Text(
              subBioText,
              style: TextStyle(color: descCol, fontSize: 12.5),
            ),
            const SizedBox(height: 12),
            GestureDetector(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
                decoration: BoxDecoration(
                  color: btnBg,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'View Profile',
                  style: TextStyle(color: btnText, fontSize: 13.5, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      );
    }

    if (session.platform == Platform.instagram) {
      // Centered Instagram DM Profile Card
      final String bioText = session.contactBio ?? '1.2M followers • 420 posts';
      final String subBioText = session.contactSubBio ?? 'You follow each other on Instagram';
      final textCol = isDark ? Colors.white : Colors.black;
      final descCol = isDark ? Colors.white38 : Colors.black38;
      final btnBg = isDark ? const Color(0xFF262626) : const Color(0xFFEFEFEF);
      final btnText = isDark ? Colors.white : Colors.black;

      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 28),
        child: Column(
          children: [
            // Instagram-style story ring
            Container(
              padding: const EdgeInsets.all(2),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFFC32E96), Color(0xFFFCAF45)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
              ),
              child: Container(
                padding: const EdgeInsets.all(2.5),
                decoration: BoxDecoration(
                  color: isDark ? Colors.black : Colors.white,
                  shape: BoxShape.circle,
                ),
                child: user.avatarBytes != null
                    ? CircleAvatar(radius: 36, backgroundImage: MemoryImage(user.avatarBytes!))
                    : CircleAvatar(
                        radius: 36,
                        backgroundColor:
                            const Color(0xFFE1306C).withValues(alpha: 0.18),
                        child: const Text('?', style: TextStyle(color: Color(0xFFE1306C), fontSize: 24)),
                      ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              user.name,
              style: TextStyle(color: textCol, fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: -0.2),
            ),
            const SizedBox(height: 4),
            Text(
              bioText,
              style: TextStyle(color: descCol, fontSize: 13),
            ),
            const SizedBox(height: 2),
            Text(
              subBioText,
              style: TextStyle(color: descCol, fontSize: 12.5),
            ),
            const SizedBox(height: 14),
            GestureDetector(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
                decoration: BoxDecoration(
                  color: btnBg,
                  borderRadius: BorderRadius.circular(8),
                  border: isDark ? null : Border.all(color: const Color(0xFFDBDBDB), width: 0.8),
                ),
                child: Text(
                  'View Profile',
                  style: TextStyle(color: btnText, fontSize: 13, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      );
    }

    if (session.platform == Platform.snapchat) {
      // Centered Snapchat Profile Card
      final String bioText = session.contactBio ?? 'You are friends! Say hi.';
      final textCol = isDark ? Colors.white : Colors.black;
      final descCol = isDark ? Colors.white38 : Colors.black38;

      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Column(
          children: [
            if (user.avatarBytes != null)
              CircleAvatar(radius: 36, backgroundImage: MemoryImage(user.avatarBytes!))
            else
              CircleAvatar(
                radius: 36,
                backgroundColor: const Color(0xFFFFFC00).withValues(alpha: 0.2),
                child: const Icon(Icons.face_rounded, color: Colors.black54, size: 40),
              ),
            const SizedBox(height: 12),
            Text(
              user.name,
              style: TextStyle(color: textCol, fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Text(
              bioText,
              style: TextStyle(color: descCol, fontSize: 13, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      );
    }

    return const SizedBox.shrink();
  }

}

void _showUnblockDialog(BuildContext context, ChatSession session) {
  final isAr = context.read<ThemeProvider>().isArabic;
  final chatProvider = Provider.of<ChatProvider>(context, listen: false);

  showDialog(
    context: context,
    builder: (ctx) {
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
    },
  );
}

// ─── WhatsApp Wallpaper Painter ──────────────────────────────────────────────────

class WhatsAppWallpaperPainter extends CustomPainter {
  final Color color;
  WhatsAppWallpaperPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    // Grid size to distribute elements uniformly across the screen
    final double stepX = 90;
    final double stepY = 90;

    for (double x = 30; x < size.width; x += stepX) {
      for (double y = 40; y < size.height; y += stepY) {
        final cellIndex = ((x / stepX).floor() + (y / stepY).floor()) % 6;
        canvas.save();
        canvas.translate(x, y);

        switch (cellIndex) {
          case 0:
            // Telephone outline
            final path = Path()
              ..moveTo(-6, -3)
              ..quadraticBezierTo(-3, -6, 0, -6)
              ..quadraticBezierTo(3, -6, 6, -3)
              ..lineTo(4, 0)
              ..lineTo(2, -1)
              ..quadraticBezierTo(0, 1, -2, -1)
              ..lineTo(-4, 0)
              ..close();
            canvas.drawPath(path, paint);
            break;
          case 1:
            // Star
            final path = Path()
              ..moveTo(0, -6)
              ..lineTo(2, -2)
              ..lineTo(6, -2)
              ..lineTo(3, 1)
              ..lineTo(4, 5)
              ..lineTo(0, 3)
              ..lineTo(-4, 5)
              ..lineTo(-3, 1)
              ..lineTo(-6, -2)
              ..lineTo(-2, -2)
              ..close();
            canvas.drawPath(path, paint);
            break;
          case 2:
            // Heart
            final path = Path()
              ..moveTo(0, 4)
              ..cubicTo(-4, 1, -6, -2, -6, -4)
              ..cubicTo(-6, -6, -3, -8, 0, -4)
              ..cubicTo(3, -8, 6, -6, 6, -4)
              ..cubicTo(6, -2, 4, 1, 0, 4);
            canvas.drawPath(path, paint);
            break;
          case 3:
            // Cloud
            final path = Path()
              ..moveTo(-5, 2)
              ..quadraticBezierTo(-7, 0, -5, -2)
              ..quadraticBezierTo(-4, -5, 0, -4)
              ..quadraticBezierTo(4, -5, 4, -2)
              ..quadraticBezierTo(6, 0, 4, 2)
              ..close();
            canvas.drawPath(path, paint);
            break;
          case 4:
            // Chat bubble
            final path = Path()
              ..moveTo(-5, -4)
              ..lineTo(5, -4)
              ..lineTo(5, 2)
              ..lineTo(1, 2)
              ..lineTo(-2, 5)
              ..lineTo(-2, 2)
              ..lineTo(-5, 2)
              ..close();
            canvas.drawPath(path, paint);
            break;
          case 5:
            // Music note
            final path = Path()
              ..moveTo(-2, 3)
              ..addOval(Rect.fromCircle(center: const Offset(-4, 3), radius: 2.2))
              ..moveTo(-1.5, 3)
              ..lineTo(-1.5, -4)
              ..lineTo(4, -2)
              ..lineTo(4, 4)
              ..addOval(Rect.fromCircle(center: const Offset(2, 4), radius: 2.2));
            canvas.drawPath(path, paint);
            break;
        }
        canvas.restore();
      }
    }
  }

  @override
  bool shouldRepaint(covariant WhatsAppWallpaperPainter oldDelegate) => false;
}
