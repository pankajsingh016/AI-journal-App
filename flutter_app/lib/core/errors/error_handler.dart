import 'package:dio/dio.dart';

import 'package:ai_journal/core/errors/exceptions.dart';

/// Maps API error codes / exceptions to user-facing messages.
class ErrorHandler {
  static String getMessage(dynamic error) {
    // Dio wraps our AppException in DioException.error – use it so backend message is shown
    if (error is DioException && error.error is AppException) {
      return (error.error as AppException).message;
    }
    if (error is AppException) return error.message;
    if (error is NetworkException) return error.message;
    if (error is UnauthorizedException) return error.message;
    if (error is ValidationException) return error.message;
    if (error is ServerException) return error.message;
    if (error is NotFoundException) return error.message;
    if (error is RateLimitException) return error.message;
    final msg = error?.toString() ?? 'Something went wrong. Please try again.';
    if (msg.contains('SocketException') || msg.contains('Connection')) {
      return 'No internet connection. Please check your network.';
    }
    return 'Something went wrong. Please try again.';
  }
}
