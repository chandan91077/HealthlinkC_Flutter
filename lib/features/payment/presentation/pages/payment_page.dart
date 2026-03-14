import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:healthlink_connect_flutter/core/di/injection_container.dart';
import 'package:healthlink_connect_flutter/core/network/api_client.dart';

class PaymentPage extends StatefulWidget {
  final String bookingId;
  const PaymentPage({super.key, required this.bookingId});

  @override
  State<PaymentPage> createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage> {
  bool _isLoading = true;
  bool _isProcessing = false;
  String? _error;
  Map<String, dynamic>? _appointment;
  String _selectedPaymentMode = 'online';
  String _selectedOnlineMethod = 'upi';

  @override
  void initState() {
    super.initState();
    _loadAppointment();
  }

  Future<void> _loadAppointment() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final response =
          await sl<ApiClient>().get('/api/appointments/${widget.bookingId}');
      final data = response.data;

      if (!mounted) {
        return;
      }

      setState(() {
        _appointment = data is Map<String, dynamic>
            ? data
            : data is Map
                ? data.map((k, v) => MapEntry(k.toString(), v))
                : null;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _error = 'Failed to load appointment for payment.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _processPayment() async {
    if (_appointment == null) {
      return;
    }

    final amount = (_appointment!['amount'] as num?)?.toDouble() ?? 0;
    if (amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Invalid payment amount.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isProcessing = true;
    });

    try {
      await sl<ApiClient>().post(
        '/api/payments',
        data: {
          'appointment_id': widget.bookingId,
          'amount': amount,
          'payment_method': _selectedPaymentMode,
          'razorpay_order_id':
              'cf_order_${DateTime.now().millisecondsSinceEpoch}',
          'razorpay_payment_id':
              'cf_pay_${DateTime.now().millisecondsSinceEpoch}',
        },
      );

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _selectedPaymentMode == 'cash'
                ? 'Cash payment selected. Appointment is pending until payment is completed.'
                : 'Online payment successful. Appointment confirmed.',
          ),
          backgroundColor:
              _selectedPaymentMode == 'cash' ? Colors.orange : Colors.green,
        ),
      );
      context.go('/appointments?tab=upcoming');
    } catch (_) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Payment failed. Please try again.'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  String _doctorName() {
    final doctor = _appointment?['doctor_id'];
    if (doctor is Map<String, dynamic>) {
      final user = doctor['user_id'];
      if (user is Map<String, dynamic>) {
        final raw = user['full_name']?.toString() ?? 'Doctor';
        final normalized =
            raw.replaceFirst(RegExp(r'^dr\.?\s*', caseSensitive: false), '');
        return 'Dr. ${normalized.isEmpty ? 'Doctor' : normalized}';
      }
    }
    return 'Dr. Doctor';
  }

  double get _doctorFee {
    final direct = (_appointment?['doctor_fee'] as num?)?.toDouble();
    if (direct != null && direct >= 0) {
      return direct;
    }

    final doctor = _appointment?['doctor_id'];
    if (doctor is Map<String, dynamic>) {
      final appointmentType =
          (_appointment?['appointment_type']?.toString() ?? 'scheduled')
              .toLowerCase();
      final fallback = appointmentType == 'emergency'
          ? (doctor['emergency_fee'] as num?)?.toDouble()
          : (doctor['consultation_fee'] as num?)?.toDouble();
      if (fallback != null && fallback >= 0) {
        return fallback;
      }
    }

    final amount = (_appointment?['amount'] as num?)?.toDouble() ?? 0;
    return amount;
  }

  double get _platformFee {
    final direct = (_appointment?['platform_fee'] as num?)?.toDouble();
    if (direct != null && direct >= 0) {
      return direct;
    }

    final amount = (_appointment?['amount'] as num?)?.toDouble() ?? 0;
    final inferred = amount - _doctorFee;
    return inferred > 0 ? inferred : 0;
  }

  double get _totalAmount {
    final amount = (_appointment?['amount'] as num?)?.toDouble() ?? 0;
    if (amount > 0) {
      return amount;
    }
    return _doctorFee + _platformFee;
  }

  String _formatRupee(double value) {
    return '₹ ${value.toStringAsFixed(2)}';
  }

  @override
  Widget build(BuildContext context) {
    final doctorFee = _doctorFee;
    final platformFee = _platformFee;
    final total = _totalAmount;

    return Scaffold(
      appBar: AppBar(title: const Text('Appointment Checkout')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Booking Summary',
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 16),
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            children: [
                              _buildFeeRow('Doctor', _doctorName()),
                              const SizedBox(height: 8),
                              _buildFeeRow('Doctor Consultation Fee',
                                  _formatRupee(doctorFee)),
                              const SizedBox(height: 8),
                              _buildFeeRow('Platform Fee (Admin)',
                                  _formatRupee(platformFee)),
                              const Divider(height: 32),
                              _buildFeeRow('Total Amount', _formatRupee(total),
                                  isTotal: true),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),
                      const Text('Payment Mode',
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 16),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          ChoiceChip(
                            label: const Text('Cash'),
                            selected: _selectedPaymentMode == 'cash',
                            onSelected: (selected) {
                              if (!selected) return;
                              setState(() => _selectedPaymentMode = 'cash');
                            },
                          ),
                          ChoiceChip(
                            label: const Text('Online'),
                            selected: _selectedPaymentMode == 'online',
                            onSelected: (selected) {
                              if (!selected) return;
                              setState(() => _selectedPaymentMode = 'online');
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _selectedPaymentMode == 'cash'
                            ? 'Pay cash at clinic/hospital. Appointment remains pending until completed.'
                            : 'Pay online now to confirm appointment immediately.',
                      ),
                      if (_selectedPaymentMode == 'online') ...[
                        const SizedBox(height: 24),
                        const Text('Online Method',
                            style: TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 16),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            _buildMethodChip(
                                'UPI', Icons.account_balance_wallet, 'upi'),
                            _buildMethodChip('Card', Icons.credit_card, 'card'),
                            _buildMethodChip('Net Banking',
                                Icons.account_balance, 'netbanking'),
                          ],
                        ),
                      ],
                      const SizedBox(height: 48),
                      ElevatedButton(
                        onPressed: _isProcessing ? null : _processPayment,
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 56),
                        ),
                        child: _isProcessing
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : Text(_selectedPaymentMode == 'cash'
                                ? 'Confirm Cash Payment'
                                : 'Pay ${_formatRupee(total)}'),
                      ),
                    ],
                  ),
                ),
    );
  }

  Widget _buildFeeRow(String title, String amount, {bool isTotal = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title,
            style: TextStyle(
                fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
                fontSize: 16)),
        Text(amount,
            style: TextStyle(
                fontWeight: isTotal ? FontWeight.bold : FontWeight.w500,
                fontSize: 16)),
      ],
    );
  }

  Widget _buildMethodChip(String title, IconData icon, String value) {
    final selected = _selectedOnlineMethod == value;
    return ChoiceChip(
      avatar: Icon(icon, size: 16),
      label: Text(title),
      selected: selected,
      onSelected: (isSelected) {
        if (!isSelected) return;
        setState(() => _selectedOnlineMethod = value);
      },
    );
  }
}
