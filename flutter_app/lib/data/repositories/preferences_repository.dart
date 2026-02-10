import 'package:ai_journal/core/constants/api_constants.dart';
import 'package:ai_journal/data/data_sources/remote/api_client.dart';

class PreferencesRepository {
  PreferencesRepository({ApiClient? apiClient}) : _api = apiClient ?? ApiClient();

  final ApiClient _api;

  Future<void> init() => _api.init();

  Future<Map<String, dynamic>> getPreferences() async {
    final data = await _api.get(ApiConstants.userPreferences);
    return data;
  }

  Future<Map<String, dynamic>> updatePreferences({
    String? theme,
    bool? reminderEnabled,
  }) async {
    final body = <String, dynamic>{};
    if (theme != null) body['theme'] = theme;
    if (reminderEnabled != null) body['reminder_enabled'] = reminderEnabled;
    if (body.isEmpty) return getPreferences();
    final data = await _api.put(ApiConstants.userPreferences, body);
    return data;
  }
}
