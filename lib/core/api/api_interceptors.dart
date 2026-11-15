import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../constants/app_constants.dart';
import 'api_exceptions.dart';

/// Attaches the Sanctum Bearer token to every request.
class AuthInterceptor extends Interceptor {
  final FlutterSecureStorage _storage;

  const AuthInterceptor(this._storage);

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final token = await _storage.read(key: AppConstants.kAuthToken);
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    // 401 → token expired or revoked → clear stored credentials
    if (err.response?.statusCode == 401) {
      await _storage.deleteAll();
      // Let the error propagate; go_router AuthNotifier will redirect to /login
    }
    handler.next(err);
  }
}

/// Normalises all Dio errors into [ApiException] instances so the UI
/// never has to handle raw DioException.
class ErrorNormalizationInterceptor extends Interceptor {
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final response = err.response;

    if (response != null) {
      final body = response.data;
      final message = (body is Map ? body['message'] : null) as String? ??
          'An error occurred (${response.statusCode}).';
      final errors = (body is Map ? body['errors'] : null) as Map<String, dynamic>?;

      handler.reject(
        DioException(
          requestOptions: err.requestOptions,
          response: response,
          error: ApiException(
            message: message,
            statusCode: response.statusCode,
            errors: errors,
          ),
          type: DioExceptionType.badResponse,
        ),
      );
      return;
    }

    // Network errors
    final String msg;
    if (err.type == DioExceptionType.connectionTimeout ||
        err.type == DioExceptionType.receiveTimeout) {
      msg = 'Connection timed out. Please check your internet connection.';
    } else if (err.type == DioExceptionType.connectionError) {
      msg = 'No internet connection. Please check your network.';
    } else {
      msg = 'Network error. Please try again.';
    }

    handler.reject(
      DioException(
        requestOptions: err.requestOptions,
        error: ApiException(message: msg, statusCode: null),
        type: err.type,
      ),
    );
  }
}

/// Development-only logging interceptor (stripped in release builds via
/// const bool.fromEnvironment('dart.vm.product')).
class LoggingInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    // ignore: avoid_print
    print('→ ${options.method} ${options.uri}');
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    // ignore: avoid_print
    print('← ${response.statusCode} ${response.requestOptions.uri}');
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    // ignore: avoid_print
    print('✗ ${err.requestOptions.uri}: ${err.message}');
    handler.next(err);
  }
}
