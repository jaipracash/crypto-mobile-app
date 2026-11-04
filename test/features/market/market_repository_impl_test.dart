import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gecko_lite/core/error/failure.dart';
import 'package:gecko_lite/features/market/data/market_remote_datasource.dart';
import 'package:gecko_lite/features/market/data/market_repository_impl.dart';

class FakeMarketRemoteDataSource implements MarketRemoteDataSource {
  FakeMarketRemoteDataSource({this.fail = false});
  final bool fail;

  Response<dynamic> _response(Object data) => Response<dynamic>(
    requestOptions: RequestOptions(path: '/api/coins'),
    data: data,
    headers: Headers.fromMap({
      'x-data-source': ['mock'],
    }),
  );

  void _maybeFail() {
    if (fail) {
      throw DioException(
        requestOptions: RequestOptions(path: '/api/coins'),
        type: DioExceptionType.connectionError,
      );
    }
  }

  @override
  Future<Response<dynamic>> getCoins(Map<String, dynamic> query) async {
    _maybeFail();
    return _response({
      'page': query['page'],
      'per_page': query['per_page'],
      'has_more': false,
      'data_source': 'mock',
      'items': [
        {
          'id': 'bitcoin',
          'symbol': 'btc',
          'name': 'Bitcoin',
          'rank': 1,
          'price': 100,
          'sparkline_7d': [98, 100],
          'is_watchlisted': true,
        },
      ],
    });
  }

  @override
  Future<Map<String, dynamic>> search(String query) async => {
    'query': query,
    'items': [],
  };

  @override
  Future<Response<dynamic>> getGlobal(String currency) async => _response({});

  @override
  Future<Response<dynamic>> getTrending() async => _response({'items': []});

  @override
  Future<Response<dynamic>> getMovers(int limit, String currency) async =>
      _response({'gainers': [], 'losers': []});
}

void main() {
  test('maps coin page DTOs and X-Data-Source header', () async {
    final repository = MarketRepositoryImpl(FakeMarketRemoteDataSource());
    final page = await repository.getCoins(
      page: 1,
      perPage: 20,
      order: 'market_cap_desc',
      currency: 'usd',
    );
    expect(page.items.single.id, 'bitcoin');
    expect(page.items.single.isWatchlisted, isTrue);
    expect(page.dataSource, 'mock');
    expect(page.hasMore, isFalse);
  });

  test('converts network errors to a typed Failure', () async {
    final repository = MarketRepositoryImpl(
      FakeMarketRemoteDataSource(fail: true),
    );
    await expectLater(
      repository.getCoins(
        page: 1,
        perPage: 20,
        order: 'market_cap_desc',
        currency: 'usd',
      ),
      throwsA(
        isA<Failure>().having(
          (failure) => failure.type,
          'type',
          FailureType.noInternet,
        ),
      ),
    );
  });
}
