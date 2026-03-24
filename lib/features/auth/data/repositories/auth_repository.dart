import 'package:healthlink_connect_flutter/core/network/api_client.dart';
import 'package:healthlink_connect_flutter/features/auth/domain/entities/auth_user.dart';
import 'package:healthlink_connect_flutter/features/auth/domain/entities/login_result.dart';

class AuthRepository {
  final ApiClient _apiClient;

  const AuthRepository(this._apiClient);

  Future<LoginResult> login({
    required String emailOrPhone,
    required String password,
  }) async {
    final credential = emailOrPhone.trim();

    final response = await _apiClient.post(
      '/api/auth/login',
      data: {
        'email':
            credential.contains('@') ? credential.toLowerCase() : credential,
        'password': password,
      },
    );

    final data = response.data;
    if (data is! Map<String, dynamic>) {
      throw const FormatException('Unexpected server response format');
    }

    return LoginResult.fromJson(data);
  }

  Future<LoginResult> googleSignIn({
    required String idToken,
    required String role,
  }) async {
    final response = await _apiClient.post(
      '/api/auth/google',
      data: {'idToken': idToken, 'role': role},
    );
    final data = response.data;
    if (data is! Map<String, dynamic>) {
      throw const FormatException('Unexpected server response format');
    }
    return LoginResult.fromJson(data);
  }

  Future<AuthUser> fetchProfile(String role) async {
    final response = await _apiClient.get('/api/auth/profile');
    final data = response.data;
    if (data is! Map<String, dynamic>) {
      throw const FormatException('Unexpected profile response format');
    }
    return AuthUser.fromJson(data, role);
  }

  Future<AuthUser> updateProfile({
    required String role,
    required String fullName,
    required String phone,
    required String locale,
    required AuthNotificationPreferences notificationPreferences,
  }) async {
    final response = await _apiClient.put(
      '/api/auth/profile',
      data: {
        'full_name': fullName,
        'phone': phone,
        'locale': locale,
        'notification_preferences': notificationPreferences.toJson(),
      },
    );
    final data = response.data;
    if (data is! Map<String, dynamic>) {
      throw const FormatException('Unexpected profile response format');
    }
    return AuthUser.fromJson(data, role);
  }
}
