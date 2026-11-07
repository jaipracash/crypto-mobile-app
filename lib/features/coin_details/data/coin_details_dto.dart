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
  const CoinChartDto(
    this.json,
    this.source, {
    required this.requestedCoinId,
    required this.requestedDays,
    required this.requestedCurrency,
  });
  final Map<String, dynamic> json;
  final String source;
  final String requestedCoinId;
  final int requestedDays;
  final String requestedCurrency;
  CoinChart toEntity() {
    final responseCoinId = json['coin_id']?.toString();
    if (responseCoinId != requestedCoinId) {
      throw FormatException('Chart response coin does not match the request.');
    }
    final responseDays = (json['days'] as num?)?.toInt();
    if (responseDays != requestedDays) {
      throw FormatException('Chart response range does not match the request.');
    }
    final responseCurrency = json['currency']?.toString().toLowerCase();
    if (responseCurrency != requestedCurrency.toLowerCase()) {
      throw FormatException(
        'Chart response currency does not match the request.',
      );
    }

    List<PricePoint> parsePoints(String key) =>
        (json[key] as List<dynamic>? ?? const [])
            .whereType<List<dynamic>>()
            .where(
              (point) =>
                  point.length >= 2 && point[0] is num && point[1] is num,
            )
            .map(
              (point) => PricePoint(
                DateTime.fromMillisecondsSinceEpoch((point[0] as num).toInt()),
                (point[1] as num).toDouble(),
              ),
            )
            .toList(growable: false);

    final candles = (json['ohlc'] as List<dynamic>? ?? const [])
        .whereType<List<dynamic>>()
        .where(
          (point) =>
              point.length >= 5 && point.take(5).every((value) => value is num),
        )
        .map(
          (point) => CandlePoint(
            timestamp: DateTime.fromMillisecondsSinceEpoch(
              (point[0] as num).toInt(),
            ),
            open: (point[1] as num).toDouble(),
            high: (point[2] as num).toDouble(),
            low: (point[3] as num).toDouble(),
            close: (point[4] as num).toDouble(),
          ),
        )
        .toList(growable: false);

    final points = parsePoints('prices');
    return CoinChart(
      coinId: json['coin_id']?.toString() ?? '',
      days: requestedDays,
      currency: requestedCurrency,
      prices: points,
      marketCaps: parsePoints('market_caps'),
      candles: candles,
      min: (json['min'] as num?)?.toDouble(),
      max: (json['max'] as num?)?.toDouble(),
      changePct: (json['change_pct'] as num?)?.toDouble(),
      dataSource: source,
    );
  }
}
