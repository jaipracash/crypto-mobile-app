import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../shared/widgets/async_value_view.dart';
import '../../../../shared/widgets/change_pill.dart';
import '../../../../shared/widgets/coin_avatar.dart';
import '../../../../shared/widgets/data_source_banner.dart';
import '../../../market/domain/coin.dart';
import '../../../settings/presentation/controllers/settings_controller.dart';
import '../../../watchlist/presentation/controllers/watchlist_controller.dart';
import '../../domain/coin_details.dart';
import '../controllers/coin_details_controller.dart';
import '../widgets/price_chart.dart';
import '../widgets/stats_grid.dart';

class CoinDetailsScreen extends ConsumerStatefulWidget {
  const CoinDetailsScreen({required this.coinId, super.key});
  final String coinId;
  @override
  ConsumerState<CoinDetailsScreen> createState() => _CoinDetailsScreenState();
}

class _CoinDetailsScreenState extends ConsumerState<CoinDetailsScreen> {
  PricePoint? _hoveredPoint;
  int _days = 7;
  bool _aboutExpanded = false;

  @override
  Widget build(BuildContext context) {
    final details = ref.watch(coinDetailsControllerProvider(widget.coinId));
    final chart = ref.watch(chartControllerProvider(widget.coinId));
    final currency =
        ref.watch(settingsControllerProvider).asData?.value.currency ?? 'usd';
    final detailsData = details.asData?.value;
    final watched =
        ref
            .watch(watchlistControllerProvider)
            .asData
            ?.value
            .items
            .any((coin) => coin.id == widget.coinId) ??
        false;
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.coinDetails),
        actions: [
          IconButton(
            tooltip: watched
                ? AppStrings.removeFromWatchlist
                : AppStrings.addToWatchlist,
            onPressed: detailsData == null
                ? null
                : () => _toggle(detailsData.coin),
            icon: Icon(
              watched ? Icons.star_rounded : Icons.star_border_rounded,
            ),
            color: watched ? AppColors.watchlistStar : null,
          ),
        ],
      ),
      body: AsyncValueView(
        value: details,
        onRetry: () =>
            ref.invalidate(coinDetailsControllerProvider(widget.coinId)),
        builder: (data) => _buildDetails(context, data, chart, currency),
      ),
    );
  }

  Widget _buildDetails(
    BuildContext context,
    CoinDetails data,
    AsyncValue<CoinChart> chart,
    String currency,
  ) {
    final chartData = chart.asData?.value;
    final coin = data.coin.copyWith(
      isWatchlisted:
          ref
              .watch(watchlistControllerProvider)
              .asData
              ?.value
              .items
              .any((item) => item.id == data.coin.id) ??
          data.coin.isWatchlisted,
    );
    final displayedPrice = _hoveredPoint?.price ?? coin.price;
    final displayedDate = _hoveredPoint?.timestamp;
    final gain = (coin.change24hPct ?? 0) >= 0;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final color = gain
        ? (dark ? AppColors.darkGain : AppColors.lightGain)
        : (dark ? AppColors.darkLoss : AppColors.lightLoss);
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSizes.screenPadding,
        AppSizes.sm,
        AppSizes.screenPadding,
        AppSizes.xxl,
      ),
      children: [
        Row(
          children: [
            CoinAvatar(
              symbol: coin.symbol,
              imageUrl: coin.image,
              size: AppSizes.detailCoinLogo,
            ),
            const SizedBox(width: AppSizes.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    coin.name,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  Text(
                    coin.symbol.toUpperCase(),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            if (coin.rank != null)
              Chip(
                label: Text('#${coin.rank}'),
                visualDensity: VisualDensity.compact,
              ),
          ],
        ),
        const SizedBox(height: AppSizes.xl),
        Text(
          Formatters.currency(displayedPrice, currency),
          style: Theme.of(context).textTheme.displayLarge,
        ),
        if (displayedDate != null) ...[
          const SizedBox(height: AppSizes.xs),
          Text(
            Formatters.dateTime(displayedDate),
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ] else ...[
          const SizedBox(height: AppSizes.sm),
          Row(
            children: [
              Icon(
                gain
                    ? Icons.arrow_upward_rounded
                    : Icons.arrow_downward_rounded,
                size: 18,
                color: color,
              ),
              ChangePill(change: coin.change24hPct),
              const SizedBox(width: AppSizes.sm),
              Text(
                AppStrings.period24h,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ],
        const SizedBox(height: AppSizes.md),
        _timeframes(context, ref),
        const SizedBox(height: AppSizes.sm),
        DataSourceBanner(
          source: chartData != null && chartData.dataSource != 'live'
              ? chartData.dataSource
              : data.dataSource,
        ),
        AsyncValueView(
          value: chart,
          onRetry: () => ref.invalidate(chartControllerProvider(widget.coinId)),
          isEmpty: (value) => value.prices.isEmpty,
          emptyTitle: AppStrings.noChartData,
          builder: (value) => PriceChart(
            chart: value,
            currency: currency,
            onTouch: (point) => setState(() => _hoveredPoint = point),
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _ChartMarker(
              label: AppStrings.low,
              value: Formatters.currency(chartData?.min, currency),
            ),
            _ChartMarker(
              label: AppStrings.change,
              value: Formatters.percent(chartData?.changePct),
            ),
            _ChartMarker(
              label: AppStrings.high,
              value: Formatters.currency(chartData?.max, currency),
            ),
          ],
        ),
        const SizedBox(height: AppSizes.xl),
        Text(
          AppStrings.marketStatistics,
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: AppSizes.md),
        StatsGrid(details: data, currency: currency),
        const SizedBox(height: AppSizes.xl),
        Text(
          '${AppStrings.about} ${coin.name}',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: AppSizes.sm),
        Text(
          data.description.isEmpty
              ? AppStrings.descriptionUnavailable
              : data.description,
          maxLines: _aboutExpanded ? null : 4,
          overflow: _aboutExpanded
              ? TextOverflow.visible
              : TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        if (data.description.length > 180)
          TextButton(
            onPressed: () => setState(() => _aboutExpanded = !_aboutExpanded),
            child: Text(
              _aboutExpanded ? AppStrings.showLess : AppStrings.readMore,
            ),
          ),
        if (data.website != null || data.whitepaper != null) ...[
          const SizedBox(height: AppSizes.md),
          Wrap(
            spacing: AppSizes.sm,
            children: [
              if (data.website != null)
                _LinkButton(label: AppStrings.website, url: data.website!),
              if (data.whitepaper != null)
                _LinkButton(
                  label: AppStrings.whitepaper,
                  url: data.whitepaper!,
                ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _timeframes(BuildContext context, WidgetRef ref) {
    const timeframes = [
      (1, '24H'),
      (7, '7D'),
      (30, '30D'),
      (90, '90D'),
      (365, '1Y'),
    ];
    return SizedBox(
      height: AppSizes.chipHeight + 4,
      child: Row(
        children: timeframes
            .map(
              (entry) => Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(right: AppSizes.xs),
                  child: ChoiceChip(
                    label: Center(child: Text(entry.$2)),
                    selected: _days == entry.$1,
                    onSelected: (_) {
                      setState(() {
                        _days = entry.$1;
                        _hoveredPoint = null;
                      });
                      ref
                          .read(chartControllerProvider(widget.coinId).notifier)
                          .setDays(entry.$1);
                    },
                  ),
                ),
              ),
            )
            .toList(),
      ),
    );
  }

  Future<void> _toggle(Coin coin) async {
    try {
      await ref.read(watchlistControllerProvider.notifier).toggle(coin);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(error.toString())));
      }
    }
  }
}

class _ChartMarker extends StatelessWidget {
  const _ChartMarker({required this.label, required this.value});
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: Theme.of(context).textTheme.bodySmall),
      Text(value, style: Theme.of(context).textTheme.bodyMedium),
    ],
  );
}

class _LinkButton extends StatelessWidget {
  const _LinkButton({required this.label, required this.url});
  final String label;
  final String url;
  @override
  Widget build(BuildContext context) => OutlinedButton.icon(
    onPressed: () async {
      final uri = Uri.tryParse(url);
      if (uri != null && await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    },
    icon: const Icon(Icons.open_in_new, size: 16),
    label: Text(label),
  );
}
