import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../settings/presentation/controllers/settings_controller.dart';
import '../../domain/coin.dart';
import '../../domain/market_filters.dart';
import 'live_price_controller.dart';
import 'market_controller.dart';

final visibleCoinsProvider = Provider.family<List<Coin>, HomeTab>((ref, tab) {
  final sourceCoins = tab == HomeTab.trending
      ? ref.watch(trendingControllerProvider).asData?.value.items ??
            const <Coin>[]
      : ref.watch(coinListControllerProvider).asData?.value.items ??
            const <Coin>[];
  final livePrices = ref.watch(liveCoinPricesProvider);
  final currency =
      ref.watch(settingsControllerProvider).asData?.value.currency ?? 'usd';
  final pricedCoins = sourceCoins.map(
    (coin) => withLivePrice(coin, livePrices, currency: currency),
  );
  final filters = ref.watch(marketFiltersProvider);
  final period = ref.watch(changePeriodProvider);
  var coins = pricedCoins.where((coin) {
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
