import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../shared/widgets/change_pill.dart';
import '../../../../shared/widgets/coin_avatar.dart';
import '../../../../shared/widgets/app_loader.dart';
import '../../../../shared/widgets/error_view.dart';
import '../../../market/domain/coin.dart';
import '../../domain/watchlist_repository.dart';
import '../controllers/add_watchlist_coins_controller.dart';
import '../controllers/watchlist_controller.dart';

class AddWatchlistCoinsScreen extends ConsumerStatefulWidget {
  const AddWatchlistCoinsScreen({super.key});

  @override
  ConsumerState<AddWatchlistCoinsScreen> createState() =>
      _AddWatchlistCoinsScreenState();
}

class _AddWatchlistCoinsScreenState
    extends ConsumerState<AddWatchlistCoinsScreen> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _listController = ScrollController();
  final Set<String> _selectedIds = {};
  String _query = '';
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _listController.addListener(_loadMoreWhenNeeded);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _listController
      ..removeListener(_loadMoreWhenNeeded)
      ..dispose();
    super.dispose();
  }

  void _loadMoreWhenNeeded() {
    if (_listController.position.extentAfter < 300) {
      unawaited(
        ref.read(addWatchlistCoinsControllerProvider.notifier).loadMore(),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final coins = ref.watch(addWatchlistCoinsControllerProvider);
    final watchlist = ref.watch(watchlistControllerProvider);
    final watchlistCoins = watchlist.asData?.value.items;
    final watchlistIds = watchlistCoins?.map((coin) => coin.id).toSet();
    final available = coins.asData?.value.items ?? const <Coin>[];
    final selectionCount = _selectedIds
        .where((id) => watchlistIds?.contains(id) != true)
        .length;

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.addCoins),
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(
              AppSizes.screenPadding.w,
              AppSizes.sm.w,
              AppSizes.screenPadding.w,
              AppSizes.md.w,
            ),
            child: TextField(
              controller: _searchController,
              onChanged: (value) => setState(() => _query = value),
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: AppStrings.searchAllCoins,
                prefixIcon: Padding(
                  padding: EdgeInsets.all(AppSizes.md.w),
                  child: SvgPicture.asset(
                    'assets/search-alt-2-svgrepo-com.svg',
                    width: AppSizes.iconMedium.w,
                    height: AppSizes.iconMedium.w,
                    colorFilter: ColorFilter.mode(
                      Theme.of(context).colorScheme.onSurfaceVariant,
                      BlendMode.srcIn,
                    ),
                  ),
                ),
                suffixIcon: _query.isEmpty
                    ? null
                    : IconButton(
                        tooltip: AppStrings.clearSearch,
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _query = '');
                        },
                        icon: const Icon(Icons.close),
                      ),
              ),
            ),
          ),
          Expanded(child: _buildCoinList(coins, watchlist, watchlistIds)),
          SafeArea(
            top: false,
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                AppSizes.screenPadding.w,
                AppSizes.sm.w,
                AppSizes.screenPadding.w,
                AppSizes.md.w,
              ),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: Theme.of(context)
                        .colorScheme
                        .primary
                        .withValues(alpha: 0.45),
                    disabledForegroundColor: Colors.white.withValues(
                      alpha: 0.75,
                    ),
                  ),
                  onPressed:
                      selectionCount == 0 || _saving || watchlistIds == null
                      ? null
                      : () => _addSelected(available, watchlistIds),
                  child: _saving
                      ? const AppLoader()
                      : Text(
                          selectionCount == 0
                              ? AppStrings.addCoins
                              : '${AppStrings.addCoins} ($selectionCount)',
                          style: Theme.of(context).textTheme.labelLarge
                              ?.copyWith(color: Colors.white),
                        ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCoinList(
    AsyncValue<AddWatchlistCoinsState> coins,
    AsyncValue<WatchlistData> watchlist,
    Set<String>? watchlistIds,
  ) {
    if (watchlist.hasError) {
      return ErrorView(
        error: watchlist.error!,
        onRetry: () => ref.read(watchlistControllerProvider.notifier).refresh(),
      );
    }
    if (watchlist.isLoading || watchlistIds == null) {
      return const Center(child: AppLoader());
    }

    return coins.when(
      loading: () => const Center(child: AppLoader()),
      error: (error, _) => ErrorView(
        error: error,
        onRetry: () => ref.invalidate(addWatchlistCoinsControllerProvider),
      ),
      data: (data) {
        final available = data.items
            .where((coin) {
              final query = _query.trim().toLowerCase();
              return query.isEmpty ||
                  coin.name.toLowerCase().contains(query) ||
                  coin.symbol.toLowerCase().contains(query);
            })
            .toList(growable: false);
        if (available.isEmpty) {
          return Center(
            child: Text(
              AppStrings.noAvailableCoins,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          );
        }
        return ListView.separated(
          controller: _listController,
          itemCount:
              available.length +
              (data.hasMore || data.isLoadingMore || data.loadMoreError != null
                  ? 1
                  : 0),
          separatorBuilder: (_, _) => Divider(
            height: 1,
            thickness: 0.5,
            color: Theme.of(context).dividerColor,
          ),
          itemBuilder: (context, index) {
            if (index >= available.length) {
              if (data.loadMoreError case final error?) {
                return TextButton(
                  onPressed: () => ref
                      .read(addWatchlistCoinsControllerProvider.notifier)
                      .loadMore(),
                  child: Text('$error', textAlign: TextAlign.center),
                );
              }
              return Padding(
                padding: EdgeInsets.all(AppSizes.md.w),
                child: Center(child: AppLoader()),
              );
            }
            final coin = available[index];
            final watchlisted = watchlistIds.contains(coin.id);
            return _SelectableCoinRow(
              coin: coin,
              selected: watchlisted || _selectedIds.contains(coin.id),
              enabled: !_saving,
              onTap: () => _toggleSelection(coin, watchlisted),
            );
          },
        );
      },
    );
  }

  Future<void> _toggleSelection(Coin coin, bool watchlisted) async {
    if (!watchlisted) {
      setState(() {
        if (!_selectedIds.add(coin.id)) _selectedIds.remove(coin.id);
      });
      return;
    }

    try {
      await ref.read(watchlistControllerProvider.notifier).toggle(coin);
      if (mounted) setState(() => _selectedIds.remove(coin.id));
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(error.toString())));
      }
    }
  }

  Future<void> _addSelected(
    List<Coin> available,
    Set<String> watchlistIds,
  ) async {
    final selected = available
        .where(
          (coin) =>
              _selectedIds.contains(coin.id) && !watchlistIds.contains(coin.id),
        )
        .toList(growable: false);
    if (selected.isEmpty) return;

    setState(() => _saving = true);
    String? firstError;
    for (final coin in selected) {
      try {
        await ref.read(watchlistControllerProvider.notifier).toggle(coin);
        _selectedIds.remove(coin.id);
      } catch (error) {
        firstError ??= error.toString();
      }
    }
    if (!mounted) return;
    setState(() => _saving = false);

    if (firstError == null) {
      Navigator.of(context).pop();
      return;
    }
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(firstError)));
  }
}

class _SelectableCoinRow extends StatelessWidget {
  const _SelectableCoinRow({
    required this.coin,
    required this.selected,
    required this.enabled,
    required this.onTap,
  });

  final Coin coin;
  final bool selected;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    checked: selected,
    child: InkWell(
      onTap: enabled ? onTap : null,
      child: SizedBox(
        height: 72,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: AppSizes.screenPadding.w),
          child: Row(
            children: [
              CoinAvatar(
                symbol: coin.symbol,
                imageUrl: coin.image,
                enableHero: false,
              ),
              SizedBox(width: AppSizes.md.w),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      coin.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyMedium
                          ?.copyWith(fontWeight: FontWeight.w600),
                    ),
                    SizedBox(height: AppSizes.xs.w),
                    ChangePill(
                      change: coin.change24hPct,
                      showBackground: false,
                    ),
                  ],
                ),
              ),
              Icon(
                selected
                    ? Icons.radio_button_checked_rounded
                    : Icons.radio_button_unchecked_rounded,
                size: 20,
                color: selected
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
