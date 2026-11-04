import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../domain/app_settings.dart';
import '../controllers/settings_controller.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsControllerProvider).asData?.value;
    final controller = ref.read(settingsControllerProvider.notifier);
    final theme = settings?.themeMode ?? AppThemeMode.system;
    final currency = settings?.currency ?? 'usd';
    final refresh = settings?.autoRefreshSeconds ?? 0;
    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.settings)),
      body: ListView(
        padding: const EdgeInsets.all(AppSizes.screenPadding),
        children: [
          Text(
            AppStrings.appearance,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: AppSizes.md),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppStrings.theme,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: AppSizes.md),
                SegmentedButton<AppThemeMode>(
                  segments: const [
                    ButtonSegment(
                      value: AppThemeMode.system,
                      label: Text(AppStrings.system),
                      icon: Icon(Icons.settings_suggest_outlined),
                    ),
                    ButtonSegment(
                      value: AppThemeMode.light,
                      label: Text(AppStrings.light),
                      icon: Icon(Icons.light_mode_outlined),
                    ),
                    ButtonSegment(
                      value: AppThemeMode.dark,
                      label: Text(AppStrings.dark),
                      icon: Icon(Icons.dark_mode_outlined),
                    ),
                  ],
                  selected: {theme},
                  onSelectionChanged: (value) =>
                      controller.setTheme(value.first),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSizes.xl),
          Text(
            AppStrings.marketPreferences,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: AppSizes.md),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppStrings.currency,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: AppSizes.md),
                SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(value: 'usd', label: Text(AppStrings.usd)),
                    ButtonSegment(value: 'inr', label: Text(AppStrings.inr)),
                  ],
                  selected: {currency},
                  onSelectionChanged: (value) async {
                    await controller.setCurrency(value.first);
                  },
                ),
                const SizedBox(height: AppSizes.xl),
                Text(
                  AppStrings.autoRefreshMarket,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: AppSizes.md),
                SegmentedButton<int>(
                  segments: const [
                    ButtonSegment(value: 0, label: Text(AppStrings.off)),
                    ButtonSegment(value: 30, label: Text(AppStrings.seconds30)),
                    ButtonSegment(value: 60, label: Text(AppStrings.seconds60)),
                  ],
                  selected: {refresh},
                  onSelectionChanged: (value) =>
                      controller.setAutoRefresh(value.first),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSizes.xl),
          Text(
            AppStrings.aboutSection,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: AppSizes.md),
          AppCard(
            padding: EdgeInsets.zero,
            child: const Column(
              children: [
                ListTile(
                  leading: Icon(Icons.eco_outlined),
                  title: Text(AppStrings.dataByCoinGecko),
                  subtitle: Text(AppStrings.coinGeckoAttribution),
                ),
                Divider(height: 1),
                ListTile(
                  leading: Icon(Icons.info_outline),
                  title: Text(AppStrings.appName),
                  trailing: Text(AppStrings.version),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSizes.xxl),
        ],
      ),
    );
  }
}
