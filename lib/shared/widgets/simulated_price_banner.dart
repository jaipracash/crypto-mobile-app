import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_sizes.dart';
import '../../core/constants/app_strings.dart';

class SimulatedPriceBanner extends StatelessWidget {
  const SimulatedPriceBanner({this.horizontalInset = true, super.key});

  final bool horizontalInset;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: EdgeInsets.fromLTRB(
        horizontalInset ? AppSizes.screenPadding.w : 0,
        AppSizes.sm.w,
        horizontalInset ? AppSizes.screenPadding.w : 0,
        AppSizes.xs.w,
      ),
      padding: EdgeInsets.symmetric(
        horizontal: AppSizes.sm.w,
        vertical: AppSizes.xs.w,
      ),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: dark ? 0.2 : 0.12),
        borderRadius: BorderRadius.circular(AppSizes.radiusSm.r),
      ),
      child: Row(
        children: [
          Icon(
            Icons.info_outline_rounded,
            size: AppSizes.iconSmall.w,
            color: dark ? const Color(0xFFFFC857) : AppColors.warning,
          ),
          SizedBox(width: AppSizes.xs.w),
          Expanded(
            child: Text(
              AppStrings.simulatedPriceStream,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: dark
                    ? Theme.of(context).colorScheme.onSurface
                    : AppColors.lightTextSecondary,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
