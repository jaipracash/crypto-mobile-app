import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../shared/widgets/async_value_view.dart';
import '../../../../shared/widgets/coin_tile.dart';
import '../../../../shared/widgets/data_source_banner.dart';
import '../../../market/domain/coin.dart';
import '../../../settings/presentation/controllers/settings_controller.dart';
import '../../../watchlist/presentation/controllers/watchlist_controller.dart';
import '../controllers/market_controller.dart';
import '../widgets/market_filter_row.dart';
import '../widgets/sort_sheet.dart';

class MarketScreen extends ConsumerStatefulWidget {
  const MarketScreen({super.key});
  @override
  ConsumerState<MarketScreen> createState() => _MarketScreenState();
}

class _MarketScreenState extends ConsumerState<MarketScreen> {
  final _scrollController = ScrollController();
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(coinListControllerProvider);
      ref.read(searchResultsProvider);
    });
  }

  void _onScroll() {
    if (_scrollController.position.extentAfter < 420) {
      ref.read(coinListControllerProvider.notifier).loadMore();
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final listValue = ref.watch(coinListControllerProvider);
    final query = ref.watch(searchQueryProvider);
    final results = ref.watch(searchResultsProvider);
    final filter = ref.watch(marketFilterProvider);
    final visibleCoins = ref.watch(visibleCoinsProvider);
    final settings = ref.watch(settingsControllerProvider).asData?.value;
    final currency = settings?.currency ?? 'usd';
    final sort = ref.watch(sortOptionProvider);
    final data = listValue.asData?.value;
    final searching = query.trim().length >= 2;
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.market),
        actions: [
          IconButton(
            tooltip: AppStrings.sortCoins,
            onPressed: () => showModalBottomSheet<void>(
              context: context,
              showDragHandle: true,
              builder: (_) => SortSheet(
                selected: sort,
                onSelected: (order) {
                  Navigator.of(context).pop();
                  ref.read(sortOptionProvider.notifier).set(order);
                  ref.read(coinListControllerProvider.notifier).setSort(order);
                },
              ),
            ),
            icon: const Icon(Icons.swap_vert_rounded),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSizes.screenPadding,
              AppSizes.sm,
              AppSizes.screenPadding,
              AppSizes.md,
            ),
            child: TextField(
              controller: _searchController,
              onChanged: ref.read(searchQueryProvider.notifier).set,
              decoration: InputDecoration(
                hintText: AppStrings.searchCoins,
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: query.isNotEmpty
                    ? IconButton(
                        tooltip: AppStrings.clearSearch,
                        onPressed: () {
                          _searchController.clear();
                          ref.read(searchQueryProvider.notifier).set('');
                        },
                        icon: const Icon(Icons.close),
                      )
                    : null,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(
              left: AppSizes.screenPadding,
              bottom: AppSizes.md,
            ),
            child: MarketFilterRow(
              selected: filter,
              onSelected: ref.read(marketFilterProvider.notifier).select,
            ),
          ),
          if (!searching && data != null)
            DataSourceBanner(source: data.dataSource),
          Expanded(
            child: searching
                ? AsyncValueView(
                    value: results,
                    onRetry: () => ref.invalidate(searchResultsProvider),
                    isEmpty: (items) => items.isEmpty,
                    emptyTitle: AppStrings.noCoinsFound,
                    emptyMessage: AppStrings.tryAnotherName,
                    builder: (items) => ListView.builder(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSizes.screenPadding,
                      ),
                      itemCount: items.length,
                      itemBuilder: (context, index) {
                        final item = items[index];
                        return ListTile(
                          leading: const Icon(Icons.currency_bitcoin),
                          title: Text(item.name),
                          subtitle: Text(item.symbol.toUpperCase()),
                          onTap: () => context.push('/coin/${item.id}'),
                        );
                      },
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: () async {
                      await ref
                          .read(coinListControllerProvider.notifier)
                          .refresh();
                      await ref
                          .read(watchlistControllerProvider.notifier)
                          .refresh();
                    },
                    child: AsyncValueView(
                      value: listValue,
                      onRetry: () => ref.invalidate(coinListControllerProvider),
                      isEmpty: (_) => visibleCoins.isEmpty,
                      emptyTitle: filter == MarketFilter.watchlisted
                          ? AppStrings.noWatchlistedCoins
                          : AppStrings.noCoinsToShow,
                      emptyMessage: AppStrings.tryAnotherFilter,
                      builder: (_) {
                        final coins = visibleCoins;
                        return ListView.builder(
                          controller: _scrollController,
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSizes.screenPadding,
                          ),
                          itemCount:
                              coins.length +
                              (data?.loadingMore == true ||
                                      data?.loadMoreError != null
                                  ? 1
                                  : 0),
                          itemBuilder: (context, index) {
                            if (index >= coins.length) {
                              if (data?.loadMoreError != null) {
                                return TextButton.icon(
                                  onPressed: ref
                                      .read(coinListControllerProvider.notifier)
                                      .retryLoadMore,
                                  icon: const Icon(Icons.refresh),
                                  label: const Text(AppStrings.loadMoreFailed),
                                );
                              }
                              return const Padding(
                                padding: EdgeInsets.all(AppSizes.lg),
                                child: Center(
                                  child: CircularProgressIndicator(),
                                ),
                              );
                            }
                            final coin = coins[index];
                            return CoinTile(
                              coin: coin,
                              currency: currency,
                              onTap: () => context.push('/coin/${coin.id}'),
                              onToggleWatchlist: () => _toggle(coin),
                            );
                          },
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Future<void> _toggle(Coin coin) async {
    try {
      await ref.read(watchlistControllerProvider.notifier).toggle(coin);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(error.toString())));
      }
    }
  }
}
