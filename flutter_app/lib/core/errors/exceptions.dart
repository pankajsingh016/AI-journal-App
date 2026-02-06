/// Base exception for API / app errors.
class AppException implements Exception {
  AppException(this.message, {this.code, this.details});
  final String message;
  final String? code;
  final dynamic details;
  @override
  String toString() => 'AppException: $message';
}

class NetworkException extends AppException {
  NetworkException([String message = 'No internet connection. Please check your network.'])
      : super(message, code: 'NETWORK_ERROR');
}

class UnauthorizedException extends AppException {
  UnauthorizedException([String message = 'Session expired. Please log in again.'])
      : super(message, code: 'UNAUTHORIZED');
}

class ValidationException extends AppException {
  ValidationException(String message, {String? field}) : super(message, code: 'VALIDATION_ERROR', details: {'field': field});
}

class ServerException extends AppException {
  ServerException([String message = 'Server error. Please try again later.'])
      : super(message, code: 'INTERNAL_SERVER_ERROR');
}

class NotFoundException extends AppException {
  NotFoundException([String message = 'Resource not found.']) : super(message, code: 'NOT_FOUND');
}

class RateLimitException extends AppException {
  RateLimitException([String message = 'Too many requests. Please wait a moment.'])
      : super(message, code: 'RATE_LIMIT_EXCEEDED');
}
