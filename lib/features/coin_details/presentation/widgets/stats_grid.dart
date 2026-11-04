import 'package:flutter/material.dart';

import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../domain/coin_details.dart';

class StatsGrid extends StatelessWidget {
  const StatsGrid({required this.details, required this.currency, super.key});
  final CoinDetails details;
  final String currency;
  @override
  Widget build(BuildContext context) {
    final coin = details.coin;
    final items = [
      (
        AppStrings.marketCap,
        Formatters.compact(coin.marketCap, currencyCode: currency),
      ),
      (
        AppStrings.volume24h,
        Formatters.compact(coin.volume24h, currencyCode: currency),
      ),
      (AppStrings.circulatingSupply, Formatters.supply(coin.circulatingSupply)),
      (AppStrings.totalSupply, Formatters.supply(coin.totalSupply)),
      (AppStrings.maxSupply, Formatters.supply(coin.maxSupply)),
      (AppStrings.high24h, Formatters.currency(details.high24h, currency)),
      (AppStrings.low24h, Formatters.currency(details.low24h, currency)),
      (AppStrings.allTimeHigh, Formatters.currency(details.ath, currency)),
      (AppStrings.allTimeLow, Formatters.currency(details.atl, currency)),
    ];
    return Column(
      children: [
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: items.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: AppSizes.sm,
            crossAxisSpacing: AppSizes.sm,
            childAspectRatio: 1.8,
          ),
          itemBuilder: (context, index) => AppCard(
            padding: const EdgeInsets.all(AppSizes.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  items[index].$1,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: AppSizes.xs),
                Text(
                  items[index].$2,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                if (index == 7 && details.athDate != null)
                  Text(
                    Formatters.date(details.athDate),
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                if (index == 7 && details.athChangePct != null)
                  Text(
                    Formatters.percent(details.athChangePct),
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                if (index == 8 && details.atlDate != null)
                  Text(
                    Formatters.date(details.atlDate),
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
              ],
            ),
          ),
        ),
        if (coin.maxSupply != null && coin.maxSupply! > 0) ...[
          const SizedBox(height: AppSizes.md),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppStrings.circulatingSupply,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: AppSizes.md),
                LinearProgressIndicator(
                  value: ((coin.circulatingSupply ?? 0) / coin.maxSupply!)
                      .clamp(0, 1),
                  borderRadius: BorderRadius.circular(AppSizes.radiusPill),
                ),
                const SizedBox(height: AppSizes.sm),
                Text(
                  '${Formatters.supply(coin.circulatingSupply)} of ${Formatters.supply(coin.maxSupply)}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
