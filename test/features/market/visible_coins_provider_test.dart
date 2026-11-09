import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:crypto_research_app/features/market/domain/coin.dart';
import 'package:crypto_research_app/features/market/domain/market_filters.dart';
import 'package:crypto_research_app/features/market/presentation/controllers/market_controller.dart';
import 'package:crypto_research_app/features/market/presentation/controllers/live_price_controller.dart';
import 'package:crypto_research_app/features/market/presentation/controllers/visible_coins_provider.dart';
import 'package:crypto_research_app/features/watchlist/domain/watchlist_repository.dart';
import 'package:crypto_research_app/features/watchlist/presentation/controllers/watchlist_controller.dart';

const _coins = [
  Coin(
    id: 'bitcoin',
    symbol: 'btc',
    name: 'Bitcoin',
    rank: 1,
    price: 120,
    marketCap: 20000000000,
    volume24h: 200000000,
    change1hPct: 2,
    change24hPct: 4,
    change7dPct: -1,
    change30dPct: 3,
  ),
  Coin(
    id: 'ethereum',
    symbol: 'eth',
    name: 'Ethereum',
    rank: 2,
    price: 10,
    marketCap: 5000000000,
    volume24h: 5000000,
    change1hPct: -3,
    change24hPct: 8,
    change7dPct: 2,
    change30dPct: -2,
  ),
];

class _FakeCoinListController extends CoinListController {
  @override
  Future<CoinListState> build() async =>
      const CoinListState(items: _coins, dataSource: 'mock');
}

class _FakeWatchlistController extends WatchlistController {
  @override
  Future<WatchlistData> build() async =>
      WatchlistData(items: [_coins.first], dataSource: 'mock');
}

void main() {
  late ProviderContainer container;

  setUp(() {
    container = ProviderContainer(
      overrides: [
        coinListControllerProvider.overrideWith(_FakeCoinListController.new),
        watchlistControllerProvider.overrideWith(_FakeWatchlistController.new),
      ],
    );
  });

  tearDown(() => container.dispose());

  test(
    'visible coins filters and sorts gainers/losers by selected period',
    () async {
      await container.read(coinListControllerProvider.future);
      await container.read(watchlistControllerProvider.future);

      expect(
        container
            .read(visibleCoinsProvider(HomeTab.gainers))
            .map((coin) => coin.id),
        ['ethereum', 'bitcoin'],
      );
      expect(
        container
            .read(visibleCoinsProvider(HomeTab.losers))
            .map((coin) => coin.id),
        isEmpty,
      );

      container.read(changePeriodProvider.notifier).set(ChangePeriod.oneHour);
      expect(
        container
            .read(visibleCoinsProvider(HomeTab.gainers))
            .map((coin) => coin.id),
        ['bitcoin'],
      );
      expect(
        container
            .read(visibleCoinsProvider(HomeTab.losers))
            .map((coin) => coin.id),
        ['ethereum'],
      );

      container.read(changePeriodProvider.notifier).set(ChangePeriod.week);
      expect(
        container
            .read(visibleCoinsProvider(HomeTab.gainers))
            .map((coin) => coin.id),
        ['ethereum'],
      );
      expect(
        container
            .read(visibleCoinsProvider(HomeTab.losers))
            .map((coin) => coin.id),
        ['bitcoin'],
      );
    },
  );

  test('visible coins applies client-side market cap filters', () async {
    await container.read(coinListControllerProvider.future);
    await container.read(watchlistControllerProvider.future);
    container
        .read(marketFiltersProvider.notifier)
        .set(const MarketFilters(marketCap: 'large'));

    expect(
      container.read(visibleCoinsProvider(HomeTab.all)).map((coin) => coin.id),
      ['bitcoin'],
    );
    expect(
      container.read(visibleCoinsProvider(HomeTab.all)).single.isWatchlisted,
      isFalse,
    );
  });

  test('live price updates immediately replace visible coin prices', () async {
    await container.read(coinListControllerProvider.future);
    final controller = container.read(liveCoinPricesProvider.notifier);

    controller.apply('usd', const [
      LivePriceUpdate(coinId: 'bitcoin', price: 125),
      LivePriceUpdate(coinId: 'ethereum', price: 12),
    ]);

    final updated = container.read(visibleCoinsProvider(HomeTab.all));
    expect(updated.first.price, 125);
    expect(updated[1].price, 12);

    controller.apply('inr', const [
      LivePriceUpdate(coinId: 'bitcoin', price: 10000),
    ]);
    expect(container.read(visibleCoinsProvider(HomeTab.all)).first.price, 125);
    expect(
      withLivePrice(_coins.first, {'usd:bitcoin': 125}, currency: 'inr').price,
      120,
    );
  });
}
