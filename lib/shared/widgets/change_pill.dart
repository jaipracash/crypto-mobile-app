import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_sizes.dart';
import '../../core/utils/formatters.dart';

class ChangePill extends StatelessWidget {
  const ChangePill({required this.change, this.compact = false, super.key});
  final double? change;
  final bool compact;
  @override
  Widget build(BuildContext context) {
    final positive = (change ?? 0) >= 0;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final color = positive
        ? (dark ? AppColors.darkGain : AppColors.lightGain)
        : (dark ? AppColors.darkLoss : AppColors.lightLoss);
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? AppSizes.sm : AppSizes.md,
        vertical: AppSizes.xs,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppSizes.radiusPill),
      ),
      child: Text(
        Formatters.percent(change),
        style: Theme.of(context).textTheme.labelMedium
            ?.copyWith(color: color, fontWeight: FontWeight.w600),
      ),
    );
  }
}
