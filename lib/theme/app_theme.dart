// App theme — colors, fonts, text styles
import 'package:flutter/material.dart';

class AppTheme {
  // Brand colors
  static const Color primary   = Color(0xFF1A237E); // deep indigo
  static const Color accent    = Color(0xFFFFAB00); // saffron/gold
  static const Color green     = Color(0xFF2E7D32);
  static const Color red       = Color(0xFFC62828);
  static const Color bg        = Color(0xFF0F1729); // dark navy
  static const Color surface   = Color(0xFF1A2540);
  static const Color card      = Color(0xFF1E2D4A);
  static const Color border    = Color(0xFF2A3D60);
  static const Color text1     = Color(0xFFECEFF1);
  static const Color text2     = Color(0xFF8FA8C8);

  static ThemeData get theme => ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: bg,
    colorScheme: const ColorScheme.dark(
      primary: primary,
      secondary: accent,
      surface: surface,
      error: red,
    ),
    fontFamily: 'Roboto',
    appBarTheme: const AppBarTheme(
      backgroundColor: bg,
      foregroundColor: text1,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(
        color: text1,
        fontSize: 20,
        fontWeight: FontWeight.w700,
        fontFamily: 'Roboto',
      ),
    ),
    cardTheme: CardTheme(
      color: card,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: border, width: 1),
      ),
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 0),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: surface,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: accent, width: 1.5),
      ),
      labelStyle: const TextStyle(color: text2),
      hintStyle: const TextStyle(color: text2),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: surface,
      selectedItemColor: accent,
      unselectedItemColor: text2,
      type: BottomNavigationBarType.fixed,
      elevation: 0,
    ),
    dividerColor: border,
    textTheme: const TextTheme(
      headlineLarge: TextStyle(color: text1, fontWeight: FontWeight.w800, fontSize: 28),
      headlineMedium: TextStyle(color: text1, fontWeight: FontWeight.w700, fontSize: 22),
      titleLarge: TextStyle(color: text1, fontWeight: FontWeight.w700, fontSize: 18),
      titleMedium: TextStyle(color: text1, fontWeight: FontWeight.w600, fontSize: 15),
      bodyLarge: TextStyle(color: text1, fontSize: 15),
      bodyMedium: TextStyle(color: text2, fontSize: 13),
      bodySmall: TextStyle(color: text2, fontSize: 11),
    ),
  );
}
