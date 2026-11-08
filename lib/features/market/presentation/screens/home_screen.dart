import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/router/routes.dart';
import '../../../../shared/widgets/async_value_view.dart';
import '../../../../shared/widgets/change_pill.dart';
import '../../../../shared/widgets/app_loader.dart';
import '../../../../shared/widgets/empty_view.dart';
import '../../../../shared/widgets/shimmer_box.dart';
import '../../../../shared/widgets/simulated_price_banner.dart';
import '../../../settings/presentation/controllers/settings_controller.dart';
import '../../../watchlist/presentation/controllers/watchlist_controller.dart';
import '../../domain/coin.dart';
import '../../domain/market_filters.dart';
import '../../domain/market_models.dart';
import '../controllers/live_price_controller.dart';
import '../controllers/market_controller.dart';
import '../widgets/coin_row.dart';
import '../widgets/market_sheets.dart';
import 'search_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final ScrollController _tabsController = ScrollController();
  Offset? _tabSwipeStart;
  int _tabSlideDirection = 1;

  @override
  void dispose() {
    _tabsController.dispose();
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
                    padding: EdgeInsets.fromLTRB(
                      AppSizes.screenPadding.w,
                      AppSizes.sm.w,
                      AppSizes.screenPadding.w,
                      AppSizes.sm.w,
                    ),
                    child: Column(
                      children: [
                        _searchSection(),
                        SizedBox(height: AppSizes.md.w),
                        const GlobalStatsStrip(),
                      ],
                    ),
                  ),
                ),
                SliverPersistentHeader(
                  pinned: true,
                  delegate: _HomeControlsDelegate(
                    minHeight: AppSizes.homePinnedHeaderHeight.h,
                    maxHeight: AppSizes.homePinnedHeaderHeight.h,
                    child: _homeControls(tab, filters),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Listener(
                    onPointerDown: (event) => _tabSwipeStart = event.position,
                    onPointerUp: (event) =>
                        _handleTabSwipe(event.position, tab),
                    onPointerCancel: (_) => _tabSwipeStart = null,
                    child: ClipRect(
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 280),
                        reverseDuration: const Duration(milliseconds: 240),
                        switchInCurve: Curves.easeOutCubic,
                        switchOutCurve: Curves.easeInCubic,
                        transitionBuilder: (child, animation) =>
                            SlideTransition(
                              position: Tween<Offset>(
                                begin: Offset(_tabSlideDirection.toDouble(), 0),
                                end: Offset.zero,
                              ).animate(animation),
                              child: FadeTransition(
                                opacity: animation,
                                child: child,
                              ),
                            ),
                        child: KeyedSubtree(
                          key: ValueKey(tab),
                          child: tab == HomeTab.overview
                              ? _overviewSection(currency)
                              : AsyncValueView<List<Coin>>(
                                  value: selectedState,
                                  onRetry: tab == HomeTab.trending
                                      ? () => ref
                                            .read(
                                              trendingControllerProvider
                                                  .notifier,
                                            )
                                            .refresh()
                                      : () => ref
                                            .read(
                                              coinListControllerProvider
                                                  .notifier,
                                            )
                                            .refresh(),
                                  loading: _CoinRowsLoading(period: period),
                                  builder: (_) => _coinListSection(
                                    tab: tab,
                                    coins: visibleCoins,
                                    currency: currency,
                                    period: period,
                                  ),
                                ),
                        ),
                      ),
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

  void _handleTabSwipe(Offset end, HomeTab currentTab) {
    final start = _tabSwipeStart;
    _tabSwipeStart = null;
    if (start == null) return;

    final delta = end - start;
    if (delta.dx.abs() < 64 || delta.dx.abs() < delta.dy.abs() * 1.3) return;

    final currentIndex = HomeTab.values.indexOf(currentTab);
    final nextIndex = (currentIndex + (delta.dx < 0 ? 1 : -1)).clamp(
      0,
      HomeTab.values.length - 1,
    );
    if (nextIndex != currentIndex) {
      _selectTab(HomeTab.values[nextIndex], direction: delta.dx < 0 ? 1 : -1);
    }
  }

  void _selectTab(HomeTab tab, {int? direction}) {
    final currentTab = ref.read(homeTabProvider);
    if (currentTab == tab) return;
    final currentIndex = HomeTab.values.indexOf(currentTab);
    final nextIndex = HomeTab.values.indexOf(tab);
    _tabSlideDirection = direction ?? (nextIndex > currentIndex ? 1 : -1);
    ref.read(homeTabProvider.notifier).select(tab);
  }

  Widget _overviewSection(String currency) {
    final overview = ref.watch(globalStatsControllerProvider);
    return AsyncValueView<MarketSnapshot>(
      value: overview,
      onRetry: () => ref.read(globalStatsControllerProvider.notifier).refresh(),
      loading: SizedBox(
        height: AppSizes.marketCardHeight.h * 2,
        child: Center(child: AppLoader()),
      ),
      builder: (snapshot) => Column(
        children: [MarketOverviewPanel(snapshot: snapshot, currency: currency)],
      ),
    );
  }

  Widget _coinListSection({
    required HomeTab tab,
    required List<Coin> coins,
    required String currency,
    required ChangePeriod period,
  }) => Column(
    children: [
      if (ref.watch(liveCoinPricesProvider).isNotEmpty)
        const SimulatedPriceBanner(),
      if (coins.isEmpty)
        Padding(
          padding: EdgeInsets.all(AppSizes.xl.w),
          child: EmptyView(
            title: tab == HomeTab.trending
                ? AppStrings.noTrending
                : AppStrings.noMatchingCoins,
            actionLabel: tab == HomeTab.trending
                ? null
                : AppStrings.resetFilters,
            onAction: tab == HomeTab.trending
                ? null
                : () => ref.read(marketFiltersProvider.notifier).reset(),
          ),
        )
      else
        Column(
          children: [
            CoinTableHeader(
              period: period,
              onPeriodTap: () => _openSheet(const PeriodSheet()),
            ),
            for (final coin in coins) ...[
              CoinRow(
                coin: coin,
                currency: currency,
                period: period,
                onTap: () => context.push('/coin/${coin.id}'),
              ),
            ],
          ],
        ),
    ],
  );

  Widget _searchSection() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Hero(
            tag: SearchScreen.homeSearchHeroTag,
            child: Material(
              color: Colors.transparent,
              child: TextField(
                readOnly: true,
                onTap: () => context.go(Routes.search),
                decoration: InputDecoration(
                  hintText: AppStrings.searchCoins,
                  hintStyle: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  prefixIconConstraints: const BoxConstraints(
                    minWidth: 36,
                    minHeight: 48,
                  ),
                  prefixIcon: Padding(
                    padding: EdgeInsets.only(
                      left: AppSizes.md.w,
                      right: AppSizes.xs.w,
                    ),
                    child: SvgPicture.asset(
                      'assets/search2.svg',
                      width: 14,
                      height: 14,
                      colorFilter: ColorFilter.mode(
                        Theme.of(context).colorScheme.onSurfaceVariant,
                        BlendMode.srcIn,
                      ),
                    ),
                  ),
                  filled: true,
                  fillColor: Theme.of(context)
                      .colorScheme
                      .surfaceContainerHighest,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppSizes.radiusMd.r),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppSizes.radiusMd.r),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppSizes.radiusMd.r),
                    borderSide: BorderSide.none,
                  ),
                  isDense: true,
                ),
              ),
            ),
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
          icon: _controlIcon('assets/notification-6-svgrepo-com.svg', size: 36),
        ),
      ],
    );
  }

  Widget _homeControls(HomeTab tab, MarketFilters filters) => Material(
    color: Theme.of(context).colorScheme.surface,
    child: Container(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Theme.of(context).dividerColor, width: 0.5),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: AppSizes.homeTabHeight.h,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      SingleChildScrollView(
                        controller: _tabsController,
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: HomeTab.values
                              .map((item) => _homeTab(item, tab))
                              .toList(),
                        ),
                      ),
                      Positioned(
                        top: 0,
                        bottom: 0,
                        right: 0,
                        child: IgnorePointer(
                          child: Container(
                            width: AppSizes.xxl.w,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.centerLeft,
                                end: Alignment.centerRight,
                                colors: [
                                  Theme.of(context).colorScheme.surface
                                      .withValues(alpha: 0),
                                  Theme.of(context).colorScheme.surface,
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(
                height: AppSizes.homeTabHeight.h,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: AppSizes.filterButtonExtent.w,
                      height: AppSizes.homeTabHeight.h,
                      child: IconButton(
                        tooltip: AppStrings.sortCoins,
                        onPressed: () => _openSheet(const SortSheet()),
                        icon: _controlIcon(
                          'assets/sort-vertical-svgrepo-com.svg',
                        ),
                        padding: EdgeInsets.zero,
                        visualDensity: VisualDensity.compact,
                      ),
                    ),
                    SizedBox(
                      width: AppSizes.filterButtonExtent.w,
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          IconButton(
                            tooltip: AppStrings.filter,
                            onPressed: () => _openSheet(const FilterSheet()),
                            icon: _controlIcon(
                              'assets/filter-svgrepo-com.svg',
                              size: AppSizes.iconMedium.w,
                            ),
                            padding: EdgeInsets.zero,
                            visualDensity: VisualDensity.compact,
                          ),
                          if (filters.activeCount > 0)
                            Positioned(
                              top: 2,
                              right: 2,
                              child: CircleAvatar(
                                radius: AppSizes.filterBadgeRadius.r,
                                backgroundColor: Theme.of(context)
                                    .colorScheme
                                    .surfaceContainerHighest,
                                child: Text(
                                  '${filters.activeCount}',
                                  style: Theme.of(context).textTheme.labelSmall
                                      ?.copyWith(
                                        fontSize:
                                            AppSizes.filterBadgeTextSize.sp,
                                      ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    ),
  );

  Widget _homeTab(HomeTab item, HomeTab selectedTab) => InkWell(
    onTap: () => _selectTab(item),
    child: SizedBox(
      width: switch (item) {
        HomeTab.overview => 82,
        HomeTab.all => 54,
        HomeTab.trending => 78,
        HomeTab.gainers => 108,
        HomeTab.losers => 66,
      },
      height: AppSizes.homeTabHeight.h,
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          Center(
            child: Text(
              _tabLabel(item),
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: item == selectedTab
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.onSurfaceVariant,
                fontWeight: item == selectedTab
                    ? FontWeight.w700
                    : FontWeight.w600,
              ),
            ),
          ),
          if (item == selectedTab)
            Container(
              width: AppSizes.tabIndicatorWidth.w,
              height: AppSizes.homeTabUnderlineHeight.h,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                borderRadius: BorderRadius.circular(AppSizes.radiusPill.r),
              ),
            ),
        ],
      ),
    ),
  );

  Widget _controlIcon(String asset, {double size = AppSizes.iconLarge}) =>
      SvgPicture.asset(
        asset,
        width: size.w,
        height: size.w,
        fit: BoxFit.contain,
        colorFilter: ColorFilter.mode(
          Theme.of(context).colorScheme.onSurfaceVariant,
          BlendMode.srcIn,
        ),
      );

  String _tabLabel(HomeTab tab) => switch (tab) {
    HomeTab.all => AppStrings.allCoins,
    HomeTab.trending => AppStrings.trending,
    HomeTab.overview => AppStrings.overview,
    HomeTab.gainers => AppStrings.topGainers,
    HomeTab.losers => AppStrings.losers,
  };

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

class _CoinRowsLoading extends StatelessWidget {
  const _CoinRowsLoading({required this.period});

  final ChangePeriod period;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      CoinTableHeader(period: period, onPeriodTap: () {}),
      for (var index = 0; index < AppSizes.loadingItemCount; index++)
        const CoinRowSkeleton(),
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
        SizedBox(width: AppSizes.sm.w),
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
    borderRadius: BorderRadius.circular(AppSizes.radiusMd.r),
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
    height: AppSizes.marketCardHeight.h,
    padding: EdgeInsets.all(AppSizes.md.w),
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.surface,
      borderRadius: BorderRadius.circular(AppSizes.radiusMd.r),
      border: Border.all(color: Theme.of(context).dividerColor),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(label, style: Theme.of(context).textTheme.bodySmall),
        SizedBox(height: AppSizes.xs.w),
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
    height: AppSizes.marketCardHeight.h,
    padding: EdgeInsets.all(AppSizes.md.w),
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.surface,
      borderRadius: BorderRadius.circular(AppSizes.radiusMd.r),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        ShimmerBox(width: 84, height: 12),
        SizedBox(height: AppSizes.sm.w),
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
  ) => SizedBox(height: maxExtent, child: child);

  @override
  bool shouldRebuild(covariant _HomeControlsDelegate oldDelegate) =>
      oldDelegate.minHeight != minHeight ||
      oldDelegate.maxHeight != maxHeight ||
      oldDelegate.child != child;
}
