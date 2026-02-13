import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:ai_journal/core/errors/error_handler.dart';
import 'package:ai_journal/data/repositories/preferences_repository.dart';

class PreferencesProvider with ChangeNotifier {
  PreferencesProvider({PreferencesRepository? repository})
      : _repo = repository ?? PreferencesRepository() {
    // Use cached values so hot reload and provider recreation keep the user's theme.
    if (_cachedTheme != null) _theme = _cachedTheme!;
    if (_cachedColorTheme != null) _colorTheme = _cachedColorTheme!;
    if (_cachedTheme != null || _cachedColorTheme != null) _hasLoadedLocalCache = true;
  }

  final PreferencesRepository _repo;

  /// Cached so that when the provider is recreated (e.g. hot reload), we keep the same theme.
  static String? _cachedTheme;
  static String? _cachedColorTheme;

  String _theme = 'auto'; // auto | light | dark
  String _colorTheme = 'warm'; // warm | ocean | forest
  bool _reminderEnabled = true;
  bool _isLoading = false;
  bool _hasLoadedLocalCache = false;
  /// True if we applied theme from local storage; if so, don't let API overwrite it with server defaults.
  bool _hadLocalTheme = false;
  String? _error;

  String get theme => _theme;
  String get colorTheme => _colorTheme;
  bool get reminderEnabled => _reminderEnabled;
  bool get isLoading => _isLoading;
  /// True after local theme cache has been applied; use to avoid flashing default theme.
  bool get hasLoadedLocalCache => _hasLoadedLocalCache;
  String? get error => _error;

  /// ThemeMode for MaterialApp: system, light, or dark.
  ThemeMode get themeMode {
    switch (_theme) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }

  Future<void> init() async {
    await _repo.init();
    await _loadLocalThemeFirst();
    await loadPreferences();
  }

  /// Load theme from local storage first so the first paint uses the user's choice (not default).
  Future<void> _loadLocalThemeFirst() async {
    try {
      final local = await _repo.getLocalTheme();
      final theme = local['theme'];
      final colorTheme = local['color_theme'];
      if (theme != null && theme.isNotEmpty) {
        _theme = theme;
        _cachedTheme = theme;
        _hadLocalTheme = true;
      }
      if (colorTheme != null && colorTheme.isNotEmpty) {
        _colorTheme = _migrateColorTheme(colorTheme);
        _cachedColorTheme = _colorTheme;
        _hadLocalTheme = true;
      }
    } catch (_) {}
    _hasLoadedLocalCache = true;
    notifyListeners();
  }

  /// Map legacy theme ids to current ones.
  static String _migrateColorTheme(String id) {
    switch (id) {
      case 'ocean':
        return 'soft_blue';
      case 'forest':
        return 'sage';
      case 'lavender':
        return 'soft_blue';
      default:
        return id;
    }
  }

  Future<void> loadPreferences() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final data = await _repo.getPreferences();
      // Don't overwrite theme from API when we already loaded user's choice from local storage
      // (avoids server defaults like 'warm' replacing the user's selected theme after restart).
      if (!_hadLocalTheme) {
        _theme = data['theme'] as String? ?? _theme;
        final raw = data['color_theme'] as String? ?? _colorTheme;
        _colorTheme = _migrateColorTheme(raw);
        _cachedTheme = _theme;
        _cachedColorTheme = _colorTheme;
        await _repo.saveLocalTheme(theme: _theme, colorTheme: _colorTheme);
      }
      _reminderEnabled = data['reminder_enabled'] as bool? ?? true;
    } catch (e) {
      _error = ErrorHandler.getMessage(e);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> setTheme(String value) async {
    if (_theme == value) return;
    _theme = value;
    _cachedTheme = value;
    notifyListeners();
    // Persist to local first so theme survives hot reload/restart even if API fails (e.g. offline).
    await _repo.saveLocalTheme(theme: value);
    try {
      await _repo.updatePreferences(theme: value);
    } catch (e) {
      _error = ErrorHandler.getMessage(e);
      notifyListeners();
    }
  }

  Future<void> setColorTheme(String value) async {
    if (_colorTheme == value) return;
    _colorTheme = value;
    _cachedColorTheme = value;
    notifyListeners();
    // Persist to local first so theme survives hot reload/restart even if API fails (e.g. offline).
    await _repo.saveLocalTheme(colorTheme: value);
    try {
      await _repo.updatePreferences(colorTheme: value);
    } catch (e) {
      _error = ErrorHandler.getMessage(e);
      notifyListeners();
    }
  }

  Future<void> setReminderEnabled(bool value) async {
    if (_reminderEnabled == value) return;
    _reminderEnabled = value;
    notifyListeners();
    try {
      await _repo.updatePreferences(reminderEnabled: value);
    } catch (e) {
      _error = ErrorHandler.getMessage(e);
      notifyListeners();
    }
  }
}
