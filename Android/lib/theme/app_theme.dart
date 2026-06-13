import 'package:flutter/material.dart';

class AppColors {
  // ── Adaptive (change with theme) ─────────────────────
  static Color bg            = const Color(0xFF0B0F1A);
  static Color surface       = const Color(0xFF131929);
  static Color surface2      = const Color(0xFF1A2235);
  static Color surface3      = const Color(0xFF1F2A40);
  static Color border        = const Color(0x1F6496FF);
  static Color textPrimary   = const Color(0xFFE8EEFF);
  static Color textSecondary = const Color(0xFF8A9BB5);
  static Color textTertiary  = const Color(0xFF4A5A75);

  // ── Fixed (same in both themes) ─────────────────────
  static const accent  = Color(0xFF3D7FFF);
  static const accent2 = Color(0xFF00D4A0);
  static const accent3 = Color(0xFFFF6B35);
  static const gold    = Color(0xFFF5C842);
  static const red     = Color(0xFFFF4D6D);

  static const List<Color> avatarColors = [
    Color(0xFF3D7FFF), Color(0xFF00D4A0), Color(0xFFFF6B35),
    Color(0xFFF5C842), Color(0xFFFF4D6D), Color(0xFF9C6FE4),
  ];

  static void applyDark() {
    bg            = const Color(0xFF0B0F1A);
    surface       = const Color(0xFF131929);
    surface2      = const Color(0xFF1A2235);
    surface3      = const Color(0xFF1F2A40);
    border        = const Color(0x1F6496FF);
    textPrimary   = const Color(0xFFE8EEFF);
    textSecondary = const Color(0xFF8A9BB5);
    textTertiary  = const Color(0xFF4A5A75);
  }

  static void applyLight() {
    bg            = const Color(0xFFF0F4FF);
    surface       = const Color(0xFFFFFFFF);
    surface2      = const Color(0xFFF5F8FF);
    surface3      = const Color(0xFFEBF0FA);
    border        = const Color(0x2A3D7FFF);
    textPrimary   = const Color(0xFF0D1B3E);
    textSecondary = const Color(0xFF4A5A80);
    textTertiary  = const Color(0xFF8A9BB5);
  }
}

class AppTheme {
  static ThemeData dark() => _build(Brightness.dark);
  static ThemeData light() => _build(Brightness.light);

  static ThemeData _build(Brightness brightness) {
    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      scaffoldBackgroundColor: AppColors.bg,
      colorScheme: ColorScheme(
        brightness: brightness,
        primary: AppColors.accent,
        onPrimary: Colors.white,
        secondary: AppColors.accent2,
        onSecondary: Colors.white,
        error: AppColors.red,
        onError: Colors.white,
        surface: AppColors.surface,
        onSurface: AppColors.textPrimary,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: AppColors.textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w800,
        ),
      ),
      navigationDrawerTheme: NavigationDrawerThemeData(
        backgroundColor: AppColors.surface,
      ),
      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: AppColors.border),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface2,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.accent),
        ),
        labelStyle: TextStyle(color: AppColors.textSecondary),
        hintStyle: TextStyle(color: AppColors.textTertiary),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.accent,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        ),
      ),
      textTheme: TextTheme(
        bodyLarge:   TextStyle(color: AppColors.textPrimary),
        bodyMedium:  TextStyle(color: AppColors.textPrimary),
        bodySmall:   TextStyle(color: AppColors.textSecondary),
        titleLarge:  TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w800),
        titleMedium: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w700),
      ),
    );
  }
}
