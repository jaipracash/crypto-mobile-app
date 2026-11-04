import 'package:equatable/equatable.dart';

import '../../market/domain/coin.dart';

class WatchlistData extends Equatable {
  const WatchlistData({required this.items, required this.dataSource});
  final List<Coin> items;
  final String dataSource;
  @override
  List<Object?> get props => [items, dataSource];
}

abstract class WatchlistRepository {
  Future<WatchlistData> getWatchlist(String currency);
  Future<void> add(String coinId);
  Future<void> remove(String coinId);
}
