import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/chat_models.dart';
import '../providers/chat_provider.dart';
import '../providers/theme_provider.dart';
import '../utils/language_helper.dart';
import 'chat_screen.dart';
import '../services/ad_service.dart';
import '../services/purchase_service.dart';
import 'fake_call_screen.dart';
import '../services/daily_prank.dart';
import '../services/feedback.dart';
import 'package:uuid/uuid.dart';

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
          IconButton(
            tooltip: LanguageHelper.translate('fake_call', themeProvider.isArabic),
            icon: const Icon(Icons.phone_in_talk_rounded, color: Color(0xFF6C63FF)),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const FakeCallScreen()),
            ),
          ),
          IconButton(
            tooltip: LanguageHelper.translate('language', themeProvider.isArabic),
            icon: const Icon(Icons.translate_rounded),
            onPressed: () => _chooseLanguage(context),
          ),
          IconButton(
            icon: Icon(
              themeProvider.isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
            ),
            onPressed: themeProvider.toggleTheme,
          ),
          const _MoreMenu(),
        ],
      ),
      body: chatProvider.sessions.isEmpty
          ? _buildEmptyState(context)
          : _buildSessionList(context, chatProvider),
      floatingActionButton: _buildFAB(context),
      bottomNavigationBar: const AdBanner(),
    );
  }

  void _chooseLanguage(BuildContext context) {
    final themeProvider = context.read<ThemeProvider>();
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            for (final e in LanguageHelper.languages.entries)
              ListTile(
                title: Text(e.value),
                trailing: themeProvider.language == e.key
                    ? const Icon(Icons.check_rounded, color: Color(0xFF6C63FF))
                    : null,
                onTap: () {
                  themeProvider.setLanguage(e.key);
                  context.read<ChatProvider>().relocalizePranks(themeProvider.isArabic);
                  Navigator.pop(ctx);
                },
              ),
          ],
        ),
      ),
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
          const SizedBox(height: 24),
          const _PrankOfTheDayCard(),
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
        const _PrankOfTheDayCard(),
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
    final isAr = context.read<ThemeProvider>().isArabic;

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
                      _desc(platform, isAr),
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

  String _desc(Platform p, bool isAr) {
    switch (p) {
      case Platform.whatsapp: return LanguageHelper.translate('whatsapp_desc', isAr);
      case Platform.messenger: return LanguageHelper.translate('messenger_desc', isAr);
      case Platform.instagram: return LanguageHelper.translate('instagram_desc', isAr);
      case Platform.snapchat: return LanguageHelper.translate('snapchat_desc', isAr);
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


/// Remove ads (with the store price), restore it, and the EEA/UK privacy form.
class _MoreMenu extends StatefulWidget {
  const _MoreMenu();

  @override
  State<_MoreMenu> createState() => _MoreMenuState();
}

class _MoreMenuState extends State<_MoreMenu> {
  bool _privacy = false;
  bool _reminder = false;

  @override
  void initState() {
    super.initState();
    DailyPrank.instance.reminderOn().then((v) {
      if (mounted) setState(() => _reminder = v);
    });
    AdService.instance.privacyOptionsRequired().then((v) {
      if (mounted) setState(() => _privacy = v);
    });
  }

  void _say(String key) {
    final isAr = context.read<ThemeProvider>().isArabic;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(LanguageHelper.translate(key, isAr)), behavior: SnackBarBehavior.floating),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isAr = context.watch<ThemeProvider>().isArabic;
    String t(String key) => LanguageHelper.translate(key, isAr);
    final purchases = PurchaseService.instance;
    return ValueListenableBuilder<bool>(
      valueListenable: AdService.instance.adsRemovedNotifier,
      builder: (context, removed, _) => PopupMenuButton<String>(
        onSelected: (v) async {
          if (v == 'remove') {
            if (!purchases.canBuy || !await purchases.buy()) _say('store_unavailable');
          } else if (v == 'restore') {
            if (purchases.canBuy) {
              await purchases.restore();
            } else {
              _say('store_unavailable');
            }
          } else if (v == 'privacy') {
            AdService.instance.showPrivacyOptions();
          } else if (v == 'reminder') {
            await DailyPrank.instance.setReminder(!_reminder, isAr);
            final on = await DailyPrank.instance.reminderOn();
            if (mounted) setState(() => _reminder = on);
          } else if (v == 'feedback') {
            await AppFeedback.send(isAr);
          }
        },
        itemBuilder: (_) => [
          // shown once the store knows the product (until then it does not exist yet)
          if (!removed && purchases.canBuy)
            PopupMenuItem(
              value: 'remove',
              child: ValueListenableBuilder<String?>(
                valueListenable: purchases.price,
                builder: (_, price, __) => Text(price == null ? t('remove_ads') : '${t('remove_ads')} ($price)'),
              ),
            ),
          if (removed) PopupMenuItem(enabled: false, child: Text(t('remove_ads_done'))),
          if (!removed && purchases.canBuy) PopupMenuItem(value: 'restore', child: Text(t('restore_purchase'))),
          PopupMenuItem(
            value: 'reminder',
            child: Text('${t('daily_reminder')}: ${_reminder ? '✓' : '✗'}'),
          ),
          if (AppFeedback.available) PopupMenuItem(value: 'feedback', child: Text(t('send_feedback'))),
          if (_privacy) PopupMenuItem(value: 'privacy', child: Text(t('privacy_settings'))),
        ],
      ),
    );
  }
}

/// Today's ready-made prank chat: one tap, choose the app, then edit and share.
class _PrankOfTheDayCard extends StatelessWidget {
  const _PrankOfTheDayCard();

  Future<void> _use(BuildContext context) async {
    final isAr = context.read<ThemeProvider>().isArabic;
    final platform = await showModalBottomSheet<Platform>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(LanguageHelper.translate('choose_platform', isAr),
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
              const SizedBox(height: 16),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 12,
                runSpacing: 12,
                children: [
                  for (final p in Platform.values)
                    ActionChip(
                      avatar: _PlatformLogo(platform: p),
                      label: Text(_platformName(p)),
                      onPressed: () => Navigator.pop(ctx, p),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
    if (platform == null || !context.mounted) return;
    final t = DailyPrank.instance.today;
    final now = DateTime.now();
    final lines = t.lines;
    context.read<ChatProvider>().createSessionCustom(
      platform: platform,
      contactName: DailyPrank.text(isAr, t.contactAr, t.contactEn),
      initialMessages: [
        for (var i = 0; i < lines.length; i++)
          ChatMessage(
            id: const Uuid().v4(),
            text: DailyPrank.text(isAr, lines[i].ar, lines[i].en),
            type: MessageType.text,
            isSender: lines[i].me,
            timestamp: now.subtract(Duration(minutes: lines.length - i)),
            status: MessageStatus.read,
          ),
      ],
    );
    Navigator.push(context, MaterialPageRoute(builder: (_) => const ChatScreen()));
    DailyPrank.instance.offerReminderOnce(isAr);
  }

  @override
  Widget build(BuildContext context) {
    final isAr = context.watch<ThemeProvider>().isArabic;
    final t = DailyPrank.instance.today;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
      child: Material(
        borderRadius: BorderRadius.circular(16),
        clipBehavior: Clip.antiAlias,
        child: Ink(
          decoration: const BoxDecoration(
            gradient: LinearGradient(colors: [Color(0xFF6C63FF), Color(0xFFFF6584)]),
          ),
          child: InkWell(
            onTap: () => _use(context),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Text('🎭', style: TextStyle(fontSize: 32)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(LanguageHelper.translate('prank_of_day', isAr),
                            style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 2),
                        Text(DailyPrank.text(isAr, t.titleAr, t.titleEn),
                            style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w800)),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
                    child: Text(LanguageHelper.translate('use_it', isAr),
                        style: const TextStyle(color: Color(0xFF6C63FF), fontWeight: FontWeight.w800)),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

String _platformName(Platform p) {
  switch (p) {
    case Platform.whatsapp: return 'WhatsApp';
    case Platform.messenger: return 'Messenger';
    case Platform.instagram: return 'Instagram';
    case Platform.snapchat: return 'Snapchat';
  }
}

class _PlatformLogo extends StatelessWidget {
  final Platform platform;
  const _PlatformLogo({required this.platform});

  @override
  Widget build(BuildContext context) {
    switch (platform) {
      case Platform.whatsapp:
        return const Icon(Icons.chat_rounded, color: Color(0xFF25D366), size: 18);
      case Platform.messenger:
        return const Icon(Icons.messenger_rounded, color: Color(0xFF0084FF), size: 18);
      case Platform.instagram:
        return const Icon(Icons.camera_alt_rounded, color: Color(0xFFE1306C), size: 18);
      case Platform.snapchat:
        return const Icon(Icons.face_rounded, color: Color(0xFFFFD600), size: 18);
    }
  }
}
