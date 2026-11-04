import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/interceptors/connectivity.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';

class OfflineBanner extends ConsumerWidget {
  const OfflineBanner({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final offline = ref.watch(isOfflineProvider).asData?.value ?? false;
    if (!offline) return const SizedBox.shrink();
    return Container(
      width: double.infinity,
      color: AppColors.warning,
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Text(
        AppStrings.offline,
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.labelMedium
            ?.copyWith(color: AppColors.lightTextPrimary),
      ),
    );
  }
}
