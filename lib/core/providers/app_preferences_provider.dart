import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AppPreferencesProvider extends ChangeNotifier {
  AppPreferencesProvider({
    required FlutterSecureStorage secureStorage,
  }) : _secureStorage = secureStorage;

  static const String _themeModeKey = 'app_theme_mode';
  static const String _biometricEnabledKey = 'biometric_enabled';
  static const String _notificationPromptedKey = 'notification_prompted';

  final FlutterSecureStorage _secureStorage;

  ThemeMode _themeMode = ThemeMode.light;
  bool _biometricEnabled = false;
  bool _notificationPrompted = false;

  ThemeMode get themeMode => _themeMode;
  bool get biometricEnabled => _biometricEnabled;
  bool get notificationPrompted => _notificationPrompted;
  bool get isDarkMode => _themeMode == ThemeMode.dark;

  Future<void> hydrate() async {
    final storedThemeMode = await _secureStorage.read(key: _themeModeKey);
    final storedBiometric =
        await _secureStorage.read(key: _biometricEnabledKey);
    final storedNotificationPrompted =
        await _secureStorage.read(key: _notificationPromptedKey);

    // Default to light mode if not previously set
    _themeMode = storedThemeMode == 'dark' ? ThemeMode.dark : ThemeMode.light;
    _biometricEnabled = storedBiometric == 'true';
    _notificationPrompted = storedNotificationPrompted == 'true';
    notifyListeners();
  }

  Future<void> setDarkMode(bool enabled) async {
    _themeMode = enabled ? ThemeMode.dark : ThemeMode.light;
    await _secureStorage.write(
      key: _themeModeKey,
      value: enabled ? 'dark' : 'light',
    );
    notifyListeners();
  }

  Future<void> setBiometricEnabled(bool enabled) async {
    _biometricEnabled = enabled;
    await _secureStorage.write(
      key: _biometricEnabledKey,
      value: enabled.toString(),
    );
    notifyListeners();
  }

  Future<void> markNotificationPrompted() async {
    _notificationPrompted = true;
    await _secureStorage.write(
      key: _notificationPromptedKey,
      value: 'true',
    );
    notifyListeners();
  }
}
