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

      onSurfaceVariant: AppColors.textSecondary,

      outline: AppColors.border,
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

    colorScheme: const ColorScheme.dark(
      primary: AppColors.primaryDark,
      onPrimary: AppColors.backgroundDark,
      secondary: AppColors.accent,
      onSecondary: AppColors.backgroundDark,
      surface: AppColors.surfaceDark,
      onSurface: AppColors.textPrimaryDark,
      error: AppColors.error,
      onError: AppColors.textPrimaryDark,
      outline: AppColors.borderDark,
      surfaceContainerLowest: AppColors.backgroundDark,
      surfaceContainerLow: AppColors.surfaceDark,
      surfaceContainer: AppColors.surfaceDark,
      surfaceContainerHigh: AppColors.surfaceElevatedDark,
      surfaceContainerHighest: AppColors.surfaceElevatedDark,
    ),

    textTheme: TextTheme(
      displayLarge: AppTypography.display.copyWith(
        color: AppColors.textPrimaryDark,
      ),

      headlineLarge: AppTypography.h1.copyWith(
        color: AppColors.textPrimaryDark,
      ),

      headlineMedium: AppTypography.h2.copyWith(
        color: AppColors.textPrimaryDark,
      ),

      headlineSmall: AppTypography.h3.copyWith(
        color: AppColors.textPrimaryDark,
      ),

      bodyLarge: AppTypography.body.copyWith(color: AppColors.textPrimaryDark),

      bodyMedium: AppTypography.bodyMedium.copyWith(
        color: AppColors.textPrimaryDark,
      ),

      bodySmall: AppTypography.caption.copyWith(
        color: AppColors.textSecondaryDark,
      ),
    ),

    cardTheme: CardThemeData(
      color: AppColors.surfaceDark,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.card),
      ),
    ),

    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.surfaceElevatedDark,
      labelStyle: AppTypography.body.copyWith(
        color: AppColors.textSecondaryDark,
      ),
      hintStyle: AppTypography.body.copyWith(
        color: AppColors.textSecondaryDark,
      ),
      prefixIconColor: AppColors.iconDark,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.medium),
        borderSide: const BorderSide(color: AppColors.borderDark),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.medium),
        borderSide: const BorderSide(color: AppColors.borderDark),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.medium),
        borderSide: const BorderSide(color: AppColors.primaryDark),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.medium),
        borderSide: const BorderSide(color: AppColors.error),
      ),
    ),

    iconTheme: const IconThemeData(color: AppColors.iconDark),
    dividerTheme: const DividerThemeData(color: AppColors.borderDark),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: AppColors.surfaceElevatedDark,
    ),
    dialogTheme: const DialogThemeData(
      backgroundColor: AppColors.surfaceElevatedDark,
    ),
    appBarTheme: const AppBarTheme(
      elevation: 0,
      backgroundColor: AppColors.backgroundDark,
      foregroundColor: AppColors.textPrimaryDark,
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected)
            ? AppColors.backgroundDark
            : AppColors.textSecondaryDark,
      ),
      trackColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected)
            ? AppColors.accent
            : AppColors.surfaceElevatedDark,
      ),
      trackOutlineColor: const WidgetStatePropertyAll(AppColors.borderDark),
    ),
    segmentedButtonTheme: SegmentedButtonThemeData(
      style: ButtonStyle(
        foregroundColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? AppColors.primaryDark
              : AppColors.textSecondaryDark,
        ),
        backgroundColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? AppColors.primaryDark.withValues(alpha: 0.18)
              : AppColors.surfaceDark,
        ),
        side: const WidgetStatePropertyAll(
          BorderSide(color: AppColors.borderDark),
        ),
      ),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: AppColors.surfaceElevatedDark,
      selectedColor: AppColors.primaryDark.withValues(alpha: 0.18),
      checkmarkColor: AppColors.primaryDark,
      labelStyle: AppTypography.caption.copyWith(
        color: AppColors.textPrimaryDark,
      ),
      side: const BorderSide(color: AppColors.borderDark),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.circular),
      ),
    ),
  );
}
