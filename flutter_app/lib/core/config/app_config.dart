import 'package:flutter_dotenv/flutter_dotenv.dart';

/// App-wide configuration. API base URL is read from assets/.env (API_BASE_URL).
class AppConfig {
  AppConfig._();

  /// Backend base URL (no trailing slash). Set in flutter_app/assets/.env as API_BASE_URL.
  static String get apiBaseUrl =>
      dotenv.env['API_BASE_URL'] ?? 'http://localhost:8000';

  /// Optional Supabase project URL (e.g. https://xxx.supabase.co) for storage image URLs.
  /// If set, journal media URLs from the API are rewritten to use this host so images load
  /// even when the backend has a different or placeholder SUPABASE_URL.
  /// Strips surrounding quotes so SUPABASE_URL="https://..." in .env works.
  static String? get supabaseUrl {
    String? s = dotenv.env['SUPABASE_URL']?.trim();
    if (s == null || s.isEmpty) return null;
    // Strip optional surrounding quotes (e.g. from .env: SUPABASE_URL="https://...")
    if (s.length >= 2 && (s.startsWith('"') && s.endsWith('"') || s.startsWith("'") && s.endsWith("'"))) {
      s = s.substring(1, s.length - 1).trim();
    }
    if (s.isEmpty) return null;
    return s.replaceFirst(RegExp(r'/$'), '');
  }

  /// Rewrite a storage URL to use [supabaseUrl] if set. Use for all entry media images.
  /// When [supabaseUrl] is null, returns [url] unchanged (backend URL is used).
  /// Set SUPABASE_URL in assets/.env to your Supabase project URL (e.g. https://xxxxx.supabase.co)
  /// so images load; use the same value as in your backend .env.
  static String rewriteMediaUrl(String url) {
    final raw = url.trim();
    if (raw.isEmpty) return url;
    // Use URL as-is when it's already a valid Supabase storage URL (same as profile picture).
    if (raw.startsWith('http') &&
        raw.contains('supabase.co') &&
        raw.contains('/storage/v1/object/public/')) {
      return raw;
    }
    final base = supabaseUrl;
    if (base == null || base.isEmpty) return raw;
    try {
      final uri = Uri.parse(raw);
      if (!uri.path.contains('/storage/v1/object/public/')) return raw;
      final origin = base.startsWith('http') ? base : 'https://$base';
      final baseUri = Uri.parse(origin);
      // Omit port when it's the default (443/80) so URL is clean and CDNs don't reject
      final port = baseUri.port;
      final isDefaultPort = (baseUri.scheme == 'https' && port == 443) ||
          (baseUri.scheme == 'http' && port == 80);
      final rewritten = Uri(
        scheme: baseUri.scheme,
        host: baseUri.host,
        port: isDefaultPort ? -1 : port,
        path: uri.path,
        query: uri.query.isEmpty ? null : uri.query,
        fragment: uri.fragment.isEmpty ? null : uri.fragment,
      );
      return rewritten.toString();
    } catch (_) {
      return raw;
    }
  }

  static const String apiV1Prefix = '/api/v1';
  static const String appName = 'AI Journal';
}
