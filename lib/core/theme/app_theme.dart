import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

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
      onPrimary: Colors.white,
      secondary: AppColors.brandAccent,
      onSecondary: const Color(0xFF0F172A),
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
          borderRadius: BorderRadius.circular(AppSizes.radiusMd.r),
          side: BorderSide(color: border),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: dark
            ? AppColors.darkSurfaceVariant
            : AppColors.lightSurfaceVariant,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusMd.r),
          borderSide: BorderSide.none,
        ),
        contentPadding: EdgeInsets.symmetric(
          horizontal: AppSizes.lg.w,
          vertical: AppSizes.md.w,
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: surface,
        indicatorColor: dark
            ? AppColors.darkSurfaceVariant
            : AppColors.lightSurfaceVariant,
        labelTextStyle: WidgetStatePropertyAll(
          AppTypography.textTheme(primary, secondary).labelMedium,
        ),
      ),
    );
  }
}
