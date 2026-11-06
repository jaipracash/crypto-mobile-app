import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gecko_lite/core/constants/app_strings.dart';
import 'package:gecko_lite/features/market/domain/coin.dart';
import 'package:gecko_lite/features/market/domain/market_filters.dart';
import 'package:gecko_lite/features/market/domain/market_models.dart';
import 'package:gecko_lite/features/market/presentation/controllers/market_controller.dart';
import 'package:gecko_lite/features/market/presentation/screens/search_screen.dart';
import 'package:gecko_lite/features/market/presentation/widgets/coin_row.dart';
import 'package:gecko_lite/features/market/presentation/widgets/market_sheets.dart';
import 'package:gecko_lite/features/settings/domain/app_settings.dart';
import 'package:gecko_lite/features/settings/presentation/controllers/settings_controller.dart';
import 'package:gecko_lite/shared/widgets/change_pill.dart';
import 'package:gecko_lite/shared/widgets/sparkline.dart';

class _SearchTestCoinListController extends CoinListController {
  @override
  Future<CoinListState> build() async => const CoinListState(
    items: [
      Coin(id: 'bitcoin', symbol: 'btc', name: 'Bitcoin', rank: 1, price: 1),
    ],
    dataSource: 'mock',
  );
}

class _SearchTestTrendingController extends TrendingController {
  @override
  Future<TrendingData> build() async => const TrendingData(
    items: [
      Coin(id: 'ethereum', symbol: 'eth', name: 'Ethereum', rank: 2, price: 2),
    ],
    dataSource: 'mock',
  );
}

class _SearchTestSettingsController extends SettingsController {
  @override
  Future<AppSettings> build() async => const AppSettings();
}

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
      sparkline7d: [65000, 66500, 65800, 67420],
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
    expect(find.textContaining('BTC'), findsOneWidget);
    expect(find.textContaining('1.3T'), findsOneWidget);
    final sparkline = tester.widget<Sparkline>(find.byType(Sparkline));
    final changePill = tester.widget<ChangePill>(find.byType(ChangePill));
    expect(sparkline.filled, isTrue);
    expect(sparkline.positive, isTrue);
    expect(sparkline.width, 66);
    expect(sparkline.height, 28);
    expect(
      tester
          .widget<LineChart>(find.byType(LineChart))
          .data
          .lineBarsData
          .single
          .isCurved,
      isTrue,
    );
    expect(changePill.showBackground, isFalse);
    expect(
      tester.getTopLeft(find.byType(Sparkline)).dy,
      lessThan(tester.getTopLeft(find.byType(ChangePill)).dy),
    );
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

    expect(find.textContaining('BTC'), findsOneWidget);
    expect(find.textContaining('1.3T'), findsOneWidget);
    expect(find.byType(VerticalDivider), findsNothing);
    expect(tester.takeException(), isNull);
  });

  test('market tabs place Overview after Trending', () {
    expect(HomeTab.values, [
      HomeTab.all,
      HomeTab.trending,
      HomeTab.overview,
      HomeTab.gainers,
      HomeTab.losers,
    ]);
  });

  test('market opens on All tab', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    expect(container.read(homeTabProvider), HomeTab.all);
  });

  testWidgets('provided navigation SVG assets render', (tester) async {
    const assets = [
      'assets/flutter.svg',
      'assets/search-alt-2-svgrepo-com.svg',
      'assets/profile-svgrepo-com.svg',
      'assets/watchlist.svg',
      'assets/filter-svgrepo-com.svg',
      'assets/notification-6-svgrepo-com.svg',
      'assets/sort-vertical-svgrepo-com.svg',
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

    expect(find.byType(SvgPicture), findsNWidgets(7));
    expect(tester.takeException(), isNull);
  });

  testWidgets('Search screen has market tabs and animates only from home', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          coinListControllerProvider.overrideWith(
            _SearchTestCoinListController.new,
          ),
          trendingControllerProvider.overrideWith(
            _SearchTestTrendingController.new,
          ),
          settingsControllerProvider.overrideWith(
            _SearchTestSettingsController.new,
          ),
        ],
        child: const MaterialApp(home: SearchScreen(animateFromHome: true)),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text(AppStrings.all), findsOneWidget);
    expect(find.text(AppStrings.trending), findsOneWidget);
    expect(find.text(AppStrings.gainers), findsOneWidget);
    expect(find.text(AppStrings.losers), findsOneWidget);
    expect(find.text('Ethereum'), findsOneWidget);
    expect(find.text('Bitcoin'), findsNothing);
    expect(find.text('Market pulse'), findsNothing);
    expect(find.byType(Sparkline), findsNothing);
    expect(find.byType(Divider), findsNothing);
    expect(find.byType(ChoiceChip), findsNothing);
    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is Hero && widget.tag == SearchScreen.homeSearchHeroTag,
      ),
      findsOneWidget,
    );

    await tester.tap(find.text(AppStrings.all));
    await tester.pumpAndSettle();
    expect(find.text('Bitcoin'), findsOneWidget);
    expect(find.text('Ethereum'), findsNothing);
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
    expect(find.byType(FilledButton), findsNWidgets(2));
    for (final chip in tester.widgetList<ChoiceChip>(find.byType(ChoiceChip))) {
      expect(chip.shape, isA<StadiumBorder>());
      expect(chip.showCheckmark, isFalse);
      expect(chip.avatar, isNull);
      expect(chip.padding, const EdgeInsets.symmetric(horizontal: 8));
      expect(chip.labelPadding, const EdgeInsets.symmetric(horizontal: 4));
      if (chip.selected) {
        expect((chip.label as Text).style?.color, Colors.white);
      }
    }
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
    expect(find.text('${AppStrings.top} 200'), findsNothing);
    expect(find.text('${AppStrings.top} 250'), findsNothing);
    expect(
      tester.getTopLeft(find.text('${AppStrings.top} 50')).dx,
      greaterThanOrEqualTo(6),
    );
    await tester.tap(find.text('${AppStrings.top} 50'));
    await tester.pumpAndSettle();
    expect(container.read(marketFiltersProvider).topLimit, 100);
    expect(find.text('${AppStrings.apply} (1)'), findsOneWidget);
    await tester.tap(find.text('${AppStrings.apply} (1)'));
    await tester.pumpAndSettle();
    expect(container.read(marketFiltersProvider).topLimit, 50);
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
