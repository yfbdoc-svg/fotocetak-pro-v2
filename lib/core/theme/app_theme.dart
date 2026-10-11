import 'package:flutter/material.dart';

class AppTheme {
  static const Color blue = Color(0xFF1677E8);
  static const Color green = Color(0xFF128C51);
  static const Color dark = Color(0xFF17263C);
  static const Color muted = Color(0xFF6B7C90);
  static const Color background = Color(0xFFF3F6FA);
  static const Color border = Color(0xFFE1E8F1);

  static ThemeData get light {
    final base = ThemeData(
      colorScheme: ColorScheme.fromSeed(seedColor: blue, surface: Colors.white),
      useMaterial3: true,
      scaffoldBackgroundColor: background,
      fontFamily: 'Segoe UI',
      visualDensity: VisualDensity.compact,
    );
    return base.copyWith(
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.white,
        foregroundColor: dark,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      textTheme: base.textTheme.apply(bodyColor: dark, displayColor: dark),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: blue,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 17),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9)),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: dark,
          side: const BorderSide(color: border),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 17),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      ),
      dividerColor: border,
      cardColor: Colors.white,
    );
  }
}
