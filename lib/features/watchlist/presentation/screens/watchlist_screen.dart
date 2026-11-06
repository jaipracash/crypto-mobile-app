import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/router/routes.dart';
import '../../../../shared/widgets/async_value_view.dart';
import '../../../../shared/widgets/coin_tile.dart';
import '../../../../shared/widgets/data_source_banner.dart';
import '../../../market/domain/coin.dart';
import '../../../settings/presentation/controllers/settings_controller.dart';
import '../controllers/watchlist_controller.dart';

class WatchlistScreen extends ConsumerWidget {
  const WatchlistScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final coins = ref.watch(watchlistControllerProvider);
    final currency =
        ref.watch(settingsControllerProvider).asData?.value.currency ?? 'usd';
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.watchlist),
        actions: [
          TextButton(
            onPressed: () =>
                ref.read(watchlistControllerProvider.notifier).refresh(),
            child: Text('${coins.asData?.value.items.length ?? 0}'),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () =>
            ref.read(watchlistControllerProvider.notifier).refresh(),
        child: AsyncValueView(
          value: coins,
          onRetry: () => ref.invalidate(watchlistControllerProvider),
          builder: (data) {
            final items = data.items;
            if (items.isEmpty) {
              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  DataSourceBanner(source: data.dataSource),
                  SizedBox(
                    height:
                        MediaQuery.sizeOf(context).height *
                        AppSizes.emptyStateHeightFraction,
                    child: Padding(
                      padding: const EdgeInsets.all(AppSizes.xl),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SvgPicture.asset(
                            'assets/not_added.svg',
                            width: 156,
                            height: 156,
                          ),
                          const SizedBox(height: AppSizes.lg),
                          Text(
                            AppStrings.emptyWatchlist,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: AppSizes.xs),
                          Text(
                            AppStrings.saveCoinsMessage,
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          const SizedBox(height: AppSizes.lg),
                          FilledButton(
                            onPressed: () =>
                                context.push(Routes.addWatchlistCoins),
                            child: const Text(AppStrings.addCoins),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            }
            return ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(
                horizontal: AppSizes.screenPadding,
              ),
              children: [
                DataSourceBanner(source: data.dataSource),
                ...items.map(
                  (coin) => Dismissible(
                    key: ValueKey(coin.id),
                    direction: DismissDirection.endToStart,
                    background: Container(
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.only(right: AppSizes.xl),
                      color: Theme.of(context).colorScheme.error,
                      child: Icon(
                        Icons.delete_outline,
                        color: Theme.of(context).colorScheme.onError,
                      ),
                    ),
                    onDismissed: (_) => _remove(context, ref, coin),
                    child: CoinTile(
                      coin: coin.copyWith(isWatchlisted: true),
                      currency: currency,
                      onTap: () => context.push('/coin/${coin.id}'),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Future<void> _remove(BuildContext context, WidgetRef ref, Coin coin) async {
    try {
      await ref.read(watchlistControllerProvider.notifier).toggle(coin);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppStrings.removedFromWatchlist(coin.name)),
          action: SnackBarAction(
            label: AppStrings.undo,
            onPressed: () =>
                ref.read(watchlistControllerProvider.notifier).toggle(coin),
          ),
        ),
      );
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(error.toString())));
      }
    }
  }
}
