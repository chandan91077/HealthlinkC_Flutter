import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;
import 'package:healthlink_connect_flutter/core/services/local_notification_service.dart';

/// MediAI Assistant Socket Service
/// Connects to the backend Socket.IO server. Listens for real-time events:
///  - assistant:notification  → medication reminders, appointment alerts
///  - assistant:response      → pushed assistant replies (future use)
class AssistantSocketService {
  AssistantSocketService({required this.notificationService});

  final LocalNotificationService notificationService;

  io.Socket? _socket;
  String? _connectedUserId;
  bool _isConnected = false;

  bool get isConnected => _isConnected;

  // External listeners (e.g. AssistantProvider can subscribe)
  final StreamController<Map<String, dynamic>> _notificationStream =
      StreamController.broadcast();

  Stream<Map<String, dynamic>> get notificationStream =>
      _notificationStream.stream;

  // ─── Connect ──────────────────────────────────────────────────────────────

  void connect({required String baseUrl, required String userId, String? sessionId}) {
    if (_isConnected && _connectedUserId == userId) return;

    disconnect(); // clean up any previous socket

    _socket = io.io(
      baseUrl,
      io.OptionBuilder()
          .setTransports(['websocket', 'polling'])
          .disableAutoConnect()
          .build(),
    );

    _socket!.onConnect((_) {
      _isConnected = true;
      _connectedUserId = userId;
      debugPrint('[AssistantSocket] Connected ✅');

      // Join the user's personal room
      _socket!.emit('assistant:join', {
        'userId': userId,
        if (sessionId != null) 'sessionId': sessionId,
      });
    });

    _socket!.on('assistant:notification', (data) async {
      debugPrint('[AssistantSocket] Notification received: $data');

      final payload = Map<String, dynamic>.from(data as Map);
      _notificationStream.add(payload);

      final type = payload['type'] as String? ?? 'general';
      final message = payload['message'] as String? ?? 'You have a new notification.';

      // Show native heads-up notification
      await notificationService.showMedicationReminder(
        title: type == 'medication' ? '💊 Medication Reminder' : '🔔 MediConnect',
        body: message,
      );
    });

    _socket!.onDisconnect((_) {
      _isConnected = false;
      debugPrint('[AssistantSocket] Disconnected');
    });

    _socket!.onError((error) {
      debugPrint('[AssistantSocket] Error: $error');
    });

    _socket!.connect();
  }

  // ─── Disconnect ───────────────────────────────────────────────────────────

  void disconnect() {
    if (_socket != null) {
      if (_connectedUserId != null) {
        _socket!.emit('assistant:leave', {'userId': _connectedUserId});
      }
      _socket!.disconnect();
      _socket!.dispose();
      _socket = null;
    }
    _isConnected = false;
    _connectedUserId = null;
  }

  void dispose() {
    disconnect();
    _notificationStream.close();
  }
}
