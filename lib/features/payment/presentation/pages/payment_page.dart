import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_cashfree_pg_sdk/api/cferrorresponse/cferrorresponse.dart';
import 'package:flutter_cashfree_pg_sdk/api/cfpayment/cfwebcheckoutpayment.dart';
import 'package:flutter_cashfree_pg_sdk/api/cfpaymentgateway/cfpaymentgatewayservice.dart';
import 'package:flutter_cashfree_pg_sdk/api/cfsession/cfsession.dart';
import 'package:flutter_cashfree_pg_sdk/utils/cfenums.dart';
import 'package:flutter_cashfree_pg_sdk/utils/cfexceptions.dart';
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
  final CFPaymentGatewayService _cashfreeGateway = CFPaymentGatewayService();

  bool _isLoading = true;
  bool _isProcessing = false;
  bool _isVerifyingPayment = false;
  String? _error;
  Map<String, dynamic>? _appointment;


  @override
  void initState() {
    super.initState();
    _cashfreeGateway.setCallback(_verifyCashfreePayment, _onCashfreeError);
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
      await _startCashfreeCheckout();
      return;
    } on DioException catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text(_dioMessage(error, 'Payment failed. Please try again.')),
          backgroundColor: Colors.red,
        ),
      );
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

  String _dioMessage(DioException error, String fallback) {
    final data = error.response?.data;
    if (data is Map<String, dynamic>) {
      final message = data['message']?.toString().trim() ?? '';
      if (message.isNotEmpty) {
        return message;
      }
    }
    return fallback;
  }

  CFEnvironment _cashfreeEnvironmentFrom(String value) {
    return value.toLowerCase() == 'production'
        ? CFEnvironment.PRODUCTION
        : CFEnvironment.SANDBOX;
  }

  Future<CFSession?> _createCashfreeSession() async {
    try {
      final response = await sl<ApiClient>().post(
        '/api/payments/cashfree/order',
        data: {'appointment_id': widget.bookingId},
      );

      final data = response.data;
      final payload = data is Map<String, dynamic>
          ? data
          : data is Map
              ? data.map((k, v) => MapEntry(k.toString(), v))
              : <String, dynamic>{};

      final orderId = payload['order_id']?.toString() ?? '';
      final paymentSessionId = payload['payment_session_id']?.toString() ?? '';
      final environment = payload['cashfree_env']?.toString() ?? 'sandbox';

      if (orderId.isEmpty || paymentSessionId.isEmpty) {
        throw const FormatException('Cashfree order session was not returned.');
      }

      return CFSessionBuilder()
          .setEnvironment(_cashfreeEnvironmentFrom(environment))
          .setOrderId(orderId)
          .setPaymentSessionId(paymentSessionId)
          .build();
    } on DioException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _dioMessage(error, 'Failed to create Cashfree order session.'),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } on CFException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error.message),
            backgroundColor: Colors.red,
          ),
        );
      }
    } on FormatException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error.message),
            backgroundColor: Colors.red,
          ),
        );
      }
    }

    return null;
  }

  Future<void> _startCashfreeCheckout() async {
    final session = await _createCashfreeSession();
    if (session == null) {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
      return;
    }

    try {
      _cashfreeGateway.setCallback(_verifyCashfreePayment, _onCashfreeError);
      final payment = CFWebCheckoutPaymentBuilder().setSession(session).build();
      _cashfreeGateway.doPayment(payment);
    } on CFException catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isProcessing = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.message),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _verifyCashfreePayment(String orderId) async {
    if (!mounted) {
      return;
    }

    setState(() {
      _isProcessing = false;
      _isVerifyingPayment = true;
    });

    try {
      await sl<ApiClient>().post(
        '/api/payments/cashfree/verify',
        data: {
          'appointment_id': widget.bookingId,
          'order_id': orderId,
        },
      );

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Payment successful. Appointment confirmed.'),
          backgroundColor: Colors.green,
        ),
      );
      context.go('/appointments?tab=upcoming');
    } on DioException catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _dioMessage(
                error, 'Payment verification failed. Please try again.'),
          ),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isVerifyingPayment = false;
        });
      }
    }
  }

  void _onCashfreeError(CFErrorResponse errorResponse, String orderId) {
    if (!mounted) {
      return;
    }

    setState(() {
      _isProcessing = false;
      _isVerifyingPayment = false;
    });

    // Mark the appointment as failed so the time slot is freed
    _markAppointmentFailed();

    final message = (errorResponse.getMessage() ?? '').trim();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message.isNotEmpty
            ? message
            : 'Payment failed. The time slot has been freed.'),
        backgroundColor: Colors.red,
      ),
    );
    context.go('/appointments?tab=upcoming');
  }

  Future<void> _markAppointmentFailed() async {
    try {
      await sl<ApiClient>().post(
        '/api/payments/cashfree/fail',
        data: {'appointment_id': widget.bookingId},
      );
    } catch (_) {
      // Best-effort; cron job will also auto-cancel unpaid appointments
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
                              _buildFeeRow('Platform Fee ',
                                  _formatRupee(platformFee)),
                              const Divider(height: 32),
                              _buildFeeRow('Total Amount', _formatRupee(total),
                                  isTotal: true),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Padding(
                        padding: EdgeInsets.only(top: 8),
                        child: Text(
                          'The app will open Cashfree checkout and let you choose UPI, card, or net banking securely.',
                        ),
                      ),
                      const SizedBox(height: 48),
                      ElevatedButton(
                        onPressed: _isProcessing || _isVerifyingPayment
                            ? null
                            : _processPayment,
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 56),
                        ),
                        child: _isProcessing || _isVerifyingPayment
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : Text('Pay ${_formatRupee(total)}'),
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
}
