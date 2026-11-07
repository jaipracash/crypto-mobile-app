import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_sizes.dart';
import '../../core/constants/app_strings.dart';

class DataSourceBanner extends StatelessWidget {
  const DataSourceBanner({
    required this.source,
    this.horizontalInset = true,
    super.key,
  });

  final String source;
  final bool horizontalInset;

  @override
  Widget build(BuildContext context) {
    if (source == 'live' || source == 'mock') return const SizedBox.shrink();
    return Container(
      margin: EdgeInsets.fromLTRB(
        horizontalInset ? AppSizes.screenPadding : 0,
        AppSizes.sm,
        horizontalInset ? AppSizes.screenPadding : 0,
        0,
      ),
      padding: EdgeInsets.symmetric(
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
              AppStrings.cachedData,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }
}
