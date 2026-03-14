import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:healthlink_connect_flutter/config/routes/app_routes.dart';
import 'package:healthlink_connect_flutter/core/di/injection_container.dart';
import 'package:healthlink_connect_flutter/core/network/api_client.dart';
import 'package:healthlink_connect_flutter/core/theme/app_colors.dart';
import 'package:healthlink_connect_flutter/features/auth/presentation/providers/auth_provider.dart';

class DoctorDetailsPage extends StatefulWidget {
  const DoctorDetailsPage({
    super.key,
    required this.doctorId,
    this.initialDoctor,
  });

  final String doctorId;
  final Map<String, dynamic>? initialDoctor;

  @override
  State<DoctorDetailsPage> createState() => _DoctorDetailsPageState();
}

class _DoctorDetailsPageState extends State<DoctorDetailsPage> {
  bool _isLoading = true;
  String? _error;
  Map<String, dynamic>? _doctor;
  List<Map<String, dynamic>> _availability = const [];

  @override
  void initState() {
    super.initState();
    _doctor = widget.initialDoctor;
    _loadDoctorDetails();
  }

  Future<void> _loadDoctorDetails() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final api = sl<ApiClient>();
      final responses = await Future.wait([
        api.get('/api/doctors/${widget.doctorId}'),
        api.get('/api/availability/${widget.doctorId}'),
      ]);

      final doctorData = responses[0].data;
      final availabilityData = responses[1].data;

      final mappedDoctor = doctorData is Map<String, dynamic>
          ? doctorData
          : doctorData is Map
              ? doctorData.map((k, v) => MapEntry(k.toString(), v))
              : null;

      final mappedAvailability = availabilityData is List
          ? availabilityData
              .whereType<Map>()
              .map((item) => item.map((k, v) => MapEntry(k.toString(), v)))
              .toList()
          : <Map<String, dynamic>>[];

      if (!mounted) {
        return;
      }

      setState(() {
        _doctor = mappedDoctor;
        _availability = mappedAvailability;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _error = 'Failed to load doctor details.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  String _doctorName() {
    final user = _doctor?['user_id'];
    if (user is Map<String, dynamic>) {
      return _doctorDisplayName(user['full_name']?.toString());
    }
    return 'Dr. Doctor';
  }

  String _doctorDisplayName(String? rawName) {
    final name = (rawName ?? 'Doctor').trim();
    final normalized =
        name.replaceFirst(RegExp(r'^dr\.?\s*', caseSensitive: false), '');
    return 'Dr. ${normalized.isEmpty ? 'Doctor' : normalized}';
  }

  String _resolveImageUrl(String? rawUrl) {
    final url = (rawUrl ?? '').trim();
    if (url.isEmpty) {
      return '';
    }
    if (url.startsWith('http://') || url.startsWith('https://')) {
      return url;
    }

    try {
      return Uri.parse(sl<ApiClient>().baseUrl).resolve(url).toString();
    } catch (_) {
      return '';
    }
  }

  String _dayLabel(int day) {
    const names = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
    if (day < 0 || day >= names.length) {
      return 'Day';
    }
    return names[day];
  }

  List<String> _availabilityLabels() {
    return _availability
        .where((slot) => slot['is_available'] != false)
        .map((slot) {
      final day = (slot['day_of_week'] as num?)?.toInt() ?? -1;
      final start = slot['start_time']?.toString() ?? '--:--';
      final end = slot['end_time']?.toString() ?? '--:--';
      return '${_dayLabel(day)} ($start - $end)';
    }).toList();
  }

  Future<void> _showCertificateSheet() async {
    final certificateUrl = _doctor?['medical_license_url']?.toString() ?? '';

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Doctor Certificate',
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 12),
                if (certificateUrl.isEmpty)
                  const Text('Certificate is not available.')
                else ...[
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: InteractiveViewer(
                      maxScale: 4,
                      child: Image.network(
                        certificateUrl,
                        fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) => Container(
                          padding: const EdgeInsets.all(16),
                          color: Colors.grey.shade100,
                          child: const Text(
                            'Certificate preview is not available as image.',
                            style: TextStyle(color: Colors.black54),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Pinch to zoom certificate image.',
                    style: TextStyle(color: Colors.black54),
                  ),
                ],
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Close'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.black54,
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

  @override
  Widget build(BuildContext context) {
    final canBookAppointment = sl<AuthProvider>().role != 'doctor';
    final name = _doctorName();
    final specialization = _doctor?['specialization']?.toString() ?? 'General';
    final experience = (_doctor?['experience_years'] as num?)?.toInt() ?? 0;
    final fee = (_doctor?['consultation_fee'] as num?)?.toInt() ?? 0;
    final emergencyFee = (_doctor?['emergency_fee'] as num?)?.toInt() ?? 0;
    final state = _doctor?['state']?.toString() ?? '';
    final location = _doctor?['location']?.toString() ?? '';
    final bio = _doctor?['bio']?.toString() ?? '';
    final user = _doctor?['user_id'];
    final email = user is Map<String, dynamic>
        ? user['email']?.toString() ?? 'N/A'
        : 'N/A';
    final avatarUrl = _resolveImageUrl(
      user is Map<String, dynamic> ? user['avatar_url']?.toString() : null,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Doctor Details'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!))
              : _doctor == null
                  ? const Center(child: Text('Doctor details not found.'))
                  : RefreshIndicator(
                      onRefresh: _loadDoctorDetails,
                      child: ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.all(16),
                        children: [
                          Card(
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    radius: 30,
                                    backgroundColor: AppColors.primary,
                                    backgroundImage: avatarUrl.isNotEmpty
                                        ? NetworkImage(avatarUrl)
                                        : null,
                                    child: avatarUrl.isEmpty
                                        ? const Icon(Icons.person,
                                            color: Colors.white)
                                        : null,
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          name,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w700,
                                            fontSize: 18,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          specialization,
                                          style: const TextStyle(
                                            color: AppColors.textSecondary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Card(
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Profile',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 16,
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  _detailRow('Experience', '$experience years'),
                                  _detailRow('Consultation Fee', '₹$fee'),
                                  _detailRow('Emergency Fee', '₹$emergencyFee'),
                                  _detailRow('Email', email),
                                  _detailRow(
                                    'Location',
                                    [location, state]
                                            .where((e) => e.isNotEmpty)
                                            .join(', ')
                                            .isEmpty
                                        ? 'N/A'
                                        : [location, state]
                                            .where((e) => e.isNotEmpty)
                                            .join(', '),
                                  ),
                                  if (bio.isNotEmpty) _detailRow('Bio', bio),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Card(
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Availability',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 16,
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  if (_availabilityLabels().isEmpty)
                                    const Text('No availability shared yet.')
                                  else
                                    ..._availabilityLabels().map(
                                      (label) => Padding(
                                        padding:
                                            const EdgeInsets.only(bottom: 6),
                                        child: Text('• $label'),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: _showCertificateSheet,
                                  child: const Text('View Certificate'),
                                ),
                              ),
                              if (canBookAppointment) ...[
                                const SizedBox(width: 10),
                                Expanded(
                                  child: ElevatedButton(
                                    onPressed: () => context.push(
                                      AppRoutes.bookAppointment.replaceFirst(
                                          ':doctorId', widget.doctorId),
                                    ),
                                    child: const Text('Book Appointment'),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
    );
  }
}
