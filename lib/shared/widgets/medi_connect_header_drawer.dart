import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:healthlink_connect_flutter/config/routes/app_routes.dart';
import 'package:healthlink_connect_flutter/features/auth/presentation/providers/auth_provider.dart';
import 'package:healthlink_connect_flutter/features/doctor/presentation/pages/specializations_page.dart';
import 'package:healthlink_connect_flutter/features/home/presentation/pages/about_page.dart';
import 'package:healthlink_connect_flutter/shared/widgets/app_logo.dart';

class MediConnectHeader extends StatelessWidget implements PreferredSizeWidget {
  const MediConnectHeader({
    super.key,
    this.forceBackToHome = false,
  });

  final bool forceBackToHome;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final bool canPop = Navigator.of(context).canPop();
    final bool showBackButton = canPop || forceBackToHome;
    final auth = context.watch<AuthProvider>();
    final bool isLoggedIn = auth.isAuthenticated;

    return AppBar(
      elevation: 0,
      backgroundColor: colorScheme.surface,
      automaticallyImplyLeading: false,
      leading: showBackButton
          ? IconButton(
              icon: const Icon(Icons.arrow_back_rounded),
              color: colorScheme.onSurface,
              onPressed: () {
                if (canPop) {
                  Navigator.pop(context);
                  return;
                }
                context.go(AppRoutes.home);
              },
            )
          : null,
      titleSpacing: 16,
      title: Row(
        children: [
          const AppLogo(size: 30, radius: 8),
          const SizedBox(width: 10),
          Flexible(
            child: Text(
              'MediConnect',
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: colorScheme.onSurface,
                fontWeight: FontWeight.w700,
                fontSize: 20,
              ),
            ),
          ),
        ],
      ),
      actions: [
        if (isLoggedIn)
          IconButton(
            icon: const Icon(Icons.dashboard_outlined),
            color: colorScheme.onSurface,
            tooltip: 'Dashboard',
            onPressed: () => _openDashboardByRole(context, auth.role),
          ),
        IconButton(
          icon: const Icon(Icons.notifications_none_rounded),
          color: colorScheme.onSurface,
          onPressed: () => context.push(AppRoutes.notifications),
        ),
        Builder(
          builder: (context) {
            return IconButton(
              icon: const Icon(Icons.menu_rounded),
              color: colorScheme.onSurface,
              onPressed: () => Scaffold.of(context).openDrawer(),
            );
          },
        ),
        const SizedBox(width: 4),
      ],
    );
  }
}

class MediConnectDrawer extends StatelessWidget {
  const MediConnectDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final auth = context.watch<AuthProvider>();
    final bool isLoggedIn = auth.isAuthenticated;

    return Drawer(
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(14, 8, 14, 14),
          children: [
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(
                'MediConnect',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
              ),
              subtitle: Text('Care when you need it'),
            ),
            const Divider(height: 24),
            _drawerItem(
              context,
              icon: Icons.home_rounded,
              label: 'Home',
              onTap: () => context.go(AppRoutes.home),
            ),
            _drawerItem(
              context,
              icon: Icons.search_rounded,
              label: 'Find Doctors',
              onTap: () => context.go(AppRoutes.doctors),
            ),
            _drawerItem(
              context,
              icon: Icons.medical_services_outlined,
              label: 'Specializations',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const SpecializationsPage(),
                ),
              ),
            ),
            _drawerItem(
              context,
              icon: Icons.info_outline_rounded,
              label: 'About',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AboutPage(),
                ),
              ),
            ),
            if (isLoggedIn)
              _drawerItem(
                context,
                icon: Icons.dashboard_outlined,
                label: 'Dashboard',
                onTap: () => _openDashboardByRole(context, auth.role),
              ),
            const SizedBox(height: 16),
            if (!isLoggedIn) ...[
              ElevatedButton(
                onPressed: () => context.go(AppRoutes.login),
                style: ElevatedButton.styleFrom(
                  backgroundColor: colorScheme.surface,
                  foregroundColor: colorScheme.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: colorScheme.outline),
                  ),
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: const Text('Sign In',
                    style: TextStyle(fontWeight: FontWeight.w700)),
              ),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: () => context.go(AppRoutes.register),
                style: ElevatedButton.styleFrom(
                  backgroundColor: colorScheme.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: const Text('Get Started',
                    style: TextStyle(fontWeight: FontWeight.w700)),
              ),
            ],
            if (isLoggedIn)
              ElevatedButton(
                onPressed: () async {
                  await context.read<AuthProvider>().logout();
                  if (!context.mounted) {
                    return;
                  }
                  context.go(AppRoutes.login);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: colorScheme.surface,
                  foregroundColor: const Color(0xFFB91C1C),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: colorScheme.outline),
                  ),
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: const Text('Logout',
                    style: TextStyle(fontWeight: FontWeight.w700)),
              ),
          ],
        ),
      ),
    );
  }

  Widget _drawerItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return ListTile(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      leading: Icon(icon, color: colorScheme.primary),
      title: Text(label),
      onTap: () {
        Navigator.of(context).pop();
        onTap();
      },
    );
  }
}

void _openDashboardByRole(BuildContext context, String? role) {
  if (role == 'doctor') {
    context.push(AppRoutes.doctorDashboard);
    return;
  }
  context.push(AppRoutes.patientDashboard);
}
