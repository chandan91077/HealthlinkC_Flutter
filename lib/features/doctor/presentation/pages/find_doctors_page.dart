import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:healthlink_connect_flutter/config/routes/app_routes.dart';
import 'package:healthlink_connect_flutter/core/di/injection_container.dart';
import 'package:healthlink_connect_flutter/core/network/api_client.dart';
import 'package:healthlink_connect_flutter/core/theme/app_colors.dart';
import 'package:healthlink_connect_flutter/features/auth/presentation/providers/auth_provider.dart';
import 'package:healthlink_connect_flutter/features/doctor/presentation/pages/doctor_details_page.dart';

class FindDoctorsPage extends StatefulWidget {
  const FindDoctorsPage({super.key});

  @override
  State<FindDoctorsPage> createState() => _FindDoctorsPageState();
}

class _FindDoctorsPageState extends State<FindDoctorsPage> {
  bool _isLoading = true;
  String? _error;
  List<Map<String, dynamic>> _doctors = const [];
  String _searchQuery = '';
  String _selectedSpecialization = 'All';
  String _selectedState = 'All';

  @override
  void initState() {
    super.initState();
    _loadDoctors();
  }

  Future<void> _loadDoctors() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final response = await sl<ApiClient>().get('/api/doctors');
      final data = response.data;
      final doctors = data is List
          ? data
              .whereType<Map>()
              .map((item) => item.map((k, v) => MapEntry(k.toString(), v)))
              .toList()
          : <Map<String, dynamic>>[];

      if (!mounted) {
        return;
      }

      setState(() {
        _doctors = doctors;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _error = 'Failed to load doctors from server.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  List<Map<String, dynamic>> get _visibleDoctors {
    final query = _searchQuery.trim().toLowerCase();
    return _doctors.where((doctor) {
      final user = doctor['user_id'];
      final name = user is Map<String, dynamic>
          ? (user['full_name']?.toString() ?? '')
          : '';
      final specialization = doctor['specialization']?.toString() ?? '';
      final location = doctor['location']?.toString() ?? '';
      final state = doctor['state']?.toString() ?? '';

      final matchesSearch = query.isEmpty ||
          name.toLowerCase().contains(query) ||
          specialization.toLowerCase().contains(query) ||
          location.toLowerCase().contains(query) ||
          state.toLowerCase().contains(query);

      final matchesSpecialization = _selectedSpecialization == 'All' ||
          specialization.toLowerCase() == _selectedSpecialization.toLowerCase();

      final matchesState = _selectedState == 'All' ||
          state.toLowerCase() == _selectedState.toLowerCase();

      return matchesSearch && matchesSpecialization && matchesState;
    }).toList();
  }

  List<String> get _specializations {
    final values = _doctors
        .map((doctor) => doctor['specialization']?.toString() ?? '')
        .where((value) => value.trim().isNotEmpty)
        .toSet()
        .toList()
      ..sort();
    return ['All', ...values];
  }

  List<String> get _states {
    final values = _doctors
        .map((doctor) => doctor['state']?.toString() ?? '')
        .where((value) => value.trim().isNotEmpty)
        .toSet()
        .toList()
      ..sort();
    return ['All', ...values];
  }

  String _doctorName(Map<String, dynamic> doctor) {
    final user = doctor['user_id'];
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

  void _openCertificate(Map<String, dynamic> doctor) {
    final certificateUrl = doctor['medical_license_url']?.toString() ?? '';
    final name = _doctorName(doctor);

    showModalBottomSheet(
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
                  'Certificate • $name',
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 12),
                if (certificateUrl.isEmpty)
                  const Text('Certificate is not available for this doctor.')
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
                  const SizedBox(height: 12),
                  const Text(
                    'Pinch to zoom certificate image.',
                    style: TextStyle(color: Colors.black54),
                  ),
                ],
                const SizedBox(height: 16),
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

  @override
  Widget build(BuildContext context) {
    final canBookAppointment = sl<AuthProvider>().role != 'doctor';
    final visibleCount = _visibleDoctors.length;

    return Container(
      color: Colors.white,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            color: AppColors.backgroundLight,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Find Your Doctor',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$visibleCount doctors available',
                  style: const TextStyle(color: AppColors.textSecondary),
                ),
                const SizedBox(height: 12),
                TextField(
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                    });
                  },
                  decoration: InputDecoration(
                    hintText: 'Search by name, specialty, or location...',
                    prefixIcon:
                        const Icon(Icons.search, color: AppColors.primary),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: _buildDropdownFilter(
                        label: 'Specialization',
                        value: _selectedSpecialization,
                        items: _specializations,
                        onChanged: (value) {
                          if (value == null) return;
                          setState(() => _selectedSpecialization = value);
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _buildDropdownFilter(
                        label: 'State',
                        value: _selectedState,
                        items: _states,
                        onChanged: (value) {
                          if (value == null) return;
                          setState(() => _selectedState = value);
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    onPressed: () {
                      setState(() {
                        _searchQuery = '';
                        _selectedSpecialization = 'All';
                        _selectedState = 'All';
                      });
                    },
                    icon: const Icon(Icons.filter_alt_off_outlined),
                    label: const Text('Clear Filters'),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? RefreshIndicator(
                        onRefresh: _loadDoctors,
                        child: ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          children: [
                            const SizedBox(height: 80),
                            Center(child: Text(_error!)),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadDoctors,
                        child: _visibleDoctors.isEmpty
                            ? ListView(
                                physics: const AlwaysScrollableScrollPhysics(),
                                children: const [
                                  SizedBox(height: 80),
                                  Center(
                                      child: Text(
                                          'No doctors found for your search.')),
                                ],
                              )
                            : ListView.builder(
                                physics: const AlwaysScrollableScrollPhysics(),
                                padding: const EdgeInsets.all(16),
                                itemCount: _visibleDoctors.length,
                                itemBuilder: (context, index) {
                                  final doctor = _visibleDoctors[index];
                                  final doctorId =
                                      doctor['_id']?.toString() ?? '';
                                  final name = _doctorName(doctor);
                                  final specialization =
                                      doctor['specialization']?.toString() ??
                                          'General';
                                  final experience =
                                      (doctor['experience_years'] as num?)
                                              ?.toInt() ??
                                          0;
                                  final fee =
                                      (doctor['consultation_fee'] as num?)
                                              ?.toInt() ??
                                          0;
                                  final emergencyFee =
                                      (doctor['emergency_fee'] as num?)
                                              ?.toInt() ??
                                          0;
                                  final state =
                                      doctor['state']?.toString() ?? '';
                                  final location =
                                      doctor['location']?.toString() ?? '';
                                  final bio = doctor['bio']?.toString() ?? '';
                                  final user = doctor['user_id'];
                                  final avatarUrl = _resolveImageUrl(
                                    doctor['profile_image_url']?.toString() ??
                                        (user is Map<String, dynamic>
                                            ? user['avatar_url']?.toString()
                                            : null),
                                  );

                                  return Card(
                                    margin: const EdgeInsets.only(bottom: 12),
                                    child: InkWell(
                                      borderRadius: BorderRadius.circular(12),
                                      onTap: doctorId.isEmpty
                                          ? null
                                          : () => Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (_) =>
                                                      DoctorDetailsPage(
                                                    doctorId: doctorId,
                                                    initialDoctor: doctor,
                                                  ),
                                                ),
                                              ),
                                      child: Padding(
                                        padding: const EdgeInsets.all(14),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                CircleAvatar(
                                                  radius: 28,
                                                  backgroundColor:
                                                      AppColors.primary,
                                                  backgroundImage: avatarUrl
                                                          .isNotEmpty
                                                      ? NetworkImage(avatarUrl)
                                                      : null,
                                                  child: avatarUrl.isEmpty
                                                      ? const Icon(Icons.person,
                                                          color: Colors.white)
                                                      : null,
                                                ),
                                                const SizedBox(width: 12),
                                                Expanded(
                                                  child: Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      Text(
                                                        name,
                                                        style: const TextStyle(
                                                          fontSize: 16,
                                                          fontWeight:
                                                              FontWeight.w700,
                                                        ),
                                                      ),
                                                      const SizedBox(height: 4),
                                                      Text(
                                                        specialization,
                                                        style: const TextStyle(
                                                          color: AppColors
                                                              .textSecondary,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 12),
                                            Text(
                                                'Experience: $experience years'),
                                            Text('Consultation Fee: ₹$fee'),
                                            Text(
                                                'Emergency Fee: ₹$emergencyFee'),
                                            if (state.isNotEmpty ||
                                                location.isNotEmpty)
                                              Text('Location: ${[
                                                location,
                                                state
                                              ].where((e) => e.isNotEmpty).join(', ')}'),
                                            if (bio.isNotEmpty) ...[
                                              const SizedBox(height: 6),
                                              Text(
                                                bio,
                                                maxLines: 3,
                                                overflow: TextOverflow.ellipsis,
                                                style: const TextStyle(
                                                  color:
                                                      AppColors.textSecondary,
                                                ),
                                              ),
                                            ],
                                            const SizedBox(height: 12),
                                            SizedBox(
                                              width: double.infinity,
                                              child: ElevatedButton(
                                                onPressed: doctorId.isEmpty
                                                    ? null
                                                    : () => Navigator.push(
                                                          context,
                                                          MaterialPageRoute(
                                                            builder: (_) =>
                                                                DoctorDetailsPage(
                                                              doctorId:
                                                                  doctorId,
                                                              initialDoctor:
                                                                  doctor,
                                                            ),
                                                          ),
                                                        ),
                                                child:
                                                    const Text('View Details'),
                                              ),
                                            ),
                                            if (canBookAppointment) ...[
                                              const SizedBox(height: 8),
                                              SizedBox(
                                                width: double.infinity,
                                                child: OutlinedButton(
                                                  onPressed: doctorId.isEmpty
                                                      ? null
                                                      : () => context.push(
                                                            AppRoutes
                                                                .bookAppointment
                                                                .replaceFirst(
                                                                    ':doctorId',
                                                                    doctorId),
                                                          ),
                                                  child: const Text(
                                                      'Book Appointment'),
                                                ),
                                              ),
                                            ],
                                            const SizedBox(height: 8),
                                            Align(
                                              alignment: Alignment.centerLeft,
                                              child: TextButton.icon(
                                                onPressed: () =>
                                                    _openCertificate(doctor),
                                                icon: const Icon(
                                                    Icons.verified_outlined),
                                                label: const Text(
                                                    'View Certificate'),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdownFilter({
    required String label,
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return DropdownButtonFormField<String>(
      initialValue: items.contains(value) ? value : 'All',
      isExpanded: true,
      decoration: InputDecoration(
        labelText: label,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
      items: items
          .map(
            (item) => DropdownMenuItem<String>(
              value: item,
              child: Text(item),
            ),
          )
          .toList(),
      onChanged: onChanged,
    );
  }
}
