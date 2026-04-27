import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:healthlink_connect_flutter/config/routes/app_routes.dart';
import 'package:healthlink_connect_flutter/core/di/injection_container.dart';
import 'package:healthlink_connect_flutter/core/network/api_client.dart';
import 'package:healthlink_connect_flutter/features/auth/presentation/providers/auth_provider.dart';

class AppointmentsPage extends StatefulWidget {
  const AppointmentsPage({
    super.key,
    this.initialTab,
  });

  final String? initialTab;

  @override
  State<AppointmentsPage> createState() => _AppointmentsPageState();
}

class _AppointmentsPageState extends State<AppointmentsPage>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late TabController _tabController;
  bool _isLoading = true;
  bool _isRefreshing = false;
  String? _error;
  List<Map<String, dynamic>> _appointments = const [];
  Timer? _autoRefreshTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: _initialTabIndex(widget.initialTab),
    );
    _loadAppointments();
    _autoRefreshTimer = Timer.periodic(const Duration(seconds: 20), (_) {
      if (!mounted || _isLoading || _isRefreshing) {
        return;
      }
      _loadAppointments(showLoader: false);
    });
  }

  int _initialTabIndex(String? tab) {
    switch ((tab ?? '').toLowerCase()) {
      case 'past':
      case 'history':
        return 1;
      case 'upcoming':
      default:
        return 0;
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _autoRefreshTimer?.cancel();
    _tabController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && mounted) {
      _loadAppointments(showLoader: false);
    }
  }

  Future<void> _loadAppointments({bool showLoader = true}) async {
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
      final response = await sl<ApiClient>().get('/api/appointments');
      final data = response.data;
      final appointments = data is List
          ? data
              .whereType<Map>()
              .map((item) => item.map((k, v) => MapEntry(k.toString(), v)))
              .toList()
          : <Map<String, dynamic>>[];
      if (!mounted) {
        return;
      }
      setState(() {
        _appointments = appointments;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      if (showLoader) {
        setState(() {
          _error = 'Failed to load appointments.';
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

  DateTime? _appointmentDateTime(Map<String, dynamic> appointment) {
    final date = appointment['appointment_date']?.toString();
    final time = appointment['appointment_time']?.toString();
    if (date == null || time == null) {
      return null;
    }
    return DateTime.tryParse('${date}T$time:00');
  }

  List<Map<String, dynamic>> get _upcomingAppointments =>
      _appointments.where((appointment) {
        final status = appointment['status']?.toString() ?? '';
        if (status == 'completed' || status == 'cancelled') {
          return false;
        }
        final dateTime = _appointmentDateTime(appointment);
        return dateTime != null &&
            dateTime
                .isAfter(DateTime.now().subtract(const Duration(minutes: 1)));
      }).toList()
        ..sort((a, b) {
          final aDate = _appointmentDateTime(a) ?? DateTime(9999);
          final bDate = _appointmentDateTime(b) ?? DateTime(9999);
          return aDate.compareTo(bDate);
        });

  List<Map<String, dynamic>> get _pastAppointments =>
      _appointments.where((appointment) {
        final status = appointment['status']?.toString() ?? '';
        if (status == 'completed' || status == 'cancelled') {
          return true;
        }
        final dateTime = _appointmentDateTime(appointment);
        return dateTime == null || dateTime.isBefore(DateTime.now());
      }).toList()
        ..sort((a, b) {
          final aDate = _appointmentDateTime(a) ?? DateTime(1970);
          final bDate = _appointmentDateTime(b) ?? DateTime(1970);
          return bDate.compareTo(aDate);
        });

  @override
  Widget build(BuildContext context) {
    final role = context.watch<AuthProvider>().role ?? 'patient';

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Appointments'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Upcoming'),
            Tab(text: 'Past'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!))
              : RefreshIndicator(
                  onRefresh: _loadAppointments,
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _AppointmentList(
                        appointments: _upcomingAppointments,
                        role: role,
                        showBookAppointmentWhenEmpty: role == 'patient',
                        onAppointmentsChanged: _loadAppointments,
                      ),
                      _AppointmentList(
                        appointments: _pastAppointments,
                        role: role,
                        showBookAppointmentWhenEmpty: false,
                        onAppointmentsChanged: _loadAppointments,
                      ),
                    ],
                  ),
                ),
    );
  }
}

class _AppointmentList extends StatelessWidget {
  const _AppointmentList({
    required this.appointments,
    required this.role,
    required this.showBookAppointmentWhenEmpty,
    required this.onAppointmentsChanged,
  });

  final List<Map<String, dynamic>> appointments;
  final String role;
  final bool showBookAppointmentWhenEmpty;
  final Future<void> Function() onAppointmentsChanged;

  Future<void> _confirmAndMarkDone(
    BuildContext context,
    String appointmentId,
    String otherPartyName,
  ) async {
    final shouldMarkDone = await showDialog<bool>(
          context: context,
          builder: (dialogContext) {
            return AlertDialog(
              title: const Text('Mark appointment as done?'),
              content: Text(
                'This will mark $otherPartyName\'s appointment as completed.',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(false),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.of(dialogContext).pop(true),
                  child: const Text('Confirm'),
                ),
              ],
            );
          },
        ) ??
        false;

    if (!shouldMarkDone || appointmentId.isEmpty) {
      return;
    }

    try {
      await sl<ApiClient>().put(
        '/api/appointments/$appointmentId',
        data: {'status': 'completed'},
      );

      if (!context.mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Appointment marked as completed.')),
      );

      await onAppointmentsChanged();
    } catch (_) {
      if (!context.mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to mark appointment as completed.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (appointments.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          const SizedBox(height: 80),
          const Center(child: Text('No appointments found.')),
          if (showBookAppointmentWhenEmpty) ...[
            const SizedBox(height: 16),
            Center(
              child: ElevatedButton.icon(
                onPressed: () => context.go(AppRoutes.doctors),
                icon: const Icon(Icons.add_circle_outline),
                label: const Text('Book Appointment'),
              ),
            ),
          ],
        ],
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: appointments.length,
      itemBuilder: (context, index) {
        final appointment = appointments[index];
        final doctor = appointment['doctor_id'];
        final patient = appointment['patient_id'];
        final otherPartyName = role == 'doctor'
            ? (patient is Map<String, dynamic>
                ? patient['full_name']?.toString() ?? 'Patient'
                : 'Patient')
            : (doctor is Map<String, dynamic> &&
                    doctor['user_id'] is Map<String, dynamic>
                ? doctor['user_id']['full_name']?.toString() ?? 'Doctor'
                : 'Doctor');
        final appointmentId = appointment['_id']?.toString() ?? '';
        final status = appointment['status']?.toString() ?? 'pending';
        final paymentStatus = appointment['payment_status']?.toString() ?? '';
        final amount = (appointment['amount'] as num?)?.toInt() ?? 0;

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        otherPartyName,
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w700),
                      ),
                    ),
                    _StatusChip(status: status),
                  ],
                ),
                if (paymentStatus == 'pending') ...[
                  const SizedBox(height: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.orange.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Colors.orange.withValues(alpha: 0.4),
                      ),
                    ),
                    child: const Text(
                      'PAYMENT PENDING',
                      style: TextStyle(
                        color: Colors.orange,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 6),
                Text(
                    '${appointment['appointment_date']} • ${appointment['appointment_time']}'),
                const SizedBox(height: 4),
                Text('Amount: ₹$amount'),
                const SizedBox(height: 4),
                Text(
                    'Appointment ID: ${appointmentId.isEmpty ? 'N/A' : appointmentId}'),
                if (paymentStatus.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text('Payment: $paymentStatus'),
                ],
                if ((appointment['reason']?.toString().isNotEmpty ??
                    false)) ...[
                  const SizedBox(height: 4),
                  Text('Reason: ${appointment['reason']}'),
                ],
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    if (appointmentId.isNotEmpty)
                      ElevatedButton(
                        onPressed: () async {
                          await context.push(
                            AppRoutes.appointmentDetailsById(appointmentId),
                            extra: appointment,
                          );
                          await onAppointmentsChanged();
                        },
                        child: const Text('View Details'),
                      ),
                    if (appointmentId.isNotEmpty)
                      OutlinedButton(
                        onPressed: () => context.push('/chat/$appointmentId'),
                        child: const Text('Open Chat'),
                      ),
                    if (role == 'doctor' &&
                        appointmentId.isNotEmpty &&
                        status == 'confirmed')
                      OutlinedButton(
                        onPressed: () => _confirmAndMarkDone(
                          context,
                          appointmentId,
                          otherPartyName,
                        ),
                        child: const Text('Mark Done'),
                      ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    Color color;
    switch (status) {
      case 'completed':
        color = Colors.green;
        break;
      case 'confirmed':
        color = Colors.blue;
        break;
      case 'cancelled':
        color = Colors.red;
        break;
      default:
        color = Colors.orange;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status.toUpperCase(),
        style:
            TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w700),
      ),
    );
  }
}
