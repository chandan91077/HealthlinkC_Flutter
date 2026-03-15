import 'package:flutter/material.dart';
import 'package:healthlink_connect_flutter/app.dart';
import 'package:healthlink_connect_flutter/core/di/injection_container.dart';
import 'package:healthlink_connect_flutter/core/config/env.dart';
import 'package:healthlink_connect_flutter/core/services/local_notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Env.load();
  await configureDependencies();
  await sl<LocalNotificationService>().initialize();
  runApp(const App());
}
