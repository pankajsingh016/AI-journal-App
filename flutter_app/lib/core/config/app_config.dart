import 'package:flutter_dotenv/flutter_dotenv.dart';

/// App-wide configuration. API base URL is read from assets/.env (API_BASE_URL).
class AppConfig {
  AppConfig._();

  /// Backend base URL (no trailing slash). Set in flutter_app/assets/.env as API_BASE_URL.
  static String get apiBaseUrl =>
      dotenv.env['API_BASE_URL'] ?? 'http://localhost:8000';

  static const String apiV1Prefix = '/api/v1';
  static const String appName = 'AI Journal';
}
