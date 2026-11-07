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

final coinChartProvider = FutureProvider.autoDispose
    .family<CoinChart, (String coinId, int days)>((ref, request) async {
      final settings = await ref.watch(settingsControllerProvider.future);
      return ref
          .watch(coinDetailsRepositoryProvider)
          .getChart(request.$1, request.$2, settings.currency);
    });
