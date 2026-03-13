import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:healthlink_connect_flutter/core/di/injection_container.dart';
import 'package:healthlink_connect_flutter/core/network/api_client.dart';
import 'package:healthlink_connect_flutter/features/auth/presentation/providers/auth_provider.dart';

class AppointmentDetailsPage extends StatefulWidget {
  const AppointmentDetailsPage({
    super.key,
    required this.appointmentId,
    this.initialAppointment,
  });

  final String appointmentId;
  final Map<String, dynamic>? initialAppointment;

  @override
  State<AppointmentDetailsPage> createState() => _AppointmentDetailsPageState();
}

class _AppointmentDetailsPageState extends State<AppointmentDetailsPage> {
  bool _isLoading = true;
  bool _isUpdatingStatus = false;
  bool _isUpdatingPermissions = false;
  String? _error;
  Map<String, dynamic>? _appointment;

  @override
  void initState() {
    super.initState();
    _appointment = widget.initialAppointment;
    _isLoading = _appointment == null;
    _loadAppointment(showLoader: _appointment == null);
  }

  String get _role => context.read<AuthProvider>().role ?? 'patient';
  bool get _isDoctor => _role == 'doctor';
  String get _status => _appointment?['status']?.toString() ?? 'pending';
  bool get _chatUnlocked => _appointment?['chat_unlocked'] == true;

  Future<void> _loadAppointment({bool showLoader = true}) async {
    if (showLoader) {
      setState(() {
        _isLoading = true;
        _error = null;
      });
    } else {
      setState(() {
        _error = null;
      });
    }

    try {
      final api = sl<ApiClient>();

      try {
        final detailsResponse =
            await api.get('/api/appointments/${widget.appointmentId}');
        final data = detailsResponse.data;
        if (data is Map<String, dynamic>) {
          _appointment = data;
        }
      } catch (_) {
        final listResponse = await api.get('/api/appointments');
        final data = listResponse.data;
        if (data is List) {
          final list = data.whereType<Map>().map((item) {
            return item.map((key, value) => MapEntry(key.toString(), value));
          }).toList();

          _appointment = list.cast<Map<String, dynamic>>().firstWhere(
                (item) => item['_id']?.toString() == widget.appointmentId,
                orElse: () => <String, dynamic>{},
              );
          if (_appointment != null && _appointment!.isEmpty) {
            _appointment = null;
          }
        }
      }

      if (!mounted) {
        return;
      }

      if (_appointment == null) {
        setState(() {
          _error = 'Appointment details not found.';
        });
      }
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _error = 'Failed to load appointment details.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _updateAppointmentStatus(String status) async {
    setState(() {
      _isUpdatingStatus = true;
    });

    try {
      final response = await sl<ApiClient>().put(
        '/api/appointments/${widget.appointmentId}',
        data: {'status': status},
      );

      final data = response.data;
      if (data is Map<String, dynamic>) {
        setState(() {
          _appointment = data;
        });
      }

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Appointment marked as ${status.trim()}.')),
      );
    } catch (_) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to update appointment status.')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isUpdatingStatus = false;
        });
      }
    }
  }

  Future<void> _toggleChatAccess() async {
    final nextChatState = !_chatUnlocked;

    setState(() {
      _isUpdatingPermissions = true;
    });

    try {
      final response = await sl<ApiClient>().put(
        '/api/appointments/${widget.appointmentId}/permissions',
        data: {'chat_unlocked': nextChatState},
      );

      final data = response.data;
      if (data is Map<String, dynamic>) {
        setState(() {
          _appointment = data;
        });
      }

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            nextChatState
                ? 'Chat enabled for this appointment.'
                : 'Chat disabled for this appointment.',
          ),
        ),
      );
    } catch (_) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to update chat access.')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isUpdatingPermissions = false;
        });
      }
    }
  }

  String _readPartyName(dynamic value, String fallback) {
    if (value is Map<String, dynamic>) {
      if (value['full_name'] != null) {
        return value['full_name'].toString();
      }
      final user = value['user_id'];
      if (user is Map<String, dynamic> && user['full_name'] != null) {
        return user['full_name'].toString();
      }
    }
    return fallback;
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.black54,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  Widget _doctorActionsCard() {
    final canMarkCompleted = _status != 'completed' && _status != 'cancelled';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Doctor Actions',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            if (canMarkCompleted)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isUpdatingStatus
                      ? null
                      : () => _updateAppointmentStatus('completed'),
                  icon: _isUpdatingStatus
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.check_circle_outline),
                  label: const Text('Mark As Done'),
                ),
              )
            else
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _status == 'completed'
                      ? 'This appointment is marked as completed on both doctor and patient views.'
                      : 'No further completion action is available for this appointment.',
                ),
              ),
            if (_status == 'completed') ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _isUpdatingPermissions ? null : _toggleChatAccess,
                  icon: _isUpdatingPermissions
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Icon(
                          _chatUnlocked
                              ? Icons.chat_bubble_outline
                              : Icons.chat,
                        ),
                  label: Text(
                    _chatUnlocked ? 'Disable Chat' : 'Enable Chat',
                  ),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: TextButton.icon(
                  onPressed: () =>
                      context.push('/chat/${widget.appointmentId}'),
                  icon: const Icon(Icons.open_in_new),
                  label: const Text('Open Chat Controls'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Appointment Details'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!))
              : _appointment == null
                  ? const Center(child: Text('Appointment details not found.'))
                  : RefreshIndicator(
                      onRefresh: _loadAppointment,
                      child: ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.all(16),
                        children: [
                          Card(
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Overview',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  _detailRow(
                                    'Appointment ID',
                                    _appointment!['_id']?.toString() ??
                                        widget.appointmentId,
                                  ),
                                  _detailRow(
                                    'Doctor',
                                    _readPartyName(
                                      _appointment!['doctor_id'],
                                      'Doctor',
                                    ),
                                  ),
                                  _detailRow(
                                    'Patient',
                                    _readPartyName(
                                      _appointment!['patient_id'],
                                      'Patient',
                                    ),
                                  ),
                                  _detailRow(
                                    'Date',
                                    _appointment!['appointment_date']
                                            ?.toString() ??
                                        'N/A',
                                  ),
                                  _detailRow(
                                    'Time',
                                    _appointment!['appointment_time']
                                            ?.toString() ??
                                        'N/A',
                                  ),
                                  _detailRow(
                                    'Status',
                                    (_appointment!['status']
                                                ?.toString()
                                                .toUpperCase() ??
                                            'PENDING')
                                        .replaceAll('_', ' '),
                                  ),
                                  _detailRow(
                                    'Amount',
                                    '₹${(_appointment!['amount'] as num?)?.toInt() ?? 0}',
                                  ),
                                  _detailRow(
                                    'Payment',
                                    _appointment!['payment_status']
                                            ?.toString() ??
                                        'N/A',
                                  ),
                                  _detailRow(
                                    'Reason',
                                    _appointment!['reason']?.toString() ??
                                        'N/A',
                                  ),
                                  _detailRow(
                                    'Notes',
                                    _appointment!['notes']?.toString() ?? 'N/A',
                                  ),
                                ],
                              ),
                            ),
                          ),
                          if (_isDoctor) ...[
                            const SizedBox(height: 16),
                            _doctorActionsCard(),
                          ],
                        ],
                      ),
                    ),
    );
  }
}
