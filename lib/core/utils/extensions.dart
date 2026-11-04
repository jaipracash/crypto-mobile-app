import 'package:flutter/material.dart';

extension ThemeContext on BuildContext {
  Color get primaryText => Theme.of(this).colorScheme.onSurface;
  Color get secondaryText =>
      Theme.of(this).textTheme.bodySmall?.color ??
      Theme.of(this).colorScheme.onSurfaceVariant;
  Color get borderColor => Theme.of(this).dividerColor;
}
