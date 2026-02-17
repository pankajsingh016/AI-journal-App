import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart' show XFile;

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
  List<EntryModel> _entriesForDate = [];
  int _currentStreak = 0;
  int _longestStreak = 0;
  Set<String> _datesWithEntries = {};

  bool get isLoading => _isLoading;
  String? get error => _error;
  List<EntryModel> get drafts => List.unmodifiable(_drafts);
  List<EntryModel> get recentEntries => List.unmodifiable(_recentEntries);
  List<EntryModel> get allEntries => List.unmodifiable(_allEntries);
  List<EntryModel> get entriesForDate => List.unmodifiable(_entriesForDate);
  int get currentStreak => _currentStreak;
  int get longestStreak => _longestStreak;
  Set<String> get datesWithEntries => Set.unmodifiable(_datesWithEntries);

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

  /// Fetch a single entry by id (includes media). Returns null on error.
  Future<EntryModel?> getEntry(String entryId) async {
    _error = null;
    try {
      final entry = await _repo.getEntry(entryId);
      return entry;
    } catch (e) {
      _error = ErrorHandler.getMessage(e);
      return null;
    }
  }

  /// Upload a photo for an entry. Entry must already exist. Returns the media item or null on error.
  Future<EntryMediaItem?> uploadEntryMedia(String entryId, XFile imageFile) async {
    _error = null;
    try {
      final item = await _repo.uploadEntryMedia(entryId, imageFile);
      notifyListeners();
      return item;
    } catch (e) {
      _error = ErrorHandler.getMessage(e);
      notifyListeners();
      return null;
    }
  }

  /// Load dates when user has published entries (for calendar).
  Future<void> loadCalendarDates() async {
    try {
      _datesWithEntries = await _repo.getEntryDates();
      notifyListeners();
    } catch (_) {
      _datesWithEntries = {};
      notifyListeners();
    }
  }

  /// Load user stats (streak, etc.) for the home screen.
  Future<void> loadUserStats() async {
    try {
      final stats = await _repo.getUserStats();
      _currentStreak = stats['current_streak'] is int
          ? stats['current_streak'] as int
          : int.tryParse(stats['current_streak']?.toString() ?? '0') ?? 0;
      _longestStreak = stats['longest_streak'] is int
          ? stats['longest_streak'] as int
          : int.tryParse(stats['longest_streak']?.toString() ?? '0') ?? 0;
      notifyListeners();
    } catch (_) {
      _currentStreak = 0;
      _longestStreak = 0;
      notifyListeners();
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

  /// Load published entries for a single day (YYYY-MM-DD). Used by calendar date tap.
  Future<void> loadEntriesForDate(String dateKey) async {
    _setLoading(true);
    _error = null;
    try {
      _entriesForDate = await _repo.listEntries(
        page: 1,
        limit: 50,
        sort: 'desc',
        isDraft: false,
        entryDate: dateKey,
      );
      notifyListeners();
    } catch (e) {
      _error = ErrorHandler.getMessage(e);
      _entriesForDate = [];
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

  /// Run an AI inspiration action on text. Returns result or null on error.
  Future<String?> runInspiration({required String text, required String action}) async {
    _error = null;
    try {
      final result = await _repo.runInspiration(text: text, action: action);
      return result;
    } catch (e) {
      _error = ErrorHandler.getMessage(e);
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
