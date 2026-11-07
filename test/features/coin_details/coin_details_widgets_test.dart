import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:gecko_lite/core/constants/app_strings.dart';
import 'package:gecko_lite/features/coin_details/data/coin_details_dto.dart';
import 'package:gecko_lite/features/coin_details/domain/coin_details.dart';
import 'package:gecko_lite/features/coin_details/presentation/widgets/historical_data_card.dart';
import 'package:gecko_lite/features/coin_details/presentation/widgets/price_chart.dart';
import 'package:gecko_lite/features/coin_details/presentation/widgets/stats_grid.dart';
import 'package:gecko_lite/features/market/domain/coin.dart';
import 'package:gecko_lite/shared/widgets/coin_avatar.dart';

void main() {
  test('coin chart reports the range requested from the repository', () {
    final chart = CoinChartDto(
      const {
        'coin_id': 'bitcoin',
        'days': 30,
        'currency': 'usd',
        'prices': [
          [1794009600000, 100],
          [1794096000000, 102],
        ],
        'market_caps': [
          [1794009600000, 1000],
          [1794096000000, 1020],
        ],
        'ohlc': [
          [1794009600000, 100, 103, 99, 102],
        ],
      },
      'live',
      requestedCoinId: 'bitcoin',
      requestedDays: 30,
      requestedCurrency: 'usd',
    ).toEntity();

    expect(chart.days, 30);
    expect(chart.prices, hasLength(2));
    expect(chart.marketCaps, hasLength(2));
    expect(chart.candles, hasLength(1));
    expect(chart.candles.single.high, 103);
  });

  test('coin chart rejects data for a different coin or range', () {
    expect(
      () => CoinChartDto(
        const {
          'coin_id': 'ethereum',
          'days': 7,
          'currency': 'usd',
          'prices': [],
        },
        'live',
        requestedCoinId: 'bitcoin',
        requestedDays: 7,
        requestedCurrency: 'usd',
      ).toEntity(),
      throwsFormatException,
    );
    expect(
      () => CoinChartDto(
        const {
          'coin_id': 'bitcoin',
          'days': 30,
          'currency': 'usd',
          'prices': [],
        },
        'live',
        requestedCoinId: 'bitcoin',
        requestedDays: 7,
        requestedCurrency: 'usd',
      ).toEntity(),
      throwsFormatException,
    );
  });

  testWidgets('coin info is shown in a bordered two-column panel', (
    tester,
  ) async {
    const details = CoinDetails(
      coin: Coin(
        id: 'bitcoin',
        symbol: 'btc',
        name: 'Bitcoin',
        price: 50000,
        marketCap: 1000000,
        volume24h: 25000,
        circulatingSupply: 20,
        totalSupply: 21,
        maxSupply: 21,
      ),
      high24h: 51000,
      low24h: 49000,
    );

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: StatsGrid(details: details, currency: 'usd'),
        ),
      ),
    );

    expect(find.text(AppStrings.marketCap), findsOneWidget);
    expect(find.text(AppStrings.fullyDilutedValuation), findsOneWidget);
    expect(find.text(AppStrings.circulatingSupply), findsOneWidget);
    expect(find.byType(GridView), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('historical data shows 24h and all-time high and low values', (
    tester,
  ) async {
    final details = CoinDetails(
      coin: const Coin(
        id: 'bitcoin',
        symbol: 'btc',
        name: 'Bitcoin',
        price: 76000,
      ),
      high24h: 76150,
      low24h: 75584,
      ath: 126080,
      athChangePct: -39.9,
      athDate: DateTime(2025, 10, 6),
      atl: 67.81,
      atlChangePct: 111681,
      atlDate: DateTime(2013, 7, 5),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: HistoricalDataCard(details: details, currency: 'usd'),
        ),
      ),
    );

    expect(find.text(AppStrings.historicalData), findsOneWidget);
    expect(find.text(AppStrings.high24h), findsOneWidget);
    expect(find.text(AppStrings.low24h), findsOneWidget);
    expect(find.text(AppStrings.allTimeHigh), findsOneWidget);
    expect(find.text(AppStrings.allTimeLow), findsOneWidget);
    expect(find.textContaining('126,080.00'), findsOneWidget);
    expect(find.textContaining('111681.00%'), findsOneWidget);
    expect(find.byIcon(Icons.arrow_downward_rounded), findsOneWidget);
    expect(find.byIcon(Icons.arrow_upward_rounded), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('price chart draws timestamp-ordered, sharp real price points', (
    tester,
  ) async {
    final earlier = DateTime(2026, 11, 6, 8);
    final later = DateTime(2026, 11, 6, 10);
    final chart = CoinChart(
      coinId: 'bitcoin',
      days: 1,
      currency: 'usd',
      prices: [
        PricePoint(later, 101),
        PricePoint(earlier.add(const Duration(hours: 1)), 104),
        PricePoint(earlier, 100),
      ],
      changePct: 4,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PriceChart(chart: chart, currency: 'usd', onTouch: (_) {}),
        ),
      ),
    );

    final line = tester.widget<LineChart>(find.byType(LineChart));
    final lineData = line.data.lineBarsData.single;
    expect(lineData.isCurved, isFalse);
    expect(lineData.barWidth, 1.6);
    expect(lineData.spots.map((spot) => spot.y), [100, 104, 101]);
    expect(line.data.titlesData.bottomTitles.sideTitles.showTitles, isTrue);
    expect(line.data.titlesData.rightTitles.sideTitles.showTitles, isTrue);
    expect(tester.takeException(), isNull);
  });

  testWidgets('empty API history shows an empty state instead of a chart', (
    tester,
  ) async {
    const chart = CoinChart(
      coinId: 'bitcoin',
      days: 7,
      currency: 'usd',
      prices: [],
    );

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: PriceChart(chart: chart, currency: 'usd', onTouch: _noTouch),
        ),
      ),
    );

    expect(find.byType(LineChart), findsNothing);
    expect(find.text(AppStrings.noChartData), findsOneWidget);
  });

  testWidgets('price chart can plot market-cap history', (tester) async {
    final chart = CoinChart(
      coinId: 'bitcoin',
      days: 7,
      currency: 'usd',
      prices: [
        PricePoint(DateTime(2026, 11, 6), 100),
        PricePoint(DateTime(2026, 11, 7), 101),
      ],
      marketCaps: [
        PricePoint(DateTime(2026, 11, 6), 1000),
        PricePoint(DateTime(2026, 11, 7), 1100),
      ],
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PriceChart(
            chart: chart,
            currency: 'usd',
            series: PriceChartSeries.marketCap,
            onTouch: (_) {},
          ),
        ),
      ),
    );

    expect(find.byType(LineChart), findsOneWidget);
    final renderedChart = tester.widget<LineChart>(find.byType(LineChart));
    expect(renderedChart.data.lineBarsData.single.spots.map((spot) => spot.y), [
      1000,
      1100,
    ]);
    expect(tester.takeException(), isNull);
  });

  testWidgets('candlestick chart renders sampled candle data', (tester) async {
    final chart = CoinChart(
      coinId: 'bitcoin',
      days: 1,
      currency: 'usd',
      prices: [
        PricePoint(DateTime(2026, 11, 6, 8), 100),
        PricePoint(DateTime(2026, 11, 6, 9), 104),
        PricePoint(DateTime(2026, 11, 6, 10), 101),
      ],
      candles: [
        CandlePoint(
          timestamp: DateTime(2026, 11, 6, 8),
          open: 100,
          high: 104,
          low: 99,
          close: 103,
        ),
        CandlePoint(
          timestamp: DateTime(2026, 11, 6, 10),
          open: 103,
          high: 105,
          low: 101,
          close: 101,
        ),
      ],
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PriceChart(
            chart: chart,
            currency: 'usd',
            style: PriceChartStyle.candles,
            onTouch: (_) {},
          ),
        ),
      ),
    );

    final customPaint = tester.widgetList<CustomPaint>(
      find.byType(CustomPaint),
    );
    expect(customPaint, isNotEmpty);
    expect(tester.takeException(), isNull);
  });

  testWidgets('details avatar does not duplicate the coin Hero tag', (
    tester,
  ) async {
    const imageUrl = 'https://example.com/bitcoin.png';
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Row(
            children: [
              CoinAvatar(symbol: 'btc', imageUrl: imageUrl),
              CoinAvatar(symbol: 'btc', imageUrl: imageUrl, enableHero: false),
            ],
          ),
        ),
      ),
    );

    expect(find.byType(Hero), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

void _noTouch(PricePoint? point) {}
