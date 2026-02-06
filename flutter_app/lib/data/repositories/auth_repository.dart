import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'package:ai_journal/core/constants/api_constants.dart';
import 'package:ai_journal/core/constants/storage_constants.dart';
import 'package:ai_journal/core/errors/exceptions.dart';
import 'package:ai_journal/data/data_sources/remote/api_client.dart';
import 'package:ai_journal/data/models/user_model.dart';

class AuthRepository {
  AuthRepository({ApiClient? apiClient, FlutterSecureStorage? storage})
      : _api = apiClient ?? ApiClient(),
        _storage = storage ?? const FlutterSecureStorage();

  final ApiClient _api;
  final FlutterSecureStorage _storage;

  Future<void> init() => _api.init();

  Future<UserModel> register(String email, String password, {String? fullName}) async {
    final data = await _api.post(ApiConstants.authRegister, {
      'email': email,
      'password': password,
      'full_name': fullName,
    });
    await _storeTokens(data);
    return await fetchProfile();
  }

  Future<UserModel> login(String email, String password) async {
    final data = await _api.post(ApiConstants.authLogin, {
      'email': email,
      'password': password,
    });
    await _storeTokens(data);
    return await fetchProfile();
  }

  Future<void> _storeTokens(Map<String, dynamic> data) async {
    await _storage.write(key: StorageConstants.accessToken, value: data['access_token'] as String?);
    await _storage.write(key: StorageConstants.refreshToken, value: data['refresh_token'] as String?);
  }

  Future<UserModel> fetchProfile() async {
    final data = await _api.get(ApiConstants.userProfile);
    await _storage.write(key: StorageConstants.userId, value: data['id'] as String?);
    return UserModel.fromJson(data);
  }

  Future<bool> get isLoggedIn async {
    final token = await _storage.read(key: StorageConstants.accessToken);
    return token != null && token.isNotEmpty;
  }

  Future<void> logout() async {
    try {
      await _api.post(ApiConstants.authLogout);
    } catch (_) {}
    await _storage.delete(key: StorageConstants.accessToken);
    await _storage.delete(key: StorageConstants.refreshToken);
    await _storage.delete(key: StorageConstants.userId);
  }

  Future<void> forgotPassword(String email) async {
    await _api.post(ApiConstants.authForgotPassword, {'email': email});
  }
}
