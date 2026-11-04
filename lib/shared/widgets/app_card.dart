import 'package:flutter/material.dart';

import '../../core/constants/app_sizes.dart';

class AppCard extends StatelessWidget {
  const AppCard({
    required this.child,
    this.padding = const EdgeInsets.all(AppSizes.lg),
    super.key,
  });
  final Widget child;
  final EdgeInsetsGeometry padding;
  @override
  Widget build(BuildContext context) => Card(
    child: Padding(padding: padding, child: child),
  );
}
