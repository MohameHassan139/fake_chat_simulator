import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/chat_models.dart';
import '../providers/chat_provider.dart';
import '../providers/theme_provider.dart';
import '../utils/language_helper.dart';
import 'chat_screen.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final chatProvider = context.watch<ChatProvider>();

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: RichText(
          text: TextSpan(
            children: [
              TextSpan(
                text: LanguageHelper.translate('app_title_1', themeProvider.isArabic),
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -1,
                ),
              ),
              TextSpan(
                text: LanguageHelper.translate('app_title_2', themeProvider.isArabic),
                style: const TextStyle(
                  color: Color(0xFF6C63FF),
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -1,
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            child: Text(
              themeProvider.isArabic ? 'English' : 'عربي',
              style: const TextStyle(
                color: Color(0xFF6C63FF),
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
            onPressed: themeProvider.toggleLanguage,
          ),
          IconButton(
            icon: Icon(
              themeProvider.isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
            ),
            onPressed: themeProvider.toggleTheme,
          ),
        ],
      ),
      body: chatProvider.sessions.isEmpty
          ? _buildEmptyState(context)
          : _buildSessionList(context, chatProvider),
      floatingActionButton: _buildFAB(context),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final themeProvider = context.read<ThemeProvider>();

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: const Color(0xFF6C63FF).withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.chat_bubble_outline_rounded,
              size: 48,
              color: Color(0xFF6C63FF),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            LanguageHelper.translate('no_chats_yet', themeProvider.isArabic),
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            LanguageHelper.translate('tap_plus_to_create', themeProvider.isArabic),
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 15,
              color: Theme.of(context)
                  .colorScheme
                  .onSurface
                  .withValues(alpha: 0.5),
              height: 1.5,
            ),
          ),
          const SizedBox(height: 32),
          _buildPlatformCards(context),
        ],
      ),
    );
  }

  Widget _buildPlatformCards(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 12,
      runSpacing: 12,
      children: Platform.values.map((p) {
        return _PlatformChip(platform: p);
      }).toList(),
    );
  }

  Widget _buildSessionList(BuildContext context, ChatProvider chatProvider) {
    final themeProvider = context.read<ThemeProvider>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
          child: Text(
            LanguageHelper.translate('my_conversations', themeProvider.isArabic).toUpperCase(),
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Theme.of(context)
                  .colorScheme
                  .onSurface
                  .withValues(alpha: 0.35),
              letterSpacing: 1,
            ),
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: chatProvider.sessions.length,
            itemBuilder: (context, index) {
              final session = chatProvider.sessions[index];
              return _SessionCard(
                session: session,
                onTap: () {
                  chatProvider.setActiveSession(session);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const ChatScreen(),
                    ),
                  );
                },
                onDelete: () => chatProvider.deleteSession(session.id),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildFAB(BuildContext context) {
    return FloatingActionButton(
      onPressed: () => _showNewChatDialog(context),
      child: const Icon(Icons.add_rounded),
    );
  }

  void _showNewChatDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _NewChatSheet(),
    );
  }
}

class _SessionCard extends StatelessWidget {
  final ChatSession session;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _SessionCard({
    required this.session,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final onSurface = colorScheme.onSurface;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                // Platform badge
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: session.platformColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Center(
                    child: _platformIcon(session.platform),
                  ),
                ),
                const SizedBox(width: 14),
                // Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            session.contactUser.name,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: onSurface,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: session.platformColor.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              session.platformName,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: session.platformColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${session.messages.length} ${LanguageHelper.translate('messages', context.read<ThemeProvider>().isArabic)}',
                        style: TextStyle(
                          fontSize: 13,
                          color: onSurface.withValues(alpha: 0.35),
                        ),
                      ),
                    ],
                  ),
                ),
                // Actions
                IconButton(
                  icon: Icon(
                    Icons.delete_outline_rounded,
                    color: onSurface.withValues(alpha: 0.25),
                    size: 20,
                  ),
                  onPressed: onDelete,
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  color: onSurface.withValues(alpha: 0.25),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _platformIcon(Platform p) {
    switch (p) {
      case Platform.whatsapp:
        return Icon(Icons.chat_rounded, color: const Color(0xFF25D366), size: 28);
      case Platform.messenger:
        return Icon(Icons.messenger_rounded, color: const Color(0xFF0084FF), size: 28);
      case Platform.instagram:
        return Icon(Icons.camera_alt_rounded, color: const Color(0xFFE1306C), size: 28);
      case Platform.snapchat:
        return Icon(Icons.face_rounded, color: const Color(0xFFFFFC00), size: 28);
    }
  }
}

class _NewChatSheet extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final onSurface = colorScheme.onSurface;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: onSurface.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            LanguageHelper.translate('choose_platform', context.read<ThemeProvider>().isArabic),
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: onSurface,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            LanguageHelper.translate('select_messaging_app', context.read<ThemeProvider>().isArabic),
            style: TextStyle(
                fontSize: 14, color: onSurface.withValues(alpha: 0.4)),
          ),
          const SizedBox(height: 24),
          ...Platform.values.map((p) => _PlatformListTile(platform: p)),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class _PlatformListTile extends StatelessWidget {
  final Platform platform;
  const _PlatformListTile({required this.platform});

  @override
  Widget build(BuildContext context) {
    final chatProvider = context.read<ChatProvider>();
    final colorScheme = Theme.of(context).colorScheme;
    final onSurface = colorScheme.onSurface;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: Theme.of(context).brightness == Brightness.dark
            ? const Color(0xFF242424)
            : const Color(0xFFEEEEEE),
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () {
            chatProvider.createSession(platform);
            Navigator.pop(context);
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ChatScreen()),
            );
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: _color(platform).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(_icon(platform), color: _color(platform), size: 24),
                ),
                const SizedBox(width: 14),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _name(platform),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: onSurface,
                      ),
                    ),
                    Text(
                      _desc(platform),
                      style: TextStyle(
                        fontSize: 12,
                        color: onSurface.withValues(alpha: 0.4),
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 14,
                  color: onSurface.withValues(alpha: 0.25),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _color(Platform p) {
    switch (p) {
      case Platform.whatsapp: return const Color(0xFF25D366);
      case Platform.messenger: return const Color(0xFF0084FF);
      case Platform.instagram: return const Color(0xFFE1306C);
      case Platform.snapchat: return const Color(0xFFFFFC00);
    }
  }

  IconData _icon(Platform p) {
    switch (p) {
      case Platform.whatsapp: return Icons.chat_rounded;
      case Platform.messenger: return Icons.messenger_rounded;
      case Platform.instagram: return Icons.camera_alt_rounded;
      case Platform.snapchat: return Icons.face_rounded;
    }
  }

  String _name(Platform p) {
    switch (p) {
      case Platform.whatsapp: return 'WhatsApp';
      case Platform.messenger: return 'Messenger';
      case Platform.instagram: return 'Instagram DM';
      case Platform.snapchat: return 'Snapchat';
    }
  }

  String _desc(Platform p) {
    switch (p) {
      case Platform.whatsapp: return 'Green bubbles · Read receipts · Status bar';
      case Platform.messenger: return 'Gradient bubbles · Avatars · Reactions';
      case Platform.instagram: return 'Gradient · Seen status · Stories';
      case Platform.snapchat: return 'Minimal · Blue bubbles · Snap streaks';
    }
  }
}

class _PlatformChip extends StatelessWidget {
  final Platform platform;
  const _PlatformChip({required this.platform});

  @override
  Widget build(BuildContext context) {
    final chatProvider = context.read<ChatProvider>();
    Color c;
    String label;
    switch (platform) {
      case Platform.whatsapp: c = const Color(0xFF25D366); label = 'WhatsApp'; break;
      case Platform.messenger: c = const Color(0xFF0084FF); label = 'Messenger'; break;
      case Platform.instagram: c = const Color(0xFFE1306C); label = 'Instagram'; break;
      case Platform.snapchat: c = const Color(0xFFFFFC00); label = 'Snapchat'; break;
    }
    return GestureDetector(
      onTap: () {
        chatProvider.createSession(platform);
        Navigator.push(context, MaterialPageRoute(builder: (_) => const ChatScreen()));
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: c.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: c.withValues(alpha: 0.4)),
        ),
        child: Text(label, style: TextStyle(color: c, fontWeight: FontWeight.w600, fontSize: 13)),
      ),
    );
  }
}

