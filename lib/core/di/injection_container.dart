import 'package:get_it/get_it.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:healthlink_connect_flutter/core/config/env.dart';
import 'package:healthlink_connect_flutter/core/network/api_client.dart';
import 'package:healthlink_connect_flutter/core/providers/app_preferences_provider.dart';
import 'package:healthlink_connect_flutter/features/auth/data/repositories/auth_repository.dart';
import 'package:healthlink_connect_flutter/features/auth/presentation/providers/auth_provider.dart';

final sl = GetIt.instance;

Future<void> configureDependencies() async {
  // External
  sl.registerLazySingleton(() => const FlutterSecureStorage());
  sl.registerLazySingleton(() => ApiClient(baseUrl: Env.apiBaseUrl));

  // Features
  _initAuth();
  _initHome();
  _initProfile();
  _initAppointments();
  _initChat();
  _initVideoCall();
  _initPayment();
  _initPrescription();
  _initNotifications();
  _initEmergency();
  _initRecords();
}

void _initAuth() {
  sl.registerLazySingleton(() => AuthRepository(sl()));
  sl.registerLazySingleton(
    () => AuthProvider(
      authRepository: sl(),
      secureStorage: sl(),
    ),
  );
}

void _initHome() {
  // Add home feature dependencies here
}

void _initProfile() {
  sl.registerLazySingleton(
    () => AppPreferencesProvider(secureStorage: sl()),
  );
}

void _initAppointments() {
  // Appointment dependencies will go here
}

void _initChat() {
  // Chat dependencies will go here
}

void _initVideoCall() {
  // Video call dependencies will go here
}

void _initPayment() {
  // Payment dependencies will go here
}

void _initPrescription() {
  // Prescription dependencies will go here
}

void _initNotifications() {
  // Notification dependencies will go here
}

void _initEmergency() {
  // Emergency dependencies will go here
}

void _initRecords() {
  // Medical records dependencies will go here
}
