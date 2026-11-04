import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../shared/widgets/async_value_view.dart';
import '../../../../shared/widgets/change_pill.dart';
import '../../../../shared/widgets/coin_avatar.dart';
import '../../../../shared/widgets/coin_tile.dart';
import '../../../../shared/widgets/data_source_banner.dart';
import '../../../settings/presentation/controllers/settings_controller.dart';
import '../../../market/domain/coin.dart';
import '../../../watchlist/presentation/controllers/watchlist_controller.dart';
import '../controllers/stats_controller.dart';

class StatsScreen extends ConsumerWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final snapshot = ref.watch(statsSnapshotProvider);
    final movers = ref.watch(statsMoversProvider);
    final trending = ref.watch(statsTrendingProvider);
    final watchlistedIds =
        ref
            .watch(watchlistControllerProvider)
            .asData
            ?.value
            .items
            .map((coin) => coin.id)
            .toSet() ??
        const <String>{};
    final currency =
        ref.watch(settingsControllerProvider).asData?.value.currency ?? 'usd';
    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.statsHeading)),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(statsSnapshotProvider);
          ref.invalidate(statsMoversProvider);
          ref.invalidate(statsTrendingProvider);
        },
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(AppSizes.screenPadding),
          children: [
            Text(
              AppStrings.globalMarket,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: AppSizes.md),
            AsyncValueView(
              value: snapshot,
              onRetry: () => ref.invalidate(statsSnapshotProvider),
              builder: (data) => Column(
                children: [
                  DataSourceBanner(source: data.dataSource),
                  AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          AppStrings.totalMarketCap,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        const SizedBox(height: AppSizes.xs),
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                Formatters.compact(
                                  data.totalMarketCap,
                                  currencyCode: currency,
                                ),
                                style: Theme.of(context)
                                    .textTheme
                                    .headlineMedium,
                              ),
                            ),
                            ChangePill(change: data.marketCapChange24hPct),
                          ],
                        ),
                        const SizedBox(height: AppSizes.lg),
                        Row(
                          children: [
                            _SummaryMetric(
                              label: AppStrings.volume24h,
                              value: Formatters.compact(
                                data.totalVolume24h,
                                currencyCode: currency,
                              ),
                            ),
                            _SummaryMetric(
                              label: AppStrings.activeCoins,
                              value: Formatters.supply(
                                data.activeCoins?.toDouble(),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSizes.md),
                  AppCard(
                    child: Row(
                      children: [
                        Expanded(
                          child: SizedBox(
                            height: AppSizes.statsChartHeight,
                            child: PieChart(
                              PieChartData(
                                sectionsSpace: AppSizes.donutSectionGap,
                                centerSpaceRadius: AppSizes.donutCenter,
                                sections: [
                                  PieChartSectionData(
                                    value: data.btcDominance ?? 0,
                                    color: AppColors.btc,
                                    radius: AppSizes.donutRadius,
                                    showTitle: false,
                                  ),
                                  PieChartSectionData(
                                    value: data.ethDominance ?? 0,
                                    color: AppColors.eth,
                                    radius: AppSizes.donutRadius,
                                    showTitle: false,
                                  ),
                                  PieChartSectionData(
                                    value: data.othersDominance ?? 0,
                                    color: AppColors.other,
                                    radius: AppSizes.donutRadius,
                                    showTitle: false,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _Legend(
                                color: AppColors.btc,
                                label: AppStrings.btc,
                                value: data.btcDominance,
                              ),
                              _Legend(
                                color: AppColors.eth,
                                label: AppStrings.eth,
                                value: data.ethDominance,
                              ),
                              _Legend(
                                color: AppColors.other,
                                label: AppStrings.others,
                                value: data.othersDominance,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSizes.xl),
            Text(
              AppStrings.topGainers,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: AppSizes.sm),
            AsyncValueView(
              value: movers,
              onRetry: () => ref.invalidate(statsMoversProvider),
              isEmpty: (data) => data.gainers.isEmpty,
              emptyTitle: AppStrings.noGainers,
              builder: (data) => Column(
                children: [
                  DataSourceBanner(source: data.dataSource),
                  ...data.gainers.map(
                    (coin) => CoinTile(
                      coin: coin.copyWith(
                        isWatchlisted: watchlistedIds.contains(coin.id),
                      ),
                      currency: currency,
                      onTap: () => context.push('/coin/${coin.id}'),
                      onToggleWatchlist: () => _toggle(ref, context, coin),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSizes.xl),
            Text(
              AppStrings.topLosers,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: AppSizes.sm),
            AsyncValueView(
              value: movers,
              onRetry: () => ref.invalidate(statsMoversProvider),
              isEmpty: (data) => data.losers.isEmpty,
              emptyTitle: AppStrings.noLosers,
              builder: (data) => Column(
                children: [
                  DataSourceBanner(source: data.dataSource),
                  ...data.losers.map(
                    (coin) => CoinTile(
                      coin: coin.copyWith(
                        isWatchlisted: watchlistedIds.contains(coin.id),
                      ),
                      currency: currency,
                      onTap: () => context.push('/coin/${coin.id}'),
                      onToggleWatchlist: () => _toggle(ref, context, coin),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSizes.xl),
            Text(
              AppStrings.trending,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: AppSizes.sm),
            AsyncValueView(
              value: trending,
              onRetry: () => ref.invalidate(statsTrendingProvider),
              isEmpty: (items) => items.isEmpty,
              emptyTitle: AppStrings.noTrending,
              builder: (items) => Column(
                children: [
                  DataSourceBanner(
                    source: items.isEmpty ? 'live' : items.first.dataSource,
                  ),
                  AppCard(
                    padding: EdgeInsets.zero,
                    child: Column(
                      children: items
                          .map(
                            (coin) => ListTile(
                              leading: CoinAvatar(
                                symbol: coin.symbol,
                                imageUrl: coin.image,
                              ),
                              title: Text(coin.name),
                              subtitle: Text(coin.symbol.toUpperCase()),
                              trailing: Text(
                                coin.rank == null ? '—' : '#${coin.rank}',
                              ),
                              onTap: () => context.push('/coin/${coin.id}'),
                            ),
                          )
                          .toList(),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _toggle(WidgetRef ref, BuildContext context, Coin coin) async {
    try {
      await ref.read(watchlistControllerProvider.notifier).toggle(coin);
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(error.toString())));
      }
    }
  }
}

class _SummaryMetric extends StatelessWidget {
  const _SummaryMetric({required this.label, required this.value});
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) => Expanded(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: AppSizes.xs),
        Text(value, style: Theme.of(context).textTheme.titleMedium),
      ],
    ),
  );
}

class _Legend extends StatelessWidget {
  const _Legend({
    required this.color,
    required this.label,
    required this.value,
  });
  final Color color;
  final String label;
  final double? value;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: AppSizes.xs),
    child: Row(
      children: [
        Container(
          width: AppSizes.legendDot,
          height: AppSizes.legendDot,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: AppSizes.sm),
        Expanded(
          child: Text(label, style: Theme.of(context).textTheme.bodySmall),
        ),
        Text(
          '${(value ?? 0).toStringAsFixed(1)}%',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ],
    ),
  );
}
