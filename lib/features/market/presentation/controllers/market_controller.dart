import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/providers/repository_providers.dart';
import '../../../settings/presentation/controllers/settings_controller.dart';
import '../../domain/coin.dart';
import '../../domain/market_filters.dart';
import '../../domain/market_models.dart';

enum HomeTab { all, trending, overview, gainers, losers }

enum ChangePeriod { oneHour, day, week, month }

extension ChangePeriodValue on ChangePeriod {
  String get label => switch (this) {
    ChangePeriod.oneHour => AppStrings.period1h,
    ChangePeriod.day => AppStrings.period24h,
    ChangePeriod.week => AppStrings.period7d,
    ChangePeriod.month => AppStrings.period30d,
  };

  double? value(Coin coin) => switch (this) {
    ChangePeriod.oneHour => coin.change1hPct,
    ChangePeriod.day => coin.change24hPct,
    ChangePeriod.week => coin.change7dPct,
    ChangePeriod.month => coin.change30dPct,
  };
}

final homeTabProvider = NotifierProvider<HomeTabController, HomeTab>(
  HomeTabController.new,
);

class HomeTabController extends Notifier<HomeTab> {
  @override
  HomeTab build() => HomeTab.overview;
  void select(HomeTab tab) => state = tab;
}

final changePeriodProvider =
    NotifierProvider<ChangePeriodController, ChangePeriod>(
      ChangePeriodController.new,
    );

class ChangePeriodController extends Notifier<ChangePeriod> {
  @override
  ChangePeriod build() => ChangePeriod.day;
  void set(ChangePeriod value) => state = value;
}

final marketFiltersProvider =
    NotifierProvider<MarketFiltersController, MarketFilters>(
      MarketFiltersController.new,
    );

class MarketFiltersController extends Notifier<MarketFilters> {
  @override
  MarketFilters build() => const MarketFilters();
  void set(MarketFilters value) => state = value;
  void reset() => state = state.reset();
}

final coinListControllerProvider =
    AsyncNotifierProvider<CoinListController, CoinListState>(
      CoinListController.new,
    );

class CoinListState {
  const CoinListState({this.items = const [], this.dataSource = 'live'});
  final List<Coin> items;
  final String dataSource;
}

class CoinListController extends AsyncNotifier<CoinListState> {
  Timer? _refreshTimer;
  int _generation = 0;

  @override
  Future<CoinListState> build() async {
    ref.listen(marketFiltersProvider, (previous, next) {
      if (previous != null && previous.topLimit != next.topLimit) {
        unawaited(refresh());
      }
    });
    ref.listen(settingsControllerProvider, (previous, next) {
      final oldSettings = previous?.asData?.value;
      final newSettings = next.asData?.value;
      _configureRefresh(newSettings?.autoRefreshSeconds ?? 0);
      if (oldSettings != null &&
          oldSettings.currency != newSettings?.currency) {
        unawaited(refresh());
      }
    });
    ref.onDispose(() => _refreshTimer?.cancel());
    final settings = await ref.read(settingsControllerProvider.future);
    _configureRefresh(settings.autoRefreshSeconds);
    return _loadFirstPage(settings.currency);
  }

  Future<CoinListState> _loadFirstPage(String currency) async {
    final generation = ++_generation;
    final page = await ref
        .read(marketRepositoryProvider)
        .getCoins(
          page: 1,
          perPage: ref.read(marketFiltersProvider).topLimit,
          order: 'market_cap_desc',
          currency: currency,
        );
    if (generation != _generation) {
      return state.asData?.value ?? const CoinListState();
    }
    return CoinListState(items: page.items, dataSource: page.dataSource);
  }

  Future<void> refresh() async {
    final currency =
        ref.read(settingsControllerProvider).asData?.value.currency ?? 'usd';
    state = const AsyncLoading<CoinListState>().copyWithPrevious(state);
    state = await AsyncValue.guard(() => _loadFirstPage(currency));
  }

  void updateWatchlisted(String coinId, bool value) {
    final current = state.asData?.value;
    if (current == null) return;
    state = AsyncData(
      CoinListState(
        items: current.items
            .map(
              (coin) => coin.id == coinId
                  ? coin.copyWith(isWatchlisted: value)
                  : coin,
            )
            .toList(growable: false),
        dataSource: current.dataSource,
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

final trendingControllerProvider =
    AsyncNotifierProvider<TrendingController, TrendingData>(
      TrendingController.new,
    );

class TrendingController extends AsyncNotifier<TrendingData> {
  @override
  Future<TrendingData> build() =>
      ref.watch(marketRepositoryProvider).getTrending();

  Future<void> refresh() async {
    state = const AsyncLoading<TrendingData>().copyWithPrevious(state);
    state = await AsyncValue.guard(
      () => ref.read(marketRepositoryProvider).getTrending(),
    );
  }
}

final globalStatsControllerProvider =
    AsyncNotifierProvider<GlobalStatsController, MarketSnapshot>(
      GlobalStatsController.new,
    );

class GlobalStatsController extends AsyncNotifier<MarketSnapshot> {
  @override
  Future<MarketSnapshot> build() async {
    final settings = await ref.watch(settingsControllerProvider.future);
    return ref.watch(marketRepositoryProvider).getGlobal(settings.currency);
  }

  Future<void> refresh() async {
    final currency =
        ref.read(settingsControllerProvider).asData?.value.currency ?? 'usd';
    state = const AsyncLoading<MarketSnapshot>().copyWithPrevious(state);
    state = await AsyncValue.guard(
      () => ref.read(marketRepositoryProvider).getGlobal(currency),
    );
  }
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

  void retry() => _schedule(ref.read(searchQueryProvider));

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

final visibleCoinsProvider = Provider.family<List<Coin>, HomeTab>((ref, tab) {
  final sourceCoins = tab == HomeTab.trending
      ? ref.watch(trendingControllerProvider).asData?.value.items ??
            const <Coin>[]
      : ref.watch(coinListControllerProvider).asData?.value.items ??
            const <Coin>[];
  final filters = ref.watch(marketFiltersProvider);
  final period = ref.watch(changePeriodProvider);
  final query = ref.watch(searchQueryProvider).trim().toLowerCase();
  var coins = sourceCoins.where((coin) {
    final marketCap = coin.marketCap;
    final volume = coin.volume24h;
    final price = coin.price;
    if (filters.marketCap == 'large' &&
        (marketCap == null || marketCap <= 10000000000)) {
      return false;
    }
    if (filters.marketCap == 'mid' &&
        (marketCap == null ||
            marketCap < 1000000000 ||
            marketCap > 10000000000)) {
      return false;
    }
    if (filters.marketCap == 'small' &&
        (marketCap == null || marketCap >= 1000000000)) {
      return false;
    }
    if (filters.volume == '100m' && (volume == null || volume <= 100000000)) {
      return false;
    }
    if (filters.volume == '10m' && (volume == null || volume <= 10000000)) {
      return false;
    }
    if (filters.volume == '1m' && (volume == null || volume <= 1000000)) {
      return false;
    }
    if (filters.price == 'under1' && (price == null || price >= 1)) {
      return false;
    }
    if (filters.price == '1to100' &&
        (price == null || price < 1 || price > 100)) {
      return false;
    }
    if (filters.price == 'over100' && (price == null || price <= 100)) {
      return false;
    }
    if (query.isNotEmpty &&
        !coin.name.toLowerCase().contains(query) &&
        !coin.symbol.toLowerCase().contains(query)) {
      return false;
    }
    return true;
  }).toList();

  if (tab == HomeTab.gainers) {
    coins = coins.where((coin) => (period.value(coin) ?? 0) > 0).toList();
    coins.sort(
      (a, b) => (period.value(b) ?? 0).compareTo(period.value(a) ?? 0),
    );
  } else if (tab == HomeTab.losers) {
    coins = coins.where((coin) => (period.value(coin) ?? 0) < 0).toList();
    coins.sort(
      (a, b) => (period.value(a) ?? 0).compareTo(period.value(b) ?? 0),
    );
  } else {
    int compare(Coin a, Coin b) {
      final comparison = switch (filters.sortField) {
        MarketSortField.marketCap => (a.marketCap ?? 0).compareTo(
          b.marketCap ?? 0,
        ),
        MarketSortField.price => (a.price ?? 0).compareTo(b.price ?? 0),
        MarketSortField.priceChange => (period.value(a) ?? 0).compareTo(
          period.value(b) ?? 0,
        ),
        MarketSortField.volume => (a.volume24h ?? 0).compareTo(
          b.volume24h ?? 0,
        ),
      };
      return filters.ascending ? comparison : -comparison;
    }

    coins.sort(compare);
  }
  return coins;
});
