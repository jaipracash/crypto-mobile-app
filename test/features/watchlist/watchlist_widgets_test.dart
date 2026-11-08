import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:gecko_lite/core/constants/app_strings.dart';
import 'package:gecko_lite/core/providers/repository_providers.dart';
import 'package:gecko_lite/core/router/routes.dart';
import 'package:gecko_lite/features/market/domain/coin.dart';
import 'package:gecko_lite/features/market/presentation/controllers/market_controller.dart';
import 'package:gecko_lite/features/market/presentation/widgets/coin_row.dart';
import 'package:gecko_lite/features/settings/domain/app_settings.dart';
import 'package:gecko_lite/features/settings/presentation/controllers/settings_controller.dart';
import 'package:gecko_lite/features/watchlist/domain/watchlist_repository.dart';
import 'package:gecko_lite/features/watchlist/presentation/controllers/add_watchlist_coins_controller.dart';
import 'package:gecko_lite/features/watchlist/presentation/controllers/watchlist_controller.dart';
import 'package:gecko_lite/features/watchlist/presentation/screens/add_watchlist_coins_screen.dart';
import 'package:gecko_lite/features/watchlist/presentation/screens/watchlist_screen.dart';

const _coins = [
  Coin(id: 'bitcoin', symbol: 'btc', name: 'Bitcoin', change24hPct: 2.4),
  Coin(id: 'ethereum', symbol: 'eth', name: 'Ethereum', change24hPct: -1.2),
];

class _TestAddCoinsController extends AddWatchlistCoinsController {
  @override
  Future<AddWatchlistCoinsState> build() async => const AddWatchlistCoinsState(
    items: _coins,
    page: 1,
    hasMore: false,
    dataSource: 'mock',
  );
}

class _EmptyTestWatchlistController extends WatchlistController {
  @override
  Future<WatchlistData> build() async =>
      const WatchlistData(items: [], dataSource: 'mock');
}

class _PopulatedTestWatchlistController extends WatchlistController {
  @override
  Future<WatchlistData> build() async =>
      const WatchlistData(items: _coins, dataSource: 'mock');
}

class _TestSettingsController extends SettingsController {
  @override
  Future<AppSettings> build() async => const AppSettings();
}

class _TestCoinListController extends CoinListController {
  @override
  Future<CoinListState> build() async => const CoinListState(items: _coins);
}

class _TestWatchlistRepository implements WatchlistRepository {
  final Set<String> coinIds = _coins.map((coin) => coin.id).toSet();

  @override
  Future<WatchlistData> getWatchlist(String currency) async => WatchlistData(
    items: _coins.where((coin) => coinIds.contains(coin.id)).toList(),
    dataSource: 'mock',
  );

  @override
  Future<void> add(String coinId) async => coinIds.add(coinId);

  @override
  Future<void> remove(String coinId) async => coinIds.remove(coinId);
}

void main() {
  testWidgets('empty watchlist opens searchable add-coins selector', (
    tester,
  ) async {
    final router = GoRouter(
      initialLocation: Routes.watchlist,
      routes: [
        GoRoute(
          path: Routes.watchlist,
          builder: (_, _) => const WatchlistScreen(),
          routes: [
            GoRoute(
              path: 'add',
              builder: (_, _) => const AddWatchlistCoinsScreen(),
            ),
          ],
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          addWatchlistCoinsControllerProvider.overrideWith(
            _TestAddCoinsController.new,
          ),
          watchlistControllerProvider.overrideWith(
            _EmptyTestWatchlistController.new,
          ),
          settingsControllerProvider.overrideWith(_TestSettingsController.new),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text(AppStrings.emptyWatchlist), findsOneWidget);
    expect(find.text('Explore market'), findsNothing);
    expect(find.text(AppStrings.addCoins), findsOneWidget);

    await tester.tap(find.text(AppStrings.addCoins));
    await tester.pumpAndSettle();
    expect(find.text(AppStrings.searchAllCoins), findsOneWidget);
    expect(find.text('Bitcoin'), findsOneWidget);
    expect(find.text('Ethereum'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'eth');
    await tester.pumpAndSettle();
    expect(find.text('Ethereum'), findsOneWidget);
    expect(find.text('Bitcoin'), findsNothing);

    await tester.tap(find.text('Ethereum'));
    await tester.pumpAndSettle();
    expect(find.text('${AppStrings.addCoins} (1)'), findsOneWidget);
    final addButton = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, '${AppStrings.addCoins} (1)'),
    );
    expect(addButton.style?.foregroundColor?.resolve({}), Colors.white);
    expect(tester.takeException(), isNull);
  });

  testWidgets('tapping an already watchlisted coin removes it', (tester) async {
    final repository = _TestWatchlistRepository();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          addWatchlistCoinsControllerProvider.overrideWith(
            _TestAddCoinsController.new,
          ),
          watchlistControllerProvider.overrideWith(
            _PopulatedTestWatchlistController.new,
          ),
          watchlistRepositoryProvider.overrideWithValue(repository),
          coinListControllerProvider.overrideWith(_TestCoinListController.new),
          settingsControllerProvider.overrideWith(_TestSettingsController.new),
        ],
        child: const MaterialApp(home: AddWatchlistCoinsScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.radio_button_checked_rounded), findsNWidgets(2));
    await tester.tap(find.text('Bitcoin'));
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.radio_button_checked_rounded), findsOneWidget);
    expect(repository.coinIds, {'ethereum'});
    expect(tester.takeException(), isNull);
  });

  testWidgets('watchlist filter only shows coins with matching daily change', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          watchlistControllerProvider.overrideWith(
            _PopulatedTestWatchlistController.new,
          ),
          settingsControllerProvider.overrideWith(_TestSettingsController.new),
        ],
        child: const MaterialApp(home: WatchlistScreen()),
      ),
    );
    await tester.pumpAndSettle();

    final appBar = tester.widget<AppBar>(find.byType(AppBar));
    expect(appBar.scrolledUnderElevation, 0);
    expect(appBar.surfaceTintColor, Colors.transparent);
    expect(find.text('2'), findsNothing);
    expect(find.text('2 watchlist'), findsOneWidget);
    expect(find.text(AppStrings.addCoins), findsOneWidget);
    final addCoinsButton = find.widgetWithText(
      FilledButton,
      AppStrings.addCoins,
    );
    expect(tester.getSize(addCoinsButton).width, 768);
    final addCoinsLabel = tester.widget<Text>(
      find.descendant(
        of: addCoinsButton,
        matching: find.text(AppStrings.addCoins),
      ),
    );
    expect(addCoinsLabel.style?.color, Colors.white);
    expect(addCoinsLabel.style?.fontWeight, FontWeight.w700);
    expect(addCoinsLabel.style?.fontSize, 16);
    expect(find.byType(CoinRow), findsNWidgets(2));
    expect(find.text('Bitcoin'), findsOneWidget);
    expect(find.text('Ethereum'), findsOneWidget);
    await tester.tap(find.byTooltip(AppStrings.filterWatchlist));
    await tester.pumpAndSettle();
    await tester.tap(find.text(AppStrings.losers));
    await tester.pumpAndSettle();

    expect(find.text('Bitcoin'), findsNothing);
    expect(find.text('Ethereum'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
