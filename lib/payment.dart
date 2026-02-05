import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';

class PaymentService {
  static const String BASE_URL = "https://api.chandus7.in";

  /// STEP 1: CREATE ORDER + USERCOURSE
  static Future<Map<String, dynamic>> createOrder({
    required int userId,
    required int courseId,
  }) async {
    final res = await http.post(
      Uri.parse("$BASE_URL/api/infumedz/payment/create-order/"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"user_id": userId, "course_id": courseId}),
    );

    if (res.statusCode != 200) {
      throw Exception("Order creation failed");
    }

    return jsonDecode(res.body);
  }

  /// STEP 3: VERIFY PAYMENT (SDK SUCCESS)
  static Future<bool> verifyPayment({
    required String orderId,
    required String paymentId,
    required String signature,
  }) async {
    final res = await http.post(
      Uri.parse("$BASE_URL/api/infumedz/payment/verify-payment/"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "order_id": orderId,
        "payment_id": paymentId,
        "signature": signature,
      }),
    );

    return res.statusCode == 200;
  }
}

class CoursePaymentScreen extends StatefulWidget {
  final int userId;
  final int courseId;
  final String courseTitle;
  final int amount; // in rupees

  const CoursePaymentScreen({
    super.key,
    required this.userId,
    required this.courseId,
    required this.courseTitle,
    required this.amount,
  });

  @override
  State<CoursePaymentScreen> createState() => _CoursePaymentScreenState();
}

class _CoursePaymentScreenState extends State<CoursePaymentScreen> {
  late Razorpay _razorpay;
  bool _loading = false;
  String _status = "";

  String? _orderId;

  @override
  void initState() {
    super.initState();
    _razorpay = Razorpay();

    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _onPaymentSuccess);

    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _onPaymentError);
  }

  @override
  void dispose() {
    _razorpay.clear();
    super.dispose();
  }

  // =====================================================
  // STEP 1: CREATE ORDER
  // =====================================================
  Future<void> startPayment() async {
    setState(() {
      _loading = true;
      _status = "Creating order…";
    });

    try {
      final data = await PaymentService.createOrder(userId: 1, courseId: 1);

      _orderId = data["order_id"];

      _openRazorpay(key: data["key"], amount: 9);
    } catch (e) {
      setState(() {
        _loading = false;
        _status = "Failed to start payment";
      });
    }
  }

  // =====================================================
  // STEP 2: OPEN RAZORPAY
  // =====================================================
  void _openRazorpay({required String key, required int amount}) {
    setState(() => _status = "Opening payment gateway…");

    _razorpay.open({
      'key': key,
      'order_id': _orderId,
      'amount': amount * 100, // Razorpay uses paise
      'currency': 'INR',
      'name': 'InfuMedz',
      'description': widget.courseTitle,
      'timeout': 180,
      'retry': {'enabled': false},
    });
  }

  // =====================================================
  // STEP 3: SDK SUCCESS (NOT FINAL TRUTH)
  // =====================================================
  Future<void> _onPaymentSuccess(PaymentSuccessResponse response) async {
    setState(() => _status = "Verifying payment…");

    final ok = await PaymentService.verifyPayment(
      orderId: _orderId!,
      paymentId: response.paymentId!,
      signature: response.signature!,
    );

    setState(() {
      _loading = false;
      _status = ok
          ? "✅ Payment Successful"
          : "⚠️ Payment processing. Please refresh.";
    });

    if (ok && mounted) {
      Navigator.pop(context, true); // return success
    }
  }

  void _onPaymentError(PaymentFailureResponse response) {
    setState(() {
      _loading = false;
      _status = "Payment cancelled or failed";
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Course Payment")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Text(
              widget.courseTitle,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 12),

            Text("₹${widget.amount}", style: const TextStyle(fontSize: 24)),

            const SizedBox(height: 30),

            ElevatedButton(
              onPressed: _loading ? null : startPayment,
              child: Text(_loading ? "Processing…" : "Pay Now"),
            ),

            const SizedBox(height: 20),

            Text(_status, style: const TextStyle(color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}
