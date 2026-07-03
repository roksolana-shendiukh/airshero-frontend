import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';
import '../services/auth_service.dart';

class AirfleetManufacturerApiService {
  final AuthService _authService;

  AirfleetManufacturerApiService(this._authService);

  Future<Map<String, String>> _headers() async {
    final token = await _authService.getToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  Future<List<Map<String, dynamic>>> getManufacturers() async {
    try {
      final response = await http.get(
        Uri.parse('${AppConfig.baseUrl}/crud/airfleet/manufacturers'),
        headers: await _headers(),
      );
      if (response.statusCode == 200) {
        return List<Map<String, dynamic>>.from(jsonDecode(response.body));
      }
      return [];
    } catch (e) {
      debugPrint('Network error (getManufacturers): $e');
      return [];
    }
  }

  Future<Map<String, dynamic>?> createManufacturer(String name) async {
    try {
      final response = await http.post(
        Uri.parse('${AppConfig.baseUrl}/crud/airfleet/manufacturers'),
        headers: await _headers(),
        body: jsonEncode({'manufacturer_name': name}),
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        return jsonDecode(response.body);
      }
      debugPrint('createManufacturer error: ${response.body}');
      return null;
    } catch (e) {
      debugPrint('Network error (createManufacturer): $e');
      return null;
    }
  }

  Future<Map<String, dynamic>?> updateManufacturer(int id, String name) async {
    try {
      final response = await http.put(
        Uri.parse('${AppConfig.baseUrl}/crud/airfleet/manufacturers/$id'),
        headers: await _headers(),
        body: jsonEncode({'manufacturer_name': name}),
      );
      if (response.statusCode == 200) return jsonDecode(response.body);
      return null;
    } catch (e) {
      debugPrint('Network error (updateManufacturer): $e');
      return null;
    }
  }

  Future<bool> deleteManufacturer(int id) async {
    try {
      final response = await http.delete(
        Uri.parse('${AppConfig.baseUrl}/crud/airfleet/manufacturers/$id'),
        headers: await _headers(),
      );
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Network error (deleteManufacturer): $e');
      return false;
    }
  }
}