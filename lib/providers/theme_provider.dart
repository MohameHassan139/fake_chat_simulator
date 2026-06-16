import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

class ThemeProvider extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.dark;
  bool _isArabic = false;

  ThemeMode get themeMode => _themeMode;
  bool get isDark => _themeMode == ThemeMode.dark;
  bool get isArabic => _isArabic;

  ThemeProvider() {
    _loadFromDatabase();
  }

  void _loadFromDatabase() {
    try {
      final settingsBox = Hive.box('settings_box');
      final isDarkVal = settingsBox.get('app_is_dark', defaultValue: true) as bool;
      _themeMode = isDarkVal ? ThemeMode.dark : ThemeMode.light;
      _isArabic = settingsBox.get('app_is_arabic', defaultValue: false) as bool;
    } catch (e) {
      debugPrint('Error loading settings in ThemeProvider: $e');
    }
  }

  void _saveSettings() {
    try {
      final settingsBox = Hive.box('settings_box');
      settingsBox.put('app_is_dark', isDark);
      settingsBox.put('app_is_arabic', _isArabic);
    } catch (e) {
      debugPrint('Error saving settings in ThemeProvider: $e');
    }
  }

  void toggleTheme() {
    _themeMode = isDark ? ThemeMode.light : ThemeMode.dark;
    _saveSettings();
    notifyListeners();
  }

  void toggleLanguage() {
    _isArabic = !_isArabic;
    _saveSettings();
    notifyListeners();
  }
}
