class Appointment {
  final String id;
  final String doctorId;
  final String doctorName;
  final String doctorSpecialization;
  final String? doctorImageUrl;
  final DateTime dateTime;
  final String status;
  final String type; // 'regular' or 'emergency'
  final double fee;

  const Appointment({
    required this.id,
    required this.doctorId,
    required this.doctorName,
    required this.doctorSpecialization,
    this.doctorImageUrl,
    required this.dateTime,
    required this.status,
    required this.type,
    required this.fee,
  });
}
