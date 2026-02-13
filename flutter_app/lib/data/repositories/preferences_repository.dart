import 'package:shared_preferences/shared_preferences.dart';

import 'package:ai_journal/core/constants/api_constants.dart';
import 'package:ai_journal/data/data_sources/remote/api_client.dart';

/// Keys for local theme cache (survives hot reload and app restarts).
const String _keyTheme = 'pref_theme';
const String _keyColorTheme = 'pref_color_theme';

class PreferencesRepository {
  PreferencesRepository({
    ApiClient? apiClient,
    SharedPreferences? sharedPreferences,
  })  : _api = apiClient ?? ApiClient(),
        _prefs = sharedPreferences;

  final ApiClient _api;
  SharedPreferences? _prefs;

  Future<void> init() async {
    await _api.init();
    _prefs ??= await SharedPreferences.getInstance();
  }

  /// Load theme from local storage only (fast; used so first paint uses saved theme).
  Future<Map<String, String?>> getLocalTheme() async {
    final prefs = _prefs ?? await SharedPreferences.getInstance();
    return {
      'theme': prefs.getString(_keyTheme),
      'color_theme': prefs.getString(_keyColorTheme),
    };
  }

  /// Persist theme locally so it survives hot reload and app updates.
  Future<void> saveLocalTheme({String? theme, String? colorTheme}) async {
    final prefs = _prefs ?? await SharedPreferences.getInstance();
    if (theme != null) await prefs.setString(_keyTheme, theme);
    if (colorTheme != null) await prefs.setString(_keyColorTheme, colorTheme);
  }

  Future<Map<String, dynamic>> getPreferences() async {
    final data = await _api.get(ApiConstants.userPreferences);
    return data;
  }

  Future<Map<String, dynamic>> updatePreferences({
    String? theme,
    String? colorTheme,
    bool? reminderEnabled,
  }) async {
    final body = <String, dynamic>{};
    if (theme != null) body['theme'] = theme;
    if (colorTheme != null) body['color_theme'] = colorTheme;
    if (reminderEnabled != null) body['reminder_enabled'] = reminderEnabled;
    if (body.isEmpty) return getPreferences();
    final data = await _api.put(ApiConstants.userPreferences, body);
    if (theme != null || colorTheme != null) {
      await saveLocalTheme(theme: theme, colorTheme: colorTheme);
    }
    return data;
  }
}
