enum MarketSortField { marketCap, price, priceChange, volume }

class MarketFilters {
  const MarketFilters({
    this.category,
    this.marketCap = 'any',
    this.volume = 'any',
    this.price = 'any',
    this.sortField = MarketSortField.marketCap,
    this.ascending = false,
    this.watchlistedOnly = false,
    this.hideStablecoins = false,
  });

  final String? category;
  final String marketCap;
  final String volume;
  final String price;
  final MarketSortField sortField;
  final bool ascending;
  final bool watchlistedOnly;
  final bool hideStablecoins;

  int get activeCount => [
    category != null,
    marketCap != 'any',
    volume != 'any',
    price != 'any',
    sortField != MarketSortField.marketCap || ascending,
    watchlistedOnly,
    hideStablecoins,
  ].where((active) => active).length;

  MarketFilters copyWith({
    String? category,
    bool clearCategory = false,
    String? marketCap,
    String? volume,
    String? price,
    MarketSortField? sortField,
    bool? ascending,
    bool? watchlistedOnly,
    bool? hideStablecoins,
  }) => MarketFilters(
    category: clearCategory ? null : category ?? this.category,
    marketCap: marketCap ?? this.marketCap,
    volume: volume ?? this.volume,
    price: price ?? this.price,
    sortField: sortField ?? this.sortField,
    ascending: ascending ?? this.ascending,
    watchlistedOnly: watchlistedOnly ?? this.watchlistedOnly,
    hideStablecoins: hideStablecoins ?? this.hideStablecoins,
  );

  MarketFilters reset() => const MarketFilters();
}
