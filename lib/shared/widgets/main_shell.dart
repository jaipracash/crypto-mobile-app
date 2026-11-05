import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
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
      destinations: [
        NavigationDestination(
          icon: _navigationIcon(
            context,
            'assets/dart-svgrepo-com.svg',
            selected: false,
          ),
          selectedIcon: _navigationIcon(
            context,
            'assets/dart-svgrepo-com.svg',
            selected: true,
          ),
          label: AppStrings.home,
        ),
        NavigationDestination(
          icon: _navigationIcon(
            context,
            'assets/search-alt-2-svgrepo-com.svg',
            selected: false,
          ),
          selectedIcon: _navigationIcon(
            context,
            'assets/search-alt-2-svgrepo-com.svg',
            selected: true,
          ),
          label: AppStrings.search,
        ),
        NavigationDestination(
          icon: _navigationIcon(
            context,
            'assets/watchlist.svg',
            selected: false,
          ),
          selectedIcon: _navigationIcon(
            context,
            'assets/watchlist.svg',
            selected: true,
          ),
          label: AppStrings.watchlist,
        ),
        NavigationDestination(
          icon: _navigationIcon(
            context,
            'assets/profile-svgrepo-com.svg',
            selected: false,
          ),
          selectedIcon: _navigationIcon(
            context,
            'assets/profile-svgrepo-com.svg',
            selected: true,
          ),
          label: AppStrings.settings,
        ),
      ],
    ),
  );

  Widget _navigationIcon(
    BuildContext context,
    String asset, {
    required bool selected,
  }) {
    final color = selected
        ? Theme.of(context).colorScheme.onSecondaryContainer
        : Theme.of(context).colorScheme.onSurfaceVariant;
    return SvgPicture.asset(
      asset,
      width: 24,
      height: 24,
      colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
    );
  }
}
