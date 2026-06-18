import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/chat_models.dart';
import '../themes/platform_themes.dart';
import '../providers/theme_provider.dart';
import '../providers/chat_provider.dart';

class PlatformInputBar extends StatelessWidget {
  final Platform platform;
  final PlatformTheme platformTheme;

  const PlatformInputBar({
    super.key,
    required this.platform,
    required this.platformTheme,
  });

  @override
  Widget build(BuildContext context) {
    final isArabic = context.watch<ThemeProvider>().isArabic;
    final chatProvider = context.watch<ChatProvider>();
    final session = chatProvider.activeSession;

    if (session != null) {
      if (session.isBlocked) {
        return _BlockedInputBar(session: session, theme: platformTheme);
      }
      if (session.isBlockedMe && (platform == Platform.messenger || platform == Platform.instagram)) {
        return _TheyBlockedMeInputBar(session: session, theme: platformTheme);
      }
    }

    switch (platform) {
      case Platform.whatsapp:
        return _WhatsAppInput(theme: platformTheme, isArabic: isArabic);
      case Platform.messenger:
        return _MessengerInput(theme: platformTheme, isArabic: isArabic);
      case Platform.instagram:
        return _InstagramInput(theme: platformTheme, isArabic: isArabic);
      case Platform.snapchat:
        return _SnapchatInput(theme: platformTheme, isArabic: isArabic);
    }
  }
}

// ─── WhatsApp Input ────────────────────────────────────────────────────────────

class _WhatsAppInput extends StatelessWidget {
  final PlatformTheme theme;
  final bool isArabic;
  const _WhatsAppInput({required this.theme, required this.isArabic});

  @override
  Widget build(BuildContext context) {
    final iconColor = theme.chatBg == const Color(0xFF0B141A)
        ? const Color(0xFF8696A0)
        : const Color(0xFF667781);
    final hintText = isArabic ? 'مراسلة' : 'Message';

    // In RTL mode mic goes left, emoji goes right
    final micButton = Container(
      width: 46,
      height: 46,
      decoration: BoxDecoration(
        color: theme.sendButtonColor,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 1,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: const Icon(Icons.mic, color: Colors.white, size: 23),
    );

    final chatProvider = context.watch<ChatProvider>();
    final String currentText = chatProvider.simulatedTypingText ?? hintText;
    final Color currentTextColor = chatProvider.simulatedTypingText != null
        ? (theme.chatBg == const Color(0xFF0B141A) ? Colors.white : Colors.black87)
        : iconColor;

    final inputField = Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: theme.inputFieldBg,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 1,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Row(
          children: isArabic
              ? [
                  // RTL: attach + camera on the left, emoji on the right
                  Icon(Icons.camera_alt_rounded, color: iconColor, size: 23),
                  const SizedBox(width: 8),
                  Transform.rotate(
                    angle: 0.7,
                    child: Icon(Icons.attach_file, color: iconColor, size: 23),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      currentText,
                      textAlign: TextAlign.right,
                      style: TextStyle(color: currentTextColor, fontSize: 16),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(Icons.emoji_emotions_outlined,
                      color: iconColor, size: 24),
                ]
              : [
                  // LTR: emoji on the left, attach + camera on the right
                  Icon(Icons.emoji_emotions_outlined,
                      color: iconColor, size: 24),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      currentText,
                      style: TextStyle(color: currentTextColor, fontSize: 16),
                    ),
                  ),
                  Transform.rotate(
                    angle: -0.7,
                    child: Icon(Icons.attach_file, color: iconColor, size: 23),
                  ),
                  const SizedBox(width: 12),
                  Icon(Icons.camera_alt_rounded, color: iconColor, size: 23),
                  const SizedBox(width: 4),
                ],
        ),
      ),
    );

    return Container(
      color: theme.inputBarBg,
      padding: const EdgeInsets.fromLTRB(6, 4, 6, 8),
      child: Row(
        children: isArabic
            ? [micButton, const SizedBox(width: 6), inputField]
            : [inputField, const SizedBox(width: 6), micButton],
      ),
    );
  }
}

// ─── Messenger Input ──────────────────────────────────────────────────────────

class _MessengerInput extends StatelessWidget {
  final PlatformTheme theme;
  final bool isArabic;
  const _MessengerInput({required this.theme, required this.isArabic});

  @override
  Widget build(BuildContext context) {
    final isDark = theme.chatBg == Colors.black ||
        theme.chatBg.toARGB32() == const Color(0xFF000000).toARGB32();
    final borderColor =
        isDark ? const Color(0xFF3A3B3C) : const Color(0xFFECECEC);

    final chatProvider = context.watch<ChatProvider>();
    final String currentText = chatProvider.simulatedTypingText ?? 'Aa';
    final Color currentTextColor = chatProvider.simulatedTypingText != null
        ? (isDark ? Colors.white : Colors.black87)
        : (isDark ? Colors.white38 : const Color(0xFF8E8E93));

    return Container(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 12),
      decoration: BoxDecoration(
        color: theme.inputBarBg,
        border: Border(top: BorderSide(color: borderColor, width: 0.8)),
      ),
      child: Row(
        children: isArabic
            ? [
                IconButton(
                  icon: Icon(Icons.thumb_up,
                      color: theme.sendButtonColor, size: 23),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: () {},
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: theme.inputFieldBg,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      currentText,
                      textAlign: TextAlign.right,
                      style: TextStyle(
                        color: currentTextColor,
                        fontSize: 15,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                IconButton(
                  icon: Icon(Icons.mic, color: theme.sendButtonColor, size: 23),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: () {},
                ),
                const SizedBox(width: 12),
                IconButton(
                  icon: Icon(Icons.image_rounded,
                      color: theme.sendButtonColor, size: 23),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: () {},
                ),
                const SizedBox(width: 12),
                IconButton(
                  icon: Icon(Icons.camera_alt,
                      color: theme.sendButtonColor, size: 23),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: () {},
                ),
                const SizedBox(width: 12),
                IconButton(
                  icon: Icon(Icons.add_circle,
                      color: theme.sendButtonColor, size: 24),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: () {},
                ),
              ]
            : [
                IconButton(
                  icon: Icon(Icons.add_circle,
                      color: theme.sendButtonColor, size: 24),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: () {},
                ),
                const SizedBox(width: 12),
                IconButton(
                  icon: Icon(Icons.camera_alt,
                      color: theme.sendButtonColor, size: 23),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: () {},
                ),
                const SizedBox(width: 12),
                IconButton(
                  icon: Icon(Icons.image_rounded,
                      color: theme.sendButtonColor, size: 23),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: () {},
                ),
                const SizedBox(width: 12),
                IconButton(
                  icon: Icon(Icons.mic, color: theme.sendButtonColor, size: 23),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: () {},
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: theme.inputFieldBg,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      currentText,
                      style: TextStyle(
                        color: currentTextColor,
                        fontSize: 15,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                IconButton(
                  icon: Icon(Icons.thumb_up,
                      color: theme.sendButtonColor, size: 23),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: () {},
                ),
              ],
      ),
    );
  }
}

// ─── Instagram Input ──────────────────────────────────────────────────────────

class _InstagramInput extends StatelessWidget {
  final PlatformTheme theme;
  final bool isArabic;
  const _InstagramInput({required this.theme, required this.isArabic});

  @override
  Widget build(BuildContext context) {
    final isDark = theme.chatBg == Colors.black ||
        theme.chatBg.toARGB32() == const Color(0xFF000000).toARGB32();
    final borderColor =
        isDark ? const Color(0xFF363636) : const Color(0xFFF2F2F2);
    final hintText = isArabic ? 'رسالة...' : 'Message...';
    final iconColor = isDark ? Colors.white54 : Colors.black54;
    final fieldBorderColor =
        isDark ? const Color(0xFF363636) : const Color(0xFFE2E2E2);

    final gradientCamera = Container(
      width: 32,
      height: 32,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFC32E96), Color(0xFF9035B9), Color(0xFF4A55D6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        shape: BoxShape.circle,
      ),
      child: const Center(
        child: Icon(Icons.camera_alt, color: Colors.white, size: 16),
      ),
    );

    final chatProvider = context.watch<ChatProvider>();
    final String currentText = chatProvider.simulatedTypingText ?? hintText;
    final Color currentTextColor = chatProvider.simulatedTypingText != null
        ? (isDark ? Colors.white : Colors.black87)
        : (isDark ? Colors.white38 : const Color(0xFF999999));

    return Container(
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 14),
      decoration: BoxDecoration(
        color: theme.inputBarBg,
        border: Border(top: BorderSide(color: borderColor, width: 0.8)),
      ),
      child: Row(
        children: isArabic
            ? [
                Expanded(
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      border: Border.all(color: fieldBorderColor, width: 1.0),
                      borderRadius: BorderRadius.circular(22),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.favorite_border, color: iconColor, size: 20),
                        const SizedBox(width: 8),
                        Icon(Icons.image_outlined, color: iconColor, size: 20),
                        const SizedBox(width: 8),
                        Icon(Icons.mic_none_outlined,
                            color: iconColor, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            currentText,
                            textAlign: TextAlign.right,
                            style: TextStyle(
                              color: currentTextColor,
                              fontSize: 14.5,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(Icons.sentiment_satisfied_alt_rounded,
                            color: iconColor, size: 20),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                gradientCamera,
              ]
            : [
                gradientCamera,
                const SizedBox(width: 10),
                Expanded(
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      border: Border.all(color: fieldBorderColor, width: 1.0),
                      borderRadius: BorderRadius.circular(22),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.sentiment_satisfied_alt_rounded,
                            color: iconColor, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            currentText,
                            style: TextStyle(
                              color: currentTextColor,
                              fontSize: 14.5,
                            ),
                          ),
                        ),
                        Icon(Icons.mic_none_outlined,
                            color: iconColor, size: 20),
                        const SizedBox(width: 8),
                        Icon(Icons.image_outlined, color: iconColor, size: 20),
                        const SizedBox(width: 8),
                        Icon(Icons.favorite_border, color: iconColor, size: 20),
                      ],
                    ),
                  ),
                ),
              ],
      ),
    );
  }
}

// ─── Snapchat Input ───────────────────────────────────────────────────────────

class _SnapchatInput extends StatelessWidget {
  final PlatformTheme theme;
  final bool isArabic;
  const _SnapchatInput({required this.theme, required this.isArabic});

  @override
  Widget build(BuildContext context) {
    final isDark =
        theme.chatBg.toARGB32() == const Color(0xFF0B0C0E).toARGB32();
    final bgColor = isDark ? const Color(0xFF0B0C0E) : Colors.white;
    final borderColor =
        isDark ? const Color(0xFF2A2A2A) : const Color(0xFFF2F2F2);
    final fieldBg = isDark ? const Color(0xFF1F2024) : const Color(0xFFF1F1F2);
    final textColor = isDark ? Colors.white54 : const Color(0xFF656667);
    final hintText = isArabic ? 'أرسل رسالة' : 'Send a chat';
    final iconBorderColor = isDark ? Colors.white54 : Colors.black87;

    final chatProvider = context.watch<ChatProvider>();
    final String currentText = chatProvider.simulatedTypingText ?? hintText;
    final Color currentTextColor = chatProvider.simulatedTypingText != null
        ? (isDark ? Colors.white : Colors.black87)
        : textColor;

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 6, 12, 14),
      decoration: BoxDecoration(
        color: bgColor,
        border: Border(top: BorderSide(color: borderColor, width: 0.8)),
      ),
      child: Row(
        children: isArabic
            ? [
                IconButton(
                  icon: Icon(Icons.sentiment_satisfied_rounded,
                      color: iconBorderColor, size: 24),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: () {},
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: fieldBg,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        IconButton(
                          icon: Icon(Icons.mic_none_outlined,
                              color: textColor, size: 21),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          onPressed: () {},
                        ),
                        const SizedBox(width: 6),
                        Icon(Icons.emoji_emotions_outlined,
                            color: textColor, size: 21),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            currentText,
                            textAlign: TextAlign.right,
                            style: TextStyle(
                              color: currentTextColor,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                IconButton(
                  icon: Icon(Icons.camera_alt_outlined,
                      color: iconBorderColor, size: 24),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: () {},
                ),
              ]
            : [
                IconButton(
                  icon: Icon(Icons.camera_alt_outlined,
                      color: iconBorderColor, size: 24),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: () {},
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: fieldBg,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            currentText,
                            style: TextStyle(
                              color: currentTextColor,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        Icon(Icons.emoji_emotions_outlined,
                            color: textColor, size: 21),
                        const SizedBox(width: 6),
                        IconButton(
                          icon: Icon(Icons.mic_none_outlined,
                              color: textColor, size: 21),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          onPressed: () {},
                        ),
                      ],
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.sentiment_satisfied_rounded,
                      color: iconBorderColor, size: 24),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: () {},
                ),
              ],
      ),
    );
  }
}

// ─── Blocked Input Bar ─────────────────────────────────────────────────────────

class _BlockedInputBar extends StatelessWidget {
  final ChatSession session;
  final PlatformTheme theme;

  const _BlockedInputBar({required this.session, required this.theme});

  @override
  Widget build(BuildContext context) {
    final isAr = context.watch<ThemeProvider>().isArabic;
    final isDark = session.isDarkMode;

    switch (session.platform) {
      case Platform.whatsapp:
        final Color cardBg = isDark ? const Color(0xFF182229) : const Color(0xFFFFEECD);
        final Color textCol = isDark ? const Color(0xFF8696A0) : const Color(0xFF54656F);

        return Container(
          color: theme.inputBarBg,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Center(
            child: InkWell(
              onTap: () => _showUnblockDialog(context, session),
              borderRadius: BorderRadius.circular(10),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isDark ? Colors.transparent : const Color(0xFFF0E0C0),
                    width: 0.8,
                  ),
                ),
                child: Text(
                  isAr 
                      ? 'لقد حظرت جهة الاتصال هذه. انقر لإلغاء الحظر.' 
                      : 'You blocked this contact. Tap to unblock.',
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

      case Platform.messenger:
        final borderColor = isDark ? const Color(0xFF3A3B3C) : const Color(0xFFECECEC);
        final descColor = isDark ? Colors.white54 : Colors.black54;

        return Container(
          decoration: BoxDecoration(
            color: theme.inputBarBg,
            border: Border(top: BorderSide(color: borderColor, width: 0.8)),
          ),
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                isAr 
                    ? 'لقد حظرت ${session.contactUser.name}' 
                    : 'You blocked ${session.contactUser.name}',
                style: TextStyle(
                  color: isDark ? Colors.white : Colors.black,
                  fontSize: 14.5,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                isAr 
                    ? 'لا يمكنك مراسلة أو الاتصال ببعضكما البعض.' 
                    : 'You can\'t message or call each other.',
                style: TextStyle(color: descColor, fontSize: 12.5),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              InkWell(
                onTap: () => _showUnblockDialog(context, session),
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                  child: Text(
                    isAr ? 'إلغاء الحظر' : 'Unblock',
                    style: const TextStyle(
                      color: Color(0xFF0084FF),
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );

      case Platform.instagram:
        final borderColor = isDark ? const Color(0xFF363636) : const Color(0xFFF2F2F2);
        final descColor = isDark ? Colors.white54 : Colors.black54;

        return Container(
          decoration: BoxDecoration(
            color: theme.inputBarBg,
            border: Border(top: BorderSide(color: borderColor, width: 0.8)),
          ),
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                isAr 
                    ? 'لقد حظرت ${session.contactUser.name}' 
                    : 'You blocked ${session.contactUser.name}',
                style: TextStyle(
                  color: isDark ? Colors.white : Colors.black,
                  fontSize: 14.5,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                isAr 
                    ? 'لا يمكنك مراسلة أو الاتصال ببعضكما البعض.' 
                    : 'You can\'t message or call each other.',
                style: TextStyle(color: descColor, fontSize: 12.5),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              InkWell(
                onTap: () => _showUnblockDialog(context, session),
                child: Text(
                  isAr ? 'إلغاء الحظر' : 'Unblock',
                  style: const TextStyle(
                    color: Color(0xFF0095F6),
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        );

      case Platform.snapchat:
        final borderColor = isDark ? const Color(0xFF2A2A2A) : const Color(0xFFF2F2F2);

        return Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF0B0C0E) : Colors.white,
            border: Border(top: BorderSide(color: borderColor, width: 0.8)),
          ),
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                isAr 
                    ? 'لقد حظرت ${session.contactUser.name}' 
                    : 'You blocked ${session.contactUser.name}',
                style: TextStyle(
                  color: isDark ? Colors.white : Colors.black,
                  fontSize: 14.5,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              GestureDetector(
                onTap: () => _showUnblockDialog(context, session),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0084FF).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    isAr ? 'إلغاء الحظر' : 'Unblock',
                    style: const TextStyle(
                      color: Color(0xFF0084FF),
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
    }
  }
}

// ─── Dialog Helper ─────────────────────────────────────────────────────────────

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

class _TheyBlockedMeInputBar extends StatelessWidget {
  final ChatSession session;
  final PlatformTheme theme;

  const _TheyBlockedMeInputBar({required this.session, required this.theme});

  @override
  Widget build(BuildContext context) {
    final isAr = context.watch<ThemeProvider>().isArabic;
    final isDark = session.isDarkMode;
    final borderColor = isDark ? const Color(0xFF363636) : const Color(0xFFF2F2F2);
    final textCol = isDark ? Colors.white38 : Colors.black38;

    String bannerText = '';
    if (session.platform == Platform.messenger) {
      bannerText = isAr ? 'هذا الشخص غير متاح على Messenger.' : 'This person is unavailable on Messenger.';
    } else {
      bannerText = isAr ? 'لا يمكنك مراسلة هذا الحساب.' : 'You can\'t message this account.';
    }

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: theme.inputBarBg,
        border: Border(top: BorderSide(color: borderColor, width: 0.8)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      child: SafeArea(
        top: false,
        child: Text(
          bannerText,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: textCol,
            fontSize: 14,
            fontWeight: FontWeight.w400,
          ),
        ),
      ),
    );
  }
}
