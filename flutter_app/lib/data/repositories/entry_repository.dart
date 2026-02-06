import 'package:ai_journal/core/constants/api_constants.dart';
import 'package:ai_journal/data/data_sources/remote/api_client.dart';
import 'package:ai_journal/data/models/entry_model.dart';

class EntryRepository {
  EntryRepository({ApiClient? apiClient}) : _api = apiClient ?? ApiClient();

  final ApiClient _api;

  Future<void> init() => _api.init();

  /// Create or save a journal entry.
  Future<EntryModel> createEntry({
    required String content,
    String? title,
    String? mood,
    bool isDraft = true,
    List<String>? tags,
  }) async {
    final now = DateTime.now();
    final data = await _api.post(ApiConstants.entries, {
      'content': content,
      'title': title,
      'mood': mood,
      'is_draft': isDraft,
      'entry_date': '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}',
      'entry_time': '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:00',
      if (tags != null) 'tags': tags,
    });
    return EntryModel.fromJson(data);
  }

  /// Get an AI-generated journaling prompt (inspiration).
  Future<String> getInspirationPrompt() async {
    final data = await _api.post(ApiConstants.aiGeneratePrompt, {});
    return data['prompt'] as String? ?? 'What are you grateful for today?';
  }
}
