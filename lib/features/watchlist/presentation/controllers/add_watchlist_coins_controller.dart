import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/api_constants.dart';
import '../../../../core/providers/repository_providers.dart';
import '../../../market/domain/coin.dart';
import '../../../settings/presentation/controllers/settings_controller.dart';

final addWatchlistCoinsControllerProvider =
    AsyncNotifierProvider<AddWatchlistCoinsController, AddWatchlistCoinsState>(
      AddWatchlistCoinsController.new,
    );

class AddWatchlistCoinsState {
  const AddWatchlistCoinsState({
    required this.items,
    required this.page,
    required this.hasMore,
    required this.dataSource,
    this.isLoadingMore = false,
    this.loadMoreError,
  });

  final List<Coin> items;
  final int page;
  final bool hasMore;
  final String dataSource;
  final bool isLoadingMore;
  final Object? loadMoreError;
}

class AddWatchlistCoinsController
    extends AsyncNotifier<AddWatchlistCoinsState> {
  static const _pageSize = ApiConstants.maxPageSize;

  @override
  Future<AddWatchlistCoinsState> build() async {
    final settings = await ref.watch(settingsControllerProvider.future);
    final page = await ref
        .watch(marketRepositoryProvider)
        .getCoins(
          page: 1,
          perPage: _pageSize,
          order: 'market_cap_desc',
          currency: settings.currency,
        );
    return AddWatchlistCoinsState(
      items: page.items,
      page: page.page,
      hasMore: page.hasMore,
      dataSource: page.dataSource,
    );
  }

  Future<void> loadMore() async {
    final current = state.asData?.value;
    if (current == null || !current.hasMore || current.isLoadingMore) return;

    state = AsyncData(
      AddWatchlistCoinsState(
        items: current.items,
        page: current.page,
        hasMore: current.hasMore,
        dataSource: current.dataSource,
        isLoadingMore: true,
      ),
    );

    try {
      final page = await ref
          .read(marketRepositoryProvider)
          .getCoins(
            page: current.page + 1,
            perPage: _pageSize,
            order: 'market_cap_desc',
            currency:
                ref.read(settingsControllerProvider).asData?.value.currency ??
                'usd',
          );
      state = AsyncData(
        AddWatchlistCoinsState(
          items: [...current.items, ...page.items],
          page: page.page,
          hasMore: page.hasMore,
          dataSource: page.dataSource,
        ),
      );
    } catch (error) {
      state = AsyncData(
        AddWatchlistCoinsState(
          items: current.items,
          page: current.page,
          hasMore: current.hasMore,
          dataSource: current.dataSource,
          loadMoreError: error,
        ),
      );
    }
  }
}
