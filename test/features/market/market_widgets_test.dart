import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gecko_lite/core/constants/app_strings.dart';
import 'package:gecko_lite/features/market/domain/coin.dart';
import 'package:gecko_lite/features/market/domain/market_filters.dart';
import 'package:gecko_lite/features/market/domain/market_models.dart';
import 'package:gecko_lite/features/market/presentation/controllers/market_controller.dart';
import 'package:gecko_lite/features/market/presentation/widgets/coin_row.dart';
import 'package:gecko_lite/features/market/presentation/widgets/market_sheets.dart';

void main() {
  testWidgets('CoinRow renders coin data without a favorite control', (
    tester,
  ) async {
    const coin = Coin(
      id: 'bitcoin',
      symbol: 'btc',
      name: 'Bitcoin',
      rank: 1,
      price: 67420,
      marketCap: 1300000000000,
      change24hPct: 2.4,
    );
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CoinRow(
            coin: coin,
            currency: 'usd',
            period: ChangePeriod.day,
            onTap: () {},
          ),
        ),
      ),
    );
    expect(find.text('Bitcoin'), findsOneWidget);
    expect(find.text('BTC'), findsOneWidget);
    expect(find.textContaining('1.3T'), findsOneWidget);
    expect(find.byTooltip(AppStrings.addToWatchlist), findsNothing);
    expect(find.byTooltip(AppStrings.removeFromWatchlist), findsNothing);
    expect(find.byIcon(Icons.star_border_rounded), findsNothing);
    expect(find.byIcon(Icons.star_rounded), findsNothing);
  });

  testWidgets('market table fits narrow screens without horizontal scrolling', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    const coin = Coin(
      id: 'bitcoin',
      symbol: 'btc',
      name: 'Bitcoin',
      rank: 1,
      price: 67420,
      marketCap: 1300000000000,
      change24hPct: 2.4,
    );
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 390,
            child: Column(
              children: [
                CoinTableHeader(period: ChangePeriod.day, onPeriodTap: () {}),
                CoinRow(
                  coin: coin,
                  currency: 'usd',
                  period: ChangePeriod.day,
                  onTap: () {},
                ),
              ],
            ),
          ),
        ),
      ),
    );

    expect(find.text(AppStrings.marketCapShort), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('provided navigation SVG assets render', (tester) async {
    const assets = [
      'assets/dart-svgrepo-com.svg',
      'assets/search-alt-2-svgrepo-com.svg',
      'assets/profile-svgrepo-com.svg',
      'assets/watchlist.svg',
    ];
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Wrap(
            children: assets
                .map((asset) => SvgPicture.asset(asset, width: 24))
                .toList(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(SvgPicture), findsNWidgets(4));
    expect(tester.takeException(), isNull);
  });

  testWidgets('FilterSheet edits a draft until Apply and Reset', (
    tester,
  ) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          home: Scaffold(
            body: Consumer(
              builder: (context, ref, _) => Column(
                children: [
                  Text('${ref.watch(marketFiltersProvider).activeCount}'),
                  TextButton(
                    onPressed: () =>
                        showMarketSheet(context, const FilterSheet()),
                    child: const Text(AppStrings.filter),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text(AppStrings.filter));
    await tester.pumpAndSettle();
    await tester.drag(
      find.byType(SingleChildScrollView),
      const Offset(0, -500),
    );
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text(AppStrings.marketCapLarge));
    await tester.tap(find.text(AppStrings.marketCapLarge));
    await tester.pumpAndSettle();
    expect(container.read(marketFiltersProvider).marketCap, 'any');
    expect(find.text('0'), findsOneWidget);
    expect(find.text('${AppStrings.apply} (1)'), findsOneWidget);
    await tester.tap(find.text('${AppStrings.apply} (1)'));
    await tester.pumpAndSettle();
    expect(container.read(marketFiltersProvider).marketCap, 'large');

    await tester.tap(find.text(AppStrings.filter));
    await tester.pumpAndSettle();
    await tester.tap(find.text(AppStrings.reset));
    await tester.pumpAndSettle();
    expect(container.read(marketFiltersProvider).marketCap, 'large');
    expect(find.text('${AppStrings.apply} (0)'), findsOneWidget);
    await tester.tap(find.text('${AppStrings.apply} (0)'));
    await tester.pumpAndSettle();
    expect(container.read(marketFiltersProvider).marketCap, 'any');
  });

  testWidgets('FilterSheet applies top count from its draft', (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () => showMarketSheet(context, const FilterSheet()),
                child: const Text(AppStrings.filter),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text(AppStrings.filter));
    await tester.pumpAndSettle();
    expect(
      tester.getTopLeft(find.text('${AppStrings.top} 50')).dx,
      greaterThanOrEqualTo(16),
    );
    await tester.tap(find.text('${AppStrings.top} 200'));
    await tester.pumpAndSettle();
    expect(container.read(marketFiltersProvider).topLimit, 100);
    expect(find.text('${AppStrings.apply} (1)'), findsOneWidget);
    await tester.tap(find.text('${AppStrings.apply} (1)'));
    await tester.pumpAndSettle();
    expect(container.read(marketFiltersProvider).topLimit, 200);
  });

  testWidgets('SortSheet applies sort field and direction separately', (
    tester,
  ) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () => showMarketSheet(context, const SortSheet()),
                child: const Text(AppStrings.sortCoins),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text(AppStrings.sortCoins));
    await tester.pumpAndSettle();
    await tester.tap(find.text(AppStrings.volume));
    await tester.tap(find.text(AppStrings.ascending));
    await tester.tap(find.text(AppStrings.apply));
    await tester.pumpAndSettle();

    expect(
      container.read(marketFiltersProvider).sortField,
      MarketSortField.volume,
    );
    expect(container.read(marketFiltersProvider).ascending, isTrue);
    expect(container.read(marketFiltersProvider).activeCount, 0);
  });

  testWidgets('Market overview shows global metrics and dominance', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: MarketOverviewPanel(
            snapshot: MarketSnapshot(
              totalMarketCap: 2500000000000,
              totalVolume24h: 95000000000,
              marketCapChange24hPct: 2.5,
              btcDominance: 54,
              ethDominance: 17,
              othersDominance: 29,
              activeCoins: 12000,
            ),
            currency: 'usd',
          ),
        ),
      ),
    );

    expect(find.text(AppStrings.totalMarketCap), findsOneWidget);
    expect(find.text(AppStrings.volume24h), findsOneWidget);
    expect(find.text(AppStrings.marketDominance), findsOneWidget);
    expect(find.text(AppStrings.activeCoins), findsOneWidget);
    expect(find.text('12000'), findsOneWidget);
  });

  testWidgets('PeriodSheet selection rows have horizontal inset', (
    tester,
  ) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () => showMarketSheet(context, const PeriodSheet()),
                child: const Text(AppStrings.changePeriod),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text(AppStrings.changePeriod));
    await tester.pumpAndSettle();
    expect(
      tester.getTopLeft(find.text(AppStrings.period1h)).dx,
      greaterThanOrEqualTo(16),
    );
  });
}
