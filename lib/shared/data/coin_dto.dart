import '../../features/market/domain/coin.dart';

class CoinDto {
  const CoinDto(this.json);
  final Map<String, dynamic> json;

  Coin toEntity() {
    final data = json['data'] is Map
        ? Map<String, dynamic>.from(json['data'] as Map)
        : const <String, dynamic>{};
    final rawSparkline = json['sparkline_7d'] ?? data['sparkline_7d'];
    final rawRank = json['rank'] ?? json['market_cap_rank'];

    return Coin(
      id: json['id']?.toString() ?? '',
      symbol: json['symbol']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      image: (json['image'] ?? json['large'] ?? json['thumb'])?.toString(),
      rank: _number(rawRank)?.toInt(),
      price: _number(json['price'] ?? json['current_price'] ?? data['price']),
      marketCap: _number(json['market_cap'] ?? data['market_cap']),
      volume24h: _number(
        json['volume_24h'] ?? json['total_volume'] ?? data['total_volume'],
      ),
      change1hPct: _number(
        json['change_1h_pct'] ?? json['price_change_percentage_1h_in_currency'],
      ),
      change24hPct: _number(
        json['change_24h_pct'] ??
            _currencyValue(
              json['price_change_percentage_24h'] ??
                  data['price_change_percentage_24h'],
            ),
      ),
      change7dPct: _number(
        json['change_7d_pct'] ?? json['price_change_percentage_7d_in_currency'],
      ),
      change30dPct: _number(
        json['change_30d_pct'] ??
            json['price_change_percentage_30d_in_currency'],
      ),
      circulatingSupply: _number(json['circulating_supply']),
      totalSupply: _number(json['total_supply']),
      maxSupply: _number(json['max_supply']),
      sparkline7d: rawSparkline is List
          ? rawSparkline
                .whereType<num>()
                .map((value) => value.toDouble())
                .toList(growable: false)
          : const [],
      isWatchlisted: json['is_watchlisted'] == true,
    );
  }

  static dynamic _currencyValue(dynamic value) {
    if (value is! Map) return value;
    return value['usd'] ?? (value.isEmpty ? null : value.values.first);
  }

  static double? _number(dynamic value) {
    if (value is num) return value.toDouble();
    if (value is! String) return null;

    final normalized = value
        .trim()
        .replaceAll(',', '')
        .replaceFirst(RegExp(r'^[^\d.+-]+'), '');
    final match = RegExp(
      r'^([+-]?(?:\d+(?:\.\d*)?|\.\d+))\s*([KMBT]?)$',
      caseSensitive: false,
    ).firstMatch(normalized);
    if (match == null) return double.tryParse(normalized);

    final amount = double.tryParse(match.group(1)!);
    final multiplier = switch (match.group(2)?.toUpperCase()) {
      'K' => 1e3,
      'M' => 1e6,
      'B' => 1e9,
      'T' => 1e12,
      _ => 1.0,
    };
    return amount == null ? null : amount * multiplier;
  }
}
