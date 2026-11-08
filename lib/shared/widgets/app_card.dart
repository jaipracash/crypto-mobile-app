import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../core/constants/app_sizes.dart';

class AppCard extends StatelessWidget {
  const AppCard({required this.child, this.padding, super.key});
  final Widget child;
  final EdgeInsetsGeometry? padding;
  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: padding ?? EdgeInsets.all(AppSizes.lg.w),
      child: child,
    ),
  );
}
