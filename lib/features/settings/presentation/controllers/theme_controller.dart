import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';

import '../../domain/app_settings.dart';
import 'settings_controller.dart';

final themeModeProvider = Provider<ThemeMode>((ref) {
  return switch (ref
      .watch(settingsControllerProvider)
      .asData
      ?.value
      .themeMode) {
    AppThemeMode.light => ThemeMode.light,
    AppThemeMode.dark => ThemeMode.dark,
    _ => ThemeMode.system,
  };
});
