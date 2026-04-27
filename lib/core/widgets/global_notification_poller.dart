import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:healthlink_connect_flutter/core/di/injection_container.dart';
import 'package:healthlink_connect_flutter/core/network/api_client.dart';
import 'package:healthlink_connect_flutter/core/services/local_notification_service.dart';
import 'package:healthlink_connect_flutter/features/auth/presentation/providers/auth_provider.dart';

class GlobalNotificationPoller extends StatefulWidget {
  const GlobalNotificationPoller({super.key, required this.child});

  final Widget child;

  @override
  State<GlobalNotificationPoller> createState() =>
      _GlobalNotificationPollerState();
}

class _GlobalNotificationPollerState extends State<GlobalNotificationPoller>
    with WidgetsBindingObserver {
  static const Duration _pollInterval = Duration(seconds: 20);

  Timer? _pollTimer;
  int _lastUnreadCount = -1;
  bool _isPolling = false;
  final Set<String> _seenUnreadNotificationIds = <String>{};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _pollUnreadNotifications();
    _pollTimer =
        Timer.periodic(_pollInterval, (_) => _pollUnreadNotifications());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _pollTimer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _pollUnreadNotifications();
    }
  }

  Future<void> _pollUnreadNotifications() async {
    if (!mounted || _isPolling) {
      return;
    }

    final auth = context.read<AuthProvider>();
    if (!auth.isAuthenticated) {
      _lastUnreadCount = -1;
      _seenUnreadNotificationIds.clear();
      return;
    }

    _isPolling = true;
    try {
      final response =
          await sl<ApiClient>().get('/api/notifications/unread-count');
      final unreadCount = (response.data is Map<String, dynamic>)
          ? ((response.data as Map<String, dynamic>)['count'] as num? ?? 0)
              .toInt()
          : 0;

      final pushEnabled = auth.user?.notificationPreferences.push == true;

      if (_lastUnreadCount < 0) {
        if (pushEnabled && unreadCount > 0) {
          final unreadNotifications = await _fetchUnreadNotifications();
          for (final notification in unreadNotifications) {
            final id = notification.id;
            if (id.isNotEmpty) {
              _seenUnreadNotificationIds.add(id);
            }
          }
        }

        _lastUnreadCount = unreadCount;
        return;
      }

      final hasNewUnread = unreadCount > _lastUnreadCount;

      if (pushEnabled && hasNewUnread) {
        final unreadNotifications = await _fetchUnreadNotifications();
        final newItems = unreadNotifications
            .where((notification) =>
                notification.id.isNotEmpty &&
                !_seenUnreadNotificationIds.contains(notification.id))
            .toList();

        if (newItems.isNotEmpty) {
          for (final item in newItems.reversed) {
            await sl<LocalNotificationService>().showSimpleNotification(
              title: _titleForType(item),
              body: item.message.isNotEmpty
                  ? item.message
                  : 'You received a new notification.',
            );
          }
        } else {
          final newUnreadCount = unreadCount - _lastUnreadCount;
          await sl<LocalNotificationService>().showSimpleNotification(
            title: 'MediConnect',
            body:
                'You have $newUnreadCount new notification${newUnreadCount > 1 ? 's' : ''}.',
          );
        }

        for (final item in newItems) {
          _seenUnreadNotificationIds.add(item.id);
        }
      }

      if (unreadCount <= _lastUnreadCount) {
        final unreadNotifications = await _fetchUnreadNotifications();
        final currentUnreadIds = unreadNotifications
            .map((notification) => notification.id)
            .where((id) => id.isNotEmpty)
            .toSet();
        _seenUnreadNotificationIds
          ..clear()
          ..addAll(currentUnreadIds);
      }

      _lastUnreadCount = unreadCount;
    } catch (_) {
    } finally {
      _isPolling = false;
    }
  }

  Future<List<_UnreadNotification>> _fetchUnreadNotifications() async {
    final response = await sl<ApiClient>().get('/api/notifications');
    final data = response.data;
    if (data is! List) {
      return const [];
    }

    return data
        .whereType<Map>()
        .map((item) => item.map((k, v) => MapEntry(k.toString(), v)))
        .where((item) => item['read'] != true)
        .map(_UnreadNotification.fromJson)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}

bool _shouldShowPhoneAlert(_UnreadNotification notification) {
  return true;
}

class _UnreadNotification {
  const _UnreadNotification({
    required this.id,
    required this.message,
    required this.type,
    required this.appointmentType,
    required this.title,
  });

  factory _UnreadNotification.fromJson(Map<String, dynamic> json) {
    final rawData = json['data'];
    final data = rawData is Map
        ? rawData.map((k, v) => MapEntry(k.toString(), v))
        : <String, dynamic>{};

    return _UnreadNotification(
      id: json['_id']?.toString() ?? '',
      message: json['message']?.toString() ?? '',
      type: json['type']?.toString() ?? '',
      appointmentType: data['appointment_type']?.toString() ?? '',
      title: data['title']?.toString().trim() ?? '',
    );
  }

  final String id;
  final String message;
  final String type;
  final String appointmentType;
  final String title;
}

String _titleForType(_UnreadNotification notification) {
  if (notification.type == 'new_appointment' &&
      notification.appointmentType == 'emergency') {
    return 'Emergency Booking';
  }

  if (notification.type == 'admin_update') {
    if (notification.title.isNotEmpty) {
      return notification.title;
    }
    return 'Admin Update';
  }

  switch (notification.type) {
    case 'new_message':
      return 'New Message';
    case 'chat_available':
    case 'chat_available_confirmation':
      return 'Chat Enabled';
    case 'chat_disabled':
    case 'chat_disabled_confirmation':
      return 'Chat Disabled';
    case 'video_link':
      return 'Video Link Available';
    case 'video_call_started':
    case 'video_call_started_confirmation':
      return 'Video Session Started';
    case 'video_call_ended':
    case 'video_call_ended_confirmation':
      return 'Video Session Ended';
    case 'appointment_confirmed':
      return 'Appointment Confirmed';
    case 'new_appointment':
      return 'New Appointment';
    case 'payment_pending':
      return 'Payment Pending';
    case 'preempted':
      return 'Appointment Updated';
    default:
      return 'MediConnect';
  }
}
