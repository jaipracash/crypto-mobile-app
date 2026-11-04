import '../domain/coin.dart';

class CoinDto {
  const CoinDto(this.json);
  final Map<String, dynamic> json;

  Coin toEntity() => Coin(
    id: json['id']?.toString() ?? '',
    symbol: json['symbol']?.toString() ?? '',
    name: json['name']?.toString() ?? '',
    image: json['image']?.toString(),
    rank: (json['rank'] as num?)?.toInt(),
    price: (json['price'] as num?)?.toDouble(),
    marketCap: (json['market_cap'] as num?)?.toDouble(),
    volume24h: (json['volume_24h'] as num?)?.toDouble(),
    change1hPct: (json['change_1h_pct'] as num?)?.toDouble(),
    change24hPct: (json['change_24h_pct'] as num?)?.toDouble(),
    change7dPct: (json['change_7d_pct'] as num?)?.toDouble(),
    change30dPct: (json['change_30d_pct'] as num?)?.toDouble(),
    circulatingSupply: (json['circulating_supply'] as num?)?.toDouble(),
    totalSupply: (json['total_supply'] as num?)?.toDouble(),
    maxSupply: (json['max_supply'] as num?)?.toDouble(),
    sparkline7d: (json['sparkline_7d'] as List<dynamic>? ?? const [])
        .whereType<num>()
        .map((value) => value.toDouble())
        .toList(growable: false),
    isWatchlisted: json['is_watchlisted'] == true,
  );
}
