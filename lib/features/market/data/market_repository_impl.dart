import 'package:dio/dio.dart';

import '../../../core/error/app_exception.dart';
import '../../../core/error/failure.dart';
import '../domain/coin.dart';
import '../domain/market_models.dart';
import '../domain/market_repository.dart';
import 'coin_dto.dart';
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
  }) async {
    try {
      final response = await _remote.getCoins({
        'page': page,
        'per_page': perPage,
        'order': order,
        'currency': currency,
      });
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
  Future<List<TrendingCoin>> getTrending() async {
    try {
      final response = await _remote.getTrending();
      final json = Map<String, dynamic>.from(response.data as Map);
      final source = response.headers.value('X-Data-Source') ?? 'live';
      return (json['items'] as List<dynamic>? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map((item) => TrendingCoinDto(item, source))
          .map((dto) => dto.toEntity())
          .toList(growable: false);
    } on DioException catch (error) {
      throw mapDioFailure(error);
    }
  }

  @override
  Future<MarketMovers> getMovers({
    required int limit,
    required String currency,
  }) async {
    try {
      final response = await _remote.getMovers(limit, currency);
      final json = Map<String, dynamic>.from(response.data as Map);
      final source = response.headers.value('X-Data-Source') ?? 'live';
      final dto = MarketMoversDto(json, source);
      return MarketMovers(
        gainers: _parseCoins(json['gainers']),
        losers: _parseCoins(json['losers']),
        dataSource: dto.toEntity().dataSource,
      );
    } on DioException catch (error) {
      throw mapDioFailure(error);
    }
  }

  List<Coin> _parseCoins(dynamic rows) => (rows as List<dynamic>? ?? const [])
      .whereType<Map<String, dynamic>>()
      .map(CoinDto.new)
      .map((dto) => dto.toEntity())
      .toList(growable: false);
}

Failure mapDioFailure(DioException error) {
  final appException = error.error;
  final code = appException is AppException ? appException.code : '';
  final message = appException is AppException
      ? appException.message
      : 'Unable to load market data. Please try again.';
  if (error.type == DioExceptionType.connectionTimeout ||
      error.type == DioExceptionType.receiveTimeout ||
      error.type == DioExceptionType.sendTimeout) {
    return Failure(
      FailureType.timeout,
      'The request timed out. Check your connection and retry.',
    );
  }
  if (error.type == DioExceptionType.connectionError) {
    return const Failure(FailureType.noInternet, 'You appear to be offline.');
  }
  return switch (code) {
    'UPSTREAM_RATE_LIMITED' => Failure(FailureType.rateLimited, message),
    'COIN_NOT_FOUND' => Failure(FailureType.notFound, message),
    'UPSTREAM_ERROR' => Failure(FailureType.server, message),
    _ => Failure(FailureType.unknown, message),
  };
}
