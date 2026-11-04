import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../shared/widgets/async_value_view.dart';
import '../../../../shared/widgets/change_pill.dart';
import '../../../../shared/widgets/data_source_banner.dart';
import '../../../../shared/widgets/empty_view.dart';
import '../../../../shared/widgets/error_view.dart';
import '../../../../shared/widgets/shimmer_box.dart';
import '../../../settings/presentation/controllers/settings_controller.dart';
import '../../../watchlist/presentation/controllers/watchlist_controller.dart';
import '../../domain/coin.dart';
import '../../domain/market_filters.dart';
import '../../domain/market_models.dart';
import '../controllers/market_controller.dart';
import '../widgets/coin_row.dart';
import '../widgets/market_sheets.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tab = ref.watch(homeTabProvider);
    final period = ref.watch(changePeriodProvider);
    final filters = ref.watch(marketFiltersProvider);
    final currency =
        ref.watch(settingsControllerProvider).asData?.value.currency ?? 'usd';
    final listState = ref.watch(coinListControllerProvider);
    final trendingState = ref.watch(trendingControllerProvider);
    final visibleCoins = ref.watch(visibleCoinsProvider(tab));
    final AsyncValue<List<Coin>> selectedState = tab == HomeTab.trending
        ? trendingState.whenData((data) => data.items)
        : listState.whenData((data) => data.items);
    final source = tab == HomeTab.trending
        ? trendingState.asData?.value.dataSource ?? 'live'
        : listState.asData?.value.dataSource ?? 'live';

    final homeTheme = theme.brightness == Brightness.light
        ? theme.copyWith(
            scaffoldBackgroundColor: Colors.white,
            colorScheme: theme.colorScheme.copyWith(
              surface: Colors.white,
              surfaceContainerHighest: Colors.white,
            ),
          )
        : theme;

    return Theme(
      data: homeTheme,
      child: Scaffold(
        backgroundColor: homeTheme.scaffoldBackgroundColor,
        body: SafeArea(
          top: true,
          bottom: false,
          child: RefreshIndicator(
            onRefresh: _refresh,
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSizes.screenPadding,
                      AppSizes.sm,
                      AppSizes.screenPadding,
                      AppSizes.sm,
                    ),
                    child: Column(
                      children: [
                        _searchSection(),
                        const SizedBox(height: AppSizes.md),
                        const GlobalStatsStrip(),
                      ],
                    ),
                  ),
                ),
                SliverPersistentHeader(
                  pinned: true,
                  delegate: _HomeControlsDelegate(
                    minHeight: AppSizes.homePinnedHeaderHeight,
                    maxHeight: AppSizes.homePinnedHeaderHeight,
                    child: _homeControls(tab, period, filters),
                  ),
                ),
                SliverToBoxAdapter(
                  child: AsyncValueView<List<Coin>>(
                    value: selectedState,
                    onRetry: tab == HomeTab.trending
                        ? () => ref
                              .read(trendingControllerProvider.notifier)
                              .refresh()
                        : () => ref
                              .read(coinListControllerProvider.notifier)
                              .refresh(),
                    loading: const _CoinRowsLoading(),
                    builder: (_) => Column(
                      children: [
                        DataSourceBanner(source: source),
                        if (visibleCoins.isEmpty)
                          Padding(
                            padding: const EdgeInsets.all(AppSizes.xl),
                            child: EmptyView(
                              title: tab == HomeTab.trending
                                  ? AppStrings.noTrending
                                  : AppStrings.noMatchingCoins,
                              actionLabel: tab == HomeTab.trending
                                  ? null
                                  : AppStrings.resetFilters,
                              onAction: tab == HomeTab.trending
                                  ? null
                                  : () => ref
                                        .read(marketFiltersProvider.notifier)
                                        .reset(),
                            ),
                          )
                        else
                          ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: visibleCoins.length,
                            itemBuilder: (context, index) {
                              final coin = visibleCoins[index];
                              return Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  CoinRow(
                                    coin: coin,
                                    currency: currency,
                                    period: period,
                                    onTap: () =>
                                        context.push('/coin/${coin.id}'),
                                  ),
                                  Divider(
                                    height: AppSizes.hairline,
                                    thickness: AppSizes.hairline,
                                    indent: AppSizes.screenPadding,
                                    endIndent: AppSizes.screenPadding,
                                    color: Theme.of(context).dividerColor,
                                  ),
                                ],
                              );
                            },
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _searchSection() {
    final query = ref.watch(searchQueryProvider);
    final results = ref.watch(searchResultsProvider);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            children: [
              TextField(
                controller: _searchController,
                onChanged: ref.read(searchQueryProvider.notifier).set,
                decoration: InputDecoration(
                  hintText: AppStrings.searchCoins,
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: query.isEmpty
                      ? null
                      : IconButton(
                          tooltip: AppStrings.clearSearch,
                          onPressed: () {
                            _searchController.clear();
                            ref.read(searchQueryProvider.notifier).set('');
                          },
                          icon: const Icon(Icons.close),
                        ),
                  filled: true,
                  fillColor: Theme.of(context)
                      .colorScheme
                      .surfaceContainerHighest,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                    borderSide: BorderSide.none,
                  ),
                  isDense: true,
                ),
              ),
              if (query.trim().length >= 2)
                Padding(
                  padding: const EdgeInsets.only(top: AppSizes.xs),
                  child: Material(
                    color: Theme.of(context).colorScheme.surface,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                      side: BorderSide(color: Theme.of(context).dividerColor),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: SizedBox(
                      height: AppSizes.searchResultsHeight,
                      child: results.when(
                        loading: () =>
                            const Center(child: CircularProgressIndicator()),
                        error: (error, _) => ErrorView(
                          message: error.toString(),
                          onRetry: () =>
                              ref.read(searchQueryProvider.notifier).set(query),
                        ),
                        data: (items) => items.isEmpty
                            ? const Center(child: Text(AppStrings.noCoinsFound))
                            : ListView.builder(
                                itemCount: items.length,
                                itemBuilder: (context, index) {
                                  final coin = items[index];
                                  return ListTile(
                                    dense: true,
                                    title: Text(coin.name),
                                    subtitle: Text(coin.symbol.toUpperCase()),
                                    onTap: () {
                                      _searchController.clear();
                                      ref
                                          .read(searchQueryProvider.notifier)
                                          .set('');
                                      context.push('/coin/${coin.id}');
                                    },
                                  );
                                },
                              ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        IconButton(
          tooltip: AppStrings.notifications,
          onPressed: () {
            FocusManager.instance.primaryFocus?.unfocus();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text(AppStrings.noNotifications)),
            );
          },
          icon: const Icon(Icons.notifications_none_rounded),
        ),
      ],
    );
  }

  Widget _homeControls(
    HomeTab tab,
    ChangePeriod period,
    MarketFilters filters,
  ) => Material(
    color: Theme.of(context).colorScheme.surface,
    child: Column(
      children: [
        Row(
          children: HomeTab.values
              .map(
                (item) => Expanded(
                  child: InkWell(
                    onTap: () =>
                        ref.read(homeTabProvider.notifier).select(item),
                    child: SizedBox(
                      height: AppSizes.homeTabHeight,
                      child: Column(
                        children: [
                          const Spacer(),
                          Text(
                            _tabLabel(item),
                            style: Theme.of(context).textTheme.labelLarge
                                ?.copyWith(
                                  color: item == tab
                                      ? Theme.of(context).colorScheme.onSurface
                                      : Theme.of(context)
                                            .colorScheme
                                            .onSurfaceVariant,
                                ),
                          ),
                          const Spacer(),
                          SizedBox(
                            height: AppSizes.homeTabUnderlineHeight,
                            child: Align(
                              alignment: Alignment.bottomCenter,
                              child: Container(
                                width: item == tab
                                    ? AppSizes.tabIndicatorWidth
                                    : 0,
                                height: AppSizes.homeTabUnderlineHeight,
                                color: item == tab
                                    ? AppColors.brand
                                    : Colors.transparent,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              )
              .toList(),
        ),
        Divider(
          height: AppSizes.hairline,
          thickness: AppSizes.hairline,
          color: Theme.of(context).dividerColor,
        ),
        SizedBox(
          height: AppSizes.homeControlsHeight,
          child: Padding(
            padding: EdgeInsets.zero,
            child: Row(
              children: [
                if (tab != HomeTab.trending)
                  Expanded(
                    flex: 3,
                    child: _MarketControlChip(
                      label:
                          '${AppStrings.top} ${ref.watch(rankLimitProvider)}',
                      onTap: () => _openSheet(const RankSheet()),
                    ),
                  ),
                if (tab != HomeTab.trending) const SizedBox(width: AppSizes.xs),
                Expanded(
                  flex: tab == HomeTab.trending ? 1 : 2,
                  child: _MarketControlChip(
                    label: period.label,
                    onTap: () => _openSheet(const PeriodSheet()),
                  ),
                ),
                const SizedBox(width: AppSizes.xs),
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    SizedBox(
                      width: AppSizes.filterButtonExtent,
                      child: IconButton(
                        tooltip: AppStrings.filter,
                        onPressed: () => _openSheet(const FilterSheet()),
                        icon: const Icon(Icons.tune_rounded),
                        padding: EdgeInsets.zero,
                        visualDensity: VisualDensity.compact,
                      ),
                    ),
                    if (filters.activeCount > 0)
                      Positioned(
                        top: 2,
                        right: 2,
                        child: CircleAvatar(
                          radius: AppSizes.filterBadgeRadius,
                          backgroundColor: Theme.of(context)
                              .colorScheme
                              .surfaceContainerHighest,
                          child: Text(
                            '${filters.activeCount}',
                            style: Theme.of(context).textTheme.labelSmall
                                ?.copyWith(
                                  fontSize: AppSizes.filterBadgeTextSize,
                                ),
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
        SizedBox(
          height: AppSizes.homeColumnHeaderHeight,
          child: Row(
            children: [
              Expanded(
                flex: 5,
                child: _SortHeader(
                  label: '#  ${AppStrings.coin}',
                  selected: filters.sortField == MarketSortField.marketCap,
                  ascending: filters.ascending,
                  onTap: () => _sortBy(MarketSortField.marketCap, filters),
                ),
              ),
              Expanded(
                flex: 4,
                child: _SortHeader(
                  label: AppStrings.price,
                  selected: filters.sortField == MarketSortField.price,
                  ascending: filters.ascending,
                  onTap: () => _sortBy(MarketSortField.price, filters),
                ),
              ),
              Expanded(
                flex: 3,
                child: _SortHeader(
                  label: '${period.label} %',
                  selected: filters.sortField == MarketSortField.priceChange,
                  ascending: filters.ascending,
                  onTap: () => _sortBy(MarketSortField.priceChange, filters),
                ),
              ),
            ],
          ),
        ),
        Divider(
          height: AppSizes.hairline,
          thickness: AppSizes.hairline,
          color: Theme.of(context).dividerColor,
        ),
      ],
    ),
  );

  String _tabLabel(HomeTab tab) => switch (tab) {
    HomeTab.all => AppStrings.allCoins,
    HomeTab.trending => AppStrings.trending,
    HomeTab.gainers => AppStrings.gainers,
    HomeTab.losers => AppStrings.losers,
  };

  void _sortBy(MarketSortField field, MarketFilters current) {
    final ascending = current.sortField == field
        ? !current.ascending
        : field == MarketSortField.priceChange;
    ref
        .read(marketFiltersProvider.notifier)
        .set(current.copyWith(sortField: field, ascending: ascending));
  }

  void _openSheet(Widget sheet) {
    FocusManager.instance.primaryFocus?.unfocus();
    showMarketSheet(context, sheet);
  }

  Future<void> _refresh() async {
    await Future.wait([
      ref.read(coinListControllerProvider.notifier).refresh(),
      ref.read(trendingControllerProvider.notifier).refresh(),
      ref.read(globalStatsControllerProvider.notifier).refresh(),
      ref.read(watchlistControllerProvider.notifier).refresh(),
    ]);
  }
}

class _SortHeader extends StatelessWidget {
  const _SortHeader({
    required this.label,
    required this.selected,
    required this.ascending,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final bool ascending;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSizes.xs),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                fontSize: AppSizes.homeColumnTitleFontSize,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          if (selected)
            Icon(
              ascending ? Icons.arrow_upward : Icons.arrow_downward,
              size: AppSizes.iconSmall,
            ),
        ],
      ),
    ),
  );
}

class _MarketControlChip extends StatelessWidget {
  const _MarketControlChip({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(AppSizes.radiusMd),
    child: SizedBox(
      height: AppSizes.marketControlChipHeight,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSizes.marketControlChipHorizontalPadding,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelMedium,
              ),
            ),
            const SizedBox(width: AppSizes.xs),
            const Icon(Icons.expand_more, size: AppSizes.iconMedium),
          ],
        ),
      ),
    ),
  );
}

class _CoinRowsLoading extends StatelessWidget {
  const _CoinRowsLoading();

  @override
  Widget build(BuildContext context) => Column(
    children: [
      for (var index = 0; index < AppSizes.loadingItemCount; index++) ...[
        const CoinRowSkeleton(),
        const Divider(height: AppSizes.hairline, thickness: AppSizes.hairline),
      ],
    ],
  );
}

class GlobalStatsStrip extends ConsumerWidget {
  const GlobalStatsStrip({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(globalStatsControllerProvider);
    final currency =
        ref.watch(settingsControllerProvider).asData?.value.currency ?? 'usd';
    final snapshot = stats.asData?.value;
    final cap = stats.isLoading
        ? const _MetricSkeleton()
        : _MetricCard(
            label: AppStrings.totalMarketCap,
            value: snapshot == null
                ? AppStrings.unavailableShort
                : Formatters.compact(
                    snapshot.totalMarketCap,
                    currencyCode: currency,
                  ),
            change: snapshot?.marketCapChange24hPct,
          );
    final volume = stats.isLoading
        ? const _MetricSkeleton()
        : _MetricCard(
            label: AppStrings.volume24h,
            value: snapshot == null
                ? AppStrings.unavailableShort
                : Formatters.compact(
                    snapshot.totalVolume24h,
                    currencyCode: currency,
                  ),
          );
    return Row(
      children: [
        Expanded(
          child: _OverviewTap(snapshot: snapshot, child: cap),
        ),
        const SizedBox(width: AppSizes.sm),
        Expanded(
          child: _OverviewTap(snapshot: snapshot, child: volume),
        ),
      ],
    );
  }
}

class _OverviewTap extends StatelessWidget {
  const _OverviewTap({required this.snapshot, required this.child});
  final MarketSnapshot? snapshot;
  final Widget child;

  @override
  Widget build(BuildContext context) => InkWell(
    borderRadius: BorderRadius.circular(AppSizes.radiusMd),
    onTap: () =>
        showMarketSheet(context, MarketOverviewSheet(snapshot: snapshot)),
    child: child,
  );
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({required this.label, required this.value, this.change});
  final String label;
  final String value;
  final double? change;

  @override
  Widget build(BuildContext context) => Container(
    height: AppSizes.marketCardHeight,
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
        const SizedBox(height: AppSizes.xs),
        Row(
          children: [
            Expanded(
              child: Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ),
            if (change != null) ChangePill(change: change, compact: true),
          ],
        ),
      ],
    ),
  );
}

class _MetricSkeleton extends StatelessWidget {
  const _MetricSkeleton();

  @override
  Widget build(BuildContext context) => Container(
    height: AppSizes.marketCardHeight,
    padding: const EdgeInsets.all(AppSizes.md),
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.surface,
      borderRadius: BorderRadius.circular(AppSizes.radiusMd),
    ),
    child: const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        ShimmerBox(width: 84, height: 12),
        SizedBox(height: AppSizes.sm),
        ShimmerBox(width: 120, height: 18),
      ],
    ),
  );
}

class _HomeControlsDelegate extends SliverPersistentHeaderDelegate {
  _HomeControlsDelegate({
    required this.minHeight,
    required this.maxHeight,
    required this.child,
  });

  final double minHeight;
  final double maxHeight;
  final Widget child;

  @override
  double get minExtent => minHeight;
  @override
  double get maxExtent => maxHeight;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) => child;

  @override
  bool shouldRebuild(covariant _HomeControlsDelegate oldDelegate) =>
      oldDelegate.minHeight != minHeight ||
      oldDelegate.maxHeight != maxHeight ||
      oldDelegate.child != child;
}
