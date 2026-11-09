import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gecko_lite/core/error/failure.dart';
import 'package:gecko_lite/features/watchlist/data/watchlist_remote_datasource.dart';
import 'package:gecko_lite/features/watchlist/data/watchlist_repository_impl.dart';

class _FakeWatchlistRemoteDataSource implements WatchlistRemoteDataSource {
  _FakeWatchlistRemoteDataSource({this.fail = false});

  final bool fail;

  @override
  Future<Response<dynamic>> getWatchlist(String currency) async {
    if (fail) {
      throw DioException(
        requestOptions: RequestOptions(path: '/api/watchlist'),
        type: DioExceptionType.connectionError,
      );
    }
    return Response<dynamic>(
      requestOptions: RequestOptions(path: '/api/watchlist'),
      data: {
        'items': [
          {'id': 'bitcoin', 'symbol': 'btc', 'name': 'Bitcoin', 'price': 50000},
        ],
      },
      headers: Headers.fromMap({
        'x-data-source': ['mock'],
      }),
    );
  }

  @override
  Future<void> add(String coinId) async {}

  @override
  Future<void> remove(String coinId) async {}
}

void main() {
  test('maps watchlist coins and data source', () async {
    final repository = WatchlistRepositoryImpl(
      _FakeWatchlistRemoteDataSource(),
    );

    final watchlist = await repository.getWatchlist('usd');

    expect(watchlist.items.single.id, 'bitcoin');
    expect(watchlist.items.single.price, 50000);
    expect(watchlist.dataSource, 'mock');
  });

  test('maps watchlist network errors to a typed failure', () async {
    final repository = WatchlistRepositoryImpl(
      _FakeWatchlistRemoteDataSource(fail: true),
    );

    await expectLater(
      repository.getWatchlist('usd'),
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
