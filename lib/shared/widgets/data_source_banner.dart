import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_sizes.dart';
import '../../core/constants/app_strings.dart';

class DataSourceBanner extends StatelessWidget {
  const DataSourceBanner({required this.source, super.key});
  final String source;
  @override
  Widget build(BuildContext context) {
    if (source == 'live') return const SizedBox.shrink();
    final isMock = source == 'mock';
    return Container(
      margin: const EdgeInsets.fromLTRB(
        AppSizes.screenPadding,
        AppSizes.sm,
        AppSizes.screenPadding,
        0,
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.md,
        vertical: AppSizes.sm,
      ),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(AppSizes.radiusSm),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline, size: 16, color: AppColors.warning),
          const SizedBox(width: AppSizes.sm),
          Expanded(
            child: Text(
              isMock ? AppStrings.sampleData : AppStrings.cachedData,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }
}
