import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';
import '../services/auth_service.dart';

class BookingApiService {
  final AuthService _authService;

  BookingApiService(this._authService);

  Future<Map<String, String>> _headers() async {
    final token = await _authService.getToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  Future<Map<String, dynamic>> createBooking(Map<String, dynamic> body) async {
    final uri = Uri.parse('${AppConfig.baseUrl}/bookings');
    final response = await http.post(uri, headers: await _headers(), body: jsonEncode(body));
    if (response.statusCode == 201) {
      return Map<String, dynamic>.from(jsonDecode(response.body) as Map);
    }
    final error = jsonDecode(response.body);
    throw Exception((error['detail'] ?? 'Failed to create booking').toString());
  }

  Future<Map<String, dynamic>> createGroupBooking(Map<String, dynamic> body) async {
    final uri = Uri.parse('${AppConfig.baseUrl}/bookings/group');
    final response = await http.post(uri, headers: await _headers(), body: jsonEncode(body));
    if (response.statusCode == 201) {
      return Map<String, dynamic>.from(jsonDecode(response.body) as Map);
    }
    final error = jsonDecode(response.body);
    throw Exception((error['detail'] ?? 'Failed to create group booking').toString());
  }

  Future<Map<String, dynamic>> reserveBooking(Map<String, dynamic> body) async {
    try {
      final uri = Uri.parse('${AppConfig.baseUrl}/bookings/reserve');
      final response = await http.post(
        uri,
        headers: await _headers(),
        body: jsonEncode(body),
      );
      if (response.statusCode == 201) {
        return jsonDecode(response.body);
      }
      throw Exception(jsonDecode(response.body)['detail'] ?? 'Reservation failed');
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> reserveGroupBooking(Map<String, dynamic> body) async {
    try {
      final uri = Uri.parse('${AppConfig.baseUrl}/bookings/reserve/group');
      final response = await http.post(
        uri,
        headers: await _headers(),
        body: jsonEncode(body),
      );
      if (response.statusCode == 201) {
        return jsonDecode(response.body);
      }
      throw Exception(jsonDecode(response.body)['detail'] ?? 'Group reservation failed');
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updateBookingPassengers(int bookingId, Map<String, dynamic> body) async {
    try {
      final uri = Uri.parse('${AppConfig.baseUrl}/bookings/$bookingId/passengers');
      final response = await http.patch(
        uri,
        headers: await _headers(),
        body: jsonEncode(body),
      );
      if (response.statusCode != 200) {
        throw Exception(jsonDecode(response.body)['detail'] ?? 'Update failed');
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getBookings({
    int skip = 0,
    int limit = 50,
    String? status,
    String? dateFilter = 'this_month',
  }) async {
    try {
      final params = {
        'skip':  skip.toString(),
        'limit': limit.toString(),
        if (status != null)      'status':      status,
        if (dateFilter != null)  'date_filter': dateFilter,
      };
      final uri = Uri.parse('${AppConfig.baseUrl}/bookings')
          .replace(queryParameters: params);
      final response = await http.get(uri, headers: await _headers());
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((e) => Map<String, dynamic>.from(e as Map)).toList();
      }
      return [];
    } catch (e) {
      debugPrint('Network error (getBookings): $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getAdultPassengers(int bookingId) async {
    final uri = Uri.parse('${AppConfig.baseUrl}/bookings/$bookingId/adult-passengers');
    final response = await http.get(uri, headers: await _headers());
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    }
    throw Exception('Failed to load adult passengers: ${response.statusCode}');
  }

  Future<void> cancelBooking(int bookingId) async {
    final uri = Uri.parse('${AppConfig.baseUrl}/bookings/$bookingId/cancel');
    final response = await http.post(uri, headers: await _headers());
    if (response.statusCode != 200) {
      final error = jsonDecode(response.body);
      throw Exception(error['detail'] ?? 'Failed to cancel booking');
    }
  }
}