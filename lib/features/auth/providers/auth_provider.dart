import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../../core/errors/user_facing_error.dart';
import '../../../core/networking/api_client.dart';
import '../models/user_profile.dart';
import '../services/auth_api_service.dart';

enum AuthStatus {
  initial,
  authenticated,
  unauthenticated,
  loading,
  error,
}

class AuthState {
  final AuthStatus status;
  final UserProfile? user;
  final String? accessToken;
  final String? errorMessage;

  const AuthState({
    required this.status,
    this.user,
    this.accessToken,
    this.errorMessage,
  });

  bool get isAuthenticated =>
      status == AuthStatus.authenticated && user != null;

  factory AuthState.initial() => const AuthState(status: AuthStatus.initial);
  factory AuthState.loading() => const AuthState(status: AuthStatus.loading);
  factory AuthState.unauthenticated() =>
      const AuthState(status: AuthStatus.unauthenticated);
  factory AuthState.authenticated(UserProfile user, String token) => AuthState(
        status: AuthStatus.authenticated,
        user: user,
        accessToken: token,
      );
  factory AuthState.error(String message) => AuthState(
        status: AuthStatus.error,
        errorMessage: message,
      );
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final authService = ref.watch(authApiServiceProvider);
  final apiClient = ref.watch(apiClientProvider);
  return AuthNotifier(authService, apiClient);
});

final currentUserProvider = Provider<UserProfile?>((ref) {
  return ref.watch(authProvider).user;
});

class AuthNotifier extends StateNotifier<AuthState> {
  static const _accessTokenKey = 'hanbova_access_token';
  static const _refreshTokenKey = 'hanbova_refresh_token';

  final AuthApiService _apiService;
  final ApiClient _apiClient;
  final FlutterSecureStorage _storage;

  AuthNotifier(
    this._apiService,
    this._apiClient, {
    FlutterSecureStorage? storage,
  })  : _storage = storage ?? const FlutterSecureStorage(),
        super(AuthState.initial()) {
    checkAuth();
  }

  Future<void> checkAuth() async {
    state = AuthState.loading();
    try {
      final token = await _storage.read(key: _accessTokenKey);
      if (token == null || token.isEmpty) {
        state = AuthState.unauthenticated();
        return;
      }

      _apiClient.setAuthToken(token);
      try {
        final profile = await _apiService.getMe();
        state = AuthState.authenticated(profile, token);
      } catch (_) {
        // Try refresh token
        final refreshToken = await _storage.read(key: _refreshTokenKey);
        if (refreshToken != null) {
          final res = await _apiService.refreshToken(refreshToken);
          final newToken = res['access_token'] as String;
          final newRefreshToken = res['refresh_token'] as String;
          final userJson = res['user'] as Map<String, dynamic>;
          final profile = UserProfile.fromJson(userJson);

          await _storage.write(key: _accessTokenKey, value: newToken);
          await _storage.write(key: _refreshTokenKey, value: newRefreshToken);
          _apiClient.setAuthToken(newToken);

          state = AuthState.authenticated(profile, newToken);
        } else {
          await logout();
        }
      }
    } catch (_) {
      state = AuthState.unauthenticated();
    }
  }

  Future<bool> register({
    required String username,
    required String email,
    required String firstName,
    required String lastName,
    String? phone,
    required String password,
  }) async {
    state = AuthState.loading();
    try {
      final res = await _apiService.register(
        username: username,
        email: email,
        firstName: firstName,
        lastName: lastName,
        phone: phone,
        password: password,
      );

      final token = res['access_token'] as String;
      final refreshToken = res['refresh_token'] as String;
      final userJson = res['user'] as Map<String, dynamic>;
      final profile = UserProfile.fromJson(userJson);

      await _storage.write(key: _accessTokenKey, value: token);
      await _storage.write(key: _refreshTokenKey, value: refreshToken);
      _apiClient.setAuthToken(token);

      state = AuthState.authenticated(profile, token);
      return true;
    } catch (e) {
      state = AuthState.error(UserFacingErrorMapper.from(e).message);
      return false;
    }
  }

  Future<bool> login({
    required String login,
    required String password,
  }) async {
    state = AuthState.loading();
    try {
      final res = await _apiService.login(
        login: login,
        password: password,
      );

      final token = res['access_token'] as String;
      final refreshToken = res['refresh_token'] as String;
      final userJson = res['user'] as Map<String, dynamic>;
      final profile = UserProfile.fromJson(userJson);

      await _storage.write(key: _accessTokenKey, value: token);
      await _storage.write(key: _refreshTokenKey, value: refreshToken);
      _apiClient.setAuthToken(token);

      state = AuthState.authenticated(profile, token);
      return true;
    } catch (e) {
      state = AuthState.error(UserFacingErrorMapper.from(e).message);
      return false;
    }
  }

  Future<void> logout() async {
    try {
      await _apiService.logout();
    } catch (_) {}
    await _storage.delete(key: _accessTokenKey);
    await _storage.delete(key: _refreshTokenKey);
    _apiClient.setAuthToken(null);
    state = AuthState.unauthenticated();
  }

  Future<Map<String, dynamic>> forgotPassword(String email) async {
    return await _apiService.forgotPassword(email);
  }

  Future<void> resetPassword({
    required String token,
    required String newPassword,
  }) async {
    await _apiService.resetPassword(token: token, newPassword: newPassword);
  }
}
