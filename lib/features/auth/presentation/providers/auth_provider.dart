import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:healthlink_connect_flutter/core/services/google_sign_in_service.dart';
import 'package:healthlink_connect_flutter/features/auth/data/repositories/auth_repository.dart';
import 'package:healthlink_connect_flutter/features/auth/domain/entities/auth_user.dart';
import 'package:healthlink_connect_flutter/core/network/api_client.dart';

class AuthProvider extends ChangeNotifier {
  AuthProvider({
    required AuthRepository authRepository,
    required FlutterSecureStorage secureStorage,
    required GoogleSignInService googleSignInService,
    required ApiClient apiClient,
  })  : _authRepository = authRepository,
        _secureStorage = secureStorage,
        _googleSignInService = googleSignInService,
        _apiClient = apiClient;

  static const String _tokenKey = 'auth_token';
  static const String _roleKey = 'user_role';

  final AuthRepository _authRepository;
  final FlutterSecureStorage _secureStorage;
  final GoogleSignInService _googleSignInService;
  final ApiClient _apiClient;

  bool _isLoading = false;
  String? _errorMessage;
  String? _token;
  String? _role;
  AuthUser? _user;

  /// For doctors: whether their profile has been verified by admin.
  /// null = not yet fetched / not a doctor.
  /// true  = verified.
  /// false = pending or rejected.
  bool? _isDoctorVerified;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String? get token => _token;
  String? get role => _role;
  AuthUser? get user => _user;
  bool get isAuthenticated => (_token ?? '').isNotEmpty;

  /// Returns true only when the doctor has been verified.
  /// For patients / admins this always returns true (no gate needed).
  bool get isDoctorVerified {
    if (_role != 'doctor') return true;
    return _isDoctorVerified ?? false;
  }

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

      // For doctors, also fetch verification status
      if (_role == 'doctor') {
        await _fetchDoctorVerification();
      }
    } catch (_) {
      // Silently fail — user stays authenticated
    } finally {
      notifyListeners();
    }
  }

  /// Fetches the doctor profile to check is_verified.
  Future<void> _fetchDoctorVerification() async {
    final userId = _user?.id?.trim() ?? '';
    if (userId.isEmpty) return;
    try {
      final response = await _apiClient.get('/api/doctors/user/$userId');
      final data = response.data;
      if (data is Map<String, dynamic>) {
        _isDoctorVerified = data['is_verified'] == true;
      }
    } catch (_) {
      // If we can't fetch, default to not-verified to be safe
      _isDoctorVerified = false;
    }
  }

  /// Call this after doctor is verified by admin so the guard unlocks immediately.
  Future<void> refreshDoctorVerification() async {
    if (_role != 'doctor') return;
    await _fetchDoctorVerification();
    notifyListeners();
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

  Future<bool> signInWithGoogle({required String role}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final idToken = await _googleSignInService.getIdToken();
      if (idToken == null) {
        _errorMessage = 'Google Sign-In was cancelled.';
        return false;
      }

      final result = await _authRepository.googleSignIn(
        idToken: idToken,
        role: role,
      );

      _token = result.token;
      _role = result.role;
      _user = result.user;
      _isDoctorVerified = null;

      await _secureStorage.write(key: _tokenKey, value: result.token);
      await _secureStorage.write(key: _roleKey, value: result.role);

      // Fetch verification status right away for doctors
      if (result.role == 'doctor') {
        await _fetchDoctorVerification();
      }

      return true;
    } catch (e) {
      _errorMessage = _extractErrorMessage(e);
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
      _isDoctorVerified = null;

      await _secureStorage.write(key: _tokenKey, value: result.token);
      await _secureStorage.write(key: _roleKey, value: result.role);

      // Fetch verification status right away for doctors
      if (result.role == 'doctor') {
        await _fetchDoctorVerification();
      }

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
    _isDoctorVerified = null;

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

    if (error is FirebaseAuthException) {
      final message = error.message?.trim();
      if (message != null && message.isNotEmpty) {
        return message;
      }

      if (error.code == 'missing-google-id-token') {
        return 'Google ID token was not generated. Verify Firebase Google Sign-In setup.';
      }
      if (error.code == 'missing-firebase-id-token') {
        return 'Firebase session token could not be created. Please try again.';
      }
      return 'Google Sign-In failed. Please try again.';
    }

    return 'Login failed. Please verify your credentials.';
  }
}

