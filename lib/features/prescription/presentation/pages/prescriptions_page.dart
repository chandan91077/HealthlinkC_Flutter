import 'package:flutter/material.dart';
import 'package:healthlink_connect_flutter/core/di/injection_container.dart';
import 'package:healthlink_connect_flutter/core/network/api_client.dart';
import 'package:healthlink_connect_flutter/core/theme/app_colors.dart';
import 'package:provider/provider.dart';
import 'package:healthlink_connect_flutter/features/auth/presentation/providers/auth_provider.dart';

class PrescriptionsPage extends StatefulWidget {
  const PrescriptionsPage({super.key});

  @override
  State<PrescriptionsPage> createState() => _PrescriptionsPageState();
}

class _PrescriptionsPageState extends State<PrescriptionsPage> {
  static const Duration _patientRecencyWindow = Duration(days: 6);
  bool _isLoading = true;
  bool _isCreating = false;
  String? _error;
  List<Map<String, dynamic>> _prescriptions = const [];

  @override
  void initState() {
    super.initState();
    _loadPrescriptions();
  }

  List<Map<String, dynamic>> _mapList(dynamic value) {
    if (value is! List) {
      return const [];
    }
    return value
        .whereType<Map>()
        .map((item) => item.map((k, v) => MapEntry(k.toString(), v)))
        .toList();
  }

  String _patientName(Map<String, dynamic> appointment) {
    final patient = appointment['patient_id'];
    if (patient is Map<String, dynamic>) {
      final name = patient['full_name']?.toString().trim() ?? '';
      if (name.isNotEmpty) {
        return name;
      }
    }
    return 'Patient';
  }

  String _patientNameFromPrescription(Map<String, dynamic> prescription) {
    final patient = prescription['patient_id'];
    if (patient is Map<String, dynamic>) {
      final name = patient['full_name']?.toString().trim() ?? '';
      if (name.isNotEmpty) {
        return name;
      }
    }

    final appointment = prescription['appointment_id'];
    if (appointment is Map<String, dynamic>) {
      final appointmentPatient = appointment['patient_id'];
      if (appointmentPatient is Map<String, dynamic>) {
        final name = appointmentPatient['full_name']?.toString().trim() ?? '';
        if (name.isNotEmpty) {
          return name;
        }
      }
    }

    return 'Patient';
  }

  List<String> _medicineLines(Map<String, dynamic> prescription) {
    final medications = prescription['medications'];
    if (medications is! List) {
      return const [];
    }

    return medications
        .whereType<Map>()
        .map((medication) {
          final map = medication.map((k, v) => MapEntry(k.toString(), v));
          final name = map['name']?.toString().trim() ?? '';
          final dosage = map['dosage']?.toString().trim() ?? '';
          final frequency = map['frequency']?.toString().trim() ?? '';
          final duration = map['duration']?.toString().trim() ?? '';

          final parts = <String>[];
          if (name.isNotEmpty) parts.add('Medicine: $name');
          if (dosage.isNotEmpty) parts.add('Dose: $dosage');
          if (frequency.isNotEmpty) parts.add('Frequency: $frequency');
          if (duration.isNotEmpty) parts.add('Duration: $duration');

          return parts.join(' • ');
        })
        .where((line) => line.isNotEmpty)
        .toList();
  }

  List<Map<String, dynamic>> _doctorBookableAppointments(
      List<Map<String, dynamic>> allAppointments) {
    final now = DateTime.now();
    final cutoff = now.subtract(_patientRecencyWindow);
    final latestByPatientId = <String, Map<String, dynamic>>{};

    for (final appointment in allAppointments) {
      final id = appointment['_id']?.toString() ?? '';
      if (id.isEmpty) {
        continue;
      }

      final status = appointment['status']?.toString() ?? '';
      if (status == 'cancelled') {
        continue;
      }

      final patientId = _patientId(appointment);
      if (patientId == null) {
        continue;
      }

      final appointmentDate = _appointmentDateTime(appointment);
      if (appointmentDate == null || appointmentDate.isBefore(cutoff)) {
        continue;
      }

      final existing = latestByPatientId[patientId];
      if (existing == null) {
        latestByPatientId[patientId] = appointment;
        continue;
      }

      final existingDate = _appointmentDateTime(existing);
      if (existingDate == null || appointmentDate.isAfter(existingDate)) {
        latestByPatientId[patientId] = appointment;
      }
    }

    final appointments = latestByPatientId.values.toList();
    appointments.sort((a, b) {
      final aDate = _appointmentDateTime(a) ?? DateTime(1970);
      final bDate = _appointmentDateTime(b) ?? DateTime(1970);
      return bDate.compareTo(aDate);
    });
    return appointments;
  }

  String? _patientId(Map<String, dynamic> appointment) {
    final patient = appointment['patient_id'];
    if (patient is Map<String, dynamic>) {
      final id = patient['_id']?.toString().trim() ?? '';
      if (id.isNotEmpty) {
        return id;
      }
    }
    return null;
  }

  DateTime? _appointmentDateTime(Map<String, dynamic> appointment) {
    final dateRaw = appointment['appointment_date']?.toString().trim() ?? '';
    final timeRaw = appointment['appointment_time']?.toString().trim() ?? '';

    if (dateRaw.isNotEmpty) {
      if (timeRaw.isNotEmpty) {
        final normalizedTime = _normalizeTimeForIso(timeRaw);
        final withTime = DateTime.tryParse('${dateRaw}T$normalizedTime');
        if (withTime != null) {
          return withTime;
        }
      }

      final dateOnly = DateTime.tryParse(dateRaw);
      if (dateOnly != null) {
        return dateOnly;
      }
    }

    final createdAt = appointment['createdAt']?.toString().trim() ?? '';
    if (createdAt.isNotEmpty) {
      final created = DateTime.tryParse(createdAt);
      if (created != null) {
        return created;
      }
    }

    final updatedAt = appointment['updatedAt']?.toString().trim() ?? '';
    if (updatedAt.isNotEmpty) {
      final updated = DateTime.tryParse(updatedAt);
      if (updated != null) {
        return updated;
      }
    }

    return null;
  }

  String _normalizeTimeForIso(String rawTime) {
    final value = rawTime.trim();
    if (value.isEmpty) {
      return '00:00:00';
    }
    if (RegExp(r'^\d{2}:\d{2}:\d{2}$').hasMatch(value)) {
      return value;
    }
    if (RegExp(r'^\d{2}:\d{2}$').hasMatch(value)) {
      return '$value:00';
    }
    return value;
  }

  Future<void> _showCreatePrescriptionSheet() async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    try {
      final response = await sl<ApiClient>().get('/api/appointments');
      final appointments = _doctorBookableAppointments(_mapList(response.data));

      if (!mounted) {
        return;
      }

      if (appointments.isEmpty) {
        scaffoldMessenger.showSnackBar(
          const SnackBar(content: Text('No booked appointments available.')),
        );
        return;
      }

      String selectedAppointmentId =
          appointments.first['_id']?.toString() ?? '';
      final diagnosisController = TextEditingController();
      final medicationController = TextEditingController();
      final instructionsController = TextEditingController();
      final notesController = TextEditingController();

      await showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        showDragHandle: true,
        builder: (sheetContext) {
          return StatefulBuilder(
            builder: (context, setSheetState) {
              return SafeArea(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    16,
                    12,
                    16,
                    MediaQuery.of(context).viewInsets.bottom + 16,
                  ),
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Add Prescription',
                          style: Theme.of(context)
                              .textTheme
                              .titleLarge
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<String>(
                          initialValue: selectedAppointmentId,
                          decoration: const InputDecoration(
                            labelText: 'Booked Appointment',
                            border: OutlineInputBorder(),
                          ),
                          items: appointments.map((appointment) {
                            final id = appointment['_id']?.toString() ?? '';
                            final patientName = _patientName(appointment);
                            final date =
                                appointment['appointment_date']?.toString() ??
                                    '-';
                            final time =
                                appointment['appointment_time']?.toString() ??
                                    '-';
                            return DropdownMenuItem<String>(
                              value: id,
                              child: Text('$patientName • $date $time'),
                            );
                          }).toList(),
                          onChanged: (value) {
                            if (value == null) {
                              return;
                            }
                            setSheetState(() {
                              selectedAppointmentId = value;
                            });
                          },
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: diagnosisController,
                          decoration: const InputDecoration(
                            labelText: 'Diagnosis',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: medicationController,
                          maxLines: 3,
                          decoration: const InputDecoration(
                            labelText:
                                'Medications (one per line: name | dosage | frequency | duration)',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: instructionsController,
                          maxLines: 2,
                          decoration: const InputDecoration(
                            labelText: 'Instructions',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: notesController,
                          maxLines: 2,
                          decoration: const InputDecoration(
                            labelText: 'Doctor Notes',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 14),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _isCreating
                                ? null
                                : () async {
                                    if (_isCreating) {
                                      return;
                                    }

                                    setState(() {
                                      _isCreating = true;
                                    });

                                    final diagnosis =
                                        diagnosisController.text.trim();
                                    if (selectedAppointmentId.isEmpty ||
                                        diagnosis.isEmpty) {
                                      if (mounted) {
                                        setState(() {
                                          _isCreating = false;
                                        });
                                      }
                                      scaffoldMessenger.showSnackBar(
                                        const SnackBar(
                                            content: Text(
                                                'Appointment and diagnosis are required.')),
                                      );
                                      return;
                                    }

                                    final medications = medicationController
                                        .text
                                        .split('\n')
                                        .map((line) => line.trim())
                                        .where((line) => line.isNotEmpty)
                                        .map((line) {
                                      final parts = line
                                          .split('|')
                                          .map((part) => part.trim())
                                          .toList();
                                      return {
                                        'name':
                                            parts.isNotEmpty ? parts[0] : '',
                                        'dosage':
                                            parts.length > 1 ? parts[1] : '',
                                        'frequency':
                                            parts.length > 2 ? parts[2] : '',
                                        'duration':
                                            parts.length > 3 ? parts[3] : '',
                                      };
                                    }).toList();

                                    try {
                                      await sl<ApiClient>().post(
                                        '/api/prescriptions',
                                        data: {
                                          'appointment_id':
                                              selectedAppointmentId,
                                          'diagnosis': diagnosis,
                                          'medications': medications,
                                          'instructions': instructionsController
                                              .text
                                              .trim(),
                                          'doctor_notes':
                                              notesController.text.trim(),
                                        },
                                      );

                                      if (context.mounted) {
                                        Navigator.of(sheetContext).pop();
                                      }

                                      await _loadPrescriptions();

                                      if (!mounted) {
                                        return;
                                      }
                                      scaffoldMessenger.showSnackBar(
                                        const SnackBar(
                                            content: Text(
                                                'Prescription added for booked patient.')),
                                      );
                                    } catch (_) {
                                      if (!mounted) {
                                        return;
                                      }
                                      scaffoldMessenger.showSnackBar(
                                        const SnackBar(
                                            content: Text(
                                                'Failed to create prescription.')),
                                      );
                                    } finally {
                                      if (mounted) {
                                        setState(() {
                                          _isCreating = false;
                                        });
                                      }
                                    }
                                  },
                            child: _isCreating
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Text('Save Prescription'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      );
    } catch (_) {
      if (!mounted) {
        return;
      }
      scaffoldMessenger.showSnackBar(
        const SnackBar(content: Text('Failed to load appointments.')),
      );
    }
  }

  Future<void> _loadPrescriptions() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final response = await sl<ApiClient>().get('/api/prescriptions');
      final data = response.data;
      final prescriptions = data is List
          ? data
              .whereType<Map>()
              .map((item) => item.map((k, v) => MapEntry(k.toString(), v)))
              .toList()
          : <Map<String, dynamic>>[];
      if (!mounted) {
        return;
      }
      setState(() {
        _prescriptions = prescriptions;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _error = 'Failed to load prescriptions.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final role = context.watch<AuthProvider>().role ?? 'patient';
    final isDoctor = role == 'doctor';

    return Scaffold(
      appBar: AppBar(
        title: Text(isDoctor ? 'Prescriptions' : 'My Prescriptions'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!))
              : RefreshIndicator(
                  onRefresh: _loadPrescriptions,
                  child: _prescriptions.isEmpty
                      ? ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          children: const [
                            SizedBox(height: 80),
                            Center(child: Text('No prescriptions found.')),
                          ],
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _prescriptions.length,
                          itemBuilder: (context, index) {
                            final prescription = _prescriptions[index];
                            final doctor = prescription['doctor_id'];
                            final appointment = prescription['appointment_id'];
                            final patientName =
                                _patientNameFromPrescription(prescription);
                            final doctorName = doctor is Map<String, dynamic> &&
                                    doctor['user_id'] is Map<String, dynamic>
                                ? doctor['user_id']['full_name']?.toString() ??
                                    'Doctor'
                                : 'Doctor';
                            final diagnosis =
                                prescription['diagnosis']?.toString() ??
                                    'No diagnosis';
                            final date = appointment is Map<String, dynamic>
                                ? appointment['appointment_date']?.toString() ??
                                    ''
                                : '';
                            final medicineLines = _medicineLines(prescription);
                            final meds = medicineLines.length;
                            final pdfUrl = prescription['pdf_url']?.toString();

                            return Card(
                              margin: const EdgeInsets.only(bottom: 16),
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: Text(
                                            isDoctor
                                                ? 'Patient: $patientName'
                                                : 'Dr. $doctorName',
                                            style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 16),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        Text(
                                          date.isEmpty ? 'No date' : date,
                                          style: const TextStyle(
                                              color: Colors.grey, fontSize: 12),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(diagnosis,
                                        style: const TextStyle(
                                            color: Colors.grey)),
                                    const SizedBox(height: 4),
                                    Text('$meds medicines prescribed'),
                                    if (medicineLines.isNotEmpty) ...[
                                      const SizedBox(height: 8),
                                      ...medicineLines
                                          .take(2)
                                          .map((line) => Text(
                                                '• $line',
                                                style: const TextStyle(
                                                  fontSize: 13,
                                                  color: Colors.black87,
                                                ),
                                              )),
                                      if (medicineLines.length > 2)
                                        Text(
                                          '+${medicineLines.length - 2} more medicines',
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey,
                                          ),
                                        ),
                                    ],
                                    const Divider(height: 24),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: OutlinedButton.icon(
                                            onPressed: () => _showDetails(
                                                context, prescription),
                                            icon: const Icon(
                                                Icons.remove_red_eye,
                                                size: 18),
                                            label: const Text('View'),
                                            style: OutlinedButton.styleFrom(
                                              foregroundColor:
                                                  AppColors.primary,
                                              side: const BorderSide(
                                                  color: AppColors.primary),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: ElevatedButton.icon(
                                            onPressed: () {
                                              final message = (pdfUrl != null &&
                                                      pdfUrl.isNotEmpty)
                                                  ? 'PDF URL: $pdfUrl'
                                                  : 'PDF not available for this prescription.';
                                              ScaffoldMessenger.of(context)
                                                  .showSnackBar(
                                                SnackBar(
                                                    content: Text(message)),
                                              );
                                            },
                                            icon: const Icon(Icons.download,
                                                size: 18),
                                            label: const Text('PDF'),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
      floatingActionButton: isDoctor
          ? FloatingActionButton.extended(
              onPressed: _isCreating ? null : _showCreatePrescriptionSheet,
              backgroundColor: AppColors.primary,
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text(
                'Add Prescription',
                style: TextStyle(color: Colors.white),
              ),
            )
          : null,
    );
  }

  Widget _detailRow(String label, String value) {
    final normalizedValue = value.trim().isEmpty ? 'Not specified' : value;
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: RichText(
        text: TextSpan(
          style: const TextStyle(fontSize: 14, color: Colors.black87),
          children: [
            TextSpan(
              text: '$label: ',
              style: const TextStyle(fontWeight: FontWeight.normal),
            ),
            TextSpan(text: normalizedValue),
          ],
        ),
      ),
    );
  }

  void _showDetails(BuildContext context, Map<String, dynamic> prescription) {
    final medications = prescription['medications'] is List
        ? prescription['medications'] as List
        : const [];
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (context) {
        return SizedBox(
          height: MediaQuery.of(context).size.height * 0.55,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  prescription['diagnosis']?.toString() ??
                      'Prescription Details',
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 12),
                ...(medications.map((medication) {
                  final map = medication is Map
                      ? medication.map((k, v) => MapEntry(k.toString(), v))
                      : <String, dynamic>{};
                  final name = map['name']?.toString().trim() ?? '';
                  final dosage = map['dosage']?.toString().trim() ?? '';
                  final frequency = map['frequency']?.toString().trim() ?? '';
                  final duration = map['duration']?.toString().trim() ?? '';
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.grey.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _detailRow('Medicine', name),
                          _detailRow('Dose', dosage),
                          _detailRow('Frequency', frequency),
                          _detailRow('Duration', duration),
                        ],
                      ),
                    ),
                  );
                })),
                if (medications.isEmpty)
                  const Text('No medication details found.'),
                const SizedBox(height: 12),
                _detailRow('Instructions',
                    prescription['instructions']?.toString() ?? 'None'),
                const SizedBox(height: 8),
                _detailRow('Doctor Notes',
                    prescription['doctor_notes']?.toString() ?? 'None'),
                const SizedBox(height: 16),
              ],
            ),
          ),
        );
      },
    );
  }
}
