import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_strings.dart';
import 'cupertino_loader.dart';
import 'empty_view.dart';
import 'error_view.dart';

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
  Widget build(BuildContext context) {
    if (value.isLoading && value.hasError) {
      return loading ?? const Center(child: CupertinoLoader());
    }

    return value.when(
      loading: () => loading ?? const Center(child: CupertinoLoader()),
      error: (error, _) => ErrorView(error: error, onRetry: onRetry),
      data: (data) => isEmpty?.call(data) == true
          ? EmptyView(title: emptyTitle, message: emptyMessage)
          : builder(data),
    );
  }
}
