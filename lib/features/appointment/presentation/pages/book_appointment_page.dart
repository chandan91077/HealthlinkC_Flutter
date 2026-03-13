import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:healthlink_connect_flutter/config/routes/app_routes.dart';
import 'package:healthlink_connect_flutter/core/di/injection_container.dart';
import 'package:healthlink_connect_flutter/core/network/api_client.dart';
import 'package:healthlink_connect_flutter/core/theme/app_colors.dart';

class BookAppointmentPage extends StatefulWidget {
  final String doctorId;
  const BookAppointmentPage({super.key, required this.doctorId});

  @override
  State<BookAppointmentPage> createState() => _BookAppointmentPageState();
}

class _BookAppointmentPageState extends State<BookAppointmentPage> {
  bool _isLoading = true;
  bool _isBooking = false;
  String? _error;

  DateTime _selectedDate = DateTime.now();
  String _selectedSlot = '';
  String _paymentMode = 'cash';
  Map<String, dynamic>? _doctor;
  List<Map<String, dynamic>> _availability = const [];
  final TextEditingController _notesController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final api = sl<ApiClient>();
      final responses = await Future.wait([
        api.get('/api/doctors/${widget.doctorId}'),
        api.get('/api/availability/${widget.doctorId}'),
      ]);

      final doctorData = responses[0].data;
      final availabilityData = responses[1].data;

      final availability = availabilityData is List
          ? availabilityData
              .whereType<Map>()
              .map((item) => item.map((k, v) => MapEntry(k.toString(), v)))
              .toList()
          : <Map<String, dynamic>>[];

      if (!mounted) {
        return;
      }

      setState(() {
        _doctor = doctorData is Map<String, dynamic>
            ? doctorData
            : doctorData is Map
                ? doctorData
                    .map((key, value) => MapEntry(key.toString(), value))
                : null;
        _availability = availability;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _error = 'Failed to load doctor details for booking.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  int _jsDayOfWeek(DateTime date) {
    return date.weekday % 7;
  }

  Map<String, dynamic>? get _selectedAvailability {
    final jsDay = _jsDayOfWeek(_selectedDate);
    for (final item in _availability) {
      final day = (item['day_of_week'] as num?)?.toInt();
      final available = item['is_available'] != false;
      if (day == jsDay && available) {
        return item;
      }
    }
    return null;
  }

  int _toMinutes(String hhmm) {
    final parts = hhmm.split(':');
    if (parts.length != 2) {
      return -1;
    }
    final hour = int.tryParse(parts[0]) ?? -1;
    final minute = int.tryParse(parts[1]) ?? -1;
    if (hour < 0 || minute < 0) {
      return -1;
    }
    return hour * 60 + minute;
  }

  List<String> get _daySlots {
    final avail = _selectedAvailability;
    if (avail == null) {
      return const [];
    }

    final start = _toMinutes(avail['start_time']?.toString() ?? '');
    final end = _toMinutes(avail['end_time']?.toString() ?? '');
    if (start < 0 || end < 0 || end <= start) {
      return const [];
    }

    final now = DateTime.now();
    final isToday = _selectedDate.year == now.year &&
        _selectedDate.month == now.month &&
        _selectedDate.day == now.day;
    final nowMinutes = now.hour * 60 + now.minute;

    final slots = <String>[];
    for (int minute = start; minute < end; minute += 30) {
      if (isToday && minute <= nowMinutes) {
        continue;
      }

      final hh = (minute ~/ 60).toString().padLeft(2, '0');
      final mm = (minute % 60).toString().padLeft(2, '0');
      slots.add('$hh:$mm');
    }
    return slots;
  }

  List<String> get _morningSlots =>
      _daySlots.where((slot) => _toMinutes(slot) < 12 * 60).toList();

  List<String> get _afternoonSlots =>
      _daySlots.where((slot) => _toMinutes(slot) >= 12 * 60).toList();

  String _displayTime(String slot) {
    final parts = slot.split(':');
    if (parts.length != 2) {
      return slot;
    }
    final hour = int.tryParse(parts[0]) ?? 0;
    final minute = int.tryParse(parts[1]) ?? 0;
    final dt = DateTime(2000, 1, 1, hour, minute);
    return DateFormat('hh:mm a').format(dt);
  }

  String _doctorDisplayName(String? rawName) {
    final name = (rawName ?? 'Doctor').trim();
    final normalized =
        name.replaceFirst(RegExp(r'^dr\.?\s*', caseSensitive: false), '');
    return 'Dr. ${normalized.isEmpty ? 'Doctor' : normalized}';
  }

  String _resolveImageUrl(String? rawUrl) {
    final url = (rawUrl ?? '').trim();
    if (url.isEmpty) {
      return '';
    }
    if (url.startsWith('http://') || url.startsWith('https://')) {
      return url;
    }

    try {
      return Uri.parse(sl<ApiClient>().baseUrl).resolve(url).toString();
    } catch (_) {
      return '';
    }
  }

  Future<void> _confirmBooking() async {
    if (_selectedSlot.isEmpty || _doctor == null) {
      return;
    }

    setState(() {
      _isBooking = true;
    });

    try {
      final consultationFee =
          (_doctor!['consultation_fee'] as num?)?.toInt() ?? 0;
      final appointmentResponse = await sl<ApiClient>().post(
        '/api/appointments',
        data: {
          'doctor_id': widget.doctorId,
          'appointment_date': DateFormat('yyyy-MM-dd').format(_selectedDate),
          'appointment_time': _selectedSlot,
          'appointment_type': 'scheduled',
          'amount': consultationFee,
          'notes': _notesController.text.trim(),
        },
      );

      final appointmentData = appointmentResponse.data;
      final appointmentId = appointmentData is Map<String, dynamic>
          ? appointmentData['_id']?.toString() ?? ''
          : '';

      if (appointmentId.isEmpty) {
        throw Exception('Appointment id not returned');
      }

      if (_paymentMode == 'cash') {
        final paymentResponse = await sl<ApiClient>().post(
          '/api/payments',
          data: {
            'appointment_id': appointmentId,
            'amount': consultationFee,
            'payment_method': 'cash',
          },
        );

        final data = paymentResponse.data;
        final pending = data is Map<String, dynamic>
            ? data['appointment_pending'] == true
            : data is Map
                ? data['appointment_pending'] == true
                : false;

        if (!pending) {
          throw Exception('Cash appointment pending state was not returned');
        }

        if (!mounted) {
          return;
        }

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Appointment created with pending cash payment. It may cancel automatically if not completed in time.',
            ),
            backgroundColor: Colors.orange,
          ),
        );
        context.go('${AppRoutes.appointments}?tab=upcoming');
        return;
      }

      if (!mounted) {
        return;
      }

      context.push('/payment/$appointmentId');
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to book appointment. Please try another slot.'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isBooking = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = _doctor?['user_id'];
    final doctorName = _doctorDisplayName(
      user is Map<String, dynamic> ? user['full_name']?.toString() : null,
    );
    final avatarUrl = _resolveImageUrl(
      user is Map<String, dynamic> ? user['avatar_url']?.toString() : null,
    );
    final specialization = _doctor?['specialization']?.toString() ?? 'General';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Book Appointment'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Doctor Profile Summary
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 30,
                            backgroundColor: AppColors.primary,
                            backgroundImage: avatarUrl.isNotEmpty
                                ? NetworkImage(avatarUrl)
                                : null,
                            child: avatarUrl.isEmpty
                                ? const Icon(Icons.person,
                                    color: Colors.white, size: 30)
                                : null,
                          ),
                          const SizedBox(width: 16),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(doctorName,
                                  style:
                                      Theme.of(context).textTheme.titleMedium),
                              Text(specialization,
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyMedium
                                      ?.copyWith(color: Colors.grey)),
                              const SizedBox(height: 2),
                              Text(
                                'Consultation Fee: ₹${(_doctor?['consultation_fee'] as num?)?.toInt() ?? 0}',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 32),

                      // Date Selection
                      Text('Select Date',
                          style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 16),
                      SizedBox(
                        height: 90,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: 14, // Next 2 weeks
                          itemBuilder: (context, index) {
                            final date =
                                DateTime.now().add(Duration(days: index));
                            final isSelected = date.day == _selectedDate.day &&
                                date.month == _selectedDate.month;

                            return GestureDetector(
                              onTap: () => setState(() {
                                _selectedDate = date;
                                _selectedSlot = '';
                              }),
                              child: Container(
                                width: 70,
                                margin: const EdgeInsets.only(right: 12),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? AppColors.primary
                                      : Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: isSelected
                                        ? AppColors.primary
                                        : Colors.grey.withValues(alpha: 0.3),
                                  ),
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      _getWeekdayShort(date.weekday),
                                      style: TextStyle(
                                          color: isSelected
                                              ? Colors.white
                                              : Colors.grey),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${date.day}',
                                      style: TextStyle(
                                        color: isSelected
                                            ? Colors.white
                                            : Colors.black,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 18,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),

                      const SizedBox(height: 32),

                      // Time Slots
                      Text('Available Slots',
                          style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 16),
                      if (_selectedAvailability == null)
                        const Text(
                          'Doctor is not available on selected date.',
                          style: TextStyle(color: Colors.redAccent),
                        )
                      else if (_daySlots.isEmpty)
                        const Text(
                          'No slots available for selected date.',
                          style: TextStyle(color: Colors.redAccent),
                        ),
                      if (_morningSlots.isNotEmpty) ...[
                        const Text('Morning',
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.grey)),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          children: _morningSlots
                              .map((slot) => _buildSlotChip(slot))
                              .toList(),
                        ),
                      ],
                      if (_afternoonSlots.isNotEmpty) ...[
                        const SizedBox(height: 24),
                        const Text('Afternoon',
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.grey)),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          children: _afternoonSlots
                              .map((slot) => _buildSlotChip(slot))
                              .toList(),
                        ),
                      ],
                      const SizedBox(height: 24),
                      TextField(
                        controller: _notesController,
                        maxLines: 3,
                        decoration: InputDecoration(
                          labelText: 'Symptoms / Notes (optional)',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text('Payment Mode',
                          style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          ChoiceChip(
                            label: const Text('Cash'),
                            selected: _paymentMode == 'cash',
                            onSelected: (selected) {
                              if (!selected) return;
                              setState(() => _paymentMode = 'cash');
                            },
                          ),
                          ChoiceChip(
                            label: const Text('Online'),
                            selected: _paymentMode == 'online',
                            onSelected: (selected) {
                              if (!selected) return;
                              setState(() => _paymentMode = 'online');
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _paymentMode == 'cash'
                            ? 'Pay cash at clinic/hospital. Appointment confirms now.'
                            : 'Open Cashfree checkout page and pay online.',
                        style: const TextStyle(color: AppColors.textSecondary),
                      ),
                      Container(
                        width: double.infinity,
                        margin: const EdgeInsets.only(top: 8),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          color: AppColors.primary.withValues(alpha: 0.08),
                        ),
                        child: Text(
                          'Pay Amount: ₹${(_doctor?['consultation_fee'] as num?)?.toInt() ?? 0}',
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                      const SizedBox(height: 48),
                    ],
                  ),
                ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: ElevatedButton(
            onPressed:
                _selectedSlot.isEmpty || _isBooking ? null : _confirmBooking,
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 56),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
            ),
            child: _isBooking
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Text(_paymentMode == 'online'
                    ? 'Proceed to Cashfree'
                    : 'Confirm Appointment'),
          ),
        ),
      ),
    );
  }

  Widget _buildSlotChip(String time) {
    final isSelected = _selectedSlot == time;
    return ChoiceChip(
      label: Text(_displayTime(time)),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) {
          setState(() => _selectedSlot = time);
        }
      },
      selectedColor: AppColors.primary,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : Colors.black87,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
    );
  }

  String _getWeekdayShort(int weekday) {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return days[weekday - 1];
  }
}
