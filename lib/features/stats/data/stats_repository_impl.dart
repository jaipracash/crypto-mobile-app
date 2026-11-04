import '../../market/domain/market_models.dart';
import '../../market/domain/market_repository.dart';
import '../domain/stats_repository.dart';

class StatsRepositoryImpl implements StatsRepository {
  const StatsRepositoryImpl(this._marketRepository);
  final MarketRepository _marketRepository;

  @override
  Future<MarketSnapshot> getSnapshot(String currency) =>
      _marketRepository.getGlobal(currency);

  @override
  Future<MarketMovers> getMovers(String currency) =>
      _marketRepository.getMovers(limit: 5, currency: currency);

  @override
  Future<List<TrendingCoin>> getTrending() => _marketRepository.getTrending();
}
