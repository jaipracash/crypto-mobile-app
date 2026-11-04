import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/repository_providers.dart';
import '../../domain/app_settings.dart';

final settingsControllerProvider =
    AsyncNotifierProvider<SettingsController, AppSettings>(
      SettingsController.new,
    );

class SettingsController extends AsyncNotifier<AppSettings> {
  @override
  Future<AppSettings> build() => ref.watch(settingsRepositoryProvider).load();

  Future<void> setTheme(AppThemeMode theme) async {
    await _save(
      (state.asData?.value ?? const AppSettings()).copyWith(themeMode: theme),
    );
  }

  Future<void> setCurrency(String currency) async {
    await _save(
      (state.asData?.value ?? const AppSettings()).copyWith(currency: currency),
    );
  }

  Future<void> setAutoRefresh(int seconds) async {
    await _save(
      (state.asData?.value ?? const AppSettings()).copyWith(
        autoRefreshSeconds: seconds,
      ),
    );
  }

  Future<void> _save(AppSettings next) async {
    state = AsyncData(next);
    await ref.read(settingsRepositoryProvider).save(next);
  }
}
