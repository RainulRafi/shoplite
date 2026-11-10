class AppConfig {

  AppConfig._();

  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://dummyjson.com',
  );

  // Maximum time to establish a connection (reach the server).
  static const Duration connectTimeout = Duration(seconds: 10);

  // Maximum time to wait for a response after connecting.
  static const Duration receiveTimeout = Duration(seconds: 15);
}
