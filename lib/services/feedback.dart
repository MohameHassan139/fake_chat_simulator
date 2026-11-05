import 'package:url_launcher/url_launcher.dart';

/// "Send feedback": an email to the developer, so an unhappy user tells us
/// the problem instead of leaving one star. Kept apart from the rating prompt
/// (Google forbids asking "do you like the app?" before it).
class AppFeedback {
  // The developer's support e-mail; the menu item stays hidden while it is empty.
  static const String supportEmail = '';

  static bool get available => supportEmail.contains('@');

  static Future<void> send(bool isArabic) async {
    final uri = Uri(
      scheme: 'mailto',
      path: supportEmail,
      query: 'subject=${Uri.encodeComponent(isArabic ? 'ملاحظة على Fake Chat' : 'Fake Chat feedback')}',
    );
    await launchUrl(uri);
  }
}
