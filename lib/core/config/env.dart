import 'package:flutter_dotenv/flutter_dotenv.dart';

class Env {
  Env._();

  // Hardcoded fallback so a missing/corrupt .env on Play Store never crashes the app
  static const String _fallbackBaseUrl =
      'https://healthcare-booking-platform.onrender.com';

  static Future<void> load() async {
    try {
      await dotenv.load(fileName: '.env');
    } catch (_) {
      // .env failed to load (e.g. corrupted asset in release build).
      // The fallback URL below will be used automatically.
    }
  }

  static String get apiBaseUrl {
    final value = dotenv.env['API_BASE_URL']?.trim() ?? '';
    // If .env didn't load or the key is missing, use the hardcoded fallback.
    return value.isNotEmpty ? value : _fallbackBaseUrl;
  }
}

