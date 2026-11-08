import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/router/routes.dart';
import '../../../../features/market/presentation/controllers/market_controller.dart';
import '../../../../features/market/presentation/controllers/live_price_controller.dart';
import '../../../../features/market/presentation/widgets/coin_row.dart';
import '../../../../shared/widgets/async_value_view.dart';
import '../../../market/domain/coin.dart';
import '../../../settings/presentation/controllers/settings_controller.dart';
import '../controllers/watchlist_controller.dart';

enum _WatchlistSort { name, price, change24h }

enum _WatchlistFilter { all, gainers, losers }

class WatchlistScreen extends ConsumerStatefulWidget {
  const WatchlistScreen({super.key});

  @override
  ConsumerState<WatchlistScreen> createState() => _WatchlistScreenState();
}

class _WatchlistScreenState extends ConsumerState<WatchlistScreen> {
  _WatchlistSort _sort = _WatchlistSort.change24h;
  _WatchlistFilter _filter = _WatchlistFilter.all;
  bool _ascending = false;

  @override
  Widget build(BuildContext context) {
    final ref = this.ref;
    final theme = Theme.of(context);
    final backgroundColor = theme.brightness == Brightness.light
        ? Colors.white
        : theme.scaffoldBackgroundColor;
    final coins = ref.watch(watchlistControllerProvider);
    final currency =
        ref.watch(settingsControllerProvider).asData?.value.currency ?? 'usd';
    final livePrices = ref.watch(liveCoinPricesProvider);
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: const Text(AppStrings.watchlist),
        backgroundColor: backgroundColor,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      body: RefreshIndicator(
        onRefresh: () =>
            ref.read(watchlistControllerProvider.notifier).refresh(),
        child: AsyncValueView(
          value: coins,
          onRetry: () =>
              ref.read(watchlistControllerProvider.notifier).refresh(),
          builder: (data) {
            final items = data.items;
            if (items.isEmpty) {
              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  SizedBox(
                    height:
                        MediaQuery.sizeOf(context).height *
                        AppSizes.emptyStateHeightFraction,
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: AppSizes.xl.w),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SvgPicture.asset(
                            'assets/not_added.svg',
                            width: 176,
                            height: 176,
                          ),
                          SizedBox(height: AppSizes.lg.w),
                          Text(
                            AppStrings.emptyWatchlist,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          SizedBox(height: AppSizes.xs.w),
                          Text(
                            AppStrings.saveCoinsMessage,
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          SizedBox(height: AppSizes.lg.w),
                          _addCoinsButton(context),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            }
            final visibleItems = _sortAndFilter(
              items
                  .map(
                    (coin) =>
                        withLivePrice(coin, livePrices, currency: currency),
                  )
                  .toList(),
            );
            return ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                _watchlistControls(context, visibleItems.length),
                if (visibleItems.isEmpty)
                  Padding(
                    padding: EdgeInsets.all(AppSizes.xl.w),
                    child: Center(
                      child: Text(
                        _filter == _WatchlistFilter.gainers
                            ? AppStrings.noGainers
                            : AppStrings.noLosers,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                  ),
                ...visibleItems.map(
                  (coin) => Dismissible(
                    key: ValueKey(coin.id),
                    direction: DismissDirection.endToStart,
                    background: Container(
                      alignment: Alignment.centerRight,
                      padding: EdgeInsets.only(right: AppSizes.xl.w),
                      color: Theme.of(context).colorScheme.error,
                      child: Icon(
                        Icons.delete_outline,
                        color: Theme.of(context).colorScheme.onError,
                      ),
                    ),
                    onDismissed: (_) => _remove(context, ref, coin),
                    child: CoinRow(
                      coin: coin.copyWith(isWatchlisted: true),
                      currency: currency,
                      period: ChangePeriod.day,
                      onTap: () => context.push('/coin/${coin.id}'),
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.only(
                    top: AppSizes.md.w,
                    bottom: AppSizes.xl.w,
                  ),
                  child: _addCoinsButton(context, withIcon: true),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _addCoinsButton(BuildContext context, {bool withIcon = false}) {
    final style = FilledButton.styleFrom(
      backgroundColor: Theme.of(context).colorScheme.primary,
      foregroundColor: Colors.white,
    );
    final label = Text(
      AppStrings.addCoins,
      style: Theme.of(context).textTheme.labelLarge?.copyWith(
        color: Colors.white,
        fontSize: 16,
        fontWeight: FontWeight.w700,
      ),
    );
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: AppSizes.screenPadding.w),
      child: SizedBox(
        width: double.infinity,
        child: withIcon
            ? FilledButton.icon(
                style: style,
                onPressed: () => context.push(Routes.addWatchlistCoins),
                icon: const Icon(Icons.add_rounded),
                label: label,
              )
            : FilledButton(
                style: style,
                onPressed: () => context.push(Routes.addWatchlistCoins),
                child: label,
              ),
      ),
    );
  }

  List<Coin> _sortAndFilter(List<Coin> coins) {
    final filtered = coins.where((coin) {
      final change = coin.change24hPct;
      return switch (_filter) {
        _WatchlistFilter.all => true,
        _WatchlistFilter.gainers => change != null && change > 0,
        _WatchlistFilter.losers => change != null && change < 0,
      };
    }).toList();

    int compare(Coin a, Coin b) {
      if (_sort == _WatchlistSort.name) {
        final result = a.name.toLowerCase().compareTo(b.name.toLowerCase());
        return _ascending ? result : -result;
      }

      final aValue = _sort == _WatchlistSort.price ? a.price : a.change24hPct;
      final bValue = _sort == _WatchlistSort.price ? b.price : b.change24hPct;
      if (aValue == null || bValue == null) {
        if (aValue == null && bValue == null) return 0;
        return aValue == null ? 1 : -1;
      }
      final result = aValue.compareTo(bValue);
      return _ascending ? result : -result;
    }

    filtered.sort(compare);
    return filtered;
  }

  Widget _watchlistControls(BuildContext context, int count) => Padding(
    padding: EdgeInsets.fromLTRB(
      AppSizes.screenPadding.w,
      AppSizes.sm.w,
      AppSizes.screenPadding.w,
      AppSizes.sm.w,
    ),
    child: Row(
      children: [
        Expanded(
          child: Text(
            '$count ${AppStrings.watchlist.toLowerCase()}',
            style: Theme.of(context).textTheme.bodySmall
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
        ),
        IconButton(
          tooltip: AppStrings.sortWatchlist,
          onPressed: () => _showSortOptions(context),
          icon: SvgPicture.asset(
            'assets/sort-vertical-svgrepo-com.svg',
            width: AppSizes.iconLarge.w,
            height: AppSizes.iconLarge.w,
            colorFilter: ColorFilter.mode(
              Theme.of(context).colorScheme.onSurfaceVariant,
              BlendMode.srcIn,
            ),
          ),
        ),
        IconButton(
          tooltip: AppStrings.filterWatchlist,
          onPressed: () => _showFilterOptions(context),
          icon: SvgPicture.asset(
            'assets/filter-svgrepo-com.svg',
            width: AppSizes.iconLarge.w,
            height: AppSizes.iconLarge.w,
            colorFilter: ColorFilter.mode(
              Theme.of(context).colorScheme.onSurfaceVariant,
              BlendMode.srcIn,
            ),
          ),
        ),
      ],
    ),
  );

  Future<void> _showSortOptions(BuildContext context) async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: EdgeInsets.all(AppSizes.md.w),
              child: Text(
                AppStrings.sortWatchlist,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            for (final option in _WatchlistSort.values)
              ListTile(
                title: Text(_sortLabel(option)),
                trailing: _sort == option
                    ? Icon(
                        _ascending
                            ? Icons.arrow_upward_rounded
                            : Icons.arrow_downward_rounded,
                        color: Theme.of(context).colorScheme.primary,
                      )
                    : null,
                onTap: () {
                  setState(() {
                    if (_sort == option) {
                      _ascending = !_ascending;
                    } else {
                      _sort = option;
                      _ascending = option == _WatchlistSort.name;
                    }
                  });
                  Navigator.of(context).pop();
                },
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _showFilterOptions(BuildContext context) async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: EdgeInsets.all(AppSizes.md.w),
              child: Text(
                AppStrings.filterWatchlist,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            for (final option in _WatchlistFilter.values)
              ListTile(
                title: Text(_filterLabel(option)),
                trailing: _filter == option
                    ? Icon(
                        Icons.check_rounded,
                        color: Theme.of(context).colorScheme.primary,
                      )
                    : null,
                onTap: () {
                  setState(() => _filter = option);
                  Navigator.of(context).pop();
                },
              ),
          ],
        ),
      ),
    );
  }

  String _sortLabel(_WatchlistSort sort) => switch (sort) {
    _WatchlistSort.name => AppStrings.name,
    _WatchlistSort.price => AppStrings.price,
    _WatchlistSort.change24h => AppStrings.change24h,
  };

  String _filterLabel(_WatchlistFilter filter) => switch (filter) {
    _WatchlistFilter.all => AppStrings.allCoinsFilter,
    _WatchlistFilter.gainers => AppStrings.gainers,
    _WatchlistFilter.losers => AppStrings.losers,
  };

  Future<void> _remove(BuildContext context, WidgetRef ref, Coin coin) async {
    try {
      await ref.read(watchlistControllerProvider.notifier).toggle(coin);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppStrings.removedFromWatchlist(coin.name)),
          action: SnackBarAction(
            label: AppStrings.undo,
            onPressed: () =>
                ref.read(watchlistControllerProvider.notifier).toggle(coin),
          ),
        ),
      );
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(error.toString())));
      }
    }
  }
}
