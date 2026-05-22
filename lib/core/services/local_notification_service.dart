import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class LocalNotificationService {
  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  bool _initialized = false;
  int _notificationId = 0;

  Future<void> initialize() async {
    if (_initialized) {
      return;
    }

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );
    await _plugin.initialize(
      settings: settings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        // Handle notification tap in foreground
      },
    );

    _initialized = true;
  }

  Future<void> requestPermissions() async {
    if (!_initialized) {
      await initialize();
    }

    // Request permissions are handled by the OS when showing the first notification
    // in flutter_local_notifications 14.1.5
  }

  Future<void> showSimpleNotification({
    required String title,
    required String body,
  }) async {
    if (!_initialized) {
      await initialize();
    }

    const androidDetails = AndroidNotificationDetails(
      'healthlink_general_alerts',
      'General Alerts',
      channelDescription: 'General app alerts and updates',
      importance: Importance.max,
      priority: Priority.high,
    );
    const iosDetails = DarwinNotificationDetails();
    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );
    _notificationId += 1;
    await _plugin.show(
      id: _notificationId,
      title: title,
      body: body,
      notificationDetails: details,
      payload: null,
    );
  }

  /// Show a medication reminder — uses a dedicated high-priority channel
  Future<void> showMedicationReminder({
    required String title,
    required String body,
  }) async {
    if (!_initialized) await initialize();

    const androidDetails = AndroidNotificationDetails(
      'mediconnect_medication_channel',
      'Medication Reminders',
      channelDescription: 'Pill and medication reminders from your doctor\'s prescriptions',
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
      icon: '@mipmap/ic_launcher',
    );
    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );
    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );
    _notificationId += 1;
    await _plugin.show(
      id: _notificationId,
      title: title,
      body: body,
      notificationDetails: details,
    );
  }
}

