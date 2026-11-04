import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/utils/formatters.dart';
import '../../domain/coin_details.dart';

class PriceChart extends StatelessWidget {
  const PriceChart({
    required this.chart,
    required this.currency,
    required this.onTouch,
    super.key,
  });
  final CoinChart chart;
  final String currency;
  final ValueChanged<PricePoint?> onTouch;

  @override
  Widget build(BuildContext context) {
    if (chart.prices.length < 2) {
      return SizedBox(
        height: AppSizes.chartHeight,
        child: Center(
          child: Text(
            AppStrings.noChartData,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
      );
    }
    final change = chart.changePct ?? 0;
    final positive = change >= 0;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final color = positive
        ? (dark ? AppColors.darkGain : AppColors.lightGain)
        : (dark ? AppColors.darkLoss : AppColors.lightLoss);
    final spots = chart.prices.indexed
        .map((entry) => FlSpot(entry.$1.toDouble(), entry.$2.price))
        .toList(growable: false);
    final minPrice =
        chart.min ??
        spots.map((spot) => spot.y).reduce((a, b) => a < b ? a : b);
    final maxPrice =
        chart.max ??
        spots.map((spot) => spot.y).reduce((a, b) => a > b ? a : b);
    final padding = ((maxPrice - minPrice).abs() * 0.12)
        .clamp(0.000000000001, double.infinity)
        .toDouble();
    return SizedBox(
      height: AppSizes.chartHeight,
      child: LineChart(
        LineChartData(
          minY: minPrice - padding,
          maxY: maxPrice + padding,
          minX: 0,
          maxX: (spots.length - 1).toDouble(),
          gridData: FlGridData(
            drawVerticalLine: false,
            horizontalInterval: ((maxPrice - minPrice) / 4).abs() < 0.000001
                ? 1
                : (maxPrice - minPrice) / 4,
            getDrawingHorizontalLine: (_) => FlLine(
              color: Theme.of(context).dividerColor.withValues(alpha: 0.45),
              strokeWidth: AppSizes.chartGridWidth,
              dashArray: [4, 5],
            ),
          ),
          titlesData: const FlTitlesData(
            leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          borderData: FlBorderData(show: false),
          lineTouchData: LineTouchData(
            handleBuiltInTouches: true,
            touchCallback: (event, response) {
              if (!event.isInterestedForInteractions) {
                onTouch(null);
                return;
              }
              final spot = response?.lineBarSpots?.first;
              if (spot != null) {
                final index = spot.spotIndex.clamp(0, chart.prices.length - 1);
                onTouch(chart.prices[index]);
              } else if (event is FlTapUpEvent || event is FlPanEndEvent) {
                onTouch(null);
              }
            },
            touchTooltipData: LineTouchTooltipData(
              getTooltipColor: (_) => Theme.of(context).colorScheme.surface,
              getTooltipItems: (spots) => spots.map((spot) {
                final point = chart.prices[spot.spotIndex];
                return LineTooltipItem(
                  '${Formatters.currency(point.price, currency)}\n${Formatters.dateTime(point.timestamp)}',
                  Theme.of(context).textTheme.labelSmall!,
                );
              }).toList(),
            ),
            getTouchedSpotIndicator: (barData, indexes) => indexes.map((index) {
              return TouchedSpotIndicatorData(
                FlLine(
                  color: color.withValues(alpha: 0.6),
                  strokeWidth: AppSizes.chartCrosshairWidth,
                  dashArray: [3, 3],
                ),
                FlDotData(
                  getDotPainter: (_, _, _, _) => FlDotCirclePainter(
                    radius: AppSizes.chartTouchDot,
                    color: color,
                    strokeWidth: AppSizes.chartTouchBorder,
                    strokeColor: Theme.of(context).colorScheme.surface,
                  ),
                ),
              );
            }).toList(),
          ),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              curveSmoothness: 0.22,
              color: color,
              barWidth: 2.4,
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    color.withValues(alpha: 0.25),
                    color.withValues(alpha: 0.01),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
