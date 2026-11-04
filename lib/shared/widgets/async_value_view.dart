import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_sizes.dart';
import '../../core/constants/app_strings.dart';
import 'empty_view.dart';
import 'error_view.dart';
import 'shimmer_box.dart';

class AsyncValueView<T> extends StatelessWidget {
  const AsyncValueView({
    required this.value,
    required this.onRetry,
    required this.builder,
    this.isEmpty,
    this.emptyTitle = AppStrings.nothingHereYet,
    this.emptyMessage,
    this.loading,
    super.key,
  });
  final AsyncValue<T> value;
  final VoidCallback onRetry;
  final Widget Function(T data) builder;
  final bool Function(T data)? isEmpty;
  final String emptyTitle;
  final String? emptyMessage;
  final Widget? loading;

  @override
  Widget build(BuildContext context) => value.when(
    loading: () => loading ?? const _DefaultLoading(),
    error: (error, _) => ErrorView(message: error.toString(), onRetry: onRetry),
    data: (data) => isEmpty?.call(data) == true
        ? EmptyView(title: emptyTitle, message: emptyMessage)
        : builder(data),
  );
}

class _DefaultLoading extends StatelessWidget {
  const _DefaultLoading();
  @override
  Widget build(BuildContext context) => ListView.separated(
    padding: const EdgeInsets.all(AppSizes.screenPadding),
    itemCount: AppSizes.loadingItemCount,
    separatorBuilder: (_, _) => const SizedBox(height: AppSizes.loadingRowGap),
    itemBuilder: (_, _) => const Row(
      children: [
        ShimmerBox(
          width: AppSizes.coinLogo,
          height: AppSizes.coinLogo,
          radius: AppSizes.radiusPill,
        ),
        SizedBox(width: AppSizes.loadingRowGap),
        Expanded(child: ShimmerBox(height: AppSizes.loadingBoxHeight)),
      ],
    ),
  );
}
