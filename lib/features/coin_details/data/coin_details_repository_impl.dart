import 'package:dio/dio.dart';

import '../../../core/error/dio_failure_mapper.dart';
import '../domain/coin_details.dart';
import '../domain/coin_details_repository.dart';
import 'coin_details_dto.dart';
import 'coin_details_remote_datasource.dart';

class CoinDetailsRepositoryImpl implements CoinDetailsRepository {
  const CoinDetailsRepositoryImpl(this._remote);
  final CoinDetailsRemoteDataSource _remote;

  @override
  Future<CoinDetails> getDetails(String coinId, String currency) async {
    try {
      final response = await _remote.getDetails(coinId, currency);
      return CoinDetailsDto(
        Map<String, dynamic>.from(response.data as Map),
        response.headers.value('X-Data-Source') ?? 'live',
      ).toEntity();
    } on DioException catch (error) {
      throw mapDioFailure(error);
    }
  }

  @override
  Future<CoinChart> getChart(String coinId, int days, String currency) async {
    try {
      final response = await _remote.getChart(coinId, days, currency);
      return CoinChartDto(
        Map<String, dynamic>.from(response.data as Map),
        response.headers.value('X-Data-Source') ?? 'live',
        requestedCoinId: coinId,
        requestedDays: days,
        requestedCurrency: currency,
      ).toEntity();
    } on DioException catch (error) {
      throw mapDioFailure(error);
    }
  }
}
