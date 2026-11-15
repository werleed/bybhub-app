import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../constants/app_constants.dart';
import 'api_interceptors.dart';

final dioProvider = Provider<Dio>((ref) {
  final storage = ref.watch(secureStorageProvider);
  final dio = Dio(BaseOptions(
    baseUrl: AppConstants.apiBaseUrl,
    connectTimeout: const Duration(seconds: 15),
    receiveTimeout: const Duration(seconds: 30),
    headers: {'Accept': 'application/json', 'Content-Type': 'application/json'},
  ));
  dio.interceptors.addAll([
    AuthInterceptor(storage),
    ErrorNormalizationInterceptor(),
  ]);
  return dio;
});

final secureStorageProvider = Provider<FlutterSecureStorage>((_) =>
    const FlutterSecureStorage(
      aOptions: AndroidOptions(encryptedSharedPreferences: false),
    ));

class ApiResponse<T> {
  final bool success;
  final String? message;
  final T? data;
  final Map<String, dynamic>? meta;
  final Map<String, dynamic>? errors;

  const ApiResponse({required this.success, this.message, this.data, this.meta, this.errors});

  factory ApiResponse.fromJson(Map<String, dynamic> json, T Function(dynamic) fromJson) {
    return ApiResponse(
      success: json['success'] as bool? ?? false,
      message: json['message'] as String?,
      data: json['data'] != null ? fromJson(json['data']) : null,
      meta: json['meta'] as Map<String, dynamic>?,
      errors: json['errors'] as Map<String, dynamic>?,
    );
  }
}
