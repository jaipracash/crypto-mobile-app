import 'package:dio/dio.dart';

import '../../../core/constants/api_constants.dart';
import '../../../core/error/dio_failure_mapper.dart';
import '../domain/market_models.dart';
import '../domain/market_repository.dart';
import '../../../shared/data/coin_dto.dart';
import 'market_dtos.dart';
import 'market_remote_datasource.dart';

class MarketRepositoryImpl implements MarketRepository {
  const MarketRepositoryImpl(this._remote);
  final MarketRemoteDataSource _remote;

  @override
  Future<CoinPage> getCoins({
    required int page,
    required int perPage,
    required String order,
    required String currency,
    String? category,
  }) async {
    try {
      final query = <String, dynamic>{
        'page': page,
        'per_page': perPage.clamp(1, ApiConstants.maxPageSize).toInt(),
        'order': order,
        'currency': currency,
      };
      if (category != null) query['category'] = category;
      final response = await _remote.getCoins(query);
      return CoinPageDto(
        Map<String, dynamic>.from(response.data as Map),
        response.headers.value('X-Data-Source') ?? 'live',
      ).toEntity();
    } on DioException catch (error) {
      throw mapDioFailure(error);
    }
  }

  @override
  Future<List<SearchCoin>> search(String query) async {
    try {
      final json = await _remote.search(query);
      return (json['items'] as List<dynamic>? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(SearchCoinDto.new)
          .map((dto) => dto.toEntity())
          .toList(growable: false);
    } on DioException catch (error) {
      throw mapDioFailure(error);
    }
  }

  @override
  Future<MarketSnapshot> getGlobal(String currency) async {
    try {
      final response = await _remote.getGlobal(currency);
      return MarketSnapshotDto(
        Map<String, dynamic>.from(response.data as Map),
        response.headers.value('X-Data-Source') ?? 'live',
      ).toEntity();
    } on DioException catch (error) {
      throw mapDioFailure(error);
    }
  }

  @override
  Future<TrendingData> getTrending() async {
    try {
      final response = await _remote.getTrending();
      final json = Map<String, dynamic>.from(response.data as Map);
      final source = response.headers.value('X-Data-Source') ?? 'live';
      return TrendingData(
        items: (json['items'] as List<dynamic>? ?? const [])
            .whereType<Map<String, dynamic>>()
            .map(CoinDto.new)
            .map((dto) => dto.toEntity())
            .toList(growable: false),
        dataSource: source,
      );
    } on DioException catch (error) {
      throw mapDioFailure(error);
    }
  }
}
