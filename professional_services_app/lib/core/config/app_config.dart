abstract class AppConfig {
  static const String appName = 'TOKLEN';

  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://127.0.0.1:8002', // Modificado para hacer match exacto con FastAPI
  );
}
