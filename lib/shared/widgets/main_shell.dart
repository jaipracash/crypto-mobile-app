import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_strings.dart';
import 'offline_banner.dart';

class MainShell extends StatelessWidget {
  const MainShell({required this.navigationShell, super.key});
  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Column(
      children: [
        const OfflineBanner(),
        Expanded(child: navigationShell),
      ],
    ),
    bottomNavigationBar: NavigationBar(
      selectedIndex: navigationShell.currentIndex,
      onDestinationSelected: navigationShell.goBranch,
      destinations: const [
        NavigationDestination(
          icon: Icon(Icons.show_chart_rounded),
          label: AppStrings.market,
        ),
        NavigationDestination(
          icon: Icon(Icons.pie_chart_outline_rounded),
          label: AppStrings.stats,
        ),
        NavigationDestination(
          icon: Icon(Icons.star_outline_rounded),
          label: AppStrings.watchlist,
        ),
        NavigationDestination(
          icon: Icon(Icons.settings_outlined),
          label: AppStrings.settings,
        ),
      ],
    ),
  );
}
