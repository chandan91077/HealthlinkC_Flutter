import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:healthlink_connect_flutter/config/routes/app_routes.dart';
import 'package:healthlink_connect_flutter/config/routes/route_guards.dart';
import 'package:healthlink_connect_flutter/core/di/injection_container.dart';
import 'package:healthlink_connect_flutter/features/auth/presentation/pages/auth_page.dart';
import 'package:healthlink_connect_flutter/features/auth/presentation/pages/startup_redirect_page.dart';
import 'package:healthlink_connect_flutter/features/auth/presentation/providers/auth_provider.dart';
import 'package:healthlink_connect_flutter/features/doctor/presentation/pages/find_doctors_page.dart';
import 'package:healthlink_connect_flutter/features/profile/presentation/pages/profile_page.dart';
import 'package:healthlink_connect_flutter/features/profile/presentation/pages/settings_page.dart';
import 'package:healthlink_connect_flutter/features/appointment/presentation/pages/appointments_page.dart';
import 'package:healthlink_connect_flutter/features/appointment/presentation/pages/appointment_details_page.dart';
import 'package:healthlink_connect_flutter/features/appointment/presentation/pages/book_appointment_page.dart';
import 'package:healthlink_connect_flutter/features/chat/presentation/pages/conversations_page.dart';
import 'package:healthlink_connect_flutter/features/chat/presentation/pages/chat_page.dart';
import 'package:healthlink_connect_flutter/features/video_call/presentation/pages/video_call_page.dart';
import 'package:healthlink_connect_flutter/features/payment/presentation/pages/payment_page.dart';
import 'package:healthlink_connect_flutter/features/prescription/presentation/pages/prescriptions_page.dart';
import 'package:healthlink_connect_flutter/features/records/presentation/pages/medical_records_page.dart';
import 'package:healthlink_connect_flutter/features/emergency/presentation/pages/emergency_page.dart';
import 'package:healthlink_connect_flutter/features/doctor/presentation/pages/doctor_dashboard_page.dart';
import 'package:healthlink_connect_flutter/features/patient/presentation/pages/patient_dashboard_page.dart';
import 'package:healthlink_connect_flutter/features/notifications/presentation/pages/notifications_page.dart';
import 'package:healthlink_connect_flutter/features/doctor/presentation/pages/all_specializations_page.dart';
import 'package:healthlink_connect_flutter/features/doctor/presentation/pages/specializations_page.dart';
import 'package:healthlink_connect_flutter/features/home/presentation/pages/about_page.dart';
import 'package:healthlink_connect_flutter/features/home/presentation/pages/benefits_page.dart';
import 'package:healthlink_connect_flutter/features/home/presentation/pages/contact_page.dart';
import 'package:healthlink_connect_flutter/features/home/presentation/pages/faq_page.dart';
import 'package:healthlink_connect_flutter/features/home/presentation/pages/home_page.dart';
import 'package:healthlink_connect_flutter/features/home/presentation/pages/join_as_doctor_page.dart';
import 'package:healthlink_connect_flutter/features/home/presentation/pages/privacy_policy_page.dart';
import 'package:healthlink_connect_flutter/features/home/presentation/pages/terms_of_service_page.dart';

import 'package:healthlink_connect_flutter/shared/widgets/scaffold_with_nav_bar.dart';

class AppRouter {
  static final _rootNavigatorKey = GlobalKey<NavigatorState>();

  static final router = GoRouter(
    initialLocation: AppRoutes.startup,
    navigatorKey: _rootNavigatorKey,
    redirect: routeGuard,
    refreshListenable: sl<AuthProvider>(),
    routes: [
      GoRoute(
        path: AppRoutes.startup,
        builder: (context, state) => const StartupRedirectPage(),
      ),
      GoRoute(
        path: AppRoutes.login,
        builder: (context, state) => const AuthPage(initialIsLogin: true),
      ),
      GoRoute(
        path: AppRoutes.register,
        builder: (context, state) => AuthPage(
          initialIsLogin: false,
          initialRole: state.uri.queryParameters['role'],
        ),
      ),
      // Main App Shell with Bottom Navigation
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return ScaffoldWithNavBar(navigationShell: navigationShell);
        },
        branches: [
          // Home tab
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.home,
                name: 'home',
                builder: (context, state) => const HomePage(),
              ),
            ],
          ),
          // Profile tab
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.profile,
                name: 'profile',
                builder: (context, state) => const ProfilePage(),
              ),
            ],
          ),
          // Appointments tab
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.appointments,
                name: 'appointments',
                builder: (context, state) => AppointmentsPage(
                  initialTab: state.uri.queryParameters['tab'],
                ),
              ),
            ],
          ),
          // Find Doctor tab
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.doctors,
                name: 'doctors',
                builder: (context, state) => const FindDoctorsPage(),
              ),
            ],
          ),
          // Chat tab
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.chat,
                name: 'chat',
                builder: (context, state) => const ConversationsPage(),
              ),
            ],
          ),
        ],
      ),

      // Other routes outside the shell
      GoRoute(
        path: '/payment/:bookingId',
        name: 'payment',
        builder: (context, state) => PaymentPage(
          bookingId: state.pathParameters['bookingId'] ?? '',
        ),
      ),
      GoRoute(
        path: AppRoutes.prescriptions,
        name: 'prescriptions',
        builder: (context, state) => const PrescriptionsPage(),
      ),
      GoRoute(
        path: AppRoutes.medicalRecords,
        name: 'medical-records',
        builder: (context, state) => const MedicalRecordsPage(),
      ),
      GoRoute(
        path: AppRoutes.videoCall,
        name: 'video-call',
        builder: (context, state) => const VideoCallPage(roomId: 'dummy_room'),
      ),
      GoRoute(
        path: '/emergency',
        name: 'emergency',
        builder: (context, state) => const EmergencyPage(),
      ),
      GoRoute(
        path: '/doctor-dashboard',
        name: 'doctor-dashboard',
        builder: (context, state) => const DoctorDashboardPage(),
      ),
      GoRoute(
        path: '/patient-dashboard',
        name: 'patient-dashboard',
        builder: (context, state) => const PatientDashboardPage(),
      ),
      GoRoute(
        path: '/chat/:id',
        name: 'chat-room',
        builder: (context, state) => ChatPage(
          conversationId: state.pathParameters['id'] ?? '',
        ),
      ),
      GoRoute(
        path: AppRoutes.bookAppointment,
        name: 'book-appointment',
        builder: (context, state) => BookAppointmentPage(
          doctorId: state.pathParameters['doctorId'] ?? '',
        ),
      ),
      GoRoute(
        path: AppRoutes.appointmentDetails,
        name: 'appointment-details',
        builder: (context, state) => AppointmentDetailsPage(
          appointmentId: state.pathParameters['appointmentId'] ?? '',
          initialAppointment: state.extra is Map<String, dynamic>
              ? state.extra as Map<String, dynamic>
              : null,
        ),
      ),
      GoRoute(
        path: AppRoutes.settings,
        name: 'settings',
        builder: (context, state) => const SettingsPage(),
      ),
      GoRoute(
        path: AppRoutes.specializations,
        name: 'specializations',
        builder: (context, state) => const SpecializationsPage(),
      ),
      GoRoute(
        path: AppRoutes.allSpecializations,
        name: 'all-specializations',
        builder: (context, state) => const AllSpecializationsPage(),
      ),
      GoRoute(
        path: AppRoutes.about,
        name: 'about',
        builder: (context, state) => const AboutPage(),
      ),
      GoRoute(
        path: AppRoutes.contact,
        name: 'contact',
        builder: (context, state) => const ContactPage(),
      ),
      GoRoute(
        path: AppRoutes.privacyPolicy,
        name: 'privacy-policy',
        builder: (context, state) => const PrivacyPolicyPage(),
      ),
      GoRoute(
        path: AppRoutes.termsOfService,
        name: 'terms-of-service',
        builder: (context, state) => const TermsOfServicePage(),
      ),
      GoRoute(
        path: AppRoutes.joinAsDoctor,
        name: 'join-as-doctor',
        builder: (context, state) => const JoinAsDoctorPage(),
      ),
      GoRoute(
        path: AppRoutes.benefits,
        name: 'benefits',
        builder: (context, state) => const BenefitsPage(),
      ),
      GoRoute(
        path: AppRoutes.faq,
        name: 'faq',
        builder: (context, state) => const FaqPage(),
      ),
      GoRoute(
        path: AppRoutes.notifications,
        name: 'notifications',
        builder: (context, state) => const NotificationsPage(),
      ),
    ],
  );
}
