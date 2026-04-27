import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:healthlink_connect_flutter/config/routes/app_router.dart';
import 'package:healthlink_connect_flutter/core/di/injection_container.dart';
import 'package:healthlink_connect_flutter/core/providers/app_preferences_provider.dart';
import 'package:healthlink_connect_flutter/core/services/local_notification_service.dart';
import 'package:healthlink_connect_flutter/core/theme/app_theme.dart';
import 'package:healthlink_connect_flutter/core/widgets/global_notification_poller.dart';
import 'package:healthlink_connect_flutter/features/auth/presentation/providers/auth_provider.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthProvider>(
          create: (_) => sl<AuthProvider>()..hydrate(),
        ),
        ChangeNotifierProvider<AppPreferencesProvider>(
          create: (_) => sl<AppPreferencesProvider>()..hydrate(),
        ),
      ],
      child: Consumer<AppPreferencesProvider>(
        builder: (context, preferences, _) {
          return NotificationPermissionGate(
            child: GlobalNotificationPoller(
              child: MaterialApp.router(
                title: 'MediConnect',
                debugShowCheckedModeBanner: false,
                theme: AppTheme.light,
                darkTheme: AppTheme.dark,
                themeMode: preferences.themeMode,
                routerConfig: AppRouter.router,
              ),
            ),
          );
        },
      ),
    );
  }
}

class NotificationPermissionGate extends StatefulWidget {
  const NotificationPermissionGate({super.key, required this.child});

  final Widget child;

  @override
  State<NotificationPermissionGate> createState() =>
      _NotificationPermissionGateState();
}

class _NotificationPermissionGateState
    extends State<NotificationPermissionGate> {
  bool _promptShown = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (_promptShown) {
      return;
    }

    final preferences = context.read<AppPreferencesProvider>();
    if (preferences.notificationPrompted) {
      _promptShown = true;
      return;
    }

    _promptShown = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showPermissionPrompt();
    });
  }

  Future<void> _showPermissionPrompt() async {
    if (!mounted) {
      return;
    }

    final shouldAllow = await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (dialogContext) {
            return AlertDialog(
              title: const Text('Enable Notifications'),
              content: const Text(
                'Allow MediConnect to send appointment, chat, and doctor action alerts to this phone?',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(false),
                  child: const Text('Not now'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.of(dialogContext).pop(true),
                  child: const Text('Allow'),
                ),
              ],
            );
          },
        ) ??
        false;

    if (!mounted) {
      return;
    }

    if (shouldAllow) {
      try {
        await sl<LocalNotificationService>().requestPermissions();
      } catch (_) {
        // Ignore permission failures; the app can still run without alerts.
      }
    }

    await context.read<AppPreferencesProvider>().markNotificationPrompted();
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
