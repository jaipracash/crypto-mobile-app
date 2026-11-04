import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/repository_providers.dart';
import '../../../market/domain/coin.dart';
import '../../../market/presentation/controllers/market_controller.dart';
import '../../../settings/presentation/controllers/settings_controller.dart';
import '../../domain/watchlist_repository.dart';

final watchlistControllerProvider =
    AsyncNotifierProvider<WatchlistController, WatchlistData>(
      WatchlistController.new,
    );

class WatchlistController extends AsyncNotifier<WatchlistData> {
  @override
  Future<WatchlistData> build() async {
    final settings = await ref.watch(settingsControllerProvider.future);
    return ref
        .watch(watchlistRepositoryProvider)
        .getWatchlist(settings.currency);
  }

  Future<void> refresh() async {
    state = const AsyncLoading<WatchlistData>().copyWithPrevious(state);
    state = await AsyncValue.guard(() async {
      final currency =
          ref.read(settingsControllerProvider).asData?.value.currency ?? 'usd';
      return ref.read(watchlistRepositoryProvider).getWatchlist(currency);
    });
  }

  Future<void> toggle(Coin coin) async {
    final previous =
        state.asData?.value ??
        const WatchlistData(items: [], dataSource: 'live');
    final exists = previous.items.any((item) => item.id == coin.id);
    final next = exists
        ? previous.items
              .where((item) => item.id != coin.id)
              .toList(growable: false)
        : [...previous.items, coin.copyWith(isWatchlisted: true)];
    state = AsyncData(
      WatchlistData(items: next, dataSource: previous.dataSource),
    );
    ref
        .read(coinListControllerProvider.notifier)
        .updateWatchlisted(coin.id, !exists);
    try {
      if (exists) {
        await ref.read(watchlistRepositoryProvider).remove(coin.id);
      } else {
        await ref.read(watchlistRepositoryProvider).add(coin.id);
      }
    } catch (error, stack) {
      state = AsyncData(previous);
      ref
          .read(coinListControllerProvider.notifier)
          .updateWatchlisted(coin.id, exists);
      Error.throwWithStackTrace(error, stack);
    }
  }
}
