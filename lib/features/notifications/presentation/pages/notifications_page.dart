import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:healthlink_connect_flutter/config/routes/app_routes.dart';
import 'package:healthlink_connect_flutter/core/di/injection_container.dart';
import 'package:healthlink_connect_flutter/core/network/api_client.dart';
import 'package:healthlink_connect_flutter/shared/widgets/medi_connect_header_drawer.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  bool _isLoading = true;
  String? _error;
  List<_NotificationItem> _notifications = const [];

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final response = await sl<ApiClient>().get('/api/notifications');
      final data = response.data;
      final list = data is List
          ? data
              .whereType<Map>()
              .map((item) => item.map((k, v) => MapEntry(k.toString(), v)))
              .toList()
          : <Map<String, dynamic>>[];

      if (!mounted) {
        return;
      }

      setState(() {
        _notifications = list.map(_NotificationItem.fromJson).toList();
      });
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _error = 'Failed to load notifications from server.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _markAllRead() async {
    try {
      await sl<ApiClient>().put('/api/notifications/mark-all-read');
    } catch (_) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to mark notifications as read.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      for (final notification in _notifications) {
        notification.isUnread = false;
      }
    });
  }

  Future<void> _clearAll() async {
    if (_notifications.isEmpty) {
      return;
    }

    try {
      await sl<ApiClient>().delete('/api/notifications/clear-all');
    } catch (_) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to clear notifications.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (!mounted) {
      return;
    }

    setState(() {
      _notifications = const [];
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('All notifications cleared.'),
      ),
    );
  }

  Future<void> _removeNotification(_NotificationItem notification) async {
    if (notification.isUnread) {
      await _markSingleRead(notification);
    }
    setState(() {
      _notifications.removeWhere((item) => item.id == notification.id);
    });
  }

  Future<void> _markSingleRead(_NotificationItem notification) async {
    if (!notification.isUnread || notification.id.isEmpty) {
      return;
    }

    try {
      await sl<ApiClient>().put('/api/notifications/${notification.id}/read');
      if (!mounted) {
        return;
      }
      setState(() {
        notification.isUnread = false;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to update notification status.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _handleNotificationTap(_NotificationItem notification) async {
    await _markSingleRead(notification);

    final appointmentId = notification.data['appointment_id']?.toString() ?? '';
    final zoomUrl = notification.data['zoom_join_url']?.toString() ?? '';

    if (!mounted) {
      return;
    }

    if (zoomUrl.isNotEmpty) {
      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Video Link'),
          content: SelectableText(zoomUrl),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        ),
      );
      return;
    }

    if (appointmentId.isNotEmpty) {
      context.push(AppRoutes.appointmentDetailsById(appointmentId));
    }
  }

  IconData _iconForType(String type) {
    switch (type) {
      case 'chat_available':
      case 'chat_available_confirmation':
      case 'chat_disabled':
      case 'chat_disabled_confirmation':
        return Icons.chat_bubble_outline;
      case 'video_link':
      case 'video_call_started':
      case 'video_call_started_confirmation':
      case 'video_call_ended':
      case 'video_call_ended_confirmation':
        return Icons.video_call_outlined;
      case 'appointment_confirmed':
      case 'payment_pending':
        return Icons.check_circle_outline;
      case 'preempted':
        return Icons.priority_high;
      default:
        return Icons.notifications_none;
    }
  }

  Color _colorForType(String type) {
    switch (type) {
      case 'chat_available':
      case 'chat_available_confirmation':
        return Colors.green;
      case 'chat_disabled':
      case 'chat_disabled_confirmation':
        return Colors.orange;
      case 'video_link':
        return Colors.blue;
      case 'video_call_started':
      case 'video_call_started_confirmation':
        return Colors.green;
      case 'video_call_ended':
      case 'video_call_ended_confirmation':
        return Colors.red;
      case 'appointment_confirmed':
        return Colors.teal;
      case 'payment_pending':
        return Colors.orange;
      case 'preempted':
        return Colors.red;
      default:
        return Colors.indigo;
    }
  }

  String _titleForType(String type) {
    switch (type) {
      case 'chat_available':
        return 'Chat Enabled';
      case 'chat_disabled':
        return 'Chat Disabled';
      case 'video_link':
        return 'Video Link Available';
      case 'chat_available_confirmation':
        return 'Chat Enabled';
      case 'chat_disabled_confirmation':
        return 'Chat Disabled';
      case 'video_call_started':
      case 'video_call_started_confirmation':
        return 'Video Session Started';
      case 'video_call_ended':
      case 'video_call_ended_confirmation':
        return 'Video Session Ended';
      case 'appointment_confirmed':
        return 'Appointment Confirmed';
      case 'payment_pending':
        return 'Payment Pending';
      case 'preempted':
        return 'Appointment Updated';
      default:
        return 'Notification';
    }
  }

  String _timeAgo(DateTime? createdAt) {
    if (createdAt == null) {
      return 'Just now';
    }

    final diff = DateTime.now().difference(createdAt);
    if (diff.inMinutes < 1) {
      return 'Just now';
    }
    if (diff.inHours < 1) {
      return '${diff.inMinutes}m ago';
    }
    if (diff.inDays < 1) {
      return '${diff.inHours}h ago';
    }
    return '${diff.inDays}d ago';
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop || !context.mounted) {
          return;
        }
        final navigator = Navigator.of(context);
        if (navigator.canPop()) {
          navigator.pop();
          return;
        }
        context.go(AppRoutes.home);
      },
      child: Scaffold(
        appBar: const MediConnectHeader(forceBackToHome: true),
        drawer: const MediConnectDrawer(),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Notifications',
                      style:
                          TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
                    ),
                  ),
                  TextButton(
                    onPressed: _notifications.isEmpty ? null : _markAllRead,
                    child: const Text('Mark all read'),
                  ),
                  PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'clear') {
                        _clearAll();
                      }
                    },
                    itemBuilder: (context) => const [
                      PopupMenuItem<String>(
                        value: 'clear',
                        child: Text('Clear all'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _error != null
                      ? ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          children: [
                            const SizedBox(height: 80),
                            Center(child: Text(_error!)),
                          ],
                        )
                      : _notifications.isEmpty
                          ? RefreshIndicator(
                              onRefresh: _loadNotifications,
                              child: const _EmptyNotificationsView(),
                            )
                          : ListView.separated(
                              physics: const AlwaysScrollableScrollPhysics(),
                              itemCount: _notifications.length,
                              separatorBuilder: (context, index) =>
                                  const Divider(height: 1),
                              itemBuilder: (context, index) {
                                final notification = _notifications[index];
                                return Dismissible(
                                  key: ValueKey(notification.id),
                                  direction: DismissDirection.endToStart,
                                  background: Container(
                                    color: Colors.red.shade400,
                                    alignment: Alignment.centerRight,
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 20),
                                    child: const Icon(Icons.delete_outline,
                                        color: Colors.white),
                                  ),
                                  onDismissed: (_) =>
                                      _removeNotification(notification),
                                  child: Container(
                                    color: notification.isUnread
                                        ? Colors.blue.withValues(alpha: 0.05)
                                        : Colors.transparent,
                                    child: ListTile(
                                      leading: CircleAvatar(
                                        backgroundColor:
                                            _colorForType(notification.type)
                                                .withValues(alpha: 0.2),
                                        child: Icon(
                                          _iconForType(notification.type),
                                          color:
                                              _colorForType(notification.type),
                                        ),
                                      ),
                                      title: Text(
                                        _titleForType(notification.type),
                                        style: TextStyle(
                                          fontWeight: notification.isUnread
                                              ? FontWeight.bold
                                              : FontWeight.normal,
                                        ),
                                      ),
                                      subtitle: Padding(
                                        padding: const EdgeInsets.only(top: 4),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(notification.message),
                                            const SizedBox(height: 4),
                                            Text(
                                              _timeAgo(notification.createdAt),
                                              style: const TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.grey),
                                            ),
                                          ],
                                        ),
                                      ),
                                      trailing: notification.isUnread
                                          ? const Icon(Icons.circle,
                                              size: 10, color: Colors.blue)
                                          : null,
                                      onTap: () =>
                                          _handleNotificationTap(notification),
                                    ),
                                  ),
                                );
                              },
                            ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NotificationItem {
  _NotificationItem({
    required this.id,
    required this.type,
    required this.message,
    required this.isUnread,
    required this.createdAt,
    required this.data,
  });

  factory _NotificationItem.fromJson(Map<String, dynamic> json) {
    return _NotificationItem(
      id: json['_id']?.toString() ?? '',
      type: json['type']?.toString() ?? 'info',
      message: json['message']?.toString() ?? '',
      isUnread: json['read'] != true,
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? ''),
      data: (json['data'] is Map)
          ? (json['data'] as Map).map((k, v) => MapEntry(k.toString(), v))
          : <String, dynamic>{},
    );
  }

  _NotificationItem copyWith({
    bool? isUnread,
  }) {
    return _NotificationItem(
      id: id,
      type: type,
      message: message,
      isUnread: isUnread ?? this.isUnread,
      createdAt: createdAt,
      data: data,
    );
  }

  final String id;
  final String type;
  final String message;
  final DateTime? createdAt;
  final Map<String, dynamic> data;
  bool isUnread;
}

class _EmptyNotificationsView extends StatelessWidget {
  const _EmptyNotificationsView();

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: const [
        SizedBox(height: 120),
        Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.notifications_off_outlined,
                    size: 56, color: Colors.grey),
                SizedBox(height: 12),
                Text(
                  'No notifications',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
                SizedBox(height: 6),
                Text(
                  'New updates and alerts from server will show here.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
