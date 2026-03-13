import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:healthlink_connect_flutter/config/routes/app_routes.dart';
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
  @override
  void initState() {
    super.initState();
    // Refresh profile data every time this page is shown
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.authProvider.fetchProfile();
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

  @override
  Widget build(BuildContext context) {
    final authProvider = widget.authProvider;
    final user = authProvider.user;
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
              onRefresh: () => authProvider.fetchProfile(),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  children: [
                    // ── Header ──────────────────────────────────────────
                    Container(
                      width: double.infinity,
                      color: Theme.of(context).primaryColor.withOpacity(0.05),
                      padding: const EdgeInsets.symmetric(vertical: 32),
                      child: Column(
                        children: [
                          Stack(
                            children: [
                              CircleAvatar(
                                radius: 50,
                                backgroundColor: AppColors.primary,
                                backgroundImage:
                                    (user?.avatarUrl?.isNotEmpty ?? false)
                                        ? NetworkImage(user!.avatarUrl!)
                                        : null,
                                child: (user?.avatarUrl?.isNotEmpty ?? false)
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
                            ],
                          ),
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
                              color: AppColors.primary.withOpacity(0.1),
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
                color: Colors.black.withOpacity(0.05),
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
                color: Colors.black.withOpacity(0.05),
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
              value: _locale,
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
