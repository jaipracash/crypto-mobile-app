import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/api_constants.dart';
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
  HomeTab build() => HomeTab.all;
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
          perPage: ref
              .read(marketFiltersProvider)
              .topLimit
              .clamp(1, ApiConstants.maxPageSize)
              .toInt(),
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
