import 'package:flutter/material.dart';

import '../../core/constants/app_strings.dart';
import '../../core/constants/app_sizes.dart';

class ErrorView extends StatelessWidget {
  const ErrorView({required this.message, required this.onRetry, super.key});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(AppSizes.xl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.cloud_off_outlined,
            size: AppSizes.xxl,
            color: Theme.of(context).colorScheme.error,
          ),
          const SizedBox(height: AppSizes.md),
          Text(
            message,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: AppSizes.lg),
          OutlinedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: const Text(AppStrings.tryAgain),
          ),
        ],
      ),
    ),
  );
}
