import 'package:equatable/equatable.dart';
import 'package:healthlink_connect_flutter/features/appointment/domain/entities/appointment.dart';

abstract class AppointmentState extends Equatable {
  const AppointmentState();

  @override
  List<Object?> get props => [];
}

class AppointmentInitial extends AppointmentState {}

class AppointmentLoading extends AppointmentState {}

class AppointmentLoaded extends AppointmentState {
  final List<Appointment> upcomingAppointments;
  final List<Appointment> pastAppointments;

  const AppointmentLoaded({
    required this.upcomingAppointments,
    required this.pastAppointments,
  });

  @override
  List<Object?> get props => [upcomingAppointments, pastAppointments];
}

class AppointmentError extends AppointmentState {
  final String message;

  const AppointmentError(this.message);

  @override
  List<Object?> get props => [message];
}

abstract class AppointmentEvent extends Equatable {
  const AppointmentEvent();

  @override
  List<Object?> get props => [];
}

class LoadAppointments extends AppointmentEvent {}
