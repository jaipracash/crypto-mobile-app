import 'package:equatable/equatable.dart';

class Coin extends Equatable {
  const Coin({
    required this.id,
    required this.symbol,
    required this.name,
    this.image,
    this.rank,
    this.price,
    this.marketCap,
    this.volume24h,
    this.change1hPct,
    this.change24hPct,
    this.change7dPct,
    this.change30dPct,
    this.circulatingSupply,
    this.totalSupply,
    this.maxSupply,
    this.sparkline7d = const [],
    this.isWatchlisted = false,
  });

  final String id;
  final String symbol;
  final String name;
  final String? image;
  final int? rank;
  final double? price;
  final double? marketCap;
  final double? volume24h;
  final double? change1hPct;
  final double? change24hPct;
  final double? change7dPct;
  final double? change30dPct;
  final double? circulatingSupply;
  final double? totalSupply;
  final double? maxSupply;
  final List<double> sparkline7d;
  final bool isWatchlisted;

  Coin copyWith({
    String? id,
    String? symbol,
    String? name,
    String? image,
    int? rank,
    double? price,
    double? marketCap,
    double? volume24h,
    double? change1hPct,
    double? change24hPct,
    double? change7dPct,
    double? change30dPct,
    double? circulatingSupply,
    double? totalSupply,
    double? maxSupply,
    List<double>? sparkline7d,
    bool? isWatchlisted,
  }) => Coin(
    id: id ?? this.id,
    symbol: symbol ?? this.symbol,
    name: name ?? this.name,
    image: image ?? this.image,
    rank: rank ?? this.rank,
    price: price ?? this.price,
    marketCap: marketCap ?? this.marketCap,
    volume24h: volume24h ?? this.volume24h,
    change1hPct: change1hPct ?? this.change1hPct,
    change24hPct: change24hPct ?? this.change24hPct,
    change7dPct: change7dPct ?? this.change7dPct,
    change30dPct: change30dPct ?? this.change30dPct,
    circulatingSupply: circulatingSupply ?? this.circulatingSupply,
    totalSupply: totalSupply ?? this.totalSupply,
    maxSupply: maxSupply ?? this.maxSupply,
    sparkline7d: sparkline7d ?? this.sparkline7d,
    isWatchlisted: isWatchlisted ?? this.isWatchlisted,
  );

  @override
  List<Object?> get props => [
    id,
    symbol,
    name,
    image,
    rank,
    price,
    marketCap,
    volume24h,
    change1hPct,
    change24hPct,
    change7dPct,
    change30dPct,
    circulatingSupply,
    totalSupply,
    maxSupply,
    sparkline7d,
    isWatchlisted,
  ];
}
