import 'package:flutter/foundation.dart';

import 'package:ai_journal/core/errors/error_handler.dart';
import 'package:ai_journal/data/models/user_model.dart';
import 'package:ai_journal/data/repositories/auth_repository.dart';

class AuthProvider with ChangeNotifier {
  AuthProvider({AuthRepository? repository}) : _repo = repository ?? AuthRepository();

  final AuthRepository _repo;
  UserModel? _user;
  bool _isLoading = false;
  String? _error;

  UserModel? get user => _user;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isLoggedIn => _user != null;

  Future<void> init() async {
    await _repo.init();
    if (await _repo.isLoggedIn) {
      try {
        _user = await _repo.fetchProfile();
      } catch (_) {
        await _repo.logout();
      }
    }
    notifyListeners();
  }

  Future<bool> login(String email, String password) async {
    _setLoading(true);
    _error = null;
    try {
      _user = await _repo.login(email, password);
      notifyListeners();
      return true;
    } catch (e) {
      _error = ErrorHandler.getMessage(e);
      notifyListeners();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> register(String email, String password, {String? fullName}) async {
    _setLoading(true);
    _error = null;
    try {
      _user = await _repo.register(email, password, fullName: fullName);
      notifyListeners();
      return true;
    } catch (e) {
      _error = ErrorHandler.getMessage(e);
      notifyListeners();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> logout() async {
    await _repo.logout();
    _user = null;
    _error = null;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  void _setLoading(bool v) {
    _isLoading = v;
  }
}
