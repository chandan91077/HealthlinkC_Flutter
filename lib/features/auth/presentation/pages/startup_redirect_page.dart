import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:healthlink_connect_flutter/config/routes/app_routes.dart';
import 'package:healthlink_connect_flutter/features/auth/presentation/providers/auth_provider.dart';

class StartupRedirectPage extends StatefulWidget {
  const StartupRedirectPage({super.key});

  @override
  State<StartupRedirectPage> createState() => _StartupRedirectPageState();
}

class _StartupRedirectPageState extends State<StartupRedirectPage> {
  @override
  void initState() {
    super.initState();
    _redirectFromPersistedSession();
  }

  Future<void> _redirectFromPersistedSession() async {
    final authProvider = context.read<AuthProvider>();
    await authProvider.hydrate();

    if (!mounted) {
      return;
    }

    final token = authProvider.token;
    final role = authProvider.role;
    final hasToken = token != null && token.isNotEmpty;

    if (hasToken && role == 'patient') {
      context.go(AppRoutes.patientDashboard);
      return;
    }

    if (hasToken && role == 'doctor') {
      context.go(AppRoutes.doctorDashboard);
      return;
    }

    context.go(AppRoutes.login);
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}
