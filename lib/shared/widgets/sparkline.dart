import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_sizes.dart';

class Sparkline extends StatelessWidget {
  const Sparkline({
    required this.values,
    this.positive = true,
    this.width,
    this.height,
    this.filled = false,
    super.key,
  });

  final List<double> values;
  final bool positive;
  final double? width;
  final double? height;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    final width = this.width ?? AppSizes.sparklineWidth.w;
    final height = this.height ?? AppSizes.sparklineHeight.h;
    if (values.length < 2) {
      return SizedBox(width: width, height: height);
    }
    final dark = Theme.of(context).brightness == Brightness.dark;
    final color = positive
        ? (dark ? AppColors.darkGain : AppColors.lightGain)
        : (dark ? AppColors.darkLoss : AppColors.lightLoss);
    final minimum = values.reduce((a, b) => a < b ? a : b);
    final maximum = values.reduce((a, b) => a > b ? a : b);
    final padding = ((maximum - minimum).abs() * 0.1)
        .clamp(0.000000000001, double.infinity)
        .toDouble();
    return SizedBox(
      width: width,
      height: height,
      child: LineChart(
        LineChartData(
          minY: minimum - padding,
          maxY: maximum + padding,
          titlesData: const FlTitlesData(show: false),
          gridData: const FlGridData(show: false),
          borderData: FlBorderData(show: false),
          lineTouchData: const LineTouchData(enabled: false),
          lineBarsData: [
            LineChartBarData(
              spots: values.indexed
                  .map((entry) => FlSpot(entry.$1.toDouble(), entry.$2))
                  .toList(),
              isCurved: true,
              curveSmoothness: 0.18,
              barWidth: AppSizes.sparklineLineWidth.w,
              color: color,
              isStrokeCapRound: true,
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(
                show: filled,
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    color.withValues(alpha: 0.32),
                    color.withValues(alpha: 0.04),
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
