import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../shared/widgets/change_pill.dart';
import '../../../../shared/widgets/coin_avatar.dart';
import '../../../../shared/widgets/sparkline.dart';
import '../../../../shared/widgets/shimmer_box.dart';
import '../../domain/coin.dart';
import '../controllers/market_controller.dart';

class CoinRow extends StatefulWidget {
  const CoinRow({
    required this.coin,
    required this.currency,
    required this.period,
    required this.onTap,
    super.key,
  });

  final Coin coin;
  final String currency;
  final ChangePeriod period;
  final VoidCallback onTap;

  @override
  State<CoinRow> createState() => _CoinRowState();
}

class _CoinRowState extends State<CoinRow> {
  Timer? _flashTimer;
  bool? _priceRose;

  @override
  void didUpdateWidget(covariant CoinRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.coin.price != widget.coin.price &&
        oldWidget.coin.price != null &&
        widget.coin.price != null) {
      _flashTimer?.cancel();
      _priceRose = widget.coin.price! >= oldWidget.coin.price!;
      _flashTimer = Timer(const Duration(milliseconds: 850), () {
        if (mounted) setState(() => _priceRose = null);
      });
    }
  }

  @override
  void dispose() {
    _flashTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dark = theme.brightness == Brightness.dark;
    final flashColor = _priceRose == null
        ? theme.colorScheme.onSurfaceVariant
        : _priceRose!
        ? (dark ? AppColors.darkGain : AppColors.lightGain)
        : (dark ? AppColors.darkLoss : AppColors.lightLoss);
    return InkWell(
      onTap: widget.onTap,
      child: SizedBox(
        height: AppSizes.coinRowHeight,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSizes.screenPadding,
          ),
          child: Row(
            children: [
              SizedBox(
                width: AppSizes.rankColumn,
                child: Text(
                  widget.coin.rank?.toString() ?? AppStrings.notAvailable,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: AppSizes.sm),
              CoinAvatar(
                symbol: widget.coin.symbol,
                imageUrl: widget.coin.image,
              ),
              const SizedBox(width: AppSizes.md),
              Expanded(
                flex: 4,
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.coin.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.w600,
                              height: 1.0,
                            ),
                          ),
                          const SizedBox(height: AppSizes.xs),
                          Text(
                            '${widget.coin.symbol.toUpperCase()} · ${Formatters.compact(widget.coin.marketCap, currencyCode: widget.currency)}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodySmall?.copyWith(
                              height: 1.0,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSizes.xs),
              Expanded(
                flex: 4,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(right: AppSizes.sm),
                      child: AnimatedDefaultTextStyle(
                        duration: const Duration(milliseconds: 180),
                        style: theme.textTheme.bodyMedium!.copyWith(
                          color: flashColor,
                          fontWeight: FontWeight.w600,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                        child: Text(
                          Formatters.currency(
                            widget.coin.price,
                            widget.currency,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.right,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSizes.sm),
              Expanded(
                flex: 3,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Sparkline(
                      values: widget.coin.sparkline7d,
                      positive: (widget.period.value(widget.coin) ?? 0) >= 0,
                      width: 62,
                      height: 24,
                      filled: true,
                    ),
                    const SizedBox(height: AppSizes.xs),
                    ChangePill(
                      change: widget.period.value(widget.coin),
                      compact: true,
                      showBackground: false,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class CoinTableHeader extends StatelessWidget {
  const CoinTableHeader({
    required this.period,
    required this.onPeriodTap,
    super.key,
  });

  final ChangePeriod period;
  final VoidCallback onPeriodTap;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: AppSizes.homeColumnHeaderHeight,
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSizes.screenPadding),
      child: Row(
        children: [
          SizedBox(
            width: AppSizes.rankColumn,
            child: Text(
              '#',
              textAlign: TextAlign.center,
              style: _style(context),
            ),
          ),
          const SizedBox(width: AppSizes.sm),
          const SizedBox(width: AppSizes.coinLogo),
          const SizedBox(width: AppSizes.md),
          Expanded(
            flex: 4,
            child: Text(AppStrings.coin, style: _style(context)),
          ),
          const SizedBox(width: AppSizes.xs),
          Expanded(
            flex: 4,
            child: Padding(
              padding: const EdgeInsets.only(right: AppSizes.sm),
              child: Text(
                AppStrings.price,
                textAlign: TextAlign.right,
                style: _style(context),
              ),
            ),
          ),
          const SizedBox(width: AppSizes.sm),
          Expanded(
            flex: 3,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Expanded(
                  child: InkWell(
                    onTap: onPeriodTap,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Flexible(
                          child: Text(
                            '${period.label} %',
                            style: _style(context),
                          ),
                        ),
                        const Icon(Icons.expand_more, size: AppSizes.iconSmall),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );

  TextStyle? _style(BuildContext context) => Theme.of(context)
      .textTheme
      .labelMedium
      ?.copyWith(
        fontSize: AppSizes.homeColumnTitleFontSize,
        fontWeight: FontWeight.w600,
      );
}

class CoinRowSkeleton extends StatelessWidget {
  const CoinRowSkeleton({super.key});

  @override
  Widget build(BuildContext context) => SizedBox(
    height: AppSizes.coinRowHeight,
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSizes.screenPadding),
      child: Row(
        children: [
          const SizedBox(
            width: AppSizes.rankColumn,
            child: ShimmerBox(
              width: AppSizes.rankColumn,
              height: AppSizes.loadingBoxHeight,
            ),
          ),
          const SizedBox(width: AppSizes.sm),
          const ShimmerBox(
            width: AppSizes.coinLogo,
            height: AppSizes.coinLogo,
            radius: AppSizes.radiusPill,
          ),
          const SizedBox(width: AppSizes.md),
          const Expanded(
            flex: 5,
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ShimmerBox(height: AppSizes.loadingBoxHeight / 2),
                      SizedBox(height: AppSizes.xs),
                      ShimmerBox(height: AppSizes.loadingBoxHeight / 3),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Expanded(
            flex: 4,
            child: Align(
              alignment: Alignment.centerRight,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  ShimmerBox(
                    width: AppSizes.loadingPriceWidth,
                    height: AppSizes.loadingBoxHeight / 2,
                  ),
                  SizedBox(height: AppSizes.xs),
                  ShimmerBox(
                    width: AppSizes.loadingChangeWidth,
                    height: AppSizes.chipHeight / 2,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    ),
  );
}
