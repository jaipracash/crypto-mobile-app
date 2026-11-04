import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../constants/app_sizes.dart';
import 'app_typography.dart';

abstract final class AppTheme {
  static ThemeData light() => _build(Brightness.light);
  static ThemeData dark() => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final dark = brightness == Brightness.dark;
    final background = dark
        ? AppColors.darkBackground
        : AppColors.lightBackground;
    final surface = dark ? AppColors.darkSurface : AppColors.lightSurface;
    final primary = dark
        ? AppColors.darkTextPrimary
        : AppColors.lightTextPrimary;
    final secondary = dark
        ? AppColors.darkTextSecondary
        : AppColors.lightTextSecondary;
    final border = dark ? AppColors.darkBorder : AppColors.lightBorder;
    final scheme = ColorScheme(
      brightness: brightness,
      primary: AppColors.brand,
      onPrimary: const Color(0xFF102000),
      secondary: AppColors.brand,
      onSecondary: const Color(0xFF102000),
      error: dark ? AppColors.darkLoss : AppColors.lightLoss,
      onError: Colors.white,
      surface: surface,
      onSurface: primary,
      surfaceContainerHighest: dark
          ? AppColors.darkSurfaceVariant
          : AppColors.lightSurfaceVariant,
      onSurfaceVariant: secondary,
    );
    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: background,
      dividerColor: border,
      textTheme: AppTypography.textTheme(primary, secondary),
      appBarTheme: AppBarTheme(
        backgroundColor: background,
        foregroundColor: primary,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: AppTypography.textTheme(primary, secondary).titleLarge,
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusMd),
          side: BorderSide(color: border),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: dark
            ? AppColors.darkSurfaceVariant
            : AppColors.lightSurfaceVariant,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusMd),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSizes.lg,
          vertical: AppSizes.md,
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: surface,
        indicatorColor: AppColors.brand.withValues(alpha: 0.18),
        labelTextStyle: WidgetStatePropertyAll(
          AppTypography.textTheme(primary, secondary).labelMedium,
        ),
      ),
    );
  }
}
