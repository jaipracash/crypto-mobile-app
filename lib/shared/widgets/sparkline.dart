import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_sizes.dart';

class Sparkline extends StatelessWidget {
  const Sparkline({required this.values, this.positive = true, super.key});
  final List<double> values;
  final bool positive;
  @override
  Widget build(BuildContext context) {
    if (values.length < 2) {
      return const SizedBox(
        width: AppSizes.sparklineWidth,
        height: AppSizes.sparklineHeight,
      );
    }
    final dark = Theme.of(context).brightness == Brightness.dark;
    final color = positive
        ? (dark ? AppColors.darkGain : AppColors.lightGain)
        : (dark ? AppColors.darkLoss : AppColors.lightLoss);
    return SizedBox(
      width: AppSizes.sparklineWidth,
      height: AppSizes.sparklineHeight,
      child: LineChart(
        LineChartData(
          minY: values.reduce((a, b) => a < b ? a : b),
          maxY: values.reduce((a, b) => a > b ? a : b),
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
              barWidth: AppSizes.sparklineLineWidth,
              color: color,
              dotData: const FlDotData(show: false),
            ),
          ],
        ),
      ),
    );
  }
}
