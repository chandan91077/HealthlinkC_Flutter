import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:healthlink_connect_flutter/features/auth/data/repositories/auth_repository.dart';
import 'package:healthlink_connect_flutter/features/auth/domain/entities/auth_user.dart';

class AuthProvider extends ChangeNotifier {
  AuthProvider({
    required AuthRepository authRepository,
    required FlutterSecureStorage secureStorage,
  })  : _authRepository = authRepository,
        _secureStorage = secureStorage;

  static const String _tokenKey = 'auth_token';
  static const String _roleKey = 'user_role';

  final AuthRepository _authRepository;
  final FlutterSecureStorage _secureStorage;

  bool _isLoading = false;
  String? _errorMessage;
  String? _token;
  String? _role;
  AuthUser? _user;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String? get token => _token;
  String? get role => _role;
  AuthUser? get user => _user;
  bool get isAuthenticated => (_token ?? '').isNotEmpty;

  Future<void> hydrate() async {
    _token = await _secureStorage.read(key: _tokenKey);
    _role = await _secureStorage.read(key: _roleKey);
    notifyListeners();
    if (isAuthenticated) {
      await fetchProfile();
    }
  }

  Future<void> fetchProfile() async {
    if (!isAuthenticated || _role == null) return;
    try {
      _user = await _authRepository.fetchProfile(_role!);
    } catch (_) {
      // Silently fail — user stays authenticated
    } finally {
      notifyListeners();
    }
  }

  Future<bool> updateProfile({
    required String fullName,
    required String phone,
    required String locale,
    required AuthNotificationPreferences notificationPreferences,
  }) async {
    if (!isAuthenticated || _role == null) return false;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      _user = await _authRepository.updateProfile(
        role: _role!,
        fullName: fullName,
        phone: phone,
        locale: locale,
        notificationPreferences: notificationPreferences,
      );
      return true;
    } catch (_) {
      _errorMessage = 'Failed to update profile. Please try again.';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> login({
    required String emailOrPhone,
    required String password,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await _authRepository.login(
        emailOrPhone: emailOrPhone,
        password: password,
      );

      _token = result.token;
      _role = result.role;
      _user = result.user;

      await _secureStorage.write(key: _tokenKey, value: result.token);
      await _secureStorage.write(key: _roleKey, value: result.role);

      return true;
    } catch (e) {
      _errorMessage = _extractErrorMessage(e);
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    _token = null;
    _role = null;
    _user = null;
    _errorMessage = null;

    await _secureStorage.delete(key: _tokenKey);
    await _secureStorage.delete(key: _roleKey);
    notifyListeners();
  }

  String _extractErrorMessage(Object error) {
    if (error is DioException) {
      final data = error.response?.data;
      if (data is Map<String, dynamic>) {
        final message = data['message']?.toString().trim();
        if (message != null && message.isNotEmpty) {
          return message;
        }
      }
    }

    if (error is FormatException) {
      return error.message;
    }

    return 'Login failed. Please verify your credentials.';
  }
}
