import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:gecko_lite/core/error/failure.dart';
import 'package:gecko_lite/features/market/domain/coin.dart';
import 'package:gecko_lite/shared/widgets/async_value_view.dart';
import 'package:gecko_lite/shared/widgets/coin_tile.dart';
import 'package:gecko_lite/shared/widgets/app_loader.dart';
import 'package:gecko_lite/shared/widgets/error_view.dart';
import 'package:gecko_lite/shared/widgets/simulated_price_banner.dart';

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
          body: CoinTile(coin: coin, currency: 'usd', onTap: () {}),
        ),
      ),
    );
    expect(find.text('Bitcoin'), findsOneWidget);
    expect(find.text('BTC'), findsOneWidget);
    expect(find.textContaining('67,420'), findsOneWidget);
    expect(find.byTooltip('Remove from watchlist'), findsNothing);
    expect(find.byIcon(Icons.star_rounded), findsNothing);
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
    expect(find.byType(AppLoader), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(AppLoader),
        matching: find.byType(CustomPaint),
      ),
      findsOneWidget,
    );

    await tester.pumpWidget(
      view(AsyncError<List<int>>(Exception('offline'), StackTrace.current)),
    );
    await tester.pumpAndSettle();
    expect(find.text('Try again'), findsOneWidget);

    await tester.pumpWidget(view(const AsyncData<List<int>>([])));
    await tester.pumpAndSettle();
    expect(find.text('No data'), findsOneWidget);

    await tester.pumpWidget(
      view(
        const AsyncLoading<List<int>>().copyWithPrevious(
          AsyncError<List<int>>(Exception('offline'), StackTrace.empty),
        ),
      ),
    );
    expect(find.byType(AppLoader), findsOneWidget);
    expect(find.text('Try again'), findsNothing);
  });

  testWidgets('ErrorView displays the offline illustration for no internet', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ErrorView(
            error: const Failure(FailureType.noInternet, 'offline'),
            onRetry: () {},
          ),
        ),
      ),
    );

    expect(find.text('No internet connection'), findsOneWidget);
    expect(find.text('Check your connection and try again.'), findsOneWidget);
    expect(find.byType(SvgPicture), findsOneWidget);
    expect(find.text('Try again'), findsOneWidget);
  });

  testWidgets('demo notice text is readable in dark theme', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.dark(),
        home: const Scaffold(body: SimulatedPriceBanner()),
      ),
    );

    final notice = tester.widget<Text>(
      find.text(
        'Demo only: prices are simulated and are not live market quotes.',
      ),
    );
    expect(notice.style?.color, ThemeData.dark().colorScheme.onSurface);
  });

  testWidgets('ErrorView displays a friendly generic error state', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ErrorView(
            error: Exception('internal technical detail'),
            onRetry: () {},
          ),
        ),
      ),
    );

    expect(find.text('Something went wrong'), findsOneWidget);
    expect(
      find.text('We could not load this right now. Please try again.'),
      findsOneWidget,
    );
    expect(find.text('internal technical detail'), findsNothing);
    expect(find.byType(SvgPicture), findsOneWidget);
    expect(find.text('Try again'), findsOneWidget);
    final retryButton = tester.widget<FilledButton>(find.byType(FilledButton));
    expect(
      retryButton.style?.backgroundColor?.resolve({}),
      Theme.of(tester.element(find.byType(FilledButton))).colorScheme.primary,
    );
  });
}
