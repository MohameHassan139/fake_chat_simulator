import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../providers/theme_provider.dart';
import 'ad_service.dart';
import '../utils/language_helper.dart';

/// The premium features (Live video mode and the AI sticker background cut)
/// open for [length] after one rewarded ad. When no ad can be shown (no
/// network, no fill, consent refused, no Rewarded unit yet) the user goes
/// through for free: an ad problem never blocks a feature. "Remove ads"
/// buyers have them for good.
class PremiumPass {
  static final PremiumPass instance = PremiumPass._();
  PremiumPass._();

  static const String _key = 'premium_until';
  static const Duration length = Duration(hours: 24);

  Future<bool> active() async {
    final prefs = await SharedPreferences.getInstance();
    final until = prefs.getInt(_key) ?? 0;
    return DateTime.now().millisecondsSinceEpoch < until;
  }

  Future<void> _grant() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_key, DateTime.now().add(length).millisecondsSinceEpoch);
  }

  /// True when the user may use a premium feature now.
  Future<bool> ensure(BuildContext context) async {
    final ads = AdService.instance;
    if (ads.adsRemoved || !ads.rewardedEnabled || await active()) return true;
    if (!context.mounted) return false;
    final isAr = context.read<ThemeProvider>().isArabic;
    final watch = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(LanguageHelper.pick(isAr, 'ميزة مميزة ⭐', 'Premium feature ⭐')),
        content: Text(LanguageHelper.pick(isAr, 'شاهد إعلاناً قصيراً لتفتح وضع الفيديو المباشر وقص خلفية الملصقات لمدة 24 ساعة.', 'Watch a short ad to unlock Live video mode and AI sticker cut-out for 24 hours.')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(LanguageHelper.pick(isAr, 'ليس الآن', 'Not now')),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(LanguageHelper.pick(isAr, 'شاهد الإعلان', 'Watch ad')),
          ),
        ],
      ),
    );
    if (watch != true) return false;
    final earned = await AdService.instance.showRewarded();
    if (earned == null) return true;                 // no ad ready: this once for free
    if (!earned) return false;                       // closed the ad early
    await _grant();
    return true;
  }
}
