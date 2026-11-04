import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/repository_providers.dart';
import '../../../settings/presentation/controllers/settings_controller.dart';
import '../../../watchlist/presentation/controllers/watchlist_controller.dart';
import '../../domain/coin.dart';
import '../../domain/market_models.dart';

final coinListControllerProvider =
    AsyncNotifierProvider<CoinListController, CoinListState>(
      CoinListController.new,
    );

class CoinListState {
  const CoinListState({
    this.items = const [],
    this.page = 1,
    this.hasMore = true,
    this.dataSource = 'live',
    this.loadingMore = false,
    this.loadMoreError,
  });
  final List<Coin> items;
  final int page;
  final bool hasMore;
  final String dataSource;
  final bool loadingMore;
  final Object? loadMoreError;

  CoinListState copyWith({
    List<Coin>? items,
    int? page,
    bool? hasMore,
    String? dataSource,
    bool? loadingMore,
    Object? loadMoreError,
    bool clearLoadMoreError = false,
  }) => CoinListState(
    items: items ?? this.items,
    page: page ?? this.page,
    hasMore: hasMore ?? this.hasMore,
    dataSource: dataSource ?? this.dataSource,
    loadingMore: loadingMore ?? this.loadingMore,
    loadMoreError: clearLoadMoreError
        ? null
        : loadMoreError ?? this.loadMoreError,
  );
}

class CoinListController extends AsyncNotifier<CoinListState> {
  Timer? _refreshTimer;
  String _sort = 'market_cap_desc';
  int _generation = 0;

  @override
  Future<CoinListState> build() async {
    ref.listen(settingsControllerProvider, (previous, next) {
      final nextSettings = next.asData?.value;
      final previousSettings = previous?.asData?.value;
      _configureRefresh(nextSettings?.autoRefreshSeconds ?? 0);
      if (previousSettings != null &&
          previousSettings.currency != nextSettings?.currency) {
        unawaited(refresh());
      }
    });
    ref.onDispose(() => _refreshTimer?.cancel());
    final settings = await ref.watch(settingsControllerProvider.future);
    _configureRefresh(settings.autoRefreshSeconds);
    return _loadFirstPage(settings.currency);
  }

  Future<CoinListState> _loadFirstPage(String currency) async {
    final generation = ++_generation;
    final page = await ref
        .read(marketRepositoryProvider)
        .getCoins(page: 1, perPage: 50, order: _sort, currency: currency);
    if (generation != _generation) {
      return state.asData?.value ?? const CoinListState();
    }
    return CoinListState(
      items: page.items,
      hasMore: page.hasMore,
      dataSource: page.dataSource,
    );
  }

  Future<void> refresh() async {
    final currency =
        ref.read(settingsControllerProvider).asData?.value.currency ?? 'usd';
    state = const AsyncLoading<CoinListState>().copyWithPrevious(state);
    state = await AsyncValue.guard(() => _loadFirstPage(currency));
  }

  Future<void> loadMore() async {
    final current = state.asData?.value;
    if (current == null ||
        !current.hasMore ||
        current.loadingMore ||
        current.loadMoreError != null) {
      return;
    }
    state = AsyncData(
      current.copyWith(loadingMore: true, clearLoadMoreError: true),
    );
    try {
      final settings = ref.read(settingsControllerProvider).asData?.value;
      final nextPage = await ref
          .read(marketRepositoryProvider)
          .getCoins(
            page: current.page + 1,
            perPage: 50,
            order: _sort,
            currency: settings?.currency ?? 'usd',
          );
      final latest = state.asData?.value ?? current;
      state = AsyncData(
        latest.copyWith(
          items: [...latest.items, ...nextPage.items],
          page: nextPage.page,
          hasMore: nextPage.hasMore,
          dataSource: nextPage.dataSource,
          loadingMore: false,
          clearLoadMoreError: true,
        ),
      );
    } catch (error) {
      final latest = state.asData?.value ?? current;
      state = AsyncData(
        latest.copyWith(loadingMore: false, loadMoreError: error),
      );
    }
  }

  Future<void> retryLoadMore() async {
    final current = state.asData?.value;
    if (current != null) {
      state = AsyncData(current.copyWith(clearLoadMoreError: true));
    }
    await loadMore();
  }

  Future<void> setSort(String order) async {
    if (_sort == order) return;
    _sort = order;
    await refresh();
  }

  void updateWatchlisted(String coinId, bool value) {
    final current = state.asData?.value;
    if (current == null) return;
    state = AsyncData(
      current.copyWith(
        items: current.items
            .map(
              (coin) => coin.id == coinId
                  ? coin.copyWith(isWatchlisted: value)
                  : coin,
            )
            .toList(growable: false),
      ),
    );
  }

  void _configureRefresh(int seconds) {
    _refreshTimer?.cancel();
    if (seconds <= 0) return;
    _refreshTimer = Timer.periodic(Duration(seconds: seconds), (_) {
      unawaited(refresh());
    });
  }
}

enum MarketFilter { all, gainers, losers, highVolume, watchlisted }

final marketFilterProvider =
    NotifierProvider<MarketFilterController, MarketFilter>(
      MarketFilterController.new,
    );

class MarketFilterController extends Notifier<MarketFilter> {
  @override
  MarketFilter build() => MarketFilter.all;
  void select(MarketFilter filter) => state = filter;
}

final sortOptionProvider = NotifierProvider<SortOptionController, String>(
  SortOptionController.new,
);

class SortOptionController extends Notifier<String> {
  @override
  String build() => 'market_cap_desc';
  void set(String value) => state = value;
}

final searchQueryProvider = NotifierProvider<SearchQueryController, String>(
  SearchQueryController.new,
);

class SearchQueryController extends Notifier<String> {
  @override
  String build() => '';
  void set(String value) => state = value;
}

final searchResultsProvider =
    AsyncNotifierProvider<SearchResultsController, List<SearchCoin>>(
      SearchResultsController.new,
    );

class SearchResultsController extends AsyncNotifier<List<SearchCoin>> {
  Timer? _timer;
  int _requestId = 0;
  @override
  Future<List<SearchCoin>> build() async {
    ref.listen(searchQueryProvider, (_, next) => _schedule(next));
    ref.onDispose(() => _timer?.cancel());
    return const [];
  }

  void _schedule(String query) {
    _timer?.cancel();
    final id = ++_requestId;
    if (query.trim().length < 2) {
      state = const AsyncData([]);
      return;
    }
    _timer = Timer(const Duration(milliseconds: 400), () async {
      state = const AsyncLoading();
      try {
        final results = await ref
            .read(marketRepositoryProvider)
            .search(query.trim());
        if (id == _requestId) state = AsyncData(results);
      } catch (error, stack) {
        if (id == _requestId) state = AsyncError(error, stack);
      }
    });
  }
}

final visibleCoinsProvider = Provider<List<Coin>>((ref) {
  final coins =
      ref.watch(coinListControllerProvider).asData?.value.items ??
      const <Coin>[];
  final filter = ref.watch(marketFilterProvider);
  final watchlisted =
      ref.watch(watchlistControllerProvider).asData?.value.items ??
      const <Coin>[];
  return switch (filter) {
    MarketFilter.all => coins,
    MarketFilter.gainers =>
      coins.where((coin) => (coin.change24hPct ?? 0) > 0).toList(),
    MarketFilter.losers =>
      coins.where((coin) => (coin.change24hPct ?? 0) < 0).toList(),
    MarketFilter.highVolume =>
      (List<Coin>.of(coins)
            ..sort((a, b) => (b.volume24h ?? 0).compareTo(a.volume24h ?? 0)))
          .take(20)
          .toList(),
    MarketFilter.watchlisted => watchlisted,
  };
});
