import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gecko_lite/core/constants/app_strings.dart';
import 'package:gecko_lite/features/market/domain/coin.dart';
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
    expect(find.text('BTC · MCap \$1.3T'), findsOneWidget);
    expect(find.byTooltip(AppStrings.addToWatchlist), findsNothing);
    expect(find.byTooltip(AppStrings.removeFromWatchlist), findsNothing);
    expect(find.byIcon(Icons.star_border_rounded), findsNothing);
    expect(find.byIcon(Icons.star_rounded), findsNothing);
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

  testWidgets('RankSheet sizes to its options instead of filling the screen', (
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
                onPressed: () => showMarketSheet(context, const RankSheet()),
                child: const Text(AppStrings.topCoins),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text(AppStrings.topCoins));
    await tester.pumpAndSettle();
    expect(tester.getTopLeft(find.text('50')).dx, greaterThanOrEqualTo(16));
    expect(
      tester.getSize(find.byType(BottomSheetScaffold)).height,
      lessThan(400),
    );
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
