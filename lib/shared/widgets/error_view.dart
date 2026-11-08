import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../core/constants/app_strings.dart';
import '../../core/constants/app_sizes.dart';
import '../../core/error/failure.dart';

class ErrorView extends StatelessWidget {
  const ErrorView({required this.error, required this.onRetry, super.key});

  final Object error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final failure = error;
    final isOffline =
        failure is Failure && failure.type == FailureType.noInternet;
    return Center(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSizes.xl,
          AppSizes.xl + AppSizes.md,
          AppSizes.xl,
          AppSizes.xl,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isOffline) ...[
              Text(
                AppStrings.noInternetConnection,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: AppSizes.sm),
              SvgPicture.asset(
                'assets/no_interente.svg',
                width: 140,
                height: 190,
                fit: BoxFit.contain,
                semanticsLabel: AppStrings.noInternetConnection,
              ),
              const SizedBox(height: AppSizes.sm),
              Text(
                AppStrings.checkInternetConnection,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ] else ...[
              SvgPicture.asset(
                'assets/something_went_rong.svg',
                width: 160,
                height: 160,
                fit: BoxFit.contain,
                semanticsLabel: AppStrings.somethingWentWrong,
              ),
              const SizedBox(height: AppSizes.md),
              Text(
                AppStrings.somethingWentWrong,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              Text(
                AppStrings.unexpectedErrorMessage,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
            const SizedBox(height: AppSizes.lg),
            FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Colors.white,
              ),
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text(AppStrings.tryAgain),
            ),
          ],
        ),
      ),
    );
  }
}
