import 'package:flutter/material.dart';

class AppColors {
  static const background = Color(0xFF0A0F1A);
  static const surface = Color(0xFF0D1A24);
  static const surfaceAlt = Color(0xFF0D3D3A);
  static const border = Color(0xFF1E3A4A);
  static const borderAlt = Color(0xFF1E4A5A);

  static const teal = Color(0xFF2DD4BF);
  static const tealDim = Color(0xFF4A9E96);
  static const tealDark = Color(0xFF051A18);

  static const textPrimary = Color(0xFFE2F8F4);
  static const textSecondary = Color(0xFFB0CDD6);
  static const textMuted = Color(0xFF4A9E96);
  static const textDim = Color(0xFF1E4A5A);
}

class AppTheme {
  static ThemeData get dark {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.background,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.teal,
        surface: AppColors.surface,
        onSurface: AppColors.textPrimary,
      ),
      fontFamily: 'monospace',
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.borderAlt, width: 0.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.borderAlt, width: 0.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.teal, width: 1),
        ),
        hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 13),
        labelStyle: const TextStyle(color: AppColors.textMuted, fontSize: 10, letterSpacing: 1.2),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.surfaceAlt,
          foregroundColor: AppColors.teal,
          side: const BorderSide(color: AppColors.teal, width: 1),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          padding: const EdgeInsets.symmetric(vertical: 16),
          textStyle: const TextStyle(
            fontFamily: 'monospace',
            fontSize: 13,
            letterSpacing: 2,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
