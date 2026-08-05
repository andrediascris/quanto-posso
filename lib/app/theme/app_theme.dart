import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_typography.dart';
import 'app_radius.dart';

class AppTheme {
  AppTheme._();

  // =====================================
  // LIGHT THEME
  // =====================================

  static ThemeData light = ThemeData(
    useMaterial3: true,

    brightness: Brightness.light,

    scaffoldBackgroundColor: AppColors.backgroundLight,

    colorScheme: ColorScheme.light(
      primary: AppColors.primary,

      secondary: AppColors.accent,

      surface: AppColors.surfaceLight,

      error: AppColors.error,

      onPrimary: AppColors.textLight,

      onSurface: AppColors.textPrimary,
    ),

    // =====================================
    // TYPOGRAPHY
    // =====================================
    textTheme: TextTheme(
      displayLarge: AppTypography.display,

      headlineLarge: AppTypography.h1,

      headlineMedium: AppTypography.h2,

      headlineSmall: AppTypography.h3,

      bodyLarge: AppTypography.body,

      bodyMedium: AppTypography.bodyMedium,

      bodySmall: AppTypography.caption,
    ),

    // =====================================
    // CARDS
    // =====================================
    cardTheme: CardThemeData(
      color: AppColors.surfaceLight,

      elevation: 0,

      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.card),
      ),
    ),

    // =====================================
    // INPUTS
    // =====================================
    inputDecorationTheme: InputDecorationTheme(
      filled: true,

      fillColor: AppColors.surfaceLight,

      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.medium),

        borderSide: BorderSide(color: AppColors.border),
      ),

      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.medium),

        borderSide: BorderSide(color: AppColors.border),
      ),
    ),

    // =====================================
    // BUTTONS
    // =====================================
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,

        foregroundColor: AppColors.textLight,

        minimumSize: const Size(double.infinity, 52),

        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.button),
        ),
      ),
    ),

    // =====================================
    // APP BAR
    // =====================================
    appBarTheme: const AppBarTheme(
      elevation: 0,

      centerTitle: false,

      backgroundColor: AppColors.backgroundLight,

      foregroundColor: AppColors.textPrimary,
    ),
  );

  // =====================================
  // DARK THEME
  // =====================================

  static ThemeData dark = ThemeData(
    useMaterial3: true,

    brightness: Brightness.dark,

    scaffoldBackgroundColor: AppColors.backgroundDark,

    colorScheme: ColorScheme.dark(
      primary: AppColors.accent,

      secondary: AppColors.primary,

      surface: AppColors.surfaceDark,

      error: AppColors.error,
    ),

    textTheme: TextTheme(
      displayLarge: AppTypography.display,

      headlineLarge: AppTypography.h1,

      headlineMedium: AppTypography.h2,

      headlineSmall: AppTypography.h3,

      bodyLarge: AppTypography.body,

      bodyMedium: AppTypography.bodyMedium,

      bodySmall: AppTypography.caption,
    ),
  );
}
