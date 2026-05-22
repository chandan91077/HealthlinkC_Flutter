import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:healthlink_connect_flutter/app.dart';
import 'package:healthlink_connect_flutter/core/di/injection_container.dart';
import 'package:healthlink_connect_flutter/core/config/env.dart';
import 'package:healthlink_connect_flutter/services/notification_service.dart';


void main() {
  // Catch ALL uncaught async errors that would otherwise silently kill the app
  runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();

    // 1. Firebase must come first — it must succeed for FCM to work.
    //    Wrap in try/catch so a SHA-1 mismatch doesn't crash the entire app.
    try {
      await Firebase.initializeApp();
      await NotificationService().init(); // Initialize notification service
    } catch (e) {
      debugPrint('[MediConnect] Firebase.initializeApp failed: $e');
      // App will run without Firebase (notifications won't work, but it won't crash)
    }

    // 2. Load .env — critical for API_BASE_URL.  Wrapped so a missing/corrupt
    //    asset file on Play Store does NOT crash the app.
    try {
      await Env.load();
    } catch (e) {
      debugPrint('[MediConnect] Env.load failed: $e');
    }

    // 3. Dependency injection
    try {
      await configureDependencies();
    } catch (e) {
      debugPrint('[MediConnect] configureDependencies failed: $e');
    }

    // 4. Local notifications — non-critical, must never crash startup
    try {
      await sl<NotificationService>().init();
    } catch (e) {
      debugPrint(
          '[MediConnect] NotificationService.initialize failed: $e');
    }

    runApp(const App());

    // 5. Connect Socket.IO assistant (after DI is ready)
    // This enables real-time medication reminders from the backend cron job.
    // The userId is connected after user logs in via AuthProvider.
  }, (error, stack) {
    // Global error zone — log and swallow so the app doesn't hard-crash
    debugPrint('[MediConnect] Uncaught error: $error\n$stack');
  });
}
