import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/utils/formatters.dart';
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
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(
        top: Radius.circular(AppSizes.radiusLg),
      ),
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
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(title, style: Theme.of(context).textTheme.titleLarge),
            ),
          ),
          Flexible(fit: FlexFit.loose, child: child),
          footer ?? const SizedBox.shrink(),
        ],
      ),
    ),
  );
}

class RankSheet extends ConsumerWidget {
  const RankSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) => BottomSheetScaffold(
    title: AppStrings.topCoins,
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSizes.screenPadding),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [50, 100, 200, 250]
            .map(
              (limit) => _SelectionTile(
                title: '$limit',
                selected: ref.watch(rankLimitProvider) == limit,
                onTap: () {
                  HapticFeedback.selectionClick();
                  ref.read(rankLimitProvider.notifier).set(limit);
                  Navigator.of(context).pop();
                },
              ),
            )
            .toList(),
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

  static const _categories = <(String, String?)>[
    (AppStrings.all, null),
    (AppStrings.defi, 'decentralized-finance-defi'),
    (AppStrings.layer1, 'layer-1'),
    (AppStrings.layer2, 'layer-2'),
    (AppStrings.meme, 'meme-token'),
    (AppStrings.artificialIntelligence, 'artificial-intelligence'),
    (AppStrings.gaming, 'gaming'),
    (AppStrings.stablecoins, 'stablecoins'),
  ];

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
          TextButton(
            onPressed: () => setState(() => _draft = _draft.reset()),
            child: const Text(AppStrings.reset),
          ),
          const Spacer(),
          FilledButton(
            onPressed: () {
              ref.read(marketFiltersProvider.notifier).set(_draft);
              Navigator.of(context).pop();
            },
            child: Text('${AppStrings.apply} (${_draft.activeCount})'),
          ),
        ],
      ),
    ),
    child: SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: AppSizes.screenPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _heading(AppStrings.sortBy),
          ...MarketSortField.values.map(
            (field) => _SelectionTile(
              title: _sortLabel(field),
              selected: _draft.sortField == field,
              onTap: () =>
                  _edit((filters) => filters.copyWith(sortField: field)),
            ),
          ),
          Row(
            children: [
              TextButton(
                onPressed: () =>
                    _edit((filters) => filters.copyWith(ascending: true)),
                child: Text(
                  AppStrings.ascending,
                  style: TextStyle(
                    fontWeight: _draft.ascending
                        ? FontWeight.w700
                        : FontWeight.normal,
                  ),
                ),
              ),
              TextButton(
                onPressed: () =>
                    _edit((filters) => filters.copyWith(ascending: false)),
                child: Text(
                  AppStrings.descending,
                  style: TextStyle(
                    fontWeight: !_draft.ascending
                        ? FontWeight.w700
                        : FontWeight.normal,
                  ),
                ),
              ),
            ],
          ),
          _heading(AppStrings.category),
          ..._categories.map(
            (entry) => _SelectionTile(
              title: entry.$1,
              selected: entry.$2 == _draft.category,
              onTap: () => _edit(
                (filters) => entry.$2 == null
                    ? filters.copyWith(clearCategory: true)
                    : filters.copyWith(category: entry.$2),
              ),
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
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text(AppStrings.watchlistedOnly),
            value: _draft.watchlistedOnly,
            onChanged: (value) =>
                _edit((filters) => filters.copyWith(watchlistedOnly: value)),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text(AppStrings.hideStablecoins),
            value: _draft.hideStablecoins,
            onChanged: (value) =>
                _edit((filters) => filters.copyWith(hideStablecoins: value)),
          ),
        ],
      ),
    ),
  );

  Widget _heading(String label) => Padding(
    padding: EdgeInsets.zero,
    child: Text(label, style: Theme.of(context).textTheme.titleMedium),
  );

  String _sortLabel(MarketSortField field) => switch (field) {
    MarketSortField.marketCap => AppStrings.marketCap,
    MarketSortField.price => AppStrings.price,
    MarketSortField.priceChange => AppStrings.priceChangeSort,
    MarketSortField.volume => AppStrings.volume,
  };

  Widget _choiceGroup(
    String title,
    String selected,
    List<(String, String)> options,
    ValueChanged<String> onChanged,
  ) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _heading(title),
      ...options.map(
        (option) => _SelectionTile(
          title: option.$2,
          selected: option.$1 == selected,
          onTap: () => onChanged(option.$1),
        ),
      ),
    ],
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
