import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:healthlink_connect_flutter/app.dart';
import 'package:healthlink_connect_flutter/core/di/injection_container.dart';
import 'package:healthlink_connect_flutter/core/config/env.dart';
import 'package:healthlink_connect_flutter/core/services/local_notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Firebase must be initialized first – before any other Firebase service
  await Firebase.initializeApp();

  await Env.load();
  await configureDependencies();

  // Notification init may fail if permissions are denied (e.g. first launch
  // on Android 13+). Wrap to prevent a hard crash on the Play Store build.
  try {
    await sl<LocalNotificationService>().initialize();
  } catch (_) {
    // Non-fatal: app continues without local notifications
  }

  runApp(const App());
}
