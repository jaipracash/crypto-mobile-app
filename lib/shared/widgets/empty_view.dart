import 'package:flutter/material.dart';

import '../../core/constants/app_sizes.dart';

class EmptyView extends StatelessWidget {
  const EmptyView({
    required this.title,
    this.message,
    this.actionLabel,
    this.onAction,
    super.key,
  });
  final String title;
  final String? message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(AppSizes.xl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.search_off_rounded,
            size: AppSizes.xxl,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: AppSizes.md),
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          if (message != null) ...[
            const SizedBox(height: AppSizes.xs),
            Text(
              message!,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: AppSizes.lg),
            FilledButton.tonal(onPressed: onAction, child: Text(actionLabel!)),
          ],
        ],
      ),
    ),
  );
}
