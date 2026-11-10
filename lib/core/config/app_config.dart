// ============================================
// All app settings in one place. Network code (Sprint 1) will get
// the URL and timeouts from here instead of defining its own values.
// ============================================
class AppConfig {
  // Private constructor: prevents unnecessary instances of AppConfig.
  // This class only contains static values, so it doesn't need instances.
  AppConfig._();

  // ============================================
  // String.fromEnvironment: inject a value from outside at build time.
  //   flutter run --dart-define=API_BASE_URL=https://staging.example.com
  // If no value is provided, defaultValue (our DummyJSON URL) is used.
  // This allows switching between Dev, Staging, and Production servers without code changes.
  // ============================================
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://dummyjson.com',
  );

  // Maximum time to establish a connection (reach the server).
  static const Duration connectTimeout = Duration(seconds: 10);

  // Maximum time to wait for a response after connecting.
  static const Duration receiveTimeout = Duration(seconds: 15);
}
