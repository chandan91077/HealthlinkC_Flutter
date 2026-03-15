import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:healthlink_connect_flutter/config/routes/app_routes.dart';
import 'package:healthlink_connect_flutter/core/di/injection_container.dart';
import 'package:healthlink_connect_flutter/core/network/api_client.dart';
import 'package:healthlink_connect_flutter/features/auth/domain/entities/auth_user.dart';
import 'package:healthlink_connect_flutter/features/auth/presentation/providers/auth_provider.dart';
import 'package:healthlink_connect_flutter/core/theme/app_colors.dart';
import 'package:healthlink_connect_flutter/features/auth/presentation/pages/auth_page.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, _) {
        if (!authProvider.isAuthenticated) {
          return const AuthPage(
            initialIsLogin: true,
            embeddedInShell: true,
          );
        }

        return _ProfileBody(authProvider: authProvider);
      },
    );
  }
}

class _ProfileBody extends StatefulWidget {
  const _ProfileBody({required this.authProvider});
  final AuthProvider authProvider;

  @override
  State<_ProfileBody> createState() => _ProfileBodyState();
}

class _ProfileBodyState extends State<_ProfileBody> {
  Map<String, dynamic>? _doctorProfile;
  List<Map<String, dynamic>> _doctorAvailability = const [];
  bool _isDoctorPracticeLoading = false;
  bool _isDoctorPhotoUploading = false;
  String? _doctorPracticeError;
  final ImagePicker _imagePicker = ImagePicker();

  bool get _isDoctorRole => widget.authProvider.role == 'doctor';

  @override
  void initState() {
    super.initState();
    // Refresh profile data every time this page is shown
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.authProvider.fetchProfile();
      _loadDoctorPracticeData();
    });
  }

  void _openEditSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _EditProfileSheet(authProvider: widget.authProvider),
    );
  }

  Future<void> _loadDoctorPracticeData() async {
    if (!_isDoctorRole) {
      return;
    }

    final userId = widget.authProvider.user?.id;
    if (userId == null || userId.isEmpty) {
      return;
    }

    setState(() {
      _isDoctorPracticeLoading = true;
      _doctorPracticeError = null;
    });

    try {
      final api = sl<ApiClient>();
      final doctorResponse = await api.get('/api/doctors/user/$userId');
      final doctorData = doctorResponse.data;
      final doctorProfile = doctorData is Map<String, dynamic>
          ? doctorData
          : doctorData is Map
              ? doctorData.map((k, v) => MapEntry(k.toString(), v))
              : null;

      if (doctorProfile == null) {
        throw Exception('Doctor profile not found');
      }

      final doctorId = doctorProfile['_id']?.toString() ?? '';
      List<Map<String, dynamic>> availability = const [];

      if (doctorId.isNotEmpty) {
        final availabilityResponse =
            await api.get('/api/availability/$doctorId');
        final data = availabilityResponse.data;
        availability = data is List
            ? data
                .whereType<Map>()
                .map((item) => item.map((k, v) => MapEntry(k.toString(), v)))
                .toList()
            : <Map<String, dynamic>>[];
      }

      if (!mounted) {
        return;
      }

      setState(() {
        _doctorProfile = doctorProfile;
        _doctorAvailability = availability;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _doctorPracticeError = 'Failed to load doctor practice details.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isDoctorPracticeLoading = false;
        });
      }
    }
  }

  String _availabilitySummary() {
    if (_doctorAvailability.isEmpty) {
      return 'Not set';
    }

    const labels = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
    final active = _doctorAvailability
        .where((entry) => entry['is_available'] != false)
        .toList();
    if (active.isEmpty) {
      return 'No active days';
    }

    final chunks = active.map((entry) {
      final day = (entry['day_of_week'] as num?)?.toInt() ?? -1;
      final dayLabel = (day >= 0 && day < labels.length) ? labels[day] : 'Day';
      final start = entry['start_time']?.toString() ?? '--:--';
      final end = entry['end_time']?.toString() ?? '--:--';
      return '$dayLabel $start-$end';
    }).toList();

    return chunks.join(', ');
  }

  Future<void> _openEditDoctorPracticeSheet() async {
    if (_doctorProfile == null) {
      await _loadDoctorPracticeData();
    }
    if (!mounted || _doctorProfile == null) {
      return;
    }

    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _EditDoctorPracticeSheet(
        doctorProfile: _doctorProfile!,
        availability: _doctorAvailability,
      ),
    );

    if (saved == true) {
      await _loadDoctorPracticeData();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Doctor practice details updated successfully.'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  String _resolveImageUrl(String? rawUrl) {
    final url = (rawUrl ?? '').trim();
    if (url.isEmpty || url.toLowerCase() == 'null') {
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

  String _doctorAvatarUrl(AuthUser? user) {
    if (_isDoctorRole) {
      final doctorImageUrl =
          _resolveImageUrl(_doctorProfile?['profile_image_url']?.toString());
      if (doctorImageUrl.isNotEmpty) {
        return doctorImageUrl;
      }
    }
    return _resolveImageUrl(user?.avatarUrl);
  }

  Future<void> _pickAndUploadDoctorPhoto() async {
    if (!_isDoctorRole || _isDoctorPhotoUploading) {
      return;
    }

    final picked = await _imagePicker.pickImage(source: ImageSource.gallery);
    if (picked == null) {
      return;
    }

    final fileSize = await picked.length();
    if (!mounted) {
      return;
    }

    if (fileSize > 2 * 1024 * 1024) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Photo must be less than 2MB.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isDoctorPhotoUploading = true;
    });

    try {
      final api = sl<ApiClient>();
      final bytes = await picked.readAsBytes();

      final uploadResponse = await api.dio.post(
        '/api/upload',
        data: FormData.fromMap({
          'file': MultipartFile.fromBytes(
            bytes,
            filename:
                picked.name.isNotEmpty ? picked.name : 'doctor-profile.jpg',
          ),
        }),
      );

      final fileUrl = uploadResponse.data is Map<String, dynamic>
          ? uploadResponse.data['fileUrl']?.toString() ?? ''
          : '';

      if (fileUrl.isEmpty) {
        throw const FormatException('Upload URL missing');
      }

      var doctorId = _doctorProfile?['_id']?.toString() ?? '';
      if (doctorId.isEmpty) {
        await _loadDoctorPracticeData();
        doctorId = _doctorProfile?['_id']?.toString() ?? '';
      }

      if (doctorId.isEmpty) {
        throw const FormatException('Doctor profile not found');
      }

      await api.put(
        '/api/doctors/$doctorId',
        data: {
          'profile_image_url': fileUrl,
        },
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _doctorProfile = {
          ...?_doctorProfile,
          '_id': doctorId,
          'profile_image_url': fileUrl,
        };
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile photo updated successfully.'),
          backgroundColor: Colors.green,
        ),
      );
    } on DioException catch (error) {
      if (!mounted) {
        return;
      }

      final message = error.response?.data is Map<String, dynamic>
          ? error.response?.data['message']?.toString() ??
              'Failed to update profile photo.'
          : 'Failed to update profile photo.';

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
        ),
      );
    } catch (_) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to update profile photo.'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isDoctorPhotoUploading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = widget.authProvider;
    final user = authProvider.user;
    final avatarUrl = _doctorAvatarUrl(user);
    final preferences = user?.notificationPreferences;

    final String initials = (user?.name?.isNotEmpty ?? false)
        ? user!.name!
            .trim()
            .split(' ')
            .map((w) => w.isEmpty ? '' : w[0].toUpperCase())
            .take(2)
            .join()
        : 'U';

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => context.push(AppRoutes.settings),
          ),
        ],
      ),
      body: authProvider.isLoading && user == null
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () async {
                await authProvider.fetchProfile();
                await _loadDoctorPracticeData();
              },
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  children: [
                    // ── Header ──────────────────────────────────────────
                    Container(
                      width: double.infinity,
                      color: Theme.of(context)
                          .primaryColor
                          .withValues(alpha: 0.05),
                      padding: const EdgeInsets.symmetric(vertical: 32),
                      child: Column(
                        children: [
                          Stack(
                            children: [
                              CircleAvatar(
                                radius: 50,
                                backgroundColor: AppColors.primary,
                                backgroundImage: avatarUrl.isNotEmpty
                                    ? NetworkImage(avatarUrl)
                                    : null,
                                child: avatarUrl.isNotEmpty
                                    ? null
                                    : Text(
                                        initials,
                                        style: const TextStyle(
                                          fontSize: 30,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                              ),
                              if (_isDoctorRole)
                                Positioned(
                                  right: 0,
                                  bottom: 0,
                                  child: Material(
                                    color: AppColors.primary,
                                    shape: const CircleBorder(),
                                    child: InkWell(
                                      customBorder: const CircleBorder(),
                                      onTap: _isDoctorPhotoUploading
                                          ? null
                                          : _pickAndUploadDoctorPhoto,
                                      child: Padding(
                                        padding: const EdgeInsets.all(8),
                                        child: _isDoctorPhotoUploading
                                            ? const SizedBox(
                                                width: 16,
                                                height: 16,
                                                child:
                                                    CircularProgressIndicator(
                                                  strokeWidth: 2,
                                                  color: Colors.white,
                                                ),
                                              )
                                            : const Icon(
                                                Icons.camera_alt,
                                                size: 16,
                                                color: Colors.white,
                                              ),
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          if (_isDoctorRole) ...[
                            const SizedBox(height: 8),
                            const Text(
                              'Tap camera icon to update photo',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                          const SizedBox(height: 14),
                          Text(
                            user?.name ?? '—',
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge
                                ?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            user?.email ?? '—',
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                          ),
                          if (user?.phone?.isNotEmpty ?? false) ...[
                            const SizedBox(height: 4),
                            Text(
                              user!.phone!,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                            ),
                          ],
                          const SizedBox(height: 10),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Text(
                              authProvider.role?.toUpperCase() ?? 'PATIENT',
                              style: const TextStyle(
                                color: AppColors.primary,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // ── Personal Info card ───────────────────────────────
                    _buildCard(
                      context,
                      title: 'Personal Information',
                      children: [
                        _InfoRow(
                          icon: Icons.person_outline,
                          label: 'Full Name',
                          value: user?.name ?? '—',
                        ),
                        const Divider(height: 1, indent: 56),
                        _InfoRow(
                          icon: Icons.email_outlined,
                          label: 'Email',
                          value: user?.email ?? '—',
                        ),
                        const Divider(height: 1, indent: 56),
                        _InfoRow(
                          icon: Icons.phone_outlined,
                          label: 'Phone',
                          value: (user?.phone?.isNotEmpty ?? false)
                              ? user!.phone!
                              : 'Not set',
                        ),
                        const Divider(height: 1, indent: 56),
                        _InfoRow(
                          icon: Icons.badge_outlined,
                          label: 'Role',
                          value: authProvider.role?.toUpperCase() ?? '—',
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    _buildCard(
                      context,
                      title: 'Account Details',
                      children: [
                        _InfoRow(
                          icon: Icons.language_outlined,
                          label: 'Language',
                          value: _localeLabel(user?.locale),
                        ),
                        const Divider(height: 1, indent: 56),
                        _InfoRow(
                          icon: Icons.event_available_outlined,
                          label: 'Member Since',
                          value: _memberSinceLabel(user?.createdAt),
                        ),
                        const Divider(height: 1, indent: 56),
                        _InfoRow(
                          icon: Icons.fingerprint,
                          label: 'User ID',
                          value: user?.id ?? '—',
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    if (_isDoctorRole) ...[
                      _buildCard(
                        context,
                        title: 'Doctor Practice Details',
                        children: [
                          if (_isDoctorPracticeLoading)
                            const Padding(
                              padding: EdgeInsets.all(16),
                              child: LinearProgressIndicator(minHeight: 3),
                            ),
                          if (_doctorPracticeError != null)
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 12),
                              child: Text(
                                _doctorPracticeError!,
                                style: const TextStyle(color: Colors.red),
                              ),
                            ),
                          _InfoRow(
                            icon: Icons.medical_services_outlined,
                            label: 'Specialization',
                            value:
                                _doctorProfile?['specialization']?.toString() ??
                                    'Not set',
                          ),
                          const Divider(height: 1, indent: 56),
                          _InfoRow(
                            icon: Icons.currency_rupee,
                            label: 'Consultation Fee',
                            value:
                                '₹${(_doctorProfile?['consultation_fee'] as num?)?.toInt() ?? 0}',
                          ),
                          const Divider(height: 1, indent: 56),
                          _InfoRow(
                            icon: Icons.warning_amber_outlined,
                            label: 'Emergency Fee',
                            value:
                                '₹${(_doctorProfile?['emergency_fee'] as num?)?.toInt() ?? 0}',
                          ),
                          const Divider(height: 1, indent: 56),
                          _InfoRow(
                            icon: Icons.calendar_month_outlined,
                            label: 'Availability',
                            value: _availabilitySummary(),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            icon: const Icon(Icons.tune),
                            label: const Text('Edit Practice Details'),
                            onPressed: _openEditDoctorPracticeSheet,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],

                    _buildCard(
                      context,
                      title: 'Notification Preferences',
                      children: [
                        _InfoRow(
                          icon: Icons.email_outlined,
                          label: 'Email Alerts',
                          value: (preferences?.email ?? false)
                              ? 'Enabled'
                              : 'Disabled',
                        ),
                        const Divider(height: 1, indent: 56),
                        _InfoRow(
                          icon: Icons.notifications_active_outlined,
                          label: 'Push Notifications',
                          value: (preferences?.push ?? false)
                              ? 'Enabled'
                              : 'Disabled',
                        ),
                        const Divider(height: 1, indent: 56),
                        _InfoRow(
                          icon: Icons.video_call_outlined,
                          label: 'Video Call Alerts',
                          value: (preferences?.videoCalls ?? false)
                              ? 'Enabled'
                              : 'Disabled',
                        ),
                        const Divider(height: 1, indent: 56),
                        _InfoRow(
                          icon: Icons.calendar_month_outlined,
                          label: 'Appointment Alerts',
                          value: (preferences?.appointments ?? false)
                              ? 'Enabled'
                              : 'Disabled',
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // ── Edit button ──────────────────────────────────────
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.edit_outlined),
                          label: const Text('Edit Profile'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
                          onPressed: _openEditSheet,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // ── Linked pages ─────────────────────────────────────
                    _buildMenuSection(
                      context,
                      title: 'More',
                      items: [
                        if (authProvider.role == 'doctor')
                          _MenuItem(
                            icon: Icons.dashboard_outlined,
                            title: 'Doctor Dashboard',
                            onTap: () =>
                                context.push(AppRoutes.doctorDashboard),
                          ),
                        _MenuItem(
                          icon: Icons.medical_services_outlined,
                          title: 'My Prescriptions',
                          onTap: () => context.push(AppRoutes.prescriptions),
                        ),
                        if (authProvider.role == 'patient')
                          _MenuItem(
                            icon: Icons.upload_file_outlined,
                            title: 'Upload Medical Records',
                            onTap: () => context.push(AppRoutes.medicalRecords),
                          ),
                        if (authProvider.role == 'doctor')
                          _MenuItem(
                            icon: Icons.folder_shared_outlined,
                            title: 'Medical Records',
                            onTap: () => context.push(AppRoutes.medicalRecords),
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // ── Logout ───────────────────────────────────────────
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
                      child: SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.red,
                            side: const BorderSide(color: Colors.red),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: () async {
                            await authProvider.logout();
                          },
                          child: const Text('Log Out'),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  String _localeLabel(String? locale) {
    switch ((locale ?? 'en').toLowerCase()) {
      case 'hi':
        return 'Hindi';
      case 'en':
      default:
        return 'English';
    }
  }

  String _memberSinceLabel(DateTime? createdAt) {
    if (createdAt == null) {
      return '—';
    }

    const monthNames = <String>[
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];

    return '${monthNames[createdAt.month - 1]} ${createdAt.day}, ${createdAt.year}';
  }

  Widget _buildCard(
    BuildContext context, {
    required String title,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.bold,
                ),
          ),
        ),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Column(children: children),
        ),
      ],
    );
  }

  Widget _buildMenuSection(
    BuildContext context, {
    required String title,
    required List<_MenuItem> items,
  }) {
    if (items.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.bold,
                ),
          ),
        ),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            children: items.asMap().entries.map((entry) {
              final index = entry.key;
              final item = entry.value;
              return Column(
                children: [
                  ListTile(
                    leading: Icon(item.icon, color: AppColors.primary),
                    title: Text(item.title),
                    trailing: const Icon(Icons.chevron_right, size: 20),
                    onTap: item.onTap,
                  ),
                  if (index < items.length - 1)
                    const Divider(height: 1, indent: 56),
                ],
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

// ── Edit Profile Bottom Sheet ─────────────────────────────────────────────────

class _EditProfileSheet extends StatefulWidget {
  const _EditProfileSheet({required this.authProvider});
  final AuthProvider authProvider;

  @override
  State<_EditProfileSheet> createState() => _EditProfileSheetState();
}

class _EditProfileSheetState extends State<_EditProfileSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _phoneCtrl;
  late String _locale;
  late bool _emailNotifications;
  late bool _pushNotifications;
  late bool _videoNotifications;
  late bool _appointmentNotifications;

  @override
  void initState() {
    super.initState();
    _nameCtrl =
        TextEditingController(text: widget.authProvider.user?.name ?? '');
    _phoneCtrl =
        TextEditingController(text: widget.authProvider.user?.phone ?? '');
    _locale = widget.authProvider.user?.locale ?? 'en';
    _emailNotifications =
        widget.authProvider.user?.notificationPreferences.email ?? false;
    _pushNotifications =
        widget.authProvider.user?.notificationPreferences.push ?? false;
    _videoNotifications =
        widget.authProvider.user?.notificationPreferences.videoCalls ?? false;
    _appointmentNotifications =
        widget.authProvider.user?.notificationPreferences.appointments ?? false;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final success = await widget.authProvider.updateProfile(
      fullName: _nameCtrl.text.trim(),
      phone: _phoneCtrl.text.trim(),
      locale: _locale,
      notificationPreferences: AuthNotificationPreferences(
        email: _emailNotifications,
        push: _pushNotifications,
        videoCalls: _videoNotifications,
        appointments: _appointmentNotifications,
      ),
    );
    if (!mounted) return;
    if (success) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile updated successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(widget.authProvider.errorMessage ?? 'Update failed'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 20, 20, 20 + bottomInset),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Edit Profile',
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _nameCtrl,
              decoration: InputDecoration(
                labelText: 'Full Name',
                prefixIcon: const Icon(Icons.person_outline),
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              textCapitalization: TextCapitalization.words,
              validator: (v) => (v == null || v.trim().length < 2)
                  ? 'Enter at least 2 characters'
                  : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _phoneCtrl,
              decoration: InputDecoration(
                labelText: 'Phone Number',
                prefixIcon: const Icon(Icons.phone_outlined),
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 8),
            Text(
              'Email cannot be changed here.',
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: Colors.grey),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: _locale,
              decoration: InputDecoration(
                labelText: 'Language',
                prefixIcon: const Icon(Icons.language_outlined),
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              items: const [
                DropdownMenuItem(value: 'en', child: Text('English')),
                DropdownMenuItem(value: 'hi', child: Text('Hindi')),
              ],
              onChanged: (value) {
                if (value == null) return;
                setState(() {
                  _locale = value;
                });
              },
            ),
            const SizedBox(height: 16),
            Text(
              'Notification Preferences',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: _emailNotifications,
              title: const Text('Email alerts'),
              onChanged: (value) {
                setState(() {
                  _emailNotifications = value;
                });
              },
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: _pushNotifications,
              title: const Text('Push notifications'),
              onChanged: (value) {
                setState(() {
                  _pushNotifications = value;
                });
              },
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: _videoNotifications,
              title: const Text('Video call alerts'),
              onChanged: (value) {
                setState(() {
                  _videoNotifications = value;
                });
              },
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: _appointmentNotifications,
              title: const Text('Appointment alerts'),
              onChanged: (value) {
                setState(() {
                  _appointmentNotifications = value;
                });
              },
            ),
            const SizedBox(height: 20),
            ListenableBuilder(
              listenable: widget.authProvider,
              builder: (context, _) {
                return SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: widget.authProvider.isLoading ? null : _save,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                    child: widget.authProvider.isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text('Save Changes',
                            style: TextStyle(fontWeight: FontWeight.w700)),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

// ── Reusable widgets ──────────────────────────────────────────────────────────

class _InfoRow extends StatelessWidget {
  const _InfoRow(
      {required this.icon, required this.label, required this.value});
  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primary, size: 22),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: AppColors.textSecondary),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MenuItem {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  _MenuItem({
    required this.icon,
    required this.title,
    required this.onTap,
  });
}

class _DayAvailabilityModel {
  _DayAvailabilityModel({
    this.id,
    required this.dayOfWeek,
    required this.isAvailable,
    required this.startTime,
    required this.endTime,
  });

  final String? id;
  final int dayOfWeek;
  bool isAvailable;
  String startTime;
  String endTime;
}

class _EditDoctorPracticeSheet extends StatefulWidget {
  const _EditDoctorPracticeSheet({
    required this.doctorProfile,
    required this.availability,
  });

  final Map<String, dynamic> doctorProfile;
  final List<Map<String, dynamic>> availability;

  @override
  State<_EditDoctorPracticeSheet> createState() =>
      _EditDoctorPracticeSheetState();
}

class _EditDoctorPracticeSheetState extends State<_EditDoctorPracticeSheet> {
  final _formKey = GlobalKey<FormState>();
  bool _isSaving = false;

  late final TextEditingController _specializationCtrl;
  late final TextEditingController _bioCtrl;
  late final TextEditingController _stateCtrl;
  late final TextEditingController _locationCtrl;
  late final TextEditingController _consultationFeeCtrl;
  late final TextEditingController _emergencyFeeCtrl;
  late final Map<int, _DayAvailabilityModel> _availabilityByDay;

  static const _dayLabels = <String>[
    'Sunday',
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
  ];

  @override
  void initState() {
    super.initState();

    _specializationCtrl = TextEditingController(
      text: widget.doctorProfile['specialization']?.toString() ?? '',
    );
    _bioCtrl = TextEditingController(
      text: widget.doctorProfile['bio']?.toString() ?? '',
    );
    _stateCtrl = TextEditingController(
      text: widget.doctorProfile['state']?.toString() ?? '',
    );
    _locationCtrl = TextEditingController(
      text: widget.doctorProfile['location']?.toString() ?? '',
    );
    _consultationFeeCtrl = TextEditingController(
      text: ((widget.doctorProfile['consultation_fee'] as num?)?.toInt() ?? 0)
          .toString(),
    );
    _emergencyFeeCtrl = TextEditingController(
      text: ((widget.doctorProfile['emergency_fee'] as num?)?.toInt() ?? 0)
          .toString(),
    );

    _availabilityByDay = {
      for (int day = 0; day < 7; day++)
        day: _DayAvailabilityModel(
          dayOfWeek: day,
          isAvailable: false,
          startTime: '09:00',
          endTime: '17:00',
        ),
    };

    for (final slot in widget.availability) {
      final day = (slot['day_of_week'] as num?)?.toInt();
      if (day == null || day < 0 || day > 6) {
        continue;
      }

      _availabilityByDay[day] = _DayAvailabilityModel(
        id: slot['_id']?.toString(),
        dayOfWeek: day,
        isAvailable: slot['is_available'] != false,
        startTime: slot['start_time']?.toString() ?? '09:00',
        endTime: slot['end_time']?.toString() ?? '17:00',
      );
    }
  }

  @override
  void dispose() {
    _specializationCtrl.dispose();
    _bioCtrl.dispose();
    _stateCtrl.dispose();
    _locationCtrl.dispose();
    _consultationFeeCtrl.dispose();
    _emergencyFeeCtrl.dispose();
    super.dispose();
  }

  bool _isValidTime(String value) {
    final text = value.trim();
    final parts = text.split(':');
    if (parts.length != 2) {
      return false;
    }

    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);
    if (hour == null || minute == null) {
      return false;
    }

    return hour >= 0 && hour <= 23 && minute >= 0 && minute <= 59;
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final api = sl<ApiClient>();
      final doctorId = widget.doctorProfile['_id']?.toString() ?? '';
      if (doctorId.isEmpty) {
        throw Exception('Doctor profile id missing');
      }

      await api.put(
        '/api/doctors/$doctorId',
        data: {
          'specialization': _specializationCtrl.text.trim(),
          'bio': _bioCtrl.text.trim(),
          'state': _stateCtrl.text.trim(),
          'location': _locationCtrl.text.trim(),
          'consultation_fee':
              int.tryParse(_consultationFeeCtrl.text.trim()) ?? 0,
          'emergency_fee': int.tryParse(_emergencyFeeCtrl.text.trim()) ?? 0,
        },
      );

      for (final entry in _availabilityByDay.entries) {
        final slot = entry.value;

        if (slot.id != null && slot.id!.isNotEmpty) {
          await api.put(
            '/api/availability/${slot.id}',
            data: {
              'start_time': slot.startTime,
              'end_time': slot.endTime,
              'is_available': slot.isAvailable,
            },
          );
          continue;
        }

        if (!slot.isAvailable) {
          continue;
        }

        await api.post(
          '/api/availability',
          data: {
            'doctor_id': doctorId,
            'day_of_week': slot.dayOfWeek,
            'start_time': slot.startTime,
            'end_time': slot.endTime,
            'is_available': slot.isAvailable,
          },
        );
      }

      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (_) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to update doctor practice details.'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(20, 20, 20, 20 + bottomInset),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    'Edit Practice Details',
                    style: Theme.of(context)
                        .textTheme
                        .titleLarge
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _specializationCtrl,
                decoration: const InputDecoration(
                  labelText: 'Specialization',
                  prefixIcon: Icon(Icons.medical_services_outlined),
                ),
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Specialization is required'
                    : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _consultationFeeCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Consultation Fee',
                  prefixIcon: Icon(Icons.currency_rupee),
                ),
                validator: (v) {
                  final value = int.tryParse((v ?? '').trim());
                  if (value == null || value < 0) {
                    return 'Enter a valid fee';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _emergencyFeeCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Emergency Fee',
                  prefixIcon: Icon(Icons.warning_amber_outlined),
                ),
                validator: (v) {
                  final value = int.tryParse((v ?? '').trim());
                  if (value == null || value < 0) {
                    return 'Enter a valid emergency fee';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _stateCtrl,
                decoration: const InputDecoration(
                  labelText: 'State',
                  prefixIcon: Icon(Icons.map_outlined),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _locationCtrl,
                decoration: const InputDecoration(
                  labelText: 'Location',
                  prefixIcon: Icon(Icons.place_outlined),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _bioCtrl,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Bio',
                  prefixIcon: Icon(Icons.description_outlined),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Weekly Availability',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              ...List.generate(7, (day) {
                final slot = _availabilityByDay[day]!;
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                _dayLabels[day],
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            Switch(
                              value: slot.isAvailable,
                              onChanged: (value) {
                                setState(() {
                                  slot.isAvailable = value;
                                });
                              },
                            ),
                          ],
                        ),
                        if (slot.isAvailable)
                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  initialValue: slot.startTime,
                                  decoration: const InputDecoration(
                                    labelText: 'Start (HH:mm)',
                                  ),
                                  onChanged: (value) {
                                    slot.startTime = value.trim();
                                  },
                                  validator: (_) {
                                    if (!slot.isAvailable) {
                                      return null;
                                    }
                                    if (!_isValidTime(slot.startTime)) {
                                      return 'Invalid time';
                                    }
                                    return null;
                                  },
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: TextFormField(
                                  initialValue: slot.endTime,
                                  decoration: const InputDecoration(
                                    labelText: 'End (HH:mm)',
                                  ),
                                  onChanged: (value) {
                                    slot.endTime = value.trim();
                                  },
                                  validator: (_) {
                                    if (!slot.isAvailable) {
                                      return null;
                                    }
                                    if (!_isValidTime(slot.endTime)) {
                                      return 'Invalid time';
                                    }
                                    return null;
                                  },
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                );
              }),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _save,
                  child: _isSaving
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Save Practice Details'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
