import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

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

class _MarketTableMetrics {
  _MarketTableMetrics(double width) : compact = width < 360;

  final bool compact;

  double get rowHeight =>
      compact ? AppSizes.coinRowHeight.h * 0.9 : AppSizes.coinRowHeight.h;
  double get headerHeight => compact
      ? AppSizes.homeColumnHeaderHeight.h * 0.9
      : AppSizes.homeColumnHeaderHeight.h;
  double get rankWidth =>
      compact ? AppSizes.rankColumn.w * 0.8 : AppSizes.rankColumn.w;
  double get rankGap => compact ? AppSizes.xs.w : AppSizes.sm.w;
  double get avatarSize =>
      compact ? AppSizes.coinLogo.w * 0.84 : AppSizes.coinLogo.w;
  double get avatarGap => compact ? AppSizes.sm.w : AppSizes.md.w;
  double get columnGap => AppSizes.xs.w;
  double get priceGap => compact ? AppSizes.xs.w : AppSizes.sm.w;
  double get priceInset => compact ? AppSizes.xs.w : AppSizes.sm.w;
  int get nameFlex => 4;
  int get priceFlex => compact ? 5 : 4;
  int get chartFlex => 3;
  double get sparklineWidth => compact ? 42.w : 62;
  double get sparklineHeight => compact ? 18.h : 24;
  double get loadingPriceWidth => compact
      ? AppSizes.loadingPriceWidth.w * 0.75
      : AppSizes.loadingPriceWidth.w;
  double get loadingChangeWidth => compact
      ? AppSizes.loadingChangeWidth.w * 0.8
      : AppSizes.loadingChangeWidth.w;
  double get headerFontSize => compact
      ? AppSizes.homeColumnTitleFontSize.sp * 0.88
      : AppSizes.homeColumnTitleFontSize.sp;
}

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
    return LayoutBuilder(
      builder: (context, constraints) {
        final metrics = _MarketTableMetrics(constraints.maxWidth);
        return InkWell(
          onTap: widget.onTap,
          child: SizedBox(
            height: metrics.rowHeight,
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: AppSizes.screenPadding.w,
              ),
              child: Row(
                children: [
                  SizedBox(
                    width: metrics.rankWidth,
                    child: Text(
                      widget.coin.rank?.toString() ?? AppStrings.notAvailable,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontSize: metrics.compact ? 11 : 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  SizedBox(width: metrics.rankGap),
                  CoinAvatar(
                    symbol: widget.coin.symbol,
                    imageUrl: widget.coin.image,
                    size: metrics.avatarSize,
                    enableHero: false,
                  ),
                  SizedBox(width: metrics.avatarGap),
                  Expanded(
                    flex: metrics.nameFlex,
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
                        SizedBox(height: AppSizes.xs.w),
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
                  SizedBox(width: metrics.columnGap),
                  Expanded(
                    flex: metrics.priceFlex,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Padding(
                          padding: EdgeInsets.only(right: metrics.priceInset),
                          child: AnimatedDefaultTextStyle(
                            duration: const Duration(milliseconds: 180),
                            style: theme.textTheme.bodyMedium!.copyWith(
                              color: flashColor,
                              fontSize: metrics.compact ? 12 : null,
                              fontWeight: FontWeight.w600,
                              fontFeatures: const [
                                FontFeature.tabularFigures(),
                              ],
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
                  SizedBox(width: metrics.priceGap),
                  Expanded(
                    flex: metrics.chartFlex,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Sparkline(
                          values: widget.coin.sparkline7d,
                          positive:
                              (widget.period.value(widget.coin) ?? 0) >= 0,
                          width: metrics.sparklineWidth,
                          height: metrics.sparklineHeight,
                          filled: true,
                        ),
                        SizedBox(height: AppSizes.xs.w),
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
      },
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
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final metrics = _MarketTableMetrics(constraints.maxWidth);
      return SizedBox(
        height: metrics.headerHeight,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: AppSizes.screenPadding.w),
          child: Row(
            children: [
              SizedBox(
                width: metrics.rankWidth,
                child: Text(
                  '#',
                  textAlign: TextAlign.center,
                  style: _style(context, metrics),
                ),
              ),
              SizedBox(width: metrics.rankGap),
              SizedBox(width: metrics.avatarSize),
              SizedBox(width: metrics.avatarGap),
              Expanded(
                flex: metrics.nameFlex,
                child: Text(AppStrings.coin, style: _style(context, metrics)),
              ),
              SizedBox(width: metrics.columnGap),
              Expanded(
                flex: metrics.priceFlex,
                child: Padding(
                  padding: EdgeInsets.only(right: metrics.priceInset),
                  child: Text(
                    AppStrings.price,
                    textAlign: TextAlign.right,
                    style: _style(context, metrics),
                  ),
                ),
              ),
              SizedBox(width: metrics.priceGap),
              Expanded(
                flex: metrics.chartFlex,
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
                                style: _style(context, metrics),
                              ),
                            ),
                            Icon(Icons.expand_more, size: AppSizes.iconSmall.w),
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
    },
  );

  TextStyle? _style(BuildContext context, _MarketTableMetrics metrics) =>
      Theme.of(context).textTheme.labelMedium?.copyWith(
        color: Theme.of(context).colorScheme.onSurface,
        fontSize: metrics.headerFontSize,
        fontWeight: FontWeight.w600,
      );
}

class CoinRowSkeleton extends StatelessWidget {
  const CoinRowSkeleton({super.key});

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final metrics = _MarketTableMetrics(constraints.maxWidth);
      return SizedBox(
        height: metrics.rowHeight,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: AppSizes.screenPadding.w),
          child: Row(
            children: [
              ShimmerBox(
                width: metrics.avatarSize,
                height: metrics.avatarSize,
                radius: AppSizes.radiusPill.r,
              ),
              SizedBox(width: metrics.avatarGap),
              Expanded(
                flex: metrics.nameFlex,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ShimmerBox(height: AppSizes.loadingBoxHeight.h / 2),
                    SizedBox(height: AppSizes.xs.w),
                    ShimmerBox(height: AppSizes.loadingBoxHeight.h / 3),
                  ],
                ),
              ),
              SizedBox(width: metrics.columnGap),
              Expanded(
                flex: metrics.priceFlex,
                child: Align(
                  alignment: Alignment.centerRight,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      ShimmerBox(
                        width: metrics.loadingPriceWidth,
                        height: AppSizes.loadingBoxHeight.h / 2,
                      ),
                      SizedBox(height: AppSizes.xs.w),
                      ShimmerBox(
                        width: metrics.loadingChangeWidth,
                        height: AppSizes.chipHeight.h / 2,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}
