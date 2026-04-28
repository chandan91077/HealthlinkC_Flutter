import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:local_auth/local_auth.dart';
import 'package:provider/provider.dart';
import 'package:healthlink_connect_flutter/config/routes/app_routes.dart';
import 'package:healthlink_connect_flutter/core/providers/app_preferences_provider.dart';
import 'package:healthlink_connect_flutter/features/auth/domain/entities/auth_user.dart';
import 'package:healthlink_connect_flutter/features/auth/presentation/providers/auth_provider.dart';
import 'package:healthlink_connect_flutter/core/theme/app_colors.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _notificationsEnabled = true;
  bool _emailNotificationsEnabled = false;
  bool _appointmentNotificationsEnabled = true;
  bool _videoCallNotificationsEnabled = true;
  bool _didInitFromProfile = false;
  final LocalAuthentication _localAuth = LocalAuthentication();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_didInitFromProfile) return;

    final authProvider = context.read<AuthProvider>();
    final user = authProvider.user;
    if (user != null) {
      _notificationsEnabled = user.notificationPreferences.push;
      _emailNotificationsEnabled = user.notificationPreferences.email;
      _appointmentNotificationsEnabled =
          user.notificationPreferences.appointments;
      _videoCallNotificationsEnabled = user.notificationPreferences.videoCalls;
      _didInitFromProfile = true;
    }
  }

  Future<void> _updatePushNotifications(
    AuthProvider authProvider,
    bool enabled,
  ) async {
    final user = authProvider.user;
    if (user == null) return;

    setState(() => _notificationsEnabled = enabled);

    final success = await authProvider.updateProfile(
      fullName: user.name ?? '',
      phone: user.phone ?? '',
      locale: user.locale,
      notificationPreferences: user.notificationPreferences.copyWith(
        push: enabled,
      ),
    );

    if (!mounted) return;

    if (!success) {
      setState(() => _notificationsEnabled = !enabled);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text(authProvider.errorMessage ?? 'Failed to update settings'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          enabled
              ? 'Push notifications enabled'
              : 'Push notifications disabled',
        ),
      ),
    );
  }

  Future<void> _updateEmailNotifications(
    AuthProvider authProvider,
    bool enabled,
  ) async {
    final user = authProvider.user;
    if (user == null) return;

    setState(() => _emailNotificationsEnabled = enabled);

    final success = await authProvider.updateProfile(
      fullName: user.name ?? '',
      phone: user.phone ?? '',
      locale: user.locale,
      notificationPreferences: user.notificationPreferences.copyWith(
        email: enabled,
      ),
    );

    if (!mounted) return;

    if (!success) {
      setState(() => _emailNotificationsEnabled = !enabled);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text(authProvider.errorMessage ?? 'Failed to update settings'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          enabled
              ? 'Email notifications enabled'
              : 'Email notifications disabled',
        ),
      ),
    );
  }

  Future<void> _updateAppointmentNotifications(
    AuthProvider authProvider,
    bool enabled,
  ) async {
    final user = authProvider.user;
    if (user == null) return;

    setState(() => _appointmentNotificationsEnabled = enabled);

    final success = await authProvider.updateProfile(
      fullName: user.name ?? '',
      phone: user.phone ?? '',
      locale: user.locale,
      notificationPreferences: user.notificationPreferences.copyWith(
        appointments: enabled,
      ),
    );

    if (!mounted) return;

    if (!success) {
      setState(() => _appointmentNotificationsEnabled = !enabled);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text(authProvider.errorMessage ?? 'Failed to update settings'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          enabled
              ? 'Appointment notifications enabled'
              : 'Appointment notifications disabled',
        ),
      ),
    );
  }

  Future<void> _updateVideoCallNotifications(
    AuthProvider authProvider,
    bool enabled,
  ) async {
    final user = authProvider.user;
    if (user == null) return;

    setState(() => _videoCallNotificationsEnabled = enabled);

    final success = await authProvider.updateProfile(
      fullName: user.name ?? '',
      phone: user.phone ?? '',
      locale: user.locale,
      notificationPreferences: user.notificationPreferences.copyWith(
        videoCalls: enabled,
      ),
    );

    if (!mounted) return;

    if (!success) {
      setState(() => _videoCallNotificationsEnabled = !enabled);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text(authProvider.errorMessage ?? 'Failed to update settings'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          enabled
              ? 'Video call notifications enabled'
              : 'Video call notifications disabled',
        ),
      ),
    );
  }

  void _showInfo(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _updateDarkMode(
    AppPreferencesProvider preferences,
    bool enabled,
  ) async {
    await preferences.setDarkMode(enabled);
    if (!mounted) return;
    _showInfo(enabled ? 'Dark mode enabled' : 'Dark mode disabled');
  }

  Future<void> _updateBiometricPreference(
    AppPreferencesProvider preferences,
    bool enabled,
  ) async {
    if (enabled) {
      try {
        final canCheck = await _localAuth.canCheckBiometrics;
        final isSupported = await _localAuth.isDeviceSupported();

        if (!canCheck || !isSupported) {
          if (!mounted) return;
          _showInfo('Biometric authentication is not available on this device');
          return;
        }

        final authenticated = await _localAuth.authenticate(
          localizedReason: 'Enable biometric authentication',
          biometricOnly: true,
        );

        if (!authenticated) {
          if (!mounted) return;
          _showInfo('Biometric authentication was not verified');
          return;
        }
      } on PlatformException {
        if (!mounted) return;
        _showInfo('Unable to access biometric authentication right now');
        return;
      }
    }

    await preferences.setBiometricEnabled(enabled);
    if (!mounted) return;
    _showInfo(
      enabled
          ? 'Biometric authentication enabled'
          : 'Biometric authentication disabled',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<AuthProvider, AppPreferencesProvider>(
      builder: (context, authProvider, preferences, _) {
        final user = authProvider.user;
        final notifications = user?.notificationPreferences ??
            const AuthNotificationPreferences(
              email: false,
              push: false,
              videoCalls: false,
              appointments: false,
            );

        if (user != null && !_didInitFromProfile) {
          _notificationsEnabled = notifications.push;
          _didInitFromProfile = true;
        }

        return Scaffold(
          appBar: AppBar(
            title: const Text('Settings'),
          ),
          body: ListView(
            children: [
              _buildSectionHeader('Notifications'),
              SwitchListTile(
                title: const Text('Push Notifications'),
                subtitle: const Text('Receive alerts on your device'),
                value: _notificationsEnabled,
                onChanged: authProvider.isLoading
                    ? null
                    : (val) => _updatePushNotifications(authProvider, val),
                secondary: const Icon(Icons.notifications_active_outlined),
              ),
              SwitchListTile(
                title: const Text('Email Notifications'),
                subtitle: const Text('Receive updates via email'),
                value: _emailNotificationsEnabled,
                onChanged: authProvider.isLoading
                    ? null
                    : (val) => _updateEmailNotifications(authProvider, val),
                secondary: const Icon(Icons.mail_outline),
              ),
              SwitchListTile(
                title: const Text('Appointment Notifications'),
                subtitle: const Text('Get alerts for appointment updates'),
                value: _appointmentNotificationsEnabled,
                onChanged: authProvider.isLoading
                    ? null
                    : (val) =>
                        _updateAppointmentNotifications(authProvider, val),
                secondary: const Icon(Icons.calendar_month_outlined),
              ),
              SwitchListTile(
                title: const Text('Video Call Notifications'),
                subtitle: const Text('Get notified about incoming video calls'),
                value: _videoCallNotificationsEnabled,
                onChanged: authProvider.isLoading
                    ? null
                    : (val) => _updateVideoCallNotifications(authProvider, val),
                secondary: const Icon(Icons.video_call_outlined),
              ),
              const Divider(),
              _buildSectionHeader('Appearance'),
              SwitchListTile(
                title: const Text('Dark Mode'),
                subtitle: const Text('Switch between light and dark themes'),
                value: preferences.isDarkMode,
                onChanged: (val) => _updateDarkMode(preferences, val),
                secondary: const Icon(Icons.dark_mode_outlined),
              ),
              const Divider(),
              _buildSectionHeader('Account'),
              ListTile(
                leading: const Icon(Icons.lock_reset_outlined),
                title: const Text('Reset Password'),
                subtitle: const Text('Set a new password using reset token'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.push(AppRoutes.resetPassword),
              ),
              const Divider(),
              _buildSectionHeader('Security'),
              SwitchListTile(
                title: const Text('Biometric Authentication'),
                subtitle: const Text('Use fingerprint/face ID to unlock'),
                value: preferences.biometricEnabled,
                onChanged: (val) =>
                    _updateBiometricPreference(preferences, val),
                secondary: const Icon(Icons.fingerprint),
              ),
              const Divider(),
              _buildSectionHeader('Support'),
              ListTile(
                leading: const Icon(Icons.help_outline),
                title: const Text('Help Center & FAQ'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.push(AppRoutes.faq),
              ),
              ListTile(
                leading: const Icon(Icons.contact_support_outlined),
                title: const Text('Contact Us'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.push(AppRoutes.contact),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 16, right: 16, top: 24, bottom: 8),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          color: AppColors.primary,
          fontSize: 12,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}
