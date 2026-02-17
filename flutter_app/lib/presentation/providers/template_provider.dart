import 'package:flutter/foundation.dart';

import 'package:ai_journal/core/errors/error_handler.dart';
import 'package:ai_journal/data/models/template_model.dart';
import 'package:ai_journal/data/repositories/template_repository.dart';

class TemplateProvider with ChangeNotifier {
  TemplateProvider({TemplateRepository? repository}) : _repo = repository ?? TemplateRepository();

  final TemplateRepository _repo;
  bool _isLoading = false;
  String? _error;
  List<TemplateModel> _templates = [];
  List<String> _categories = [];

  bool get isLoading => _isLoading;
  String? get error => _error;
  List<TemplateModel> get templates => List.unmodifiable(_templates);
  List<String> get categories => List.unmodifiable(_categories);

  Future<void> init() async {
    await _repo.init();
  }

  /// Load templates (and categories). Optionally filter by [category].
  Future<void> loadTemplates({String? category}) async {
    _setLoading(true);
    _error = null;
    try {
      _templates = await _repo.listTemplates(category: category);
      final apiCategories = await _repo.listCategories();
      if (apiCategories.isNotEmpty) {
        _categories = List<String>.from(apiCategories)..sort();
      } else if (_templates.isNotEmpty) {
        _categories = List<String>.from(_templates.map((t) => t.category).toSet())..sort();
      } else {
        _categories = [];
      }
      notifyListeners();
    } catch (e) {
      _error = ErrorHandler.getMessage(e);
      notifyListeners();
    } finally {
      _setLoading(false);
    }
  }

  /// Create a user template. Returns the created template or null on error.
  Future<TemplateModel?> createTemplate({
    required String name,
    String? description,
    String category = 'custom',
    String title = '',
    String content = '',
  }) async {
    _error = null;
    try {
      final t = await _repo.createTemplate(
        name: name,
        description: description,
        category: category,
        title: title,
        content: content,
      );
      _templates = await _repo.listTemplates();
      notifyListeners();
      return t;
    } catch (e) {
      _error = ErrorHandler.getMessage(e);
      notifyListeners();
      return null;
    }
  }

  void _setLoading(bool value) {
    _isLoading = value;
  }
}
