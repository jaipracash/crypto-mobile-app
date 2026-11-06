import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

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
    final points = [...chart.prices]
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
    if (points.length < 2) {
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

    final positive = (chart.changePct ?? 0) >= 0;
    final color = positive ? AppColors.lightGain : AppColors.lightLoss;
    final textColor = Theme.of(context).colorScheme.onSurfaceVariant;
    final spots = points.indexed
        .map((entry) => FlSpot(entry.$1.toDouble(), entry.$2.price))
        .toList(growable: false);
    final minPrice = spots
        .map((spot) => spot.y)
        .reduce((a, b) => a < b ? a : b);
    final maxPrice = spots
        .map((spot) => spot.y)
        .reduce((a, b) => a > b ? a : b);
    final priceRange = maxPrice - minPrice;
    final padding = priceRange > 0 ? priceRange * 0.1 : maxPrice.abs() * 0.02;
    final safePadding = padding > 0 ? padding : 0.000000001;
    final minY = minPrice - safePadding;
    final maxY = maxPrice + safePadding;
    final yInterval = (maxY - minY) / 4;
    final xInterval = ((spots.length - 1) / 3).clamp(1.0, double.infinity);

    return SizedBox(
      height: AppSizes.chartHeight + 34,
      child: LineChart(
        LineChartData(
          minY: minY,
          maxY: maxY,
          minX: 0,
          maxX: (spots.length - 1).toDouble(),
          clipData: const FlClipData.all(),
          gridData: FlGridData(
            drawVerticalLine: false,
            horizontalInterval: yInterval,
            getDrawingHorizontalLine: (_) =>
                FlLine(color: const Color(0xFFE9EDF2), strokeWidth: 0.8),
          ),
          titlesData: FlTitlesData(
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: yInterval,
                reservedSize: 56,
                getTitlesWidget: (value, _) => Padding(
                  padding: const EdgeInsets.only(right: AppSizes.xs),
                  child: Text(
                    Formatters.compact(value, currencyCode: currency),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.labelSmall
                        ?.copyWith(color: textColor, fontSize: 10),
                  ),
                ),
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: xInterval,
                reservedSize: 26,
                getTitlesWidget: (value, _) {
                  final index = value.round().clamp(0, points.length - 1);
                  final pattern = chart.days <= 1 ? 'HH:mm' : 'MMM d';
                  return Padding(
                    padding: const EdgeInsets.only(top: AppSizes.xs),
                    child: Text(
                      DateFormat(pattern)
                          .format(points[index].timestamp.toLocal()),
                      maxLines: 1,
                      style: Theme.of(context).textTheme.labelSmall
                          ?.copyWith(color: textColor, fontSize: 10),
                    ),
                  );
                },
              ),
            ),
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
                final index = spot.spotIndex.clamp(0, points.length - 1);
                onTouch(points[index]);
              } else if (event is FlTapUpEvent || event is FlPanEndEvent) {
                onTouch(null);
              }
            },
            touchTooltipData: LineTouchTooltipData(
              getTooltipColor: (_) => Colors.white,
              tooltipBorder: BorderSide(color: const Color(0xFFE3E7EC)),
              getTooltipItems: (touchedSpots) => touchedSpots.map((spot) {
                final point = points[spot.spotIndex];
                return LineTooltipItem(
                  '${Formatters.currency(point.price, currency)}\n${Formatters.dateTime(point.timestamp)}',
                  Theme.of(context).textTheme.labelSmall!
                      .copyWith(color: AppColors.lightTextPrimary),
                );
              }).toList(),
            ),
            getTouchedSpotIndicator: (_, indexes) => indexes.map((_) {
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
                    strokeColor: Colors.white,
                  ),
                ),
              );
            }).toList(),
          ),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: false,
              color: color,
              barWidth: 2.4,
              isStrokeCapRound: true,
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    color.withValues(alpha: 0.2),
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
