import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/constants/storage_keys.dart';
import '../domain/app_settings.dart';
import '../domain/settings_repository.dart';

class SettingsRepositoryImpl implements SettingsRepository {
  const SettingsRepositoryImpl(this._preferences);
  final SharedPreferences _preferences;

  @override
  Future<AppSettings> load() async => AppSettings(
    themeMode: switch (_preferences.getString(StorageKeys.themeMode)) {
      'light' => AppThemeMode.light,
      'dark' => AppThemeMode.dark,
      'system' => AppThemeMode.system,
      _ => AppThemeMode.light,
    },
    currency: _preferences.getString(StorageKeys.currency) ?? 'usd',
    autoRefreshSeconds:
        _preferences.getInt(StorageKeys.autoRefreshSeconds) ?? 0,
  );

  @override
  Future<void> save(AppSettings settings) async {
    final themeName = switch (settings.themeMode) {
      AppThemeMode.light => 'light',
      AppThemeMode.dark => 'dark',
      AppThemeMode.system => 'system',
    };
    await _preferences.setString(StorageKeys.themeMode, themeName);
    await _preferences.setString(StorageKeys.currency, settings.currency);
    await _preferences.setInt(
      StorageKeys.autoRefreshSeconds,
      settings.autoRefreshSeconds,
    );
  }
}
