import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:healthlink_connect_flutter/config/routes/app_routes.dart';
import 'package:healthlink_connect_flutter/core/di/injection_container.dart';
import 'package:healthlink_connect_flutter/core/network/api_client.dart';
import 'package:healthlink_connect_flutter/core/theme/app_colors.dart';
import 'package:healthlink_connect_flutter/features/auth/presentation/providers/auth_provider.dart';
import 'package:healthlink_connect_flutter/shared/widgets/medi_connect_header_drawer.dart';

class DoctorDashboardPage extends StatefulWidget {
  const DoctorDashboardPage({super.key});

  @override
  State<DoctorDashboardPage> createState() => _DoctorDashboardPageState();
}

class _DoctorDashboardPageState extends State<DoctorDashboardPage> {
  bool _isLoading = true;
  String? _error;
  Map<String, dynamic>? _doctorProfile;
  String _verificationStatus = 'pending';
  String _rejectionReason = '';
  List<Map<String, dynamic>> _appointments = const [];
  int _conversationCount = 0;
  int _unreadNotifications = 0;
  int _prescriptionCount = 0;

  @override
  void initState() {
    super.initState();
    _loadDashboard();
  }

  Future<void> _loadDashboard() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final api = sl<ApiClient>();
      final authProvider = sl<AuthProvider>();
      final doctorUserId = authProvider.user?.id?.trim() ?? '';

      if (doctorUserId.isEmpty) {
        throw const FormatException('Unable to resolve doctor account.');
      }

      final doctorResponse = await api.get('/api/doctors/user/$doctorUserId');
      final doctorProfile = _mapObject(doctorResponse.data);

      if (doctorProfile == null) {
        throw const FormatException('Doctor profile not found.');
      }

      final isVerified = doctorProfile['is_verified'] == true;
      final verificationStatus =
          doctorProfile['verification_status']?.toString().toLowerCase() ??
              'pending';
      final rejectionReason =
          doctorProfile['rejection_reason']?.toString().trim() ?? '';

      if (!mounted) {
        return;
      }

      if (!isVerified) {
        setState(() {
          _doctorProfile = doctorProfile;
          _verificationStatus = verificationStatus;
          _rejectionReason = rejectionReason;
          _appointments = const [];
          _conversationCount = 0;
          _unreadNotifications = 0;
          _prescriptionCount = 0;
          _isLoading = false;
        });
        return;
      }

      final results = await Future.wait([
        api.get('/api/appointments'),
        api.get('/api/messages/conversations'),
        api.get('/api/notifications/unread-count'),
        api.get('/api/prescriptions'),
      ]);

      if (!mounted) {
        return;
      }

      setState(() {
        _doctorProfile = doctorProfile;
        _verificationStatus = verificationStatus;
        _rejectionReason = rejectionReason;
        _appointments = _mapList(results[0].data);
        _conversationCount = _mapList(results[1].data).length;
        _unreadNotifications = (results[2].data is Map<String, dynamic>)
            ? ((results[2].data as Map<String, dynamic>)['count'] as num? ?? 0)
                .toInt()
            : 0;
        _prescriptionCount = _mapList(results[3].data).length;
      });
    } on DioException catch (error) {
      if (!mounted) {
        return;
      }

      if (error.response?.statusCode == 404) {
        setState(() {
          _doctorProfile = const {
            'is_verified': false,
            'verification_status': 'pending',
          };
          _verificationStatus = 'pending';
          _rejectionReason = '';
          _error = null;
          _appointments = const [];
          _conversationCount = 0;
          _unreadNotifications = 0;
          _prescriptionCount = 0;
        });
      } else {
        setState(() {
          _error = 'Failed to load doctor dashboard.';
        });
      }
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _error = 'Failed to load doctor dashboard.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
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

  Map<String, dynamic>? _mapObject(dynamic value) {
    if (value is Map<String, dynamic>) {
      return value;
    }
    if (value is Map) {
      return value.map((key, val) => MapEntry(key.toString(), val));
    }
    return null;
  }

  DateTime? _appointmentDateTime(Map<String, dynamic> appointment) {
    final date = appointment['appointment_date']?.toString();
    final time = appointment['appointment_time']?.toString();
    if (date == null || time == null) {
      return null;
    }
    return DateTime.tryParse('${date}T$time:00');
  }

  String _todayString() {
    final now = DateTime.now();
    final month = now.month.toString().padLeft(2, '0');
    final day = now.day.toString().padLeft(2, '0');
    return '${now.year}-$month-$day';
  }

  int get _todayCount => _appointments.where((appointment) {
        return appointment['appointment_date']?.toString() == _todayString() &&
            appointment['status']?.toString() != 'cancelled';
      }).length;

  int get _pendingCount => _appointments
      .where((appointment) => appointment['status']?.toString() == 'pending')
      .length;

  int get _totalEarnings => _appointments.fold<int>(0, (sum, appointment) {
        if (appointment['payment_status']?.toString() == 'paid') {
          return sum + ((appointment['amount'] as num?)?.toInt() ?? 0);
        }
        return sum;
      });

  int get _totalPatients {
    final patientIds = <String>{};
    for (final appointment in _appointments) {
      final patient = appointment['patient_id'];
      if (patient is Map<String, dynamic>) {
        final id = patient['_id']?.toString();
        if (id != null && id.isNotEmpty) {
          patientIds.add(id);
        }
      }
    }
    return patientIds.length;
  }

  List<Map<String, dynamic>> get _todayQueue {
    final items = _appointments.where((appointment) {
      return appointment['appointment_date']?.toString() == _todayString() &&
          appointment['status']?.toString() != 'cancelled' &&
          appointment['status']?.toString() != 'completed';
    }).toList();
    items.sort((a, b) {
      final aDate = _appointmentDateTime(a) ?? DateTime(1970);
      final bDate = _appointmentDateTime(b) ?? DateTime(1970);
      return aDate.compareTo(bDate);
    });
    return items.take(5).toList();
  }

  Future<void> _markAppointmentDone(String appointmentId) async {
    if (appointmentId.isEmpty) {
      return;
    }

    try {
      await sl<ApiClient>().put(
        '/api/appointments/$appointmentId',
        data: {'status': 'completed'},
      );

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Appointment marked as completed.')),
      );

      await _loadDashboard();
    } catch (_) {
      if (!mounted) {
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
    final quickActions = [
      _DoctorAction(
          'Appointments',
          Icons.calendar_today,
          '${_appointments.length} records',
          () => context.go(AppRoutes.appointments)),
      _DoctorAction(
          'Messages',
          Icons.chat_bubble_outline,
          '$_conversationCount conversations',
          () => context.push(AppRoutes.chat)),
      _DoctorAction(
          'Notifications',
          Icons.notifications_none,
          '$_unreadNotifications unread',
          () => context.push(AppRoutes.notifications)),
      _DoctorAction(
          'Prescriptions',
          Icons.description_outlined,
          '$_prescriptionCount issued',
          () => context.push(AppRoutes.prescriptions)),
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
                  ? _DoctorErrorView(message: _error!, onRetry: _loadDashboard)
                  : (_doctorProfile != null &&
                          _doctorProfile!['is_verified'] != true)
                      ? _DoctorVerificationGate(
                          verificationStatus: _verificationStatus,
                          rejectionReason: _rejectionReason,
                        )
                      : SingleChildScrollView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(20),
                                  gradient: const LinearGradient(
                                    colors: [
                                      Color(0xFF0D5C57),
                                      Color(0xFF2A9D8F)
                                    ],
                                  ),
                                ),
                                child: const Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Doctor Dashboard',
                                        style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 24,
                                            fontWeight: FontWeight.w700)),
                                    SizedBox(height: 8),
                                    Text(
                                        'Track appointments, patients, conversations, and earnings in one place.',
                                        style: TextStyle(
                                            color: Color(0xFFE6FFFA))),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 16),
                              GridView.count(
                                crossAxisCount: 2,
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                crossAxisSpacing: 12,
                                mainAxisSpacing: 12,
                                childAspectRatio: 1.2,
                                children: [
                                  _DoctorStatCard(
                                      'Today\'s Appointments',
                                      '$_todayCount',
                                      Icons.calendar_today,
                                      Colors.blue),
                                  _DoctorStatCard(
                                      'Pending Requests',
                                      '$_pendingCount',
                                      Icons.hourglass_bottom,
                                      Colors.orange),
                                  _DoctorStatCard(
                                      'Total Earnings',
                                      '₹$_totalEarnings',
                                      Icons.account_balance_wallet,
                                      Colors.green),
                                  _DoctorStatCard(
                                      'Patients Served',
                                      '$_totalPatients',
                                      Icons.people_outline,
                                      Colors.purple),
                                ],
                              ),
                              const SizedBox(height: 24),
                              Text('Quick Actions',
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleLarge
                                      ?.copyWith(fontWeight: FontWeight.w700)),
                              const SizedBox(height: 12),
                              GridView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: quickActions.length,
                                gridDelegate:
                                    const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 2,
                                  crossAxisSpacing: 12,
                                  mainAxisSpacing: 12,
                                  childAspectRatio: 1.2,
                                ),
                                itemBuilder: (context, index) {
                                  final item = quickActions[index];
                                  return Card(
                                    shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(16)),
                                    child: InkWell(
                                      borderRadius: BorderRadius.circular(16),
                                      onTap: item.onTap,
                                      child: Padding(
                                        padding: const EdgeInsets.all(16),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Icon(item.icon,
                                                color: AppColors.primary),
                                            const Spacer(),
                                            Text(item.title,
                                                style: const TextStyle(
                                                    fontWeight:
                                                        FontWeight.w700)),
                                            const SizedBox(height: 4),
                                            Text(item.caption,
                                                style: const TextStyle(
                                                    color: Colors.grey,
                                                    fontSize: 12)),
                                          ],
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                              const SizedBox(height: 24),
                              Text('Patient Queue - Today',
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleLarge
                                      ?.copyWith(fontWeight: FontWeight.w700)),
                              const SizedBox(height: 12),
                              if (_todayQueue.isEmpty)
                                const _DoctorEmptyBlock(
                                    message:
                                        'No appointments scheduled for today.')
                              else
                                ..._todayQueue
                                    .map((appointment) => _DoctorQueueCard(
                                          appointment: appointment,
                                          onMarkDone: _markAppointmentDone,
                                        )),
                            ],
                          ),
                        ),
        ),
      ),
    );
  }
}

class _DoctorVerificationGate extends StatelessWidget {
  const _DoctorVerificationGate({
    required this.verificationStatus,
    required this.rejectionReason,
  });

  final String verificationStatus;
  final String rejectionReason;

  @override
  Widget build(BuildContext context) {
    final isRejected = verificationStatus == 'rejected';

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      isRejected ? Icons.cancel_outlined : Icons.hourglass_top,
                      color: isRejected ? Colors.redAccent : Colors.orange,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      isRejected
                          ? 'Verification Rejected'
                          : 'Verification Pending',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  isRejected
                      ? 'Your doctor profile was not approved. Please contact support or update your profile details and reapply.'
                      : 'Your doctor account is under admin review. You will get access after verification is approved.',
                  style: const TextStyle(color: Colors.black87),
                ),
                const SizedBox(height: 14),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isRejected
                        ? const Color(0xFFFFF1F2)
                        : const Color(0xFFFFF8E1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    isRejected && rejectionReason.isNotEmpty
                        ? 'Reason: $rejectionReason'
                        : isRejected
                            ? 'Reason: Not provided by admin.'
                            : 'Verification usually takes 1-2 business days.',
                    style: TextStyle(
                      color: isRejected ? Colors.redAccent : Colors.orange[900],
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _DoctorStatCard extends StatelessWidget {
  const _DoctorStatCard(this.title, this.value, this.icon, this.color);

  final String title;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 16),
            Text(value,
                style:
                    const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(title,
                style: const TextStyle(color: Colors.grey, fontSize: 12)),
          ],
        ),
      ),
    );
  }
}

class _DoctorQueueCard extends StatelessWidget {
  const _DoctorQueueCard({
    required this.appointment,
    required this.onMarkDone,
  });

  final Map<String, dynamic> appointment;
  final Future<void> Function(String appointmentId) onMarkDone;

  @override
  Widget build(BuildContext context) {
    final patient = appointment['patient_id'];
    final patientName = patient is Map<String, dynamic>
        ? patient['full_name']?.toString() ?? 'Patient'
        : 'Patient';
    final time = appointment['appointment_time']?.toString() ?? '--:--';
    final status = appointment['status']?.toString() ?? 'pending';
    final appointmentId = appointment['_id']?.toString() ?? '';
    final canMarkDone = appointmentId.isNotEmpty &&
        status != 'completed' &&
        status != 'cancelled';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: const CircleAvatar(child: Icon(Icons.person)),
        title: Text(patientName),
        subtitle: Text('$time • ${status.toUpperCase()}'),
        trailing: Wrap(
          spacing: 8,
          children: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () {
                if (appointmentId.isNotEmpty) {
                  context.push(AppRoutes.chat);
                } else {
                  context.go(AppRoutes.appointments);
                }
              },
              child: const Text('Open'),
            ),
            if (canMarkDone)
              OutlinedButton(
                onPressed: () => onMarkDone(appointmentId),
                child: const Text('Mark Done'),
              ),
          ],
        ),
      ),
    );
  }
}

class _DoctorEmptyBlock extends StatelessWidget {
  const _DoctorEmptyBlock({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: Text(message, style: const TextStyle(color: Colors.grey)),
    );
  }
}

class _DoctorErrorView extends StatelessWidget {
  const _DoctorErrorView({required this.message, required this.onRetry});

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

class _DoctorAction {
  const _DoctorAction(this.title, this.icon, this.caption, this.onTap);

  final String title;
  final IconData icon;
  final String caption;
  final VoidCallback onTap;
}
