import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_sizes.dart';
import '../../core/utils/formatters.dart';

class ChangePill extends StatelessWidget {
  const ChangePill({
    required this.change,
    this.compact = false,
    this.showBackground = true,
    super.key,
  });
  final double? change;
  final bool compact;
  final bool showBackground;
  @override
  Widget build(BuildContext context) {
    final positive = (change ?? 0) >= 0;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final color = positive
        ? (dark ? AppColors.darkGain : AppColors.lightGain)
        : (dark ? AppColors.darkLoss : AppColors.lightLoss);
    final text = Text(
      Formatters.percent(change),
      style: Theme.of(context).textTheme.labelMedium
          ?.copyWith(color: color, fontWeight: FontWeight.w600),
    );
    if (!showBackground) return text;
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? AppSizes.sm.w : AppSizes.md.w,
        vertical: AppSizes.xs.w,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppSizes.radiusPill.r),
      ),
      child: text,
    );
  }
}
