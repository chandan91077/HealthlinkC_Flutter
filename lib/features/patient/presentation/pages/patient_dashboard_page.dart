import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:healthlink_connect_flutter/config/routes/app_routes.dart';
import 'package:healthlink_connect_flutter/core/di/injection_container.dart';
import 'package:healthlink_connect_flutter/core/network/api_client.dart';
import 'package:healthlink_connect_flutter/core/theme/app_colors.dart';
import 'package:healthlink_connect_flutter/features/auth/presentation/providers/auth_provider.dart';
import 'package:healthlink_connect_flutter/shared/widgets/medi_connect_header_drawer.dart';

class PatientDashboardPage extends StatefulWidget {
  const PatientDashboardPage({super.key});

  @override
  State<PatientDashboardPage> createState() => _PatientDashboardPageState();
}

class _PatientDashboardPageState extends State<PatientDashboardPage>
    with WidgetsBindingObserver {
  bool _isLoading = true;
  bool _isRefreshing = false;
  String? _error;
  List<Map<String, dynamic>> _appointments = const [];
  int _prescriptionCount = 0;
  int _conversationCount = 0;
  int _unreadNotifications = 0;
  Timer? _autoRefreshTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadDashboard();
    _autoRefreshTimer = Timer.periodic(const Duration(seconds: 20), (_) {
      if (!mounted || _isLoading || _isRefreshing) {
        return;
      }
      _loadDashboard(showLoader: false);
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _autoRefreshTimer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && mounted) {
      _loadDashboard(showLoader: false);
    }
  }

  Future<void> _loadDashboard({bool showLoader = true}) async {
    if (_isRefreshing) {
      return;
    }

    _isRefreshing = true;

    if (showLoader && mounted) {
      setState(() {
        _isLoading = true;
        _error = null;
      });
    }

    try {
      final api = sl<ApiClient>();
      final results = await Future.wait([
        api.get('/api/appointments'),
        api.get('/api/prescriptions'),
        api.get('/api/notifications/unread-count'),
        api.get('/api/messages/conversations'),
      ]);

      final appointments = _mapList(results[0].data);
      final prescriptions = _mapList(results[1].data);
      final unreadCount = (results[2].data is Map<String, dynamic>)
          ? ((results[2].data as Map<String, dynamic>)['count'] as num? ?? 0)
              .toInt()
          : 0;
      final conversations = _mapList(results[3].data);

      if (!mounted) {
        return;
      }

      setState(() {
        _appointments = appointments;
        _prescriptionCount = prescriptions.length;
        _unreadNotifications = unreadCount;
        _conversationCount = conversations.length;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      if (showLoader) {
        setState(() {
          _error = 'Failed to load dashboard data.';
        });
      }
    } finally {
      _isRefreshing = false;
      if (mounted) {
        if (showLoader) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  List<Map<String, dynamic>> _mapList(dynamic value) {
    if (value is! List) {
      return const [];
    }

    return value.whereType<Map>().map((item) {
      return item.map((key, val) => MapEntry(key.toString(), val));
    }).toList();
  }

  DateTime? _appointmentDateTime(Map<String, dynamic> appointment) {
    final date = appointment['appointment_date']?.toString();
    final time = appointment['appointment_time']?.toString();
    if (date == null || time == null) {
      return null;
    }
    return DateTime.tryParse('${date}T$time:00');
  }

  bool _isUpcoming(Map<String, dynamic> appointment) {
    final status = appointment['status']?.toString() ?? '';
    if (status == 'completed' || status == 'cancelled') {
      return false;
    }
    final dateTime = _appointmentDateTime(appointment);
    if (dateTime == null) {
      return false;
    }
    return dateTime
        .isAfter(DateTime.now().subtract(const Duration(minutes: 1)));
  }

  int get _upcomingCount => _appointments.where(_isUpcoming).length;

  int get _completedCount => _appointments
      .where((appointment) => appointment['status']?.toString() == 'completed')
      .length;

  @override
  Widget build(BuildContext context) {
    final userName = context.watch<AuthProvider>().user?.name ?? 'Patient';
    final pastCount = (_appointments.length - _upcomingCount).clamp(0, 999999);

    final coreItems = [
      _DashboardAction(
        title: 'Appointments',
        icon: Icons.calendar_month,
        caption: '$_upcomingCount upcoming • $pastCount past',
        onTap: () => context.go('${AppRoutes.appointments}?tab=upcoming'),
      ),
      _DashboardAction(
        title: 'Upload Medical Records',
        icon: Icons.upload_file_outlined,
        caption: 'Store and share with doctors',
        onTap: () => context.push(AppRoutes.medicalRecords),
      ),
      _DashboardAction(
        title: 'Prescriptions',
        icon: Icons.description_outlined,
        caption: '$_prescriptionCount prescribed by doctors',
        onTap: () => context.push(AppRoutes.prescriptions),
      ),
    ];

    final communicationItems = [
      _DashboardAction(
        title: 'Chat with Doctors',
        icon: Icons.chat_bubble_outline,
        caption: '$_conversationCount active chats',
        onTap: () => context.go(AppRoutes.chat),
      ),
      _DashboardAction(
        title: 'Notifications',
        icon: Icons.notifications_none,
        caption: '$_unreadNotifications unread alerts',
        onTap: () => context.push(AppRoutes.notifications),
      ),
    ];

    final discoveryItems = [
      _DashboardAction(
        title: 'Browse Doctors',
        icon: Icons.medical_services_outlined,
        caption: 'Verified specialists',
        onTap: () => context.go(AppRoutes.doctors),
      ),
      _DashboardAction(
        title: 'Specializations',
        icon: Icons.filter_alt_outlined,
        caption: 'Filter by specialty',
        onTap: () => context.push(AppRoutes.specializations),
      ),
      _DashboardAction(
        title: 'Payments',
        icon: Icons.payments_outlined,
        caption: 'Review bookings',
        onTap: () => context.go(AppRoutes.appointments),
      ),
    ];

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
        body: RefreshIndicator(
          onRefresh: _loadDashboard,
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _error != null
                  ? _DashboardErrorView(
                      message: _error!, onRetry: _loadDashboard)
                  : SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _PatientHero(
                            name: userName,
                            upcomingCount: _upcomingCount,
                            unreadCount: _unreadNotifications,
                          ),
                          const SizedBox(height: 16),
                          _StatsGrid(
                            items: [
                              _StatItem('Upcoming', '$_upcomingCount',
                                  Icons.calendar_today, Colors.blue),
                              _StatItem('Completed', '$_completedCount',
                                  Icons.check_circle_outline, Colors.green),
                              _StatItem('Prescriptions', '$_prescriptionCount',
                                  Icons.description_outlined, Colors.orange),
                              _StatItem(
                                  'Alerts',
                                  '$_unreadNotifications',
                                  Icons.notifications_active_outlined,
                                  Colors.purple),
                            ],
                          ),
                          const SizedBox(height: 24),
                          const _SectionHeader(title: 'Core Features'),
                          const SizedBox(height: 12),
                          _ActionGrid(items: coreItems),
                          const SizedBox(height: 24),
                          const _SectionHeader(title: 'Communication & Health'),
                          const SizedBox(height: 12),
                          _ActionGrid(items: communicationItems),
                          const SizedBox(height: 24),
                          const _SectionHeader(title: 'Discovery & Support'),
                          const SizedBox(height: 12),
                          _ActionGrid(items: discoveryItems),
                        ],
                      ),
                    ),
        ),
      ),
    );
  }
}

class _PatientHero extends StatelessWidget {
  const _PatientHero({
    required this.name,
    required this.upcomingCount,
    required this.unreadCount,
  });

  final String name;
  final int upcomingCount;
  final int unreadCount;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          colors: [Color(0xFF0D5C57), Color(0xFF17A398)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Welcome back, $name',
            style: const TextStyle(
                color: Colors.white, fontSize: 24, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Text(
            'You have $upcomingCount upcoming appointments and $unreadCount unread alerts.',
            style: const TextStyle(color: Color(0xFFE6FFFA), height: 1.4),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
    );
  }
}

class _StatsGrid extends StatelessWidget {
  const _StatsGrid({required this.items});

  final List<_StatItem> items;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 380;

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: items.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            mainAxisExtent: isCompact ? 124 : 116,
          ),
          itemBuilder: (context, index) {
            final item = items[index];
            return Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: EdgeInsets.all(isCompact ? 12 : 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(item.icon,
                        color: item.color, size: isCompact ? 22 : 24),
                    SizedBox(height: isCompact ? 8 : 10),
                    Text(
                      item.value,
                      style: TextStyle(
                        fontSize: isCompact ? 22 : 24,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.label,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: isCompact ? 12 : 13,
                        height: 1.15,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _ActionGrid extends StatelessWidget {
  const _ActionGrid({required this.items});

  final List<_DashboardAction> items;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: items.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.08,
      ),
      itemBuilder: (context, index) {
        final item = items[index];
        return Card(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: item.onTap,
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(item.icon, color: AppColors.primary),
                  ),
                  const Spacer(),
                  Text(item.title,
                      style: const TextStyle(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 4),
                  Text(item.caption,
                      style: const TextStyle(color: Colors.grey, fontSize: 12)),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _DashboardErrorView extends StatelessWidget {
  const _DashboardErrorView({required this.message, required this.onRetry});

  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 40),
              const Icon(Icons.error_outline,
                  size: 56, color: Colors.redAccent),
              const SizedBox(height: 12),
              Text(message),
              const SizedBox(height: 16),
              ElevatedButton(onPressed: onRetry, child: const Text('Retry')),
            ],
          ),
        ),
      ],
    );
  }
}

class _DashboardAction {
  const _DashboardAction({
    required this.title,
    required this.icon,
    required this.caption,
    required this.onTap,
  });

  final String title;
  final IconData icon;
  final String caption;
  final VoidCallback onTap;
}

class _StatItem {
  const _StatItem(this.label, this.value, this.icon, this.color);

  final String label;
  final String value;
  final IconData icon;
  final Color color;
}
