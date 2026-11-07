import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';

import '../../domain/app_settings.dart';
import 'settings_controller.dart';

final themeModeProvider = Provider<ThemeMode>((ref) {
  final themeMode = ref
      .watch(settingsControllerProvider)
      .asData
      ?.value
      .themeMode;
  return switch (themeMode) {
    AppThemeMode.light => ThemeMode.light,
    AppThemeMode.dark => ThemeMode.dark,
    AppThemeMode.system => ThemeMode.system,
    null => ThemeMode.light,
  };
});
