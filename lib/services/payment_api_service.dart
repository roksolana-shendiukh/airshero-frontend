import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';
import '../services/auth_service.dart';

class PaymentApiService {
  final AuthService _authService;

  PaymentApiService(this._authService);

  Future<Map<String, String>> _headers() async {
    final token = await _authService.getToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  Future<List<Map<String, dynamic>>> getPaymentMethods() async {
    final uri = Uri.parse('${AppConfig.baseUrl}/payment-methods');
    final response = await http.get(uri, headers: await _headers());
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    }
    throw Exception('Failed to load payment methods: ${response.statusCode}');
  }

  Future<void> processPayment({
    required int bookingId,
    required int paymentMethodId,
    required String status,
    required double amount,
    String? email,
  }) async {
    final uri = Uri.parse('${AppConfig.baseUrl}/bookings/$bookingId/payment');
    final response = await http.post(
      uri,
      headers: await _headers(),
      body: jsonEncode({
        'payment_method_id': paymentMethodId,
        'status':            status,
        'amount':            amount,
        if (email != null) 'email': email,
      }),
    );
    if (response.statusCode != 200) {
      final error = jsonDecode(response.body);
      throw Exception((error['detail'] ?? 'Failed to process payment').toString());
    }
  }

  Future<Map<String, dynamic>> confirmPayment({
    required int bookingId,
    required Map<String, dynamic> data,
  }) async {
    final uri = Uri.parse('${AppConfig.baseUrl}/bookings/$bookingId/payment');
    final response = await http.post(
      uri,
      headers: await _headers(),
      body: jsonEncode(data),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    final error = jsonDecode(response.body);
    final detail = error['detail'] ?? 'payment_error';
    switch (detail) {
      case 'booking_expired':
        throw Exception('Your booking has expired. Please start a new search.');
      case 'booking_not_found':
        throw Exception('Booking not found. Please contact support.');
      default:
        throw Exception('Payment could not be processed. Please try again.');
    }
  }
}