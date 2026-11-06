import 'package:flutter/material.dart';

import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/utils/formatters.dart';
import '../../domain/coin_details.dart';

class StatsGrid extends StatelessWidget {
  const StatsGrid({required this.details, required this.currency, super.key});

  final CoinDetails details;
  final String currency;

  @override
  Widget build(BuildContext context) {
    final coin = details.coin;
    final fullyDilutedValuation = coin.price != null && coin.maxSupply != null
        ? coin.price! * coin.maxSupply!
        : null;
    final ratio =
        coin.marketCap != null &&
            fullyDilutedValuation != null &&
            fullyDilutedValuation > 0
        ? (coin.marketCap! / fullyDilutedValuation).toStringAsFixed(2)
        : AppStrings.notAvailable;
    final items = [
      (
        AppStrings.marketCap,
        Formatters.compact(coin.marketCap, currencyCode: currency),
      ),
      (AppStrings.circulatingSupply, Formatters.supply(coin.circulatingSupply)),
      (
        AppStrings.fullyDilutedValuation,
        Formatters.compact(fullyDilutedValuation, currencyCode: currency),
      ),
      (AppStrings.totalSupply, Formatters.supply(coin.totalSupply)),
      (AppStrings.marketCapFdvRatio, ratio),
      (AppStrings.maxSupply, Formatters.supply(coin.maxSupply)),
      (
        AppStrings.volume24h,
        Formatters.compact(coin.volume24h, currencyCode: currency),
      ),
      (
        AppStrings.range24h,
        '${Formatters.currency(details.low24h, currency)} - ${Formatters.currency(details.high24h, currency)}',
      ),
    ];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Theme.of(context).dividerColor),
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
      ),
      padding: const EdgeInsets.all(AppSizes.lg),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: items.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: AppSizes.lg,
          crossAxisSpacing: AppSizes.md,
          childAspectRatio: 1.8,
        ),
        itemBuilder: (context, index) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              items[index].$1,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: AppSizes.xs),
            Text(
              items[index].$2,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodyMedium
                  ?.copyWith(fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }
}
