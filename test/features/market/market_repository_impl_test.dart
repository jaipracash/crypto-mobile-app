import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gecko_lite/core/error/failure.dart';
import 'package:gecko_lite/features/market/data/market_remote_datasource.dart';
import 'package:gecko_lite/features/market/data/market_repository_impl.dart';
import 'package:gecko_lite/shared/data/coin_dto.dart';

class FakeMarketRemoteDataSource implements MarketRemoteDataSource {
  FakeMarketRemoteDataSource({this.fail = false});
  final bool fail;
  Map<String, dynamic>? coinQuery;

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
    coinQuery = query;
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
          'change_1h_pct': 0.1,
          'change_24h_pct': 2.4,
          'change_7d_pct': 4.8,
          'change_30d_pct': 12.0,
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
}

void main() {
  test('maps nested CoinGecko trending item data', () {
    final coin = const CoinDto({
      'id': 'bitcoin',
      'symbol': 'btc',
      'name': 'Bitcoin',
      'market_cap_rank': 1,
      'data': {
        'price': '\$67,420.15',
        'market_cap': '\$1.32T',
        'total_volume': '\$28.4B',
        'price_change_percentage_24h': {'usd': '2.4'},
      },
    }).toEntity();

    expect(coin.price, 67420.15);
    expect(coin.marketCap, 1.32e12);
    expect(coin.volume24h, 28.4e9);
    expect(coin.change24hPct, 2.4);
  });

  test('maps coin page DTOs and X-Data-Source header', () async {
    final remote = FakeMarketRemoteDataSource();
    final repository = MarketRepositoryImpl(remote);
    final page = await repository.getCoins(
      page: 1,
      perPage: 250,
      order: 'market_cap_desc',
      currency: 'usd',
      category: 'layer-1',
    );
    expect(page.items.single.id, 'bitcoin');
    expect(page.items.single.isWatchlisted, isTrue);
    expect(page.dataSource, 'mock');
    expect(page.hasMore, isFalse);
    expect(page.items.single.change1hPct, 0.1);
    expect(page.items.single.change24hPct, 2.4);
    expect(page.items.single.change7dPct, 4.8);
    expect(page.items.single.change30dPct, 12.0);
    expect(remote.coinQuery?['per_page'], 100);
    expect(remote.coinQuery?['category'], 'layer-1');
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
