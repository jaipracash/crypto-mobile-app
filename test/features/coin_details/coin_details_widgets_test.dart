import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:gecko_lite/core/constants/app_strings.dart';
import 'package:gecko_lite/features/coin_details/domain/coin_details.dart';
import 'package:gecko_lite/features/coin_details/presentation/widgets/price_chart.dart';
import 'package:gecko_lite/features/coin_details/presentation/widgets/stats_grid.dart';
import 'package:gecko_lite/features/market/domain/coin.dart';

void main() {
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
    expect(lineData.spots.map((spot) => spot.y), [100, 104, 101]);
    expect(line.data.titlesData.bottomTitles.sideTitles.showTitles, isTrue);
    expect(line.data.titlesData.leftTitles.sideTitles.showTitles, isTrue);
    expect(tester.takeException(), isNull);
  });
}
