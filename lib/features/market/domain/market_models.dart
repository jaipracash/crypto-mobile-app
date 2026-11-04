import 'package:equatable/equatable.dart';

import 'coin.dart';

class CoinPage extends Equatable {
  const CoinPage({
    required this.items,
    required this.page,
    required this.hasMore,
    required this.dataSource,
  });
  final List<Coin> items;
  final int page;
  final bool hasMore;
  final String dataSource;
  @override
  List<Object?> get props => [items, page, hasMore, dataSource];
}

class SearchCoin extends Equatable {
  const SearchCoin({
    required this.id,
    required this.symbol,
    required this.name,
    this.image,
    this.rank,
  });
  final String id;
  final String symbol;
  final String name;
  final String? image;
  final int? rank;
  @override
  List<Object?> get props => [id, symbol, name, image, rank];
}

class MarketSnapshot extends Equatable {
  const MarketSnapshot({
    this.totalMarketCap,
    this.totalVolume24h,
    this.marketCapChange24hPct,
    this.btcDominance,
    this.ethDominance,
    this.othersDominance,
    this.activeCoins,
    this.dataSource = 'live',
  });
  final double? totalMarketCap;
  final double? totalVolume24h;
  final double? marketCapChange24hPct;
  final double? btcDominance;
  final double? ethDominance;
  final double? othersDominance;
  final int? activeCoins;
  final String dataSource;
  @override
  List<Object?> get props => [
    totalMarketCap,
    totalVolume24h,
    marketCapChange24hPct,
    btcDominance,
    ethDominance,
    othersDominance,
    activeCoins,
    dataSource,
  ];
}

class TrendingData extends Equatable {
  const TrendingData({required this.items, this.dataSource = 'live'});
  final List<Coin> items;
  final String dataSource;
  @override
  List<Object?> get props => [items, dataSource];
}
