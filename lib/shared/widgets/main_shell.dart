import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_strings.dart';
import 'offline_banner.dart';

class MainShell extends StatefulWidget {
  const MainShell({required this.navigationShell, super.key});
  final StatefulNavigationShell navigationShell;

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell>
    with SingleTickerProviderStateMixin {
  late final AnimationController _homeShimmerController;

  @override
  void initState() {
    super.initState();
    _homeShimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    );
  }

  @override
  void dispose() {
    _homeShimmerController.dispose();
    super.dispose();
  }

  void _selectDestination(int index) {
    widget.navigationShell.goBranch(index);
    if (index == 0) _homeShimmerController.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Column(children: [Expanded(child: widget.navigationShell)]),
    bottomNavigationBar: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const OfflineBanner(),
        Divider(
          height: 1,
          thickness: 0.5,
          color: Theme.of(context).dividerColor,
        ),
        NavigationBar(
          height: 68,
          selectedIndex: widget.navigationShell.currentIndex,
          onDestinationSelected: _selectDestination,
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
          labelTextStyle: WidgetStateProperty.resolveWith((states) {
            final selected = states.contains(WidgetState.selected);
            return Theme.of(context).textTheme.labelMedium?.copyWith(
              color: selected
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.onSurfaceVariant,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
            );
          }),
          destinations: [
            NavigationDestination(
              icon: _homeIcon(selected: false),
              selectedIcon: _homeIcon(selected: true),
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
      ],
    ),
  );

  Widget _homeIcon({required bool selected}) => AnimatedBuilder(
    animation: _homeShimmerController,
    builder: (context, _) {
      const size = 24.0;
      final baseColor = selected
          ? Theme.of(context).colorScheme.primary
          : _inactiveNavigationColor(context);
      Widget icon(Color color) => SvgPicture.asset(
        'assets/flutter.svg',
        width: size,
        height: size,
        colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
      );

      return SizedBox(
        width: size,
        height: size,
        child: Stack(
          children: [
            icon(baseColor),
            if (_homeShimmerController.isAnimating)
              ShaderMask(
                blendMode: BlendMode.srcIn,
                shaderCallback: (bounds) {
                  final position = -1.5 + 3 * _homeShimmerController.value;
                  return LinearGradient(
                    begin: Alignment(position, position),
                    end: Alignment(position + 1.15, position + 1.15),
                    colors: [
                      Colors.white.withValues(alpha: 0),
                      Colors.white.withValues(alpha: 0.28),
                      Colors.white.withValues(alpha: 0.9),
                      Colors.white.withValues(alpha: 0.28),
                      Colors.white.withValues(alpha: 0),
                    ],
                    stops: const [0, 0.3, 0.5, 0.7, 1],
                  ).createShader(bounds);
                },
                child: icon(Colors.white),
              ),
          ],
        ),
      );
    },
  );

  Widget _navigationIcon(
    BuildContext context,
    String asset, {
    required bool selected,
  }) {
    final color = selected
        ? Theme.of(context).colorScheme.primary
        : _inactiveNavigationColor(context);
    return SvgPicture.asset(
      asset,
      width: 24,
      height: 24,
      colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
    );
  }

  Color _inactiveNavigationColor(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
      ? const Color(0xFF8B96A5)
      : const Color(0xFF8A9099);
}
