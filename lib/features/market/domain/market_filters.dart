enum MarketSortField { marketCap, price, priceChange, volume }

class MarketFilters {
  const MarketFilters({
    this.topLimit = 100,
    this.marketCap = 'any',
    this.volume = 'any',
    this.price = 'any',
    this.sortField = MarketSortField.marketCap,
    this.ascending = false,
  });

  final int topLimit;
  final String marketCap;
  final String volume;
  final String price;
  final MarketSortField sortField;
  final bool ascending;

  int get activeCount => [
    topLimit != 100,
    marketCap != 'any',
    volume != 'any',
    price != 'any',
  ].where((active) => active).length;

  MarketFilters copyWith({
    int? topLimit,
    String? marketCap,
    String? volume,
    String? price,
    MarketSortField? sortField,
    bool? ascending,
  }) => MarketFilters(
    topLimit: topLimit ?? this.topLimit,
    marketCap: marketCap ?? this.marketCap,
    volume: volume ?? this.volume,
    price: price ?? this.price,
    sortField: sortField ?? this.sortField,
    ascending: ascending ?? this.ascending,
  );

  MarketFilters reset() => const MarketFilters();
}
