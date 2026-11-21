class AppConfig {
  AppConfig._();

  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://dummyjson.com',
  );

  static const Duration connectTimeout = Duration(seconds: 10);

  static const Duration receiveTimeout = Duration(seconds: 15);

  // --dart-define=ACCESS_TOKEN_MINUTES=1
  static const int accessTokenMinutes = int.fromEnvironment(
    'ACCESS_TOKEN_MINUTES',
    defaultValue: 60,
  );
}
