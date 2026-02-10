import 'package:flutter/foundation.dart';

import 'package:ai_journal/core/errors/error_handler.dart';
import 'package:ai_journal/data/models/entry_model.dart';
import 'package:ai_journal/data/repositories/entry_repository.dart';

class EntryProvider with ChangeNotifier {
  EntryProvider({EntryRepository? repository}) : _repo = repository ?? EntryRepository();

  final EntryRepository _repo;
  bool _isLoading = false;
  String? _error;
  List<EntryModel> _drafts = [];
  List<EntryModel> _recentEntries = [];
  List<EntryModel> _allEntries = [];

  bool get isLoading => _isLoading;
  String? get error => _error;
  List<EntryModel> get drafts => List.unmodifiable(_drafts);
  List<EntryModel> get recentEntries => List.unmodifiable(_recentEntries);
  List<EntryModel> get allEntries => List.unmodifiable(_allEntries);

  Future<void> init() async {
    await _repo.init();
  }

  /// Save entry (creates new or updates existing).
  Future<EntryModel?> saveEntry({
    String? entryId,
    required String content,
    String? title,
    String? mood,
    bool isDraft = true,
    List<String>? tags,
  }) async {
    _setLoading(true);
    _error = null;
    try {
      final entry = entryId != null
          ? await _repo.updateEntry(
              id: entryId,
              content: content,
              title: title,
              mood: mood,
              isDraft: isDraft,
              tags: tags,
            )
          : await _repo.createEntry(
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

  /// Load recent published entries (for home screen).
  Future<void> loadRecentEntries() async {
    _error = null;
    try {
      _recentEntries = await _repo.listEntries(
        page: 1,
        limit: 10,
        sort: 'desc',
        isDraft: false,
      );
      notifyListeners();
    } catch (e) {
      _error = ErrorHandler.getMessage(e);
      _recentEntries = [];
      notifyListeners();
    }
  }

  /// Load all published entries (latest first, for "See all" screen).
  Future<void> loadAllEntries() async {
    _setLoading(true);
    _error = null;
    try {
      _allEntries = await _repo.listEntries(
        page: 1,
        limit: 50,
        sort: 'desc',
        isDraft: false,
      );
      notifyListeners();
    } catch (e) {
      _error = ErrorHandler.getMessage(e);
      _allEntries = [];
      notifyListeners();
    } finally {
      _setLoading(false);
    }
  }

  /// Load draft entries.
  Future<void> loadDrafts() async {
    _setLoading(true);
    _error = null;
    try {
      _drafts = await _repo.getDrafts();
      notifyListeners();
    } catch (e) {
      _error = ErrorHandler.getMessage(e);
      _drafts = [];
      notifyListeners();
    } finally {
      _setLoading(false);
    }
  }

  /// Delete an entry and remove it from local lists.
  Future<bool> deleteEntry(String id) async {
    _error = null;
    try {
      await _repo.deleteEntry(id);
      _drafts = _drafts.where((e) => e.id != id).toList();
      _recentEntries = _recentEntries.where((e) => e.id != id).toList();
      _allEntries = _allEntries.where((e) => e.id != id).toList();
      notifyListeners();
      return true;
    } catch (e) {
      _error = ErrorHandler.getMessage(e);
      notifyListeners();
      return false;
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
