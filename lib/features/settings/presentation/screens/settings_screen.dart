import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_strings.dart';
import '../../domain/app_settings.dart';
import '../controllers/settings_controller.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme =
        ref.watch(settingsControllerProvider).asData?.value.themeMode ??
        AppThemeMode.light;
    final controller = ref.read(settingsControllerProvider.notifier);
    final baseTheme = Theme.of(context);
    final colors = baseTheme.colorScheme;

    return Scaffold(
      backgroundColor: baseTheme.scaffoldBackgroundColor,
      appBar: AppBar(title: const Text(AppStrings.settings)),
      body: Padding(
        padding: const EdgeInsets.all(AppSizes.screenPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppStrings.preferences,
              style: baseTheme.textTheme.titleSmall?.copyWith(
                color: colors.onSurfaceVariant,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: AppSizes.lg),
            Row(
              children: [
                Text(
                  AppStrings.theme,
                  style: baseTheme.textTheme.titleMedium?.copyWith(
                    color: colors.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: AppSizes.md),
                Expanded(
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 248),
                      child: _ThemeSelector(
                        selected: theme,
                        background: colors.surfaceContainerHighest,
                        selectedBackground: colors.surface,
                        selectedForeground: colors.onSurface,
                        unselectedForeground: colors.onSurfaceVariant,
                        onSelected: controller.setTheme,
                        labels: const {
                          AppThemeMode.light: AppStrings.light,
                          AppThemeMode.dark: AppStrings.dark,
                          AppThemeMode.system: AppStrings.system,
                        },
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ThemeSelector extends StatelessWidget {
  const _ThemeSelector({
    required this.selected,
    required this.background,
    required this.selectedBackground,
    required this.selectedForeground,
    required this.unselectedForeground,
    required this.onSelected,
    required this.labels,
  });

  final AppThemeMode selected;
  final Color background;
  final Color selectedBackground;
  final Color selectedForeground;
  final Color unselectedForeground;
  final ValueChanged<AppThemeMode> onSelected;
  final Map<AppThemeMode, String> labels;

  static const _options = AppThemeMode.values;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final selectedIndex = _options.indexOf(selected);
      return Container(
        height: 40,
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Stack(
          children: [
            AnimatedAlign(
              alignment: Alignment(-1.0 + selectedIndex.toDouble(), 0),
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeInOutCubic,
              child: SizedBox(
                width: constraints.maxWidth / _options.length,
                height: double.infinity,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: selectedBackground,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x120E1B2A),
                        blurRadius: 5,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Row(
              children: [
                for (final option in _options)
                  Expanded(
                    child: Semantics(
                      button: true,
                      selected: option == selected,
                      label: labels[option],
                      child: InkWell(
                        key: ValueKey('theme-option-${option.name}'),
                        borderRadius: BorderRadius.circular(14),
                        onTap: () => onSelected(option),
                        child: Center(
                          child: AnimatedDefaultTextStyle(
                            duration: const Duration(milliseconds: 160),
                            curve: Curves.easeOut,
                            style:
                                Theme.of(context).textTheme.bodyMedium
                                    ?.copyWith(
                                      color: option == selected
                                          ? selectedForeground
                                          : unselectedForeground,
                                      fontWeight: option == selected
                                          ? FontWeight.w600
                                          : FontWeight.w500,
                                    ) ??
                                TextStyle(
                                  color: option == selected
                                      ? selectedForeground
                                      : unselectedForeground,
                                ),
                            child: Text(labels[option]!),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      );
    },
  );
}
