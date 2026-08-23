import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/networking/api_client.dart';
import '../models/user_profile.dart';

final authApiServiceProvider = Provider<AuthApiService>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return AuthApiService(apiClient);
});

class AuthApiService {
  final ApiClient _client;

  AuthApiService(this._client);

  Future<Map<String, dynamic>> register({
    required String username,
    required String email,
    required String firstName,
    required String lastName,
    String? phone,
    required String password,
  }) async {
    return await _client.post('/auth/register', {
      'username': username,
      'email': email,
      'first_name': firstName,
      'last_name': lastName,
      if (phone != null && phone.isNotEmpty) 'phone': phone,
      'password': password,
    });
  }

  Future<Map<String, dynamic>> login({
    required String login,
    required String password,
  }) async {
    return await _client.post('/auth/login', {
      'login': login,
      'password': password,
    });
  }

  Future<Map<String, dynamic>> refreshToken(String refreshToken) async {
    return await _client.post('/auth/refresh', {
      'refresh_token': refreshToken,
    });
  }

  Future<void> logout() async {
    try {
      await _client.post('/auth/logout', {});
    } catch (_) {}
  }

  Future<Map<String, dynamic>> forgotPassword(String email) async {
    return await _client.post('/auth/forgot-password', {
      'email': email,
    });
  }

  Future<void> resetPassword({
    required String token,
    required String newPassword,
  }) async {
    await _client.post('/auth/reset-password', {
      'token': token,
      'new_password': newPassword,
    });
  }

  Future<UserProfile> getMe() async {
    final res = await _client.get('/me');
    return UserProfile.fromJson(res);
  }
}
