abstract final class ApiConstants {
  static const apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://crypto-api-hyqi.onrender.com',
  );
  static const requestTimeout = Duration(seconds: 15);
  static const connectTimeout = Duration(seconds: 8);
  static const defaultPageSize = 50;
  static const maxPageSize = 100;
}
