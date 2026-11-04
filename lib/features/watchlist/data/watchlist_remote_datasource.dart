import 'package:dio/dio.dart';

abstract class WatchlistRemoteDataSource {
  Future<Response<dynamic>> getWatchlist(String currency);
  Future<void> add(String coinId);
  Future<void> remove(String coinId);
}

class WatchlistRemoteDataSourceImpl implements WatchlistRemoteDataSource {
  const WatchlistRemoteDataSourceImpl(this._dio);
  final Dio _dio;
  @override
  Future<Response<dynamic>> getWatchlist(String currency) => _dio.get<dynamic>(
    '/api/watchlist',
    queryParameters: {'currency': currency},
  );
  @override
  Future<void> add(String coinId) async =>
      _dio.post<dynamic>('/api/watchlist/$coinId');
  @override
  Future<void> remove(String coinId) async =>
      _dio.delete<dynamic>('/api/watchlist/$coinId');
}
