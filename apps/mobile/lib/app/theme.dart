import 'package:flutter/material.dart';

class MemoTheme {
  // Colors
  static const Color background = Color(0xFFF4F1EB); // tactile map-paper
  static const Color onBackground = Color(0xFF1E2923); // deep ink text
  static const Color primary = Color(0xFF3B5B43); // moss primary actions
  static const Color onPrimary = Colors.white;
  static const Color danger = Color(0xFFD67D6F); // muted coral danger
  static const Color onDanger = Colors.white;
  static const Color accent = Color(0xFFB5935A); // brass pin accents
  static const Color onAccent = Colors.white;

  static ThemeData get lightTheme {
    return ThemeData(
      colorScheme: const ColorScheme.light(
        primary: primary,
        onPrimary: onPrimary,
        secondary: accent,
        onSecondary: onAccent,
        error: danger,
        onError: onDanger,
        surface: background,
        onSurface: onBackground,
      ),
      scaffoldBackgroundColor: background,
      appBarTheme: const AppBarTheme(
        backgroundColor: background,
        foregroundColor: onBackground,
        elevation: 0,
        centerTitle: true,
      ),
      textTheme: const TextTheme(
        displayLarge: TextStyle(color: onBackground, fontWeight: FontWeight.bold),
        displayMedium: TextStyle(color: onBackground, fontWeight: FontWeight.bold),
        displaySmall: TextStyle(color: onBackground, fontWeight: FontWeight.bold),
        headlineLarge: TextStyle(color: onBackground, fontWeight: FontWeight.bold),
        headlineMedium: TextStyle(color: onBackground, fontWeight: FontWeight.bold),
        headlineSmall: TextStyle(color: onBackground, fontWeight: FontWeight.bold),
        titleLarge: TextStyle(color: onBackground, fontWeight: FontWeight.w600),
        titleMedium: TextStyle(color: onBackground, fontWeight: FontWeight.w600),
        titleSmall: TextStyle(color: onBackground, fontWeight: FontWeight.w600),
        bodyLarge: TextStyle(color: onBackground),
        bodyMedium: TextStyle(color: onBackground),
        bodySmall: TextStyle(color: onBackground),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: onPrimary,
          minimumSize: const Size.fromHeight(56),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: onBackground,
          side: const BorderSide(color: onBackground),
          minimumSize: const Size.fromHeight(56),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}
