import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_sizes.dart';
import '../../core/constants/app_strings.dart';

class SimulatedPriceBanner extends StatelessWidget {
  const SimulatedPriceBanner({super.key});

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.fromLTRB(
      AppSizes.screenPadding,
      AppSizes.xs,
      AppSizes.screenPadding,
      AppSizes.xs,
    ),
    padding: const EdgeInsets.symmetric(
      horizontal: AppSizes.sm,
      vertical: AppSizes.xs,
    ),
    decoration: BoxDecoration(
      color: AppColors.warning.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(AppSizes.radiusSm),
    ),
    child: Row(
      children: [
        const Icon(
          Icons.info_outline_rounded,
          size: AppSizes.iconSmall,
          color: AppColors.warning,
        ),
        const SizedBox(width: AppSizes.xs),
        Expanded(
          child: Text(
            AppStrings.simulatedPriceStream,
            style: Theme.of(context).textTheme.labelSmall
                ?.copyWith(color: AppColors.lightTextSecondary),
          ),
        ),
      ],
    ),
  );
}
