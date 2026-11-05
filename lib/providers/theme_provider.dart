import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../utils/language_helper.dart';

class ThemeProvider extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.dark;
  String _language = 'en';

  ThemeMode get themeMode => _themeMode;
  bool get isDark => _themeMode == ThemeMode.dark;
  bool get isArabic => _language == 'ar';
  String get language => _language;

  ThemeProvider() {
    _loadFromDatabase();
  }

  void _loadFromDatabase() {
    try {
      final settingsBox = Hive.box('settings_box');
      final isDarkVal = settingsBox.get('app_is_dark', defaultValue: true) as bool;
      _themeMode = isDarkVal ? ThemeMode.dark : ThemeMode.light;
      final wasArabic = settingsBox.get('app_is_arabic', defaultValue: false) as bool;
      final saved = settingsBox.get('app_language') as String?;
      _language = saved != null && LanguageHelper.languages.containsKey(saved)
          ? saved
          : (wasArabic ? 'ar' : _deviceLanguage());
      LanguageHelper.code = _language;
    } catch (e) {
      debugPrint('Error loading settings in ThemeProvider: $e');
    }
  }

  void _saveSettings() {
    try {
      final settingsBox = Hive.box('settings_box');
      settingsBox.put('app_is_dark', isDark);
      settingsBox.put('app_is_arabic', isArabic);
      settingsBox.put('app_language', _language);
    } catch (e) {
      debugPrint('Error saving settings in ThemeProvider: $e');
    }
  }

  void toggleTheme() {
    _themeMode = isDark ? ThemeMode.light : ThemeMode.dark;
    _saveSettings();
    notifyListeners();
  }

  /// First start: the phone's language when the app has it, else English.
  String _deviceLanguage() {
    final code = WidgetsBinding.instance.platformDispatcher.locale.languageCode;
    return LanguageHelper.languages.containsKey(code) ? code : 'en';
  }

  void setLanguage(String code) {
    if (!LanguageHelper.languages.containsKey(code)) return;
    _language = code;
    LanguageHelper.code = code;
    _saveSettings();
    notifyListeners();
  }
}
