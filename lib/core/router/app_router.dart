import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/coin_details/presentation/screens/coin_details_screen.dart';
import '../../features/market/presentation/screens/market_screen.dart';
import '../../features/settings/presentation/screens/settings_screen.dart';
import '../../features/stats/presentation/screens/stats_screen.dart';
import '../../features/watchlist/presentation/screens/watchlist_screen.dart';
import '../../shared/widgets/main_shell.dart';
import 'routes.dart';

final rootNavigatorKey = GlobalKey<NavigatorState>();

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: Routes.market,
    routes: [
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            MainShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.market,
                builder: (_, _) => const MarketScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.stats,
                builder: (_, _) => const StatsScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.watchlist,
                builder: (_, _) => const WatchlistScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.settings,
                builder: (_, _) => const SettingsScreen(),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: Routes.coin,
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) =>
            CoinDetailsScreen(coinId: state.pathParameters['id']!),
      ),
    ],
  );
});
