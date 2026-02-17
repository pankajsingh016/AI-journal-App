import 'package:ai_journal/core/constants/api_constants.dart';
import 'package:ai_journal/data/data_sources/remote/api_client.dart';
import 'package:ai_journal/data/models/template_model.dart';

class TemplateRepository {
  TemplateRepository({ApiClient? apiClient}) : _api = apiClient ?? ApiClient();

  final ApiClient _api;

  Future<void> init() => _api.init();

  /// List templates (system + user's own). Optionally filter by [category].
  Future<List<TemplateModel>> listTemplates({String? category}) async {
    final query = <String, String>{};
    if (category != null && category.isNotEmpty) query['category'] = category;
    final data = await _api.getList(
      ApiConstants.templates,
      queryParameters: query.isNotEmpty ? query : null,
    );
    final list = <TemplateModel>[];
    for (final item in data) {
      if (item is! Map) continue;
      final t = TemplateModel.fromJson(Map<String, dynamic>.from(item as Map));
      if (t != null) list.add(t);
    }
    return list;
  }

  /// Fetch distinct categories for templates.
  Future<List<String>> listCategories() async {
    final data = await _api.getList(ApiConstants.templatesCategories);
    final list = <String>[];
    for (final item in data) {
      if (item is String) list.add(item);
    }
    return list;
  }

  /// Get a single template by id.
  Future<TemplateModel?> getTemplate(String templateId) async {
    final data = await _api.get(ApiConstants.templateId(templateId));
    return TemplateModel.fromJson(data);
  }

  /// Create a user-owned template.
  Future<TemplateModel> createTemplate({
    required String name,
    String? description,
    String category = 'custom',
    String title = '',
    String content = '',
  }) async {
    final body = <String, dynamic>{
      'name': name,
      'category': category,
      'structure': {'title': title, 'content': content},
    };
    if (description != null && description.isNotEmpty) body['description'] = description;
    final data = await _api.post(ApiConstants.templates, body);
    final t = TemplateModel.fromJson(data);
    if (t == null) throw Exception('Invalid template response');
    return t;
  }
}
