import 'package:dio/dio.dart';

abstract class CoinDetailsRemoteDataSource {
  Future<Response<dynamic>> getDetails(String coinId, String currency);
  Future<Response<dynamic>> getChart(String coinId, int days, String currency);
}

class CoinDetailsRemoteDataSourceImpl implements CoinDetailsRemoteDataSource {
  const CoinDetailsRemoteDataSourceImpl(this._dio);
  final Dio _dio;
  @override
  Future<Response<dynamic>> getDetails(String coinId, String currency) =>
      _dio.get<dynamic>(
        '/api/coins/$coinId',
        queryParameters: {'currency': currency},
      );
  @override
  Future<Response<dynamic>> getChart(
    String coinId,
    int days,
    String currency,
  ) => _dio.get<dynamic>(
    '/api/coins/$coinId/chart',
    queryParameters: {'days': days, 'currency': currency},
  );
}
