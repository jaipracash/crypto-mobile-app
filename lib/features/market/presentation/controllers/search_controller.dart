import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/repository_providers.dart';
import '../../domain/market_models.dart';

final searchQueryProvider = NotifierProvider<SearchQueryController, String>(
  SearchQueryController.new,
);

class SearchQueryController extends Notifier<String> {
  @override
  String build() => '';
  void set(String value) => state = value;
}

final searchResultsProvider =
    AsyncNotifierProvider<SearchResultsController, List<SearchCoin>>(
      SearchResultsController.new,
    );

class SearchResultsController extends AsyncNotifier<List<SearchCoin>> {
  Timer? _timer;
  int _requestId = 0;

  @override
  Future<List<SearchCoin>> build() async {
    ref.listen(searchQueryProvider, (_, next) => _schedule(next));
    ref.onDispose(() => _timer?.cancel());
    return const [];
  }

  void retry() => _schedule(ref.read(searchQueryProvider));

  void _schedule(String query) {
    _timer?.cancel();
    final id = ++_requestId;
    if (query.trim().length < 2) {
      state = const AsyncData([]);
      return;
    }
    _timer = Timer(const Duration(milliseconds: 400), () async {
      state = const AsyncLoading();
      try {
        final results = await ref
            .read(marketRepositoryProvider)
            .search(query.trim());
        if (id == _requestId) state = AsyncData(results);
      } catch (error, stack) {
        if (id == _requestId) state = AsyncError(error, stack);
      }
    });
  }
}
