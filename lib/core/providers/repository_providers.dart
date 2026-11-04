import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/coin_details/data/coin_details_remote_datasource.dart';
import '../../features/coin_details/data/coin_details_repository_impl.dart';
import '../../features/coin_details/domain/coin_details_repository.dart';
import '../../features/market/data/market_remote_datasource.dart';
import '../../features/market/data/market_repository_impl.dart';
import '../../features/market/domain/market_repository.dart';
import '../../features/settings/data/settings_repository_impl.dart';
import '../../features/settings/domain/settings_repository.dart';
import '../../features/watchlist/data/watchlist_remote_datasource.dart';
import '../../features/watchlist/data/watchlist_repository_impl.dart';
import '../../features/watchlist/domain/watchlist_repository.dart';
import 'core_providers.dart';

final marketRemoteDataSourceProvider = Provider<MarketRemoteDataSource>(
  (ref) => MarketRemoteDataSourceImpl(ref.watch(dioProvider).dio),
);
final marketRepositoryProvider = Provider<MarketRepository>(
  (ref) => MarketRepositoryImpl(ref.watch(marketRemoteDataSourceProvider)),
);

final coinDetailsRemoteDataSourceProvider =
    Provider<CoinDetailsRemoteDataSource>(
      (ref) => CoinDetailsRemoteDataSourceImpl(ref.watch(dioProvider).dio),
    );
final coinDetailsRepositoryProvider = Provider<CoinDetailsRepository>(
  (ref) =>
      CoinDetailsRepositoryImpl(ref.watch(coinDetailsRemoteDataSourceProvider)),
);

final watchlistRemoteDataSourceProvider = Provider<WatchlistRemoteDataSource>(
  (ref) => WatchlistRemoteDataSourceImpl(ref.watch(dioProvider).dio),
);
final watchlistRepositoryProvider = Provider<WatchlistRepository>(
  (ref) =>
      WatchlistRepositoryImpl(ref.watch(watchlistRemoteDataSourceProvider)),
);

final settingsRepositoryProvider = Provider<SettingsRepository>(
  (ref) => SettingsRepositoryImpl(ref.watch(sharedPreferencesProvider)),
);
