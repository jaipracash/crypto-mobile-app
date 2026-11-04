import 'package:dio/dio.dart';

abstract class MarketRemoteDataSource {
  Future<Response<dynamic>> getCoins(Map<String, dynamic> query);
  Future<Map<String, dynamic>> search(String query);
  Future<Response<dynamic>> getGlobal(String currency);
  Future<Response<dynamic>> getTrending();
  Future<Response<dynamic>> getMovers(int limit, String currency);
}

class MarketRemoteDataSourceImpl implements MarketRemoteDataSource {
  const MarketRemoteDataSourceImpl(this._dio);
  final Dio _dio;

  @override
  Future<Response<dynamic>> getCoins(Map<String, dynamic> query) =>
      _dio.get<dynamic>('/api/coins', queryParameters: query);

  @override
  Future<Map<String, dynamic>> search(String query) async =>
      (await _dio.get<Map<String, dynamic>>(
        '/api/search',
        queryParameters: {'q': query},
      )).data!;

  @override
  Future<Response<dynamic>> getGlobal(String currency) => _dio.get<dynamic>(
    '/api/market/global',
    queryParameters: {'currency': currency},
  );

  @override
  Future<Response<dynamic>> getTrending() =>
      _dio.get<dynamic>('/api/market/trending');

  @override
  Future<Response<dynamic>> getMovers(int limit, String currency) =>
      _dio.get<dynamic>(
        '/api/market/movers',
        queryParameters: {'limit': limit, 'currency': currency},
      );
}
