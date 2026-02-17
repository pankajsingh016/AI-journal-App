import 'package:image_picker/image_picker.dart' show XFile;

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
  /// If [entryDate] is set (YYYY-MM-DD), returns only entries written on that day.
  Future<List<EntryModel>> listEntries({
    int page = 1,
    int limit = 20,
    String sort = 'desc',
    bool? isDraft,
    String? entryDate,
  }) async {
    final query = <String, dynamic>{
      'page': page,
      'limit': limit,
      'sort': sort,
    };
    if (isDraft != null) query['is_draft'] = isDraft;
    if (entryDate != null && entryDate.isNotEmpty) query['entry_date'] = entryDate;
    final data = await _api.getList(
      ApiConstants.entries,
      queryParameters: query.map((k, v) => MapEntry(k, v.toString())),
    );
    final list = <EntryModel>[];
    for (final item in data) {
      if (item is! Map) continue;
      try {
        list.add(EntryModel.fromJson(Map<String, dynamic>.from(item as Map)));
      } catch (_) {
        // Skip malformed items so one bad entry doesn't break the list
      }
    }
    return list;
  }

  /// List draft entries. Uses same list endpoint as History with is_draft=true for reliability.
  Future<List<EntryModel>> getDrafts() async {
    final data = await _api.getList(
      ApiConstants.entries,
      queryParameters: const {
        'is_draft': 'true',
        'page': '1',
        'limit': '50',
        'sort': 'desc',
      },
    );
    final list = <EntryModel>[];
    for (final item in data) {
      if (item is! Map) continue;
      try {
        list.add(EntryModel.fromJson(Map<String, dynamic>.from(item as Map)));
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

  /// Get user stats (total entries, words, current/longest streak).
  Future<Map<String, dynamic>> getUserStats() async {
    final data = await _api.get(ApiConstants.userStats);
    return data;
  }

  /// Get dates (YYYY-MM-DD) when the user has at least one published entry.
  Future<Set<String>> getEntryDates() async {
    final data = await _api.get(ApiConstants.entriesDates);
    final list = data['dates'];
    if (list is! List) return {};
    return list.map((e) => e?.toString() ?? '').where((s) => s.length >= 10).toSet();
  }

  /// Get an AI-generated journaling prompt (inspiration).
  Future<String> getInspirationPrompt() async {
    final data = await _api.post(ApiConstants.aiGeneratePrompt, {});
    return data['prompt'] as String? ?? 'What are you grateful for today?';
  }

  /// Run an AI inspiration action (improve, grammar, expand, soften, title, questions). Returns result text or null.
  Future<String?> runInspiration({required String text, required String action}) async {
    final data = await _api.post(ApiConstants.aiInspiration, {'text': text, 'action': action});
    return data['result']?.toString();
  }

  /// Upload a photo (or other image) for an entry. Entry must already exist.
  Future<EntryMediaItem?> uploadEntryMedia(String entryId, XFile imageFile) async {
    final data = await _api.postMultipartXFile(ApiConstants.entryMedia(entryId), imageFile);
    if (data is! Map) return null;
    // API returns { id, url, file_name, mime_type } directly
    final map = data is Map<String, dynamic> ? data : Map<String, dynamic>.from(data as Map);
    return EntryMediaItem.fromJson(map);
  }
}
