import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gecko_lite/features/market/domain/coin.dart';
import 'package:gecko_lite/shared/widgets/async_value_view.dart';
import 'package:gecko_lite/shared/widgets/coin_tile.dart';
import 'package:gecko_lite/shared/widgets/shimmer_box.dart';

void main() {
  testWidgets('CoinTile shows coin identity and market price', (tester) async {
    const coin = Coin(
      id: 'bitcoin',
      symbol: 'btc',
      name: 'Bitcoin',
      price: 67420.15,
      rank: 1,
      change24hPct: 2.4,
      isWatchlisted: true,
    );
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CoinTile(
            coin: coin,
            currency: 'usd',
            onTap: () {},
            onToggleWatchlist: () {},
          ),
        ),
      ),
    );
    expect(find.text('Bitcoin'), findsOneWidget);
    expect(find.text('BTC'), findsOneWidget);
    expect(find.textContaining('67,420'), findsOneWidget);
    expect(find.byTooltip('Remove from watchlist'), findsOneWidget);
  });

  testWidgets('AsyncValueView renders loading, error, and empty states', (
    tester,
  ) async {
    Widget view(AsyncValue<List<int>> value) => MaterialApp(
      home: Scaffold(
        body: AsyncValueView<List<int>>(
          value: value,
          onRetry: () {},
          isEmpty: (items) => items.isEmpty,
          emptyTitle: 'No data',
          builder: (items) => Text('${items.length} values'),
        ),
      ),
    );

    await tester.pumpWidget(view(const AsyncLoading<List<int>>()));
    expect(find.byType(ShimmerBox), findsWidgets);

    await tester.pumpWidget(
      view(AsyncError<List<int>>(Exception('offline'), StackTrace.current)),
    );
    await tester.pumpAndSettle();
    expect(find.text('Try again'), findsOneWidget);

    await tester.pumpWidget(view(const AsyncData<List<int>>([])));
    await tester.pumpAndSettle();
    expect(find.text('No data'), findsOneWidget);
  });
}
