import 'market_models.dart';

abstract class MarketRepository {
  Future<CoinPage> getCoins({
    required int page,
    required int perPage,
    required String order,
    required String currency,
    String? category,
  });
  Future<List<SearchCoin>> search(String query);
  Future<MarketSnapshot> getGlobal(String currency);
  Future<TrendingData> getTrending();
}
