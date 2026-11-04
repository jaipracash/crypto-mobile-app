import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

abstract final class AppTypography {
  static TextTheme textTheme(Color primary, Color secondary) {
    final base = GoogleFonts.interTextTheme();
    return base.copyWith(
      displayLarge: base.displayLarge?.copyWith(
        color: primary,
        fontSize: 32,
        fontWeight: FontWeight.w700,
        fontFeatures: const [FontFeature.tabularFigures()],
      ),
      headlineMedium: base.headlineMedium?.copyWith(
        color: primary,
        fontSize: 24,
        fontWeight: FontWeight.w700,
      ),
      titleLarge: base.titleLarge?.copyWith(
        color: primary,
        fontSize: 18,
        fontWeight: FontWeight.w600,
      ),
      titleMedium: base.titleMedium?.copyWith(
        color: primary,
        fontSize: 16,
        fontWeight: FontWeight.w600,
      ),
      bodyMedium: base.bodyMedium?.copyWith(
        color: primary,
        fontSize: 14,
        fontWeight: FontWeight.w400,
      ),
      bodySmall: base.bodySmall?.copyWith(
        color: secondary,
        fontSize: 12,
        fontWeight: FontWeight.w400,
      ),
      labelSmall: base.labelSmall?.copyWith(
        color: secondary,
        fontSize: 10,
        fontWeight: FontWeight.w500,
      ),
    );
  }
}
