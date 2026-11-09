import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'core/constants/app_strings.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'features/market/presentation/controllers/live_price_controller.dart';
import 'features/settings/presentation/controllers/settings_controller.dart';
import 'features/settings/presentation/controllers/theme_controller.dart';

class CryptoResearchApp extends ConsumerWidget {
  const CryptoResearchApp({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currency =
        ref.watch(settingsControllerProvider).asData?.value.currency ?? 'usd';
    ref.listen(simulatedPriceUpdatesProvider(currency), (_, next) {
      next.whenData(
        (updates) =>
            ref.read(liveCoinPricesProvider.notifier).apply(currency, updates),
      );
    });
    return ScreenUtilInit(
      designSize: const Size(390, 844),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) => MaterialApp.router(
        title: AppStrings.appName,
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light(),
        darkTheme: AppTheme.dark(),
        themeMode: ref.watch(themeModeProvider),
        routerConfig: ref.watch(appRouterProvider),
      ),
    );
  }
}
