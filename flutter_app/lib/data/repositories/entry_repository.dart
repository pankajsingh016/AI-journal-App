import 'package:ai_journal/core/constants/api_constants.dart';
import 'package:ai_journal/data/data_sources/remote/api_client.dart';
import 'package:ai_journal/data/models/entry_model.dart';

class EntryRepository {
  EntryRepository({ApiClient? apiClient}) : _api = apiClient ?? ApiClient();

  final ApiClient _api;

  Future<void> init() => _api.init();

  /// Create a journal entry (draft or published).
  Future<EntryModel> createEntry({
    required String content,
    String? title,
    String? mood,
    bool isDraft = true,
    List<String>? tags,
  }) async {
    final now = DateTime.now();
    final body = <String, dynamic>{
      'content': content,
      'is_draft': isDraft,
      'entry_date': '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}',
      'entry_time': '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:00',
    };
    if (title != null && title.isNotEmpty) body['title'] = title;
    if (mood != null) body['mood'] = mood;
    if (tags != null) body['tags'] = tags;
    final data = await _api.post(ApiConstants.entries, body);
    return EntryModel.fromJson(data as Map<String, dynamic>);
  }

  /// List entries (published by default, latest first).
  Future<List<EntryModel>> listEntries({
    int page = 1,
    int limit = 20,
    String sort = 'desc',
    bool? isDraft,
  }) async {
    final query = <String, dynamic>{
      'page': page,
      'limit': limit,
      'sort': sort,
    };
    if (isDraft != null) query['is_draft'] = isDraft;
    final data = await _api.getList(
      ApiConstants.entries,
      queryParameters: query.map((k, v) => MapEntry(k, v.toString())),
    );
    final list = <EntryModel>[];
    for (final item in data) {
      if (item is! Map<String, dynamic>) continue;
      try {
        list.add(EntryModel.fromJson(item));
      } catch (_) {
        // Skip malformed items so one bad entry doesn't break the list
      }
    }
    return list;
  }

  /// List draft entries.
  Future<List<EntryModel>> getDrafts() async {
    final data = await _api.getList(ApiConstants.entriesDrafts);
    final list = <EntryModel>[];
    for (final item in data) {
      if (item is! Map<String, dynamic>) continue;
      try {
        list.add(EntryModel.fromJson(item));
      } catch (_) {}
    }
    return list;
  }

  /// Get a single entry by id.
  Future<EntryModel> getEntry(String id) async {
    final data = await _api.get(ApiConstants.entryId(id));
    return EntryModel.fromJson(data);
  }

  /// Update an existing entry. Always sends content and is_draft so the backend persists changes.
  Future<EntryModel> updateEntry({
    required String id,
    required String content,
    String? title,
    String? mood,
    bool? isDraft,
    List<String>? tags,
  }) async {
    final body = <String, dynamic>{
      'content': content,
      'is_draft': isDraft ?? true,
    };
    body['title'] = title;
    if (mood != null) body['mood'] = mood;
    if (tags != null) body['tags'] = tags;
    final data = await _api.put(ApiConstants.entryId(id), body);
    return EntryModel.fromJson(data as Map<String, dynamic>);
  }

  /// Delete an entry (soft-delete on the server).
  Future<void> deleteEntry(String id) async {
    await _api.delete(ApiConstants.entryId(id));
  }

  /// Get an AI-generated journaling prompt (inspiration).
  Future<String> getInspirationPrompt() async {
    final data = await _api.post(ApiConstants.aiGeneratePrompt, {});
    return data['prompt'] as String? ?? 'What are you grateful for today?';
  }
}
