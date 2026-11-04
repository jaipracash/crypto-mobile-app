import 'package:equatable/equatable.dart';

enum AppThemeMode { system, light, dark }

class AppSettings extends Equatable {
  const AppSettings({
    this.themeMode = AppThemeMode.system,
    this.currency = 'usd',
    this.autoRefreshSeconds = 0,
  });
  final AppThemeMode themeMode;
  final String currency;
  final int autoRefreshSeconds;

  AppSettings copyWith({
    AppThemeMode? themeMode,
    String? currency,
    int? autoRefreshSeconds,
  }) => AppSettings(
    themeMode: themeMode ?? this.themeMode,
    currency: currency ?? this.currency,
    autoRefreshSeconds: autoRefreshSeconds ?? this.autoRefreshSeconds,
  );

  @override
  List<Object?> get props => [themeMode, currency, autoRefreshSeconds];
}
