import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/repository_providers.dart';
import '../../../market/domain/market_models.dart';
import '../../../settings/presentation/controllers/settings_controller.dart';

final statsSnapshotProvider =
    AsyncNotifierProvider<StatsSnapshotController, MarketSnapshot>(
      StatsSnapshotController.new,
    );

class StatsSnapshotController extends AsyncNotifier<MarketSnapshot> {
  @override
  Future<MarketSnapshot> build() async {
    final settings = await ref.watch(settingsControllerProvider.future);
    return ref.watch(statsRepositoryProvider).getSnapshot(settings.currency);
  }
}

final statsMoversProvider =
    AsyncNotifierProvider<StatsMoversController, MarketMovers>(
      StatsMoversController.new,
    );

class StatsMoversController extends AsyncNotifier<MarketMovers> {
  @override
  Future<MarketMovers> build() async {
    final settings = await ref.watch(settingsControllerProvider.future);
    return ref.watch(statsRepositoryProvider).getMovers(settings.currency);
  }
}

final statsTrendingProvider =
    AsyncNotifierProvider<StatsTrendingController, List<TrendingCoin>>(
      StatsTrendingController.new,
    );

class StatsTrendingController extends AsyncNotifier<List<TrendingCoin>> {
  @override
  Future<List<TrendingCoin>> build() =>
      ref.watch(statsRepositoryProvider).getTrending();
}
