import 'package:equatable/equatable.dart';

import '../../market/domain/coin.dart';

class CoinDetails extends Equatable {
  const CoinDetails({
    required this.coin,
    this.high24h,
    this.low24h,
    this.ath,
    this.athChangePct,
    this.athDate,
    this.atl,
    this.atlChangePct,
    this.atlDate,
    this.description = '',
    this.website,
    this.whitepaper,
    this.dataSource = 'live',
  });

  final Coin coin;
  final double? high24h;
  final double? low24h;
  final double? ath;
  final double? athChangePct;
  final DateTime? athDate;
  final double? atl;
  final double? atlChangePct;
  final DateTime? atlDate;
  final String description;
  final String? website;
  final String? whitepaper;
  final String dataSource;

  @override
  List<Object?> get props => [
    coin,
    high24h,
    low24h,
    ath,
    athChangePct,
    athDate,
    atl,
    atlChangePct,
    atlDate,
    description,
    website,
    whitepaper,
    dataSource,
  ];
}

class PricePoint extends Equatable {
  const PricePoint(this.timestamp, this.price);
  final DateTime timestamp;
  final double price;
  @override
  List<Object?> get props => [timestamp, price];
}

class CandlePoint extends Equatable {
  const CandlePoint({
    required this.timestamp,
    required this.open,
    required this.high,
    required this.low,
    required this.close,
  });

  final DateTime timestamp;
  final double open;
  final double high;
  final double low;
  final double close;

  @override
  List<Object?> get props => [timestamp, open, high, low, close];
}

class CoinChart extends Equatable {
  const CoinChart({
    required this.coinId,
    required this.days,
    required this.currency,
    required this.prices,
    this.marketCaps = const [],
    this.candles = const [],
    this.min,
    this.max,
    this.changePct,
    this.dataSource = 'live',
  });
  final String coinId;
  final int days;
  final String currency;
  final List<PricePoint> prices;
  final List<PricePoint> marketCaps;
  final List<CandlePoint> candles;
  final double? min;
  final double? max;
  final double? changePct;
  final String dataSource;
  @override
  List<Object?> get props => [
    coinId,
    days,
    currency,
    prices,
    marketCaps,
    candles,
    min,
    max,
    changePct,
    dataSource,
  ];
}
