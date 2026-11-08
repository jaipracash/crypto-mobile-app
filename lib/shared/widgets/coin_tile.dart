import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../core/constants/app_sizes.dart';
import '../../core/utils/formatters.dart';
import '../../features/market/domain/coin.dart';
import 'change_pill.dart';
import 'coin_avatar.dart';
import 'sparkline.dart';

class CoinTile extends StatelessWidget {
  const CoinTile({
    required this.coin,
    required this.currency,
    required this.onTap,
    super.key,
  });
  final Coin coin;
  final String currency;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSizes.radiusMd.r),
      child: SizedBox(
        height: AppSizes.coinTileHeight.h,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: AppSizes.sm.w),
          child: Row(
            children: [
              SizedBox(
                width: AppSizes.rankColumn.w,
                child: Text(
                  coin.rank?.toString() ?? '—',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodySmall,
                ),
              ),
              SizedBox(width: AppSizes.sm.w),
              CoinAvatar(symbol: coin.symbol, imageUrl: coin.image),
              SizedBox(width: AppSizes.md.w),
              Expanded(
                flex: 5,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      coin.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      coin.symbol.toUpperCase(),
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              Expanded(
                flex: 4,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      Formatters.currency(coin.price, currency),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: AppSizes.xs.w),
                    ChangePill(change: coin.change24hPct, compact: true),
                  ],
                ),
              ),
              SizedBox(width: AppSizes.sm.w),
              Sparkline(
                values: coin.sparkline7d,
                positive: (coin.change24hPct ?? 0) >= 0,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
