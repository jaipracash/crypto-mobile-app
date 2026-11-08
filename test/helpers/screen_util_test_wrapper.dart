import 'package:flutter/widgets.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

Widget screenUtilTestWrapper(Widget child) => ScreenUtilInit(
  designSize: const Size(800, 600),
  builder: (_, child) => child!,
  child: child,
);
