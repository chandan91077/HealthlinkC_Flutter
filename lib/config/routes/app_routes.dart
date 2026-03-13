class AppRoutes {
  AppRoutes._();

  static const String startup = '/startup';
  static const String login = '/login';
  static const String register = '/register';
  static const String home = '/home';
  static const String profile = '/profile';
  static const String appointments = '/appointments';
  static const String doctors = '/doctors';
  static const String specializations = '/specializations';
  static const String allSpecializations = '/all-specializations';
  static const String about = '/about';
  static const String contact = '/contact';
  static const String privacyPolicy = '/privacy-policy';
  static const String termsOfService = '/terms-of-service';
  static const String joinAsDoctor = '/join-as-doctor';
  static const String benefits = '/benefits';
  static const String faq = '/faq';
  static const String chat = '/chat';
  static const String notifications = '/notifications';

  // New feature routes
  static const String bookAppointment = '/book/:doctorId';
  static const String settings = '/settings';
  static const String videoCall = '/video';
  static const String payment = '/payment';
  static const String prescriptions = '/prescriptions';
  static const String emergency = '/emergency';
  static const String medicalRecords = '/records';
  static const String appointmentDetails =
      '/appointment-details/:appointmentId';
  static const String doctorDashboard = '/doctor-dashboard';
  static const String patientDashboard = '/patient-dashboard';

  static String appointmentDetailsById(String appointmentId) =>
      '/appointment-details/$appointmentId';
}
