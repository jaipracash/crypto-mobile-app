import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../shared/widgets/change_pill.dart';
import '../../domain/market_filters.dart';
import '../../domain/market_models.dart';
import '../controllers/market_controller.dart';

Future<T?> showMarketSheet<T>(BuildContext context, Widget child) =>
    showModalBottomSheet<T>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      constraints: BoxConstraints(
        maxHeight:
            MediaQuery.sizeOf(context).height * AppSizes.sheetMaxHeightFraction,
      ),
      builder: (_) => child,
    );

class BottomSheetScaffold extends StatelessWidget {
  const BottomSheetScaffold({
    required this.title,
    required this.child,
    this.footer,
    super.key,
  });

  final String title;
  final Widget child;
  final Widget? footer;

  @override
  Widget build(BuildContext context) => Material(
    color: Theme.of(context).colorScheme.surface,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppSizes.radiusLg),
    ),
    clipBehavior: Clip.antiAlias,
    child: SafeArea(
      top: false,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: AppSizes.md),
          Container(
            width: AppSizes.sheetHandleWidth,
            height: AppSizes.sheetHandleHeight,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.onSurfaceVariant
                  .withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(AppSizes.radiusPill),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSizes.lg),
            child: SizedBox(
              width: double.infinity,
              child: Center(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
            ),
          ),
          Flexible(fit: FlexFit.loose, child: child),
          footer ?? const SizedBox.shrink(),
        ],
      ),
    ),
  );
}

class PeriodSheet extends ConsumerWidget {
  const PeriodSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(changePeriodProvider);
    return BottomSheetScaffold(
      title: AppStrings.changePeriod,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSizes.screenPadding),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: ChangePeriod.values
              .map(
                (period) => _SelectionTile(
                  title: period.label,
                  selected: selected == period,
                  onTap: () {
                    HapticFeedback.selectionClick();
                    ref.read(changePeriodProvider.notifier).set(period);
                    Navigator.of(context).pop();
                  },
                ),
              )
              .toList(),
        ),
      ),
    );
  }
}

class FilterSheet extends ConsumerStatefulWidget {
  const FilterSheet({super.key});

  @override
  ConsumerState<FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends ConsumerState<FilterSheet> {
  late MarketFilters _draft;

  @override
  void initState() {
    super.initState();
    _draft = ref.read(marketFiltersProvider);
  }

  void _edit(MarketFilters Function(MarketFilters) update) {
    HapticFeedback.selectionClick();
    setState(() => _draft = update(_draft));
  }

  @override
  Widget build(BuildContext context) => BottomSheetScaffold(
    title: AppStrings.filter,
    footer: Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSizes.screenPadding),
      child: Row(
        children: [
          Expanded(
            child: FilledButton(
              onPressed: () => setState(() => _draft = _draft.reset()),
              child: const Text(AppStrings.reset),
              style: _sheetButtonStyle(
                context,
                backgroundColor: Theme.of(context)
                    .colorScheme
                    .surfaceContainerHighest,
                foregroundColor: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ),
          const SizedBox(width: AppSizes.sm),
          Expanded(
            child: FilledButton(
              onPressed: () {
                ref.read(marketFiltersProvider.notifier).set(_draft);
                Navigator.of(context).pop();
              },
              child: Text('${AppStrings.apply} (${_draft.activeCount})'),
              style: _sheetButtonStyle(context),
            ),
          ),
        ],
      ),
    ),
    child: SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(
        AppSizes.screenPadding,
        AppSizes.md,
        AppSizes.screenPadding,
        AppSizes.lg,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _choiceGroup(
            AppStrings.showTop,
            _draft.topLimit.toString(),
            const [
              ('50', 'Top 50'),
              ('100', 'Top 100'),
              ('200', 'Top 200'),
              ('250', 'Top 250'),
            ],
            (value) => _edit(
              (filters) => filters.copyWith(topLimit: int.parse(value)),
            ),
          ),
          _choiceGroup(AppStrings.marketCap, _draft.marketCap, const [
            ('any', AppStrings.any),
            ('large', AppStrings.marketCapLarge),
            ('mid', AppStrings.marketCapMid),
            ('small', AppStrings.marketCapSmall),
          ], (value) => _edit((filters) => filters.copyWith(marketCap: value))),
          _choiceGroup(AppStrings.volume24h, _draft.volume, const [
            ('any', AppStrings.any),
            ('100m', AppStrings.volumeOver100m),
            ('10m', AppStrings.volumeOver10m),
            ('1m', AppStrings.volumeOver1m),
          ], (value) => _edit((filters) => filters.copyWith(volume: value))),
          _choiceGroup(AppStrings.price, _draft.price, const [
            ('any', AppStrings.any),
            ('under1', AppStrings.priceUnder1),
            ('1to100', AppStrings.price1To100),
            ('over100', AppStrings.priceOver100),
          ], (value) => _edit((filters) => filters.copyWith(price: value))),
        ],
      ),
    ),
  );

  Widget _choiceGroup(
    String title,
    String selected,
    List<(String, String)> options,
    ValueChanged<String> onChanged,
  ) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Padding(
        padding: const EdgeInsets.only(bottom: AppSizes.sm),
        child: Text(title, style: Theme.of(context).textTheme.titleSmall),
      ),
      Wrap(
        spacing: AppSizes.sm,
        runSpacing: AppSizes.xs,
        children: options.map((option) {
          final isSelected = option.$1 == selected;
          return _sheetChoiceChip(
            context,
            label: option.$2,
            selected: isSelected,
            onSelected: () => onChanged(option.$1),
          );
        }).toList(),
      ),
      const SizedBox(height: AppSizes.lg),
    ],
  );
}

class SortSheet extends ConsumerStatefulWidget {
  const SortSheet({super.key});

  @override
  ConsumerState<SortSheet> createState() => _SortSheetState();
}

class _SortSheetState extends ConsumerState<SortSheet> {
  late MarketSortField _field;
  late bool _ascending;

  @override
  void initState() {
    super.initState();
    final filters = ref.read(marketFiltersProvider);
    _field = filters.sortField;
    _ascending = filters.ascending;
  }

  @override
  Widget build(BuildContext context) => BottomSheetScaffold(
    title: AppStrings.sortCoins,
    footer: Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSizes.screenPadding),
      child: SizedBox(
        width: double.infinity,
        child: FilledButton(
          onPressed: () {
            ref
                .read(marketFiltersProvider.notifier)
                .set(
                  ref
                      .read(marketFiltersProvider)
                      .copyWith(sortField: _field, ascending: _ascending),
                );
            Navigator.of(context).pop();
          },
          child: const Text(AppStrings.apply),
          style: _sheetButtonStyle(context),
        ),
      ),
    ),
    child: Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSizes.screenPadding,
        AppSizes.lg,
        AppSizes.screenPadding,
        AppSizes.xl,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppStrings.sortBy,
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: AppSizes.sm),
          Wrap(
            spacing: AppSizes.sm,
            runSpacing: AppSizes.xs,
            children: MarketSortField.values.map((field) {
              final selected = field == _field;
              return _sheetChoiceChip(
                context,
                label: _sortLabel(field),
                selected: selected,
                onSelected: () => setState(() => _field = field),
              );
            }).toList(),
          ),
          const SizedBox(height: AppSizes.lg),
          Text(AppStrings.order, style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: AppSizes.sm),
          Wrap(
            spacing: AppSizes.sm,
            children: [
              _directionChip(AppStrings.ascending, true),
              _directionChip(AppStrings.descending, false),
            ],
          ),
        ],
      ),
    ),
  );

  Widget _directionChip(String label, bool ascending) => _sheetChoiceChip(
    context,
    label: label,
    selected: _ascending == ascending,
    onSelected: () => setState(() => _ascending = ascending),
  );

  String _sortLabel(MarketSortField field) => switch (field) {
    MarketSortField.marketCap => AppStrings.marketCap,
    MarketSortField.price => AppStrings.price,
    MarketSortField.priceChange => AppStrings.priceChangeSort,
    MarketSortField.volume => AppStrings.volume,
  };
}

Widget _sheetChoiceChip(
  BuildContext context, {
  required String label,
  required bool selected,
  required VoidCallback onSelected,
}) => ChoiceChip(
  label: Text(
    label,
    style: Theme.of(context).textTheme.labelMedium?.copyWith(
      color: selected
          ? Theme.of(context).colorScheme.onPrimary
          : Theme.of(context).colorScheme.onSurface,
    ),
  ),
  selected: selected,
  onSelected: (_) => onSelected(),
  showCheckmark: false,
  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
  visualDensity: VisualDensity.compact,
  padding: const EdgeInsets.symmetric(horizontal: AppSizes.xs),
  labelPadding: const EdgeInsets.symmetric(horizontal: AppSizes.xs),
  selectedColor: Theme.of(context).colorScheme.primary,
  backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
  shape: const StadiumBorder(),
  side: BorderSide.none,
);

ButtonStyle _sheetButtonStyle(
  BuildContext context, {
  Color? backgroundColor,
  Color? foregroundColor,
}) => FilledButton.styleFrom(
  backgroundColor: backgroundColor,
  foregroundColor: foregroundColor,
  minimumSize: const Size(0, 44),
  padding: const EdgeInsets.symmetric(horizontal: AppSizes.md),
  shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(AppSizes.radiusMd),
  ),
  textStyle: Theme.of(context).textTheme.labelLarge,
);

class MarketOverviewPanel extends StatelessWidget {
  const MarketOverviewPanel({
    required this.snapshot,
    required this.currency,
    super.key,
  });

  final MarketSnapshot snapshot;
  final String currency;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasDominance = [
      snapshot.btcDominance,
      snapshot.ethDominance,
      snapshot.othersDominance,
    ].any((value) => value != null && value > 0);

    return Padding(
      padding: const EdgeInsets.all(AppSizes.screenPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(AppStrings.globalMarket, style: theme.textTheme.titleLarge),
          const SizedBox(height: AppSizes.md),
          Row(
            children: [
              Expanded(
                child: _overviewMetric(
                  context,
                  label: AppStrings.totalMarketCap,
                  value: Formatters.compact(
                    snapshot.totalMarketCap,
                    currencyCode: currency,
                  ),
                  change: snapshot.marketCapChange24hPct,
                ),
              ),
              const SizedBox(width: AppSizes.sm),
              Expanded(
                child: _overviewMetric(
                  context,
                  label: AppStrings.volume24h,
                  value: Formatters.compact(
                    snapshot.totalVolume24h,
                    currencyCode: currency,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSizes.md),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSizes.lg),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(AppSizes.radiusMd),
              border: Border.all(color: theme.dividerColor),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppStrings.marketDominance,
                  style: theme.textTheme.titleMedium,
                ),
                const SizedBox(height: AppSizes.md),
                if (hasDominance)
                  Row(
                    children: [
                      SizedBox(
                        width: 148,
                        height: 148,
                        child: PieChart(
                          PieChartData(
                            centerSpaceRadius: AppSizes.donutCenter,
                            sectionsSpace: AppSizes.donutSectionGap,
                            sections: [
                              _section(snapshot.btcDominance, AppColors.btc),
                              _section(snapshot.ethDominance, AppColors.eth),
                              _section(
                                snapshot.othersDominance,
                                AppColors.other,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSizes.md),
                      Expanded(
                        child: Column(
                          children: [
                            _dominanceRow(
                              context,
                              AppStrings.btc,
                              snapshot.btcDominance,
                              AppColors.btc,
                            ),
                            _dominanceRow(
                              context,
                              AppStrings.eth,
                              snapshot.ethDominance,
                              AppColors.eth,
                            ),
                            _dominanceRow(
                              context,
                              AppStrings.others,
                              snapshot.othersDominance,
                              AppColors.other,
                            ),
                          ],
                        ),
                      ),
                    ],
                  )
                else
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: AppSizes.xl),
                    child: Center(
                      child: Text(
                        AppStrings.notAvailable,
                        style: theme.textTheme.bodyMedium,
                      ),
                    ),
                  ),
                const Divider(height: AppSizes.xl),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        AppStrings.activeCoins,
                        style: theme.textTheme.bodyMedium,
                      ),
                    ),
                    Text(
                      snapshot.activeCoins?.toString() ??
                          AppStrings.notAvailable,
                      style: theme.textTheme.titleMedium,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _overviewMetric(
    BuildContext context, {
    required String label,
    required String value,
    double? change,
  }) => Container(
    height: 112,
    padding: const EdgeInsets.all(AppSizes.md),
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.surface,
      borderRadius: BorderRadius.circular(AppSizes.radiusMd),
      border: Border.all(color: Theme.of(context).dividerColor),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(label, style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: AppSizes.sm),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        if (change != null) ...[
          const SizedBox(height: AppSizes.xs),
          ChangePill(change: change, compact: true),
        ],
      ],
    ),
  );

  PieChartSectionData _section(double? value, Color color) =>
      PieChartSectionData(
        value: value ?? 0,
        color: color,
        radius: AppSizes.donutRadius,
        showTitle: false,
      );

  Widget _dominanceRow(
    BuildContext context,
    String label,
    double? value,
    Color color,
  ) => Padding(
    padding: const EdgeInsets.symmetric(vertical: AppSizes.xs),
    child: Row(
      children: [
        Icon(Icons.circle, size: AppSizes.legendDot, color: color),
        const SizedBox(width: AppSizes.sm),
        Expanded(child: Text(label)),
        Text(
          value == null
              ? AppStrings.notAvailable
              : '${value.toStringAsFixed(2)}%',
          style: Theme.of(context).textTheme.labelLarge,
        ),
      ],
    ),
  );
}

class _SelectionTile extends StatelessWidget {
  const _SelectionTile({
    required this.title,
    required this.selected,
    required this.onTap,
  });

  final String title;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => ListTile(
    dense: true,
    contentPadding: EdgeInsets.zero,
    title: Text(title),
    trailing: selected
        ? Icon(Icons.check, color: Theme.of(context).colorScheme.onSurface)
        : const SizedBox(width: AppSizes.iconMedium),
    onTap: onTap,
  );
}

class MarketOverviewSheet extends StatelessWidget {
  const MarketOverviewSheet({required this.snapshot, super.key});
  final MarketSnapshot? snapshot;

  @override
  Widget build(BuildContext context) => BottomSheetScaffold(
    title: AppStrings.marketOverview,
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSizes.screenPadding),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            height: AppSizes.statsChartHeight,
            child: PieChart(
              PieChartData(
                centerSpaceRadius: AppSizes.donutCenter,
                sectionsSpace: AppSizes.donutSectionGap,
                sections: [
                  _section(snapshot?.btcDominance, AppColors.btc),
                  _section(snapshot?.ethDominance, AppColors.eth),
                  _section(snapshot?.othersDominance, AppColors.other),
                ],
              ),
            ),
          ),
          _legend(
            context,
            AppStrings.btc,
            snapshot?.btcDominance,
            AppColors.btc,
          ),
          _legend(
            context,
            AppStrings.eth,
            snapshot?.ethDominance,
            AppColors.eth,
          ),
          _legend(
            context,
            AppStrings.others,
            snapshot?.othersDominance,
            AppColors.other,
          ),
          const SizedBox(height: AppSizes.lg),
          _metric(
            context,
            AppStrings.activeCoins,
            snapshot?.activeCoins?.toString() ?? AppStrings.notAvailable,
          ),
          _metric(
            context,
            AppStrings.marketCapChange,
            Formatters.percent(snapshot?.marketCapChange24hPct),
          ),
        ],
      ),
    ),
  );

  PieChartSectionData _section(double? value, Color color) =>
      PieChartSectionData(
        value: value ?? 0,
        color: color,
        radius: AppSizes.donutRadius,
        showTitle: false,
      );

  Widget _legend(
    BuildContext context,
    String label,
    double? value,
    Color color,
  ) => Row(
    children: [
      Icon(Icons.circle, size: AppSizes.legendDot, color: color),
      const SizedBox(width: AppSizes.sm),
      Expanded(child: Text(label)),
      Text(
        value == null
            ? AppStrings.notAvailable
            : '${value.toStringAsFixed(2)}%',
      ),
    ],
  );

  Widget _metric(BuildContext context, String label, String value) => Row(
    children: [
      Expanded(
        child: Text(label, style: Theme.of(context).textTheme.bodySmall),
      ),
      Text(value, style: Theme.of(context).textTheme.titleMedium),
    ],
  );
}
