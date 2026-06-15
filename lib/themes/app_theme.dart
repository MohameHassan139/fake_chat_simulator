import 'package:flutter/material.dart';

class AppTheme {
  AppTheme._();

  static const Color _darkBg = Color(0xFF0D0D0D);
  static const Color _darkSurface = Color(0xFF1A1A1A);
  static const Color _darkCard = Color(0xFF242424);
  static const Color _accent = Color(0xFF6C63FF);
  static const Color _accentSecondary = Color(0xFFFF6584);

  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: _darkBg,
      colorScheme: ColorScheme.dark(
        primary: _accent,
        secondary: _accentSecondary,
        surface: _darkSurface,
        background: _darkBg,
        onPrimary: Colors.white,
        onBackground: Colors.white,
        onSurface: Colors.white,
      ),
      cardTheme: CardThemeData(
        color: _darkCard,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: _darkBg,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: const TextStyle(
          color: Colors.white,
          fontSize: 22,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.5,
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: _darkSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: _accent,
        foregroundColor: Colors.white,
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: _darkCard,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: _accent, width: 2),
        ),
        hintStyle: TextStyle(color: Colors.white38),
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      textTheme: const TextTheme(
        headlineLarge: TextStyle(fontWeight: FontWeight.w800, letterSpacing: -1),
        headlineMedium: TextStyle(fontWeight: FontWeight.w700, letterSpacing: -0.5),
        titleLarge: TextStyle(fontWeight: FontWeight.w600),
        bodyMedium: TextStyle(height: 1.5),
      ),
    );
  }

  static ThemeData get lightTheme {
    return ThemeData(
      brightness: Brightness.light,
      scaffoldBackgroundColor: const Color(0xFFF5F5F5),
      colorScheme: ColorScheme.light(
        primary: _accent,
        secondary: _accentSecondary,
        surface: Colors.white,
        background: const Color(0xFFF5F5F5),
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }
}
