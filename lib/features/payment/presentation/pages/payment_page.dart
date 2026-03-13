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
  String _selectedMethod = 'upi';

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

    final amount = (_appointment!['amount'] as num?)?.toInt() ?? 0;
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
          'payment_method': 'online',
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
        const SnackBar(
          content: Text('Online payment successful. Appointment confirmed.'),
          backgroundColor: Colors.green,
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

  @override
  Widget build(BuildContext context) {
    final amount = (_appointment?['amount'] as num?)?.toInt() ?? 0;
    const tax = 0;
    final total = amount + tax;

    return Scaffold(
      appBar: AppBar(title: const Text('Cashfree Checkout')),
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
                              _buildFeeRow('Consultation Fee', '₹ $amount.00'),
                              const SizedBox(height: 8),
                              _buildFeeRow('Taxes & SGST', '₹ $tax.00'),
                              const Divider(height: 32),
                              _buildFeeRow('Total Amount', '₹ $total.00',
                                  isTotal: true),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),
                      const Text('Online Payment Method',
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
                          _buildMethodChip('Net Banking', Icons.account_balance,
                              'netbanking'),
                        ],
                      ),
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
                            : Text('Pay ₹ $total.00'),
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
    final selected = _selectedMethod == value;
    return ChoiceChip(
      avatar: Icon(icon, size: 16),
      label: Text(title),
      selected: selected,
      onSelected: (isSelected) {
        if (!isSelected) return;
        setState(() => _selectedMethod = value);
      },
    );
  }
}
