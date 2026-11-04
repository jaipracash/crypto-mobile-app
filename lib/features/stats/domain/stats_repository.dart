import '../../market/domain/market_models.dart';

abstract class StatsRepository {
  Future<MarketSnapshot> getSnapshot(String currency);
  Future<MarketMovers> getMovers(String currency);
  Future<List<TrendingCoin>> getTrending();
}
