import 'coin_details.dart';

abstract class CoinDetailsRepository {
  Future<CoinDetails> getDetails(String coinId, String currency);
  Future<CoinChart> getChart(String coinId, int days, String currency);
}
