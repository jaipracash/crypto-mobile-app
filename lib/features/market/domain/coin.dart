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
    this.change24hPct,
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
  final double? change24hPct;
  final double? circulatingSupply;
  final double? totalSupply;
  final double? maxSupply;
  final List<double> sparkline7d;
  final bool isWatchlisted;

  Coin copyWith({bool? isWatchlisted}) => Coin(
    id: id,
    symbol: symbol,
    name: name,
    image: image,
    rank: rank,
    price: price,
    marketCap: marketCap,
    volume24h: volume24h,
    change24hPct: change24hPct,
    circulatingSupply: circulatingSupply,
    totalSupply: totalSupply,
    maxSupply: maxSupply,
    sparkline7d: sparkline7d,
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
    change24hPct,
    circulatingSupply,
    totalSupply,
    maxSupply,
    sparkline7d,
    isWatchlisted,
  ];
}
