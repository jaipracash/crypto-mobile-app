import 'package:dio/dio.dart';

import '../../../core/error/dio_failure_mapper.dart';
import '../../../shared/data/coin_dto.dart';
import '../domain/watchlist_repository.dart';
import 'watchlist_remote_datasource.dart';

class WatchlistRepositoryImpl implements WatchlistRepository {
  const WatchlistRepositoryImpl(this._remote);
  final WatchlistRemoteDataSource _remote;

  @override
  Future<WatchlistData> getWatchlist(String currency) async {
    try {
      final response = await _remote.getWatchlist(currency);
      final json = Map<String, dynamic>.from(response.data as Map);
      final items = (json['items'] as List<dynamic>? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(CoinDto.new)
          .map((dto) => dto.toEntity())
          .toList(growable: false);
      return WatchlistData(
        items: items,
        dataSource: response.headers.value('X-Data-Source') ?? 'live',
      );
    } on DioException catch (error) {
      throw mapDioFailure(error);
    }
  }

  @override
  Future<void> add(String coinId) async {
    try {
      await _remote.add(coinId);
    } on DioException catch (error) {
      throw mapDioFailure(error);
    }
  }

  @override
  Future<void> remove(String coinId) async {
    try {
      await _remote.remove(coinId);
    } on DioException catch (error) {
      throw mapDioFailure(error);
    }
  }
}
