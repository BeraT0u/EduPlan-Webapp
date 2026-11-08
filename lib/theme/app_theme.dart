import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_typography.dart';

class AppTheme {
  static ThemeData get warmPaperTheme {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: AppColors.backgroundCanvas,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primaryBlue,
        primary: AppColors.primaryBlue,
        surface: AppColors.cardSurface,
      ),
      textTheme: appTextTheme,
      cardTheme: CardThemeData(
        color: AppColors.cardSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: AppColors.borderStructural, width: 1),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.borderStructural),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.borderStructural),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.primaryBlue, width: 2),
        ),
      ),
    );
  }
}
