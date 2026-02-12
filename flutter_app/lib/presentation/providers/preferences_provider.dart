import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:ai_journal/core/errors/error_handler.dart';
import 'package:ai_journal/data/repositories/preferences_repository.dart';

class PreferencesProvider with ChangeNotifier {
  PreferencesProvider({PreferencesRepository? repository})
      : _repo = repository ?? PreferencesRepository();

  final PreferencesRepository _repo;

  String _theme = 'auto'; // auto | light | dark
  String _colorTheme = 'warm'; // warm | ocean | forest
  bool _reminderEnabled = true;
  bool _isLoading = false;
  String? _error;

  String get theme => _theme;
  String get colorTheme => _colorTheme;
  bool get reminderEnabled => _reminderEnabled;
  bool get isLoading => _isLoading;
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
    await loadPreferences();
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
      _theme = data['theme'] as String? ?? 'auto';
      final raw = data['color_theme'] as String? ?? 'warm';
      _colorTheme = _migrateColorTheme(raw);
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
    notifyListeners();
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
    notifyListeners();
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
