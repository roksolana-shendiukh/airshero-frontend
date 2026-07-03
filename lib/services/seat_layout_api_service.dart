import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';
import '../services/auth_service.dart';

class SeatLayoutApiService {
  final AuthService _authService;

  SeatLayoutApiService(this._authService);

  Future<Map<String, String>> _headers() async {
    final token = await _authService.getToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  Future<List<Map<String, dynamic>>> getSeatTypes() async {
    try {
      final response = await http.get(
        Uri.parse('${AppConfig.baseUrl}/crud/airfleet/seat-types/all'),
        headers: await _headers(),
      );
      if (response.statusCode == 200) {
        return List<Map<String, dynamic>>.from(jsonDecode(response.body));
      }
      return [];
    } catch (e) {
      debugPrint('Network error (getSeatTypes): $e');
      return [];
    }
  }

  Future<Map<String, dynamic>?> createSeatLayout({
    required int airfleetId,
    required int classId,
    required int seatTypeId,
    required int rows,
    required String columns,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('${AppConfig.baseUrl}/crud/airfleet/$airfleetId/seat-layouts'),
        headers: await _headers(),
        body: jsonEncode({
          'class_id':            classId,
          'seat_type_id':        seatTypeId,
          'seat_layout_rows':    rows,
          'seat_layout_columns': columns,
        }),
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        return jsonDecode(response.body);
      }
      return null;
    } catch (e) {
      debugPrint('Network error (createSeatLayout): $e');
      return null;
    }
  }

  Future<Map<String, dynamic>?> updateSeatLayout({
    required int seatLayoutId,
    required int classId,
    required int seatTypeId,
    required int rows,
    required String columns,
  }) async {
    try {
      final response = await http.put(
        Uri.parse('${AppConfig.baseUrl}/crud/airfleet/seat-layouts/$seatLayoutId'),
        headers: await _headers(),
        body: jsonEncode({
          'class_id':            classId,
          'seat_type_id':        seatTypeId,
          'seat_layout_rows':    rows,
          'seat_layout_columns': columns,
        }),
      );
      if (response.statusCode == 200) return jsonDecode(response.body);
      return null;
    } catch (e) {
      debugPrint('Network error (updateSeatLayout): $e');
      return null;
    }
  }

  Future<bool> deleteSeatLayout(int id) async {
    try {
      final response = await http.delete(
        Uri.parse('${AppConfig.baseUrl}/crud/airfleet/seat-layouts/$id'),
        headers: await _headers(),
      );
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Network error (deleteSeatLayout): $e');
      return false;
    }
  }
}