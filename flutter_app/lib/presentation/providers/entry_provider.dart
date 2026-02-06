import 'package:flutter/foundation.dart';

import 'package:ai_journal/core/errors/error_handler.dart';
import 'package:ai_journal/data/models/entry_model.dart';
import 'package:ai_journal/data/repositories/entry_repository.dart';

class EntryProvider with ChangeNotifier {
  EntryProvider({EntryRepository? repository}) : _repo = repository ?? EntryRepository();

  final EntryRepository _repo;
  bool _isLoading = false;
  String? _error;

  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> init() async {
    await _repo.init();
  }

  /// Save entry (draft or publish).
  Future<EntryModel?> saveEntry({
    required String content,
    String? title,
    String? mood,
    bool isDraft = true,
    List<String>? tags,
  }) async {
    _setLoading(true);
    _error = null;
    try {
      final entry = await _repo.createEntry(
        content: content,
        title: title,
        mood: mood,
        isDraft: isDraft,
        tags: tags,
      );
      notifyListeners();
      return entry;
    } catch (e) {
      _error = ErrorHandler.getMessage(e);
      notifyListeners();
      return null;
    } finally {
      _setLoading(false);
    }
  }

  /// Fetch AI inspiration prompt.
  Future<String?> getInspirationPrompt() async {
    _setLoading(true);
    _error = null;
    try {
      final prompt = await _repo.getInspirationPrompt();
      _setLoading(false);
      notifyListeners();
      return prompt;
    } catch (e) {
      _error = ErrorHandler.getMessage(e);
      _setLoading(false);
      notifyListeners();
      return null;
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  void _setLoading(bool v) {
    _isLoading = v;
  }
}
