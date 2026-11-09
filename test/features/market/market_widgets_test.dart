import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gecko_lite/core/constants/app_sizes.dart';
import 'package:gecko_lite/core/constants/app_strings.dart';
import 'package:gecko_lite/features/market/domain/coin.dart';
import 'package:gecko_lite/features/market/domain/market_filters.dart';
import 'package:gecko_lite/features/market/domain/market_models.dart';
import 'package:gecko_lite/features/market/presentation/controllers/market_controller.dart';
import 'package:gecko_lite/features/market/presentation/controllers/search_controller.dart';
import 'package:gecko_lite/features/market/presentation/controllers/visible_coins_provider.dart';
import 'package:gecko_lite/features/market/presentation/screens/home_screen.dart';
import 'package:gecko_lite/features/market/presentation/screens/search_screen.dart';
import 'package:gecko_lite/features/market/presentation/widgets/coin_row.dart';
import 'package:gecko_lite/features/market/presentation/widgets/market_sheets.dart';
import 'package:gecko_lite/features/settings/domain/app_settings.dart';
import 'package:gecko_lite/features/settings/presentation/controllers/settings_controller.dart';
import 'package:gecko_lite/shared/widgets/change_pill.dart';
import 'package:gecko_lite/shared/widgets/shimmer_box.dart';
import 'package:gecko_lite/shared/widgets/sparkline.dart';

import '../../helpers/screen_util_test_wrapper.dart';

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

class _HomeTestGlobalStatsController extends GlobalStatsController {
  @override
  Future<MarketSnapshot> build() async => const MarketSnapshot(
    totalMarketCap: 2500000000000,
    totalVolume24h: 95000000000,
    marketCapChange24hPct: 2.5,
  );
}

void main() {
  testWidgets('home controls fit a short narrow screen without overflow', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(325, 560);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ScreenUtilInit(
        designSize: const Size(390, 844),
        minTextAdapt: true,
        splitScreenMode: true,
        builder: (_, child) => child!,
        child: ProviderScope(
          overrides: [
            coinListControllerProvider.overrideWith(
              _SearchTestCoinListController.new,
            ),
            trendingControllerProvider.overrideWith(
              _SearchTestTrendingController.new,
            ),
            globalStatsControllerProvider.overrideWith(
              _HomeTestGlobalStatsController.new,
            ),
            settingsControllerProvider.overrideWith(
              _SearchTestSettingsController.new,
            ),
          ],
          child: const MaterialApp(home: HomeScreen()),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      tester.getSize(find.byType(TextField)).height,
      greaterThanOrEqualTo(44),
    );
    final searchRect = tester.getRect(find.byType(TextField));
    final notificationRect = tester.getRect(
      find.byTooltip(AppStrings.notifications),
    );
    expect(notificationRect.right, greaterThan(317));
    expect(searchRect.right, lessThan(notificationRect.left));
    expect(tester.takeException(), isNull);
  });

  testWidgets('Coin row skeleton omits rank-column shimmer', (tester) async {
    await tester.pumpWidget(
      screenUtilTestWrapper(
        const MaterialApp(
          home: Scaffold(body: SizedBox(width: 390, child: CoinRowSkeleton())),
        ),
      ),
    );

    expect(find.byType(ShimmerBox), findsNWidgets(5));
    final avatar = tester.getRect(find.byType(ShimmerBox).first);
    expect(avatar.left, closeTo(AppSizes.screenPadding.w, 0.1));
  });

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
      screenUtilTestWrapper(
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
      ),
    );
    expect(find.text('Bitcoin'), findsOneWidget);
    expect(find.textContaining('BTC'), findsOneWidget);
    expect(find.textContaining('1.3T'), findsOneWidget);
    final sparkline = tester.widget<Sparkline>(find.byType(Sparkline));
    final changePill = tester.widget<ChangePill>(find.byType(ChangePill));
    expect(sparkline.filled, isTrue);
    expect(sparkline.positive, isTrue);
    expect(sparkline.width, 62);
    expect(sparkline.height, 24);
    final sparklineData = tester
        .widget<LineChart>(find.byType(LineChart))
        .data
        .lineBarsData
        .single;
    expect(sparklineData.isCurved, isTrue);
    expect(sparklineData.barWidth, 1.0);
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
      screenUtilTestWrapper(
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
      ),
    );

    expect(find.textContaining('BTC'), findsOneWidget);
    expect(find.textContaining('1.3T'), findsOneWidget);
    expect(find.byType(VerticalDivider), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('market table compacts price and columns on narrow screens', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 640);
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
      sparkline7d: [65000, 66500, 65800, 67420],
    );
    await tester.pumpWidget(
      screenUtilTestWrapper(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 320,
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
      ),
    );

    final priceStyles = tester
        .widgetList<AnimatedDefaultTextStyle>(
          find.byType(AnimatedDefaultTextStyle),
        )
        .map((style) => style.style.fontSize);
    expect(priceStyles, contains(12));
    expect(
      tester.widget<Sparkline>(find.byType(Sparkline)).width,
      lessThan(50),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('market table headers use high-contrast color in dark theme', (
    tester,
  ) async {
    await tester.pumpWidget(
      screenUtilTestWrapper(
        MaterialApp(
          theme: ThemeData.dark(),
          home: Scaffold(
            body: CoinTableHeader(period: ChangePeriod.day, onPeriodTap: () {}),
          ),
        ),
      ),
    );

    final nameHeader = tester.widget<Text>(find.text(AppStrings.coin));
    expect(nameHeader.style?.color, ThemeData.dark().colorScheme.onSurface);
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

  test('search query does not filter the home market coin list', () async {
    final container = ProviderContainer(
      overrides: [
        coinListControllerProvider.overrideWith(
          _SearchTestCoinListController.new,
        ),
        settingsControllerProvider.overrideWith(
          _SearchTestSettingsController.new,
        ),
      ],
    );
    addTearDown(container.dispose);

    await container.read(coinListControllerProvider.future);
    container.read(searchQueryProvider.notifier).set('ethereum');

    expect(
      container.read(visibleCoinsProvider(HomeTab.all)).map((coin) => coin.id),
      ['bitcoin'],
    );
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
      screenUtilTestWrapper(
        MaterialApp(
          home: Scaffold(
            body: Wrap(
              children: assets
                  .map((asset) => SvgPicture.asset(asset, width: 24))
                  .toList(),
            ),
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
      screenUtilTestWrapper(
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
      screenUtilTestWrapper(
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

  testWidgets('FilterSheet stays within narrow screen horizontal bounds', (
    tester,
  ) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      screenUtilTestWrapper(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) => TextButton(
                  onPressed: () =>
                      showMarketSheet(context, const FilterSheet()),
                  child: const Text(AppStrings.filter),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text(AppStrings.filter));
    await tester.pumpAndSettle();

    final resetButton = find.widgetWithText(FilledButton, AppStrings.reset);
    final applyButton = find.widgetWithText(FilledButton, 'Apply (0)');
    final resetRect = tester.getRect(resetButton);
    final applyRect = tester.getRect(applyButton);
    final horizontalInset = AppSizes.lg.w;
    expect(resetRect.left, closeTo(horizontalInset, 0.1));
    expect(applyRect.right, closeTo(320 - horizontalInset, 0.1));
    final contentPadding =
        tester
                .widget<SingleChildScrollView>(
                  find.byType(SingleChildScrollView),
                )
                .padding!
            as EdgeInsets;
    expect(contentPadding.left, horizontalInset);
    expect(contentPadding.right, horizontalInset);
    final showTopRect = tester.getRect(find.text(AppStrings.showTop));
    expect(showTopRect.left, closeTo(resetRect.left, 0.1));
    final footerPadding = tester
        .widgetList<Padding>(find.byType(Padding))
        .firstWhere((padding) {
          final child = padding.child;
          return child is Row &&
              child.children.any((widget) => widget is Expanded);
        })
        .padding
        .resolve(TextDirection.ltr);
    expect(footerPadding.left, horizontalInset);
    expect(footerPadding.right, horizontalInset);
    for (final chip in find.byType(ChoiceChip).evaluate()) {
      final rect = tester.getRect(find.byWidget(chip.widget));
      expect(rect.left, greaterThanOrEqualTo(horizontalInset));
      expect(rect.right, lessThanOrEqualTo(320 - horizontalInset));
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets('FilterSheet applies top count from its draft', (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    await tester.pumpWidget(
      screenUtilTestWrapper(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) => TextButton(
                  onPressed: () =>
                      showMarketSheet(context, const FilterSheet()),
                  child: const Text(AppStrings.filter),
                ),
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
      screenUtilTestWrapper(
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
      screenUtilTestWrapper(
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
      ),
    );

    expect(find.text(AppStrings.totalMarketCap), findsOneWidget);
    expect(find.text(AppStrings.volume24h), findsOneWidget);
    expect(find.text(AppStrings.marketDominance), findsOneWidget);
    expect(find.text(AppStrings.activeCoins), findsOneWidget);
    expect(find.text('12000'), findsOneWidget);
  });

  testWidgets('Market overview sheet leaves space below market cap change', (
    tester,
  ) async {
    await tester.pumpWidget(
      screenUtilTestWrapper(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () => showMarketSheet(
                  context,
                  const MarketOverviewSheet(
                    snapshot: MarketSnapshot(marketCapChange24hPct: 2.5),
                  ),
                ),
                child: const Text(AppStrings.marketOverview),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text(AppStrings.marketOverview));
    await tester.pumpAndSettle();

    final sheetBottom = tester.getRect(find.byType(BottomSheetScaffold)).bottom;
    final finalMetricBottom = tester
        .getRect(find.text(AppStrings.marketCapChange))
        .bottom;
    expect(sheetBottom - finalMetricBottom, greaterThanOrEqualTo(9));
    expect(tester.takeException(), isNull);
  });

  testWidgets('PeriodSheet selection rows have horizontal inset', (
    tester,
  ) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    await tester.pumpWidget(
      screenUtilTestWrapper(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) => TextButton(
                  onPressed: () =>
                      showMarketSheet(context, const PeriodSheet()),
                  child: const Text(AppStrings.changePeriod),
                ),
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
