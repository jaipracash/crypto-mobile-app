import '../domain/market_models.dart';
import '../domain/coin.dart';
import 'coin_dto.dart';

class CoinPageDto {
  const CoinPageDto(this.json, this.dataSource);
  final Map<String, dynamic> json;
  final String dataSource;

  CoinPage toEntity() => CoinPage(
    items: (json['items'] as List<dynamic>? ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(CoinDto.new)
        .map((dto) => dto.toEntity())
        .toList(growable: false),
    page: (json['page'] as num?)?.toInt() ?? 1,
    hasMore: json['has_more'] == true,
    dataSource: json['data_source']?.toString() ?? dataSource,
  );
}

class SearchCoinDto {
  const SearchCoinDto(this.json);
  final Map<String, dynamic> json;
  SearchCoin toEntity() => SearchCoin(
    id: json['id']?.toString() ?? '',
    symbol: json['symbol']?.toString() ?? '',
    name: json['name']?.toString() ?? '',
    image: json['image']?.toString(),
    rank: (json['rank'] as num?)?.toInt(),
  );
}

class MarketSnapshotDto {
  const MarketSnapshotDto(this.json, this.source);
  final Map<String, dynamic> json;
  final String source;
  MarketSnapshot toEntity() => MarketSnapshot(
    totalMarketCap: (json['total_market_cap'] as num?)?.toDouble(),
    totalVolume24h: (json['total_volume_24h'] as num?)?.toDouble(),
    marketCapChange24hPct: (json['market_cap_change_24h_pct'] as num?)
        ?.toDouble(),
    btcDominance: (json['btc_dominance'] as num?)?.toDouble(),
    ethDominance: (json['eth_dominance'] as num?)?.toDouble(),
    othersDominance: (json['others_dominance'] as num?)?.toDouble(),
    activeCoins: (json['active_coins'] as num?)?.toInt(),
    dataSource: source,
  );
}

class TrendingCoinDto {
  const TrendingCoinDto(this.json, this.source);
  final Map<String, dynamic> json;
  final String source;
  TrendingCoin toEntity() => TrendingCoin(
    id: json['id']?.toString() ?? '',
    name: json['name']?.toString() ?? '',
    symbol: json['symbol']?.toString() ?? '',
    image: json['image']?.toString(),
    rank: (json['rank'] as num?)?.toInt(),
    priceBtc: (json['price_btc'] as num?)?.toDouble(),
    dataSource: source,
  );
}

class MarketMoversDto {
  const MarketMoversDto(this.json, this.source);
  final Map<String, dynamic> json;
  final String source;
  MarketMovers toEntity() => MarketMovers(
    gainers: _coins(json['gainers']),
    losers: _coins(json['losers']),
    dataSource: source,
  );

  List<Coin> _coins(dynamic rows) => (rows as List<dynamic>? ?? const [])
      .whereType<Map<String, dynamic>>()
      .map(CoinDto.new)
      .map((dto) => dto.toEntity())
      .toList(growable: false);
}
