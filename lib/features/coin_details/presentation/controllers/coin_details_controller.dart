import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/repository_providers.dart';
import '../../../settings/presentation/controllers/settings_controller.dart';
import '../../domain/coin_details.dart';

final coinDetailsControllerProvider =
    AsyncNotifierProvider.family<CoinDetailsController, CoinDetails, String>(
      CoinDetailsController.new,
    );

class CoinDetailsController extends FamilyAsyncNotifier<CoinDetails, String> {
  @override
  Future<CoinDetails> build(String coinId) async {
    final settings = await ref.watch(settingsControllerProvider.future);
    return ref
        .watch(coinDetailsRepositoryProvider)
        .getDetails(coinId, settings.currency);
  }
}

final chartControllerProvider =
    AsyncNotifierProvider.family<ChartController, CoinChart, String>(
      ChartController.new,
    );

class ChartController extends FamilyAsyncNotifier<CoinChart, String> {
  int _days = 7;
  int get days => _days;

  @override
  Future<CoinChart> build(String coinId) async {
    final settings = await ref.watch(settingsControllerProvider.future);
    return ref
        .watch(coinDetailsRepositoryProvider)
        .getChart(coinId, _days, settings.currency);
  }

  Future<void> setDays(int days) async {
    _days = days;
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final settings = ref.read(settingsControllerProvider).asData?.value;
      return ref
          .read(coinDetailsRepositoryProvider)
          .getChart(arg, days, settings?.currency ?? 'usd');
    });
  }
}
