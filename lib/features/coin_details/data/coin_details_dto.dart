import '../../market/data/coin_dto.dart';
import '../domain/coin_details.dart';

class CoinDetailsDto {
  const CoinDetailsDto(this.json, this.source);
  final Map<String, dynamic> json;
  final String source;
  CoinDetails toEntity() => CoinDetails(
    coin: CoinDto(json).toEntity(),
    high24h: (json['high_24h'] as num?)?.toDouble(),
    low24h: (json['low_24h'] as num?)?.toDouble(),
    ath: (json['ath'] as num?)?.toDouble(),
    athChangePct: (json['ath_change_pct'] as num?)?.toDouble(),
    athDate: DateTime.tryParse(json['ath_date']?.toString() ?? ''),
    atl: (json['atl'] as num?)?.toDouble(),
    atlChangePct: (json['atl_change_pct'] as num?)?.toDouble(),
    atlDate: DateTime.tryParse(json['atl_date']?.toString() ?? ''),
    description: json['description']?.toString() ?? '',
    website: (json['links'] as Map<String, dynamic>?)?['website']?.toString(),
    whitepaper: (json['links'] as Map<String, dynamic>?)?['whitepaper']
        ?.toString(),
    dataSource: source,
  );
}

class CoinChartDto {
  const CoinChartDto(this.json, this.source);
  final Map<String, dynamic> json;
  final String source;
  CoinChart toEntity() {
    final points = (json['prices'] as List<dynamic>? ?? const [])
        .whereType<List<dynamic>>()
        .where(
          (point) => point.length >= 2 && point[0] is num && point[1] is num,
        )
        .map(
          (point) => PricePoint(
            DateTime.fromMillisecondsSinceEpoch((point[0] as num).toInt()),
            (point[1] as num).toDouble(),
          ),
        )
        .toList(growable: false);
    return CoinChart(
      coinId: json['coin_id']?.toString() ?? '',
      days: (json['days'] as num?)?.toInt() ?? 7,
      currency: json['currency']?.toString() ?? 'usd',
      prices: points,
      min: (json['min'] as num?)?.toDouble(),
      max: (json['max'] as num?)?.toDouble(),
      changePct: (json['change_pct'] as num?)?.toDouble(),
      dataSource: source,
    );
  }
}
