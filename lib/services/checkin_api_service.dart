import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';
import '../services/auth_service.dart';

class CheckInApiService {
  final AuthService _authService;

  CheckInApiService(this._authService);

  Future<Map<String, String>> _headers() async {
    final token = await _authService.getToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  Future<List<Map<String, dynamic>>> searchBooking({
    required String documentNumber,
    required String flightNumber,
    required DateTime departsDate,
  }) async {
    try {
      final uri = Uri.parse('${AppConfig.baseUrl}/checkin/booking').replace(
        queryParameters: {
          'document_number': documentNumber,
          'flight_number':   flightNumber,
          'departs_date':    departsDate.toIso8601String().split('T')[0],
        },
      );

      final response = await http.get(uri, headers: await _headers());

      if (response.statusCode == 200) {
        debugPrint('CHECKIN BOOKING: ${response.body}');
        final List<dynamic> data = jsonDecode(response.body);
        return data.cast<Map<String, dynamic>>();
      } else if (response.statusCode == 404) {
        return [];
      } else {
        debugPrint('CheckIn booking error: ${response.statusCode} ${response.body}');
        return [];
      }
    } catch (e) {
      debugPrint('Network error (searchBooking): $e');
      rethrow;
    }
  }
}