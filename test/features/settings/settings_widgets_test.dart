import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:crypto_research_app/core/constants/app_strings.dart';
import 'package:crypto_research_app/core/providers/repository_providers.dart';
import 'package:crypto_research_app/features/settings/domain/app_settings.dart';
import 'package:crypto_research_app/features/settings/domain/settings_repository.dart';
import 'package:crypto_research_app/features/settings/presentation/screens/settings_screen.dart';

import '../../helpers/screen_util_test_wrapper.dart';

class _MemorySettingsRepository implements SettingsRepository {
  AppSettings settings = const AppSettings();

  @override
  Future<AppSettings> load() async => settings;

  @override
  Future<void> save(AppSettings settings) async {
    this.settings = settings;
  }
}

void main() {
  testWidgets('settings only shows preferences and saves the selected theme', (
    tester,
  ) async {
    final settingsRepository = _MemorySettingsRepository();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          settingsRepositoryProvider.overrideWithValue(settingsRepository),
        ],
        child: screenUtilTestWrapper(
          MaterialApp(theme: ThemeData.dark(), home: const SettingsScreen()),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text(AppStrings.preferences), findsOneWidget);
    expect(find.text(AppStrings.theme), findsOneWidget);
    expect(find.text(AppStrings.currency), findsNothing);
    expect(find.text(AppStrings.aboutSection), findsNothing);
    expect(find.byType(Divider), findsNothing);
    expect(find.byType(AnimatedAlign), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('theme-option-dark')));
    await tester.pumpAndSettle();
    expect(settingsRepository.settings.themeMode, AppThemeMode.dark);
    expect(
      tester.widget<Scaffold>(find.byType(Scaffold)).backgroundColor,
      Colors.white,
    );
  });
}
