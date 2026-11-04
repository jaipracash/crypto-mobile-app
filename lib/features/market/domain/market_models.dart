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

class TrendingCoin extends Equatable {
  const TrendingCoin({
    required this.id,
    required this.name,
    required this.symbol,
    this.image,
    this.rank,
    this.priceBtc,
    this.dataSource = 'live',
  });
  final String id;
  final String name;
  final String symbol;
  final String? image;
  final int? rank;
  final double? priceBtc;
  final String dataSource;
  @override
  List<Object?> get props => [
    id,
    name,
    symbol,
    image,
    rank,
    priceBtc,
    dataSource,
  ];
}

class MarketMovers extends Equatable {
  const MarketMovers({
    required this.gainers,
    required this.losers,
    this.dataSource = 'live',
  });
  final List<Coin> gainers;
  final List<Coin> losers;
  final String dataSource;
  @override
  List<Object?> get props => [gainers, losers, dataSource];
}
