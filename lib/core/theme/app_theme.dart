import 'package:flutter/material.dart';

class AppColors {
  static const background = Color(0xFF100F0E);
  static const surface = Color(0xFF1A1714);
  static const surfaceAlt = Color(0xFF3A1A10);
  static const border = Color(0xFF3B3028);
  static const borderAlt = Color(0xFF6E3A1F);

  static const teal = Color(0xFFFF7A1A);
  static const tealDim = Color(0xFFC74214);
  static const tealDark = Color(0xFF24100A);

  static const textPrimary = Color(0xFFFFF1E3);
  static const textSecondary = Color(0xFFD5B59D);
  static const textMuted = Color(0xFFFFB45F);
  static const textDim = Color(0xFF6E3A1F);
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
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
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
        labelStyle: const TextStyle(
          color: AppColors.textMuted,
          fontSize: 10,
          letterSpacing: 1.2,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.surfaceAlt,
          foregroundColor: AppColors.teal,
          side: const BorderSide(color: AppColors.teal, width: 1),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
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
