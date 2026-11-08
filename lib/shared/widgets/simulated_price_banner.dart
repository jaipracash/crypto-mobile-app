import 'package:flutter/material.dart';

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
        horizontalInset ? AppSizes.screenPadding : 0,
        AppSizes.sm,
        horizontalInset ? AppSizes.screenPadding : 0,
        AppSizes.xs,
      ),
      padding: EdgeInsets.symmetric(
        horizontal: AppSizes.sm,
        vertical: AppSizes.xs,
      ),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: dark ? 0.2 : 0.12),
        borderRadius: BorderRadius.circular(AppSizes.radiusSm),
      ),
      child: Row(
        children: [
          Icon(
            Icons.info_outline_rounded,
            size: AppSizes.iconSmall,
            color: dark ? const Color(0xFFFFC857) : AppColors.warning,
          ),
          const SizedBox(width: AppSizes.xs),
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
