import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../../core/api/api_client.dart';
import '../../../core/api/api_exceptions.dart';
import '../../../core/constants/app_constants.dart';
import '../domain/user_model.dart';

// ── Auth state ─────────────────────────────────────────────────────────────

class AuthState {
  final UserModel? user;
  final bool isLoading;

  const AuthState({this.user, this.isLoading = false});

  bool get isAuthenticated => user != null;

  AuthState copyWith({UserModel? user, bool? isLoading, bool clearUser = false}) =>
      AuthState(
        user: clearUser ? null : (user ?? this.user),
        isLoading: isLoading ?? this.isLoading,
      );
}

// ── AuthNotifier ──────────────────────────────────────────────────────────

class AuthNotifier extends Notifier<AuthState> {
  late Dio _dio;
  late FlutterSecureStorage _storage;

  @override
  AuthState build() {
    _dio = ref.watch(dioProvider);
    _storage = ref.watch(secureStorageProvider);
    _init();
    return const AuthState();
  }

  Future<void> _init() async {
    state = state.copyWith(isLoading: true);
    try {
      final token = await _storage.read(key: AppConstants.kAuthToken);
      final userJson = await _storage.read(key: AppConstants.kUserJson);
      if (token != null && userJson != null) {
        final user = UserModel.fromJson(jsonDecode(userJson) as Map<String, dynamic>);
        state = AuthState(user: user);
        _refreshUser();
      } else {
        state = const AuthState();
      }
    } catch (_) {
      state = const AuthState();
    }
  }

  Future<void> _refreshUser() async {
    try {
      final response = await _dio.get('/auth/me');
      final body = response.data as Map<String, dynamic>;
      if (body['success'] == true && body['data'] != null) {
        final user = UserModel.fromJson(body['data'] as Map<String, dynamic>);
        await _storage.write(key: AppConstants.kUserJson, value: jsonEncode(user.toJson()));
        state = AuthState(user: user);
      }
    } catch (_) {}
  }

  Future<UserModel> login(String email, String password, {String deviceName = 'BYBHUB Mobile'}) async {
    state = state.copyWith(isLoading: true);
    try {
      final response = await _dio.post('/auth/login', data: {
        'email': email,
        'password': password,
        'device_name': deviceName,
      });
      return _handleAuthResponse(response);
    } on DioException catch (e) {
      state = state.copyWith(isLoading: false);
      throw e.error ?? ApiException(message: 'Login failed.', statusCode: null);
    }
  }

  Future<UserModel> register({
    required String name,
    required String email,
    required String phone,
    required String password,
    required String passwordConfirmation,
    required String country,
    String? ref,
    String deviceName = 'BYBHUB Mobile',
  }) async {
    state = state.copyWith(isLoading: true);
    try {
      final response = await _dio.post('/auth/register', data: {
        'name': name,
        'email': email,
        'phone': phone,
        'password': password,
        'password_confirmation': passwordConfirmation,
        'country': country,
        'terms_accepted': true,
        if (ref != null) 'ref': ref,
        'device_name': deviceName,
      });
      return _handleAuthResponse(response);
    } on DioException catch (e) {
      state = state.copyWith(isLoading: false);
      throw e.error ?? ApiException(message: 'Registration failed.', statusCode: null);
    }
  }

  Future<void> logout() async {
    try { await _dio.post('/auth/logout'); } catch (_) {}
    await _clearSession();
  }

  Future<void> _clearSession() async {
    await _storage.deleteAll();
    state = const AuthState();
  }

  UserModel _handleAuthResponse(Response response) {
    final body = response.data as Map<String, dynamic>;
    final token = body['data']?['token'] as String?;
    final userData = body['data']?['user'] as Map<String, dynamic>?;

    if (token == null || userData == null) {
      state = state.copyWith(isLoading: false);
      throw const ApiException(message: 'Invalid response from server.', statusCode: null);
    }

    final user = UserModel.fromJson(userData);
    _storage.write(key: AppConstants.kAuthToken, value: token);
    _storage.write(key: AppConstants.kUserJson, value: jsonEncode(user.toJson()));
    state = AuthState(user: user);
    return user;
  }
}

// ── Providers ─────────────────────────────────────────────────────────────

final authNotifierProvider = NotifierProvider<AuthNotifier, AuthState>(AuthNotifier.new);

final authStateProvider = Provider<AuthState>((ref) => ref.watch(authNotifierProvider));
