import 'dart:io';

import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart' show XFile;

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../../core/config/app_config.dart';
import '../../../core/constants/storage_constants.dart';
import '../../../core/errors/exceptions.dart';

class ApiClient {
  ApiClient({String? baseUrl, FlutterSecureStorage? storage})
      : _dio = Dio(BaseOptions(
          baseUrl: baseUrl ?? '${AppConfig.apiBaseUrl}${AppConfig.apiV1Prefix}',
          connectTimeout: const Duration(seconds: 15),
          receiveTimeout: const Duration(seconds: 30),
          headers: {'Content-Type': 'application/json', 'Accept': 'application/json'},
        )),
        _storage = storage ?? const FlutterSecureStorage();

  final Dio _dio;
  final FlutterSecureStorage _storage;

  Future<void> init() async {
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await _storage.read(key: StorageConstants.accessToken);
        if (token != null && token.isNotEmpty) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        return handler.next(options);
      },
      onError: (err, handler) async {
        if (err.response?.statusCode == 401) {
          final refreshed = await _tryRefreshToken();
          if (refreshed) {
            return handler.resolve(
              await _dio.fetch(err.requestOptions.copyWith(headers: {
                ...?err.requestOptions.headers,
                'Authorization': 'Bearer ${await _storage.read(key: StorageConstants.accessToken)}',
              })),
            );
          }
        }
        final appError = _mapError(err);
        return handler.reject(DioException(
          requestOptions: err.requestOptions,
          error: appError,
          response: err.response,
        ));
      },
    ));
  }

  Future<bool> _tryRefreshToken() async {
    final refresh = await _storage.read(key: StorageConstants.refreshToken);
    if (refresh == null) return false;
    try {
      final r = await _dio.post('/auth/refresh', data: {'refresh_token': refresh});
      final data = r.data as Map<String, dynamic>;
      await _storage.write(key: StorageConstants.accessToken, value: data['access_token'] as String?);
      await _storage.write(key: StorageConstants.refreshToken, value: data['refresh_token'] as String?);
      return true;
    } catch (_) {
      return false;
    }
  }

  Exception _mapError(DioException err) {
    if (err.type == DioExceptionType.connectionTimeout ||
        err.type == DioExceptionType.connectionError) {
      return NetworkException(
        'Could not reach the server. Check that the backend is running and '
        'API_BASE_URL in assets/.env is correct (e.g. http://localhost:8000 or your machine IP).',
      );
    }
    final status = err.response?.statusCode;
    final data = err.response?.data;
    String message = _extractErrorMessage(data);
    if (status == 401) return UnauthorizedException(message);
    if (status == 400) return ValidationException(message);
    if (status == 404) return NotFoundException(message);
    if (status == 429) return RateLimitException(message);
    if (status != null && status >= 500) return ServerException(message);
    return AppException(message);
  }

  /// Extract user-facing message from API error body (our format or FastAPI/HTTPException detail).
  static String _extractErrorMessage(dynamic data) {
    const fallback = 'Something went wrong. Please try again.';
    if (data == null) return fallback;
    if (data is String && data.trim().isNotEmpty) return data.trim();
    if (data is! Map) return fallback;
    // Our API: { "error": { "message": "...", "details": { "hint": "..." } } }
    if (data['error'] is Map) {
      final err = data['error'] as Map;
      final msg = err['message'];
      if (msg is String && msg.isNotEmpty) {
        const generic = 'An unexpected error occurred. Please try again.';
        if (msg == generic && err['details'] is Map) {
          final hint = (err['details'] as Map)['hint'];
          if (hint is String && hint.isNotEmpty) return hint;
        }
        return msg;
      }
    }
    // FastAPI HTTPException: { "detail": { "error": { "message": "..." } } } or { "detail": "..." }
    final detail = data['detail'];
    if (detail is Map) {
      if (detail['error'] is Map) {
        final msg = (detail['error'] as Map)['message'];
        if (msg is String && msg.isNotEmpty) return msg;
      }
      final msg = detail['message'];
      if (msg is String && msg.isNotEmpty) return msg;
    }
    if (detail is String && detail.isNotEmpty) return detail;
    if (detail is List && detail.isNotEmpty && detail.first is Map) {
      final msg = (detail.first as Map)['msg'];
      if (msg is String && msg.isNotEmpty) return msg;
    }
    return fallback;
  }

  Future<Map<String, dynamic>> get(String path, {Map<String, dynamic>? queryParameters}) async {
    final r = await _dio.get<dynamic>(path, queryParameters: queryParameters);
    return _toMap(r.data);
  }

  Future<List<dynamic>> getList(String path, {Map<String, dynamic>? queryParameters}) async {
    final r = await _dio.get<dynamic>(path, queryParameters: queryParameters);
    final data = r.data;
    if (data is List) return data as List<dynamic>;
    if (data is Map) {
      final list = data['data'] ?? data['items'] ?? data['results'] ?? data['entries'];
      if (list is List) return list as List<dynamic>;
    }
    return [];
  }

  Future<Map<String, dynamic>> post(String path, [Map<String, dynamic>? data]) async {
    final r = await _dio.post<dynamic>(path, data: data);
    return _toMap(r.data);
  }

  Future<Map<String, dynamic>> put(String path, [Map<String, dynamic>? data]) async {
    final r = await _dio.put<dynamic>(path, data: data);
    return _toMap(r.data);
  }

  Future<void> delete(String path) async {
    await _dio.delete(path);
  }

  /// PATCH with multipart file (e.g. avatar upload). Uses [File] path (mobile/desktop).
  Future<Map<String, dynamic>> patchMultipart(
    String path,
    File file, {
    String fieldName = 'file',
  }) async {
    final name = file.path.split(RegExp(r'[/\\]')).last;
    final filename = name.contains('.') ? name : 'avatar.jpg';
    final formData = FormData.fromMap({
      fieldName: await MultipartFile.fromFile(file.path, filename: filename),
    });
    final r = await _dio.patch<dynamic>(path, data: formData);
    return _toMap(r.data);
  }

  /// PATCH with multipart from [XFile] (works on all platforms including web).
  Future<Map<String, dynamic>> patchMultipartXFile(
    String path,
    XFile xFile, {
    String fieldName = 'file',
  }) async {
    final bytes = await xFile.readAsBytes();
    final name = xFile.name;
    final filename = (name != null && name.contains('.')) ? name : 'avatar.jpg';
    final formData = FormData.fromMap({
      fieldName: MultipartFile.fromBytes(bytes, filename: filename),
    });
    final r = await _dio.patch<dynamic>(path, data: formData);
    return _toMap(r.data);
  }

  static Map<String, dynamic> _toMap(dynamic data) {
    if (data is Map<String, dynamic>) return data;
    if (data is Map) return Map<String, dynamic>.from(data);
    if (data != null) return {'data': data};
    return {};
  }
}
