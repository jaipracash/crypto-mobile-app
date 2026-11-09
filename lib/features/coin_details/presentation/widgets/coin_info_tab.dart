import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../features/market/domain/coin.dart';
import '../../domain/coin_details.dart';
import 'historical_data_card.dart';
import 'stats_grid.dart';

class CoinInfoTab extends StatelessWidget {
  const CoinInfoTab({
    required this.details,
    required this.coin,
    required this.currency,
    super.key,
  });

  final CoinDetails details;
  final Coin coin;
  final String currency;

  @override
  Widget build(BuildContext context) => ListView(
    physics: const BouncingScrollPhysics(
      parent: AlwaysScrollableScrollPhysics(),
    ),
    dragStartBehavior: DragStartBehavior.down,
    padding: EdgeInsets.fromLTRB(
      AppSizes.screenPadding.w,
      AppSizes.lg.w,
      AppSizes.screenPadding.w,
      AppSizes.xxl.w,
    ),
    children: [
      Text(
        AppStrings.info,
        style: Theme.of(context).textTheme.titleMedium
            ?.copyWith(fontWeight: FontWeight.w700),
      ),
      SizedBox(height: AppSizes.md.w),
      StatsGrid(details: details, currency: currency),
      SizedBox(height: AppSizes.xl.w),
      HistoricalDataCard(details: details, currency: currency),
      SizedBox(height: AppSizes.xl.w),
      Text(
        '${AppStrings.aboutCoin} ${coin.name}',
        style: Theme.of(context).textTheme.titleMedium
            ?.copyWith(fontWeight: FontWeight.w700),
      ),
      SizedBox(height: AppSizes.sm.w),
      Text(
        details.description.isEmpty
            ? AppStrings.descriptionUnavailable
            : details.description,
        style: Theme.of(context).textTheme.bodyMedium,
      ),
    ],
  );
}
