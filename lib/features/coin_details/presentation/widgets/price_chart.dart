import 'dart:ui' as ui;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/utils/formatters.dart';
import '../../domain/coin_details.dart';

enum PriceChartSeries { price, marketCap }

enum PriceChartStyle { line, candles }

class PriceChart extends StatelessWidget {
  const PriceChart({
    required this.chart,
    required this.currency,
    required this.onTouch,
    this.series = PriceChartSeries.price,
    this.style = PriceChartStyle.line,
    this.rangeHours,
    super.key,
  });

  final CoinChart chart;
  final String currency;
  final ValueChanged<PricePoint?> onTouch;
  final PriceChartSeries series;
  final PriceChartStyle style;
  final int? rangeHours;

  @override
  Widget build(BuildContext context) {
    if (style == PriceChartStyle.candles) {
      return _buildCandles(context);
    }

    final sourcePoints = series == PriceChartSeries.price
        ? chart.prices
        : chart.marketCaps;
    final points = [...sourcePoints]
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
    if (rangeHours case final hours? when hours < chart.days * 24) {
      if (points.isNotEmpty) {
        final cutoff = points.last.timestamp.subtract(Duration(hours: hours));
        points.removeWhere((point) => point.timestamp.isBefore(cutoff));
      }
    }
    if (points.length < 2) {
      return SizedBox(
        height: AppSizes.chartHeight,
        child: Center(
          child: Text(
            series == PriceChartSeries.marketCap
                ? AppStrings.marketCapChartUnavailable
                : AppStrings.noChartData,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
      );
    }

    final selectedChange = points.first.price == 0
        ? chart.changePct ?? 0
        : (points.last.price - points.first.price) / points.first.price * 100;
    final positive = selectedChange >= 0;
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
            leftTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            rightTitles: AxisTitles(
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
                  '${_formatValue(point.price)}\n${Formatters.dateTime(point.timestamp)}',
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

  Widget _buildCandles(BuildContext context) {
    final candles = [...chart.candles]
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
    if (rangeHours case final hours? when hours < chart.days * 24) {
      if (candles.isNotEmpty) {
        final cutoff = candles.last.timestamp.subtract(Duration(hours: hours));
        candles.removeWhere((candle) => candle.timestamp.isBefore(cutoff));
      }
    }
    if (candles.isEmpty) {
      return SizedBox(
        height: AppSizes.chartHeight,
        child: Center(
          child: Text(
            AppStrings.candleChartUnavailable,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
      );
    }

    final minPrice = candles
        .map((candle) => candle.low)
        .reduce((a, b) => a < b ? a : b);
    final maxPrice = candles
        .map((candle) => candle.high)
        .reduce((a, b) => a > b ? a : b);
    final padding = (maxPrice - minPrice) * 0.1;
    final safePadding = padding > 0
        ? padding
        : (maxPrice.abs() * 0.02)
              .clamp(0.000000001, double.infinity)
              .toDouble();
    return SizedBox(
      height: AppSizes.chartHeight + 34,
      child: CustomPaint(
        painter: _CandlestickPainter(
          candles: candles,
          currency: currency,
          days: chart.days,
          minY: minPrice - safePadding,
          maxY: maxPrice + safePadding,
          positiveColor: AppColors.lightGain,
          negativeColor: AppColors.lightLoss,
          gridColor: const Color(0xFFE9EDF2),
        ),
        child: const SizedBox.expand(),
      ),
    );
  }

  String _formatValue(double value) => series == PriceChartSeries.price
      ? Formatters.currency(value, currency)
      : Formatters.compact(value, currencyCode: currency);
}

class _CandlestickPainter extends CustomPainter {
  const _CandlestickPainter({
    required this.candles,
    required this.currency,
    required this.days,
    required this.minY,
    required this.maxY,
    required this.positiveColor,
    required this.negativeColor,
    required this.gridColor,
  });

  final List<CandlePoint> candles;
  final String currency;
  final int days;
  final double minY;
  final double maxY;
  final Color positiveColor;
  final Color negativeColor;
  final Color gridColor;

  @override
  void paint(Canvas canvas, Size size) {
    const leftInset = 8.0;
    const rightInset = 68.0;
    const topInset = 8.0;
    const bottomInset = 30.0;
    final chartRect = Rect.fromLTRB(
      leftInset,
      topInset,
      size.width - rightInset,
      size.height - bottomInset,
    );
    final gridPaint = Paint()
      ..color = gridColor
      ..strokeWidth = 0.8;
    for (var index = 0; index <= 4; index++) {
      final y = chartRect.top + chartRect.height * index / 4;
      canvas.drawLine(
        Offset(chartRect.left, y),
        Offset(chartRect.right, y),
        gridPaint,
      );
      final value = maxY - (maxY - minY) * index / 4;
      _drawLabel(
        canvas,
        Formatters.compact(value, currencyCode: currency),
        Offset(chartRect.right + 4, y - 6),
        maxWidth: rightInset - 8,
      );
    }

    for (final index in {0, candles.length ~/ 2, candles.length - 1}) {
      final label = DateFormat(days <= 1 ? 'HH:mm' : 'MMM d')
          .format(candles[index].timestamp.toLocal());
      final x =
          chartRect.left +
          chartRect.width *
              index /
              (candles.length - 1).clamp(1, candles.length);
      _drawLabel(
        canvas,
        label,
        Offset(x - 24, chartRect.bottom + 5),
        maxWidth: 48,
      );
    }

    final range = maxY - minY;
    double yFor(double value) =>
        chartRect.bottom - (value - minY) / range * chartRect.height;
    final step = chartRect.width / candles.length;
    final bodyWidth = (step * 0.56).clamp(2.0, 12.0);
    for (var index = 0; index < candles.length; index++) {
      final candle = candles[index];
      final x = chartRect.left + step * (index + 0.5);
      final color = candle.close >= candle.open ? positiveColor : negativeColor;
      final paint = Paint()
        ..color = color
        ..strokeWidth = 1.4;
      canvas.drawLine(
        Offset(x, yFor(candle.high)),
        Offset(x, yFor(candle.low)),
        paint,
      );
      final top = yFor(candle.open < candle.close ? candle.close : candle.open);
      final bottom = yFor(
        candle.open > candle.close ? candle.close : candle.open,
      );
      final body = Rect.fromLTRB(
        x - bodyWidth / 2,
        top,
        x + bodyWidth / 2,
        bottom > top ? bottom : top + 1.5,
      );
      canvas.drawRect(body, paint);
    }
  }

  void _drawLabel(
    Canvas canvas,
    String text,
    Offset offset, {
    required double maxWidth,
  }) {
    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: const TextStyle(
          color: AppColors.lightTextSecondary,
          fontSize: 10,
        ),
      ),
      textDirection: ui.TextDirection.ltr,
      maxLines: 1,
      ellipsis: '…',
    )..layout(maxWidth: maxWidth);
    painter.paint(canvas, offset);
  }

  @override
  bool shouldRepaint(_CandlestickPainter oldDelegate) =>
      candles != oldDelegate.candles ||
      minY != oldDelegate.minY ||
      maxY != oldDelegate.maxY ||
      currency != oldDelegate.currency ||
      days != oldDelegate.days ||
      positiveColor != oldDelegate.positiveColor ||
      negativeColor != oldDelegate.negativeColor;
}
