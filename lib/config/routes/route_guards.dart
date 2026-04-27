import 'package:go_router/go_router.dart';
import 'package:healthlink_connect_flutter/core/di/injection_container.dart';
import 'package:healthlink_connect_flutter/features/auth/presentation/providers/auth_provider.dart';
import 'app_routes.dart';

String? routeGuard(context, GoRouterState state) {
  final authProvider = sl<AuthProvider>();
  final bool isLoggedIn = authProvider.isAuthenticated;
  final role = authProvider.role;

  final publicPages = [
    '/',
    AppRoutes.startup,
    AppRoutes.home,
    AppRoutes.appointments,
    AppRoutes.doctors,
    AppRoutes.chat,
    AppRoutes.profile,
    AppRoutes.specializations,
    AppRoutes.allSpecializations,
    AppRoutes.about,
    AppRoutes.contact,
    AppRoutes.privacyPolicy,
    AppRoutes.termsOfService,
    AppRoutes.joinAsDoctor,
    AppRoutes.benefits,
    AppRoutes.faq,
    AppRoutes.notifications,
    AppRoutes.login,
    AppRoutes.register,
    AppRoutes.resetPassword,
  ];

  final isPublicPage = publicPages.contains(state.matchedLocation);

  if (!isLoggedIn && !isPublicPage) return AppRoutes.login;
  if (isLoggedIn &&
      role == 'doctor' &&
      state.matchedLocation == AppRoutes.bookAppointment) {
    return AppRoutes.doctorDashboard;
  }
  if (isLoggedIn &&
      (state.matchedLocation == AppRoutes.login ||
          state.matchedLocation == AppRoutes.register)) {
    if (role == 'doctor') {
      return AppRoutes.doctorDashboard;
    }

    if (role == 'patient') {
      return AppRoutes.patientDashboard;
    }

    return AppRoutes.home;
  }
  return null;
}
