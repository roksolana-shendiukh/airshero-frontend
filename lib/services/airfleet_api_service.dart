import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import '../config/app_config.dart';
import '../services/auth_service.dart';

class AirfleetApiService {
  final AuthService _authService;

  AirfleetApiService(this._authService);

  Future<Map<String, String>> _headers() async {
    final token = await _authService.getToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  Future<List<Map<String, dynamic>>> getAirfleets() async {
    try {
      final response = await http.get(
        Uri.parse('${AppConfig.baseUrl}/crud/airfleet'),
        headers: await _headers(),
      );
      if (response.statusCode == 200) {
        return List<Map<String, dynamic>>.from(jsonDecode(response.body));
      }
      return [];
    } catch (e) {
      debugPrint('Network error (getAirfleets): $e');
      return [];
    }
  }

  Future<Map<String, dynamic>?> getAirfleet(int id) async {
    try {
      final response = await http.get(
        Uri.parse('${AppConfig.baseUrl}/crud/airfleet/$id'),
        headers: await _headers(),
      );
      if (response.statusCode == 200) return jsonDecode(response.body);
      return null;
    } catch (e) {
      debugPrint('Network error (getAirfleet): $e');
      return null;
    }
  }

  Future<Map<String, dynamic>?> createAirfleet({
    required int manufacturerId,
    required String model,
    required double rangeKm,
    required double speed,
    required int seatCapacity,
    required double baggageCapacity,
    double? fuelConsumption,
    String? imageUrl,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('${AppConfig.baseUrl}/crud/airfleet'),
        headers: await _headers(),
        body: jsonEncode({
          'airfleet_manufacturer_id': manufacturerId,
          'aircraft_model':           model,
          'aircraft_range_km':        rangeKm,
          'aircraft_speed':           speed,
          'seat_capacity':            seatCapacity,
          'baggage_capacity':         baggageCapacity,
          if (fuelConsumption != null) 'aircraft_fuel_consumption': fuelConsumption,
          if (imageUrl != null)        'aircraft_url': imageUrl,
        }),
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        return jsonDecode(response.body);
      }
      debugPrint('createAirfleet error: ${response.body}');
      return null;
    } catch (e) {
      debugPrint('Network error (createAirfleet): $e');
      return null;
    }
  }

  Future<Map<String, dynamic>?> updateAirfleet({
    required int airfleetId,
    required int manufacturerId,
    required String model,
    required double rangeKm,
    required double speed,
    required int seatCapacity,
    required double baggageCapacity,
    double? fuelConsumption,
    String? imageUrl,
  }) async {
    try {
      final response = await http.put(
        Uri.parse('${AppConfig.baseUrl}/crud/airfleet/$airfleetId'),
        headers: await _headers(),
        body: jsonEncode({
          'airfleet_manufacturer_id': manufacturerId,
          'aircraft_model':           model,
          'aircraft_range_km':        rangeKm,
          'aircraft_speed':           speed,
          'seat_capacity':            seatCapacity,
          'baggage_capacity':         baggageCapacity,
          if (fuelConsumption != null) 'aircraft_fuel_consumption': fuelConsumption,
          if (imageUrl != null)        'aircraft_url': imageUrl,
        }),
      );
      if (response.statusCode == 200) return jsonDecode(response.body);
      return null;
    } catch (e) {
      debugPrint('Network error (updateAirfleet): $e');
      return null;
    }
  }

  Future<bool> deleteAirfleet(int id) async {
    try {
      final response = await http.delete(
        Uri.parse('${AppConfig.baseUrl}/crud/airfleet/$id'),
        headers: await _headers(),
      );
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Network error (deleteAirfleet): $e');
      return false;
    }
  }

  Future<String?> uploadAirfleetPhoto(
      int airfleetId, List<int> fileBytes, String fileName) async {
    try {
      final token = await _authService.getToken();
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('${AppConfig.baseUrl}/crud/airfleet/$airfleetId/photo'),
      );
      if (token != null) request.headers['Authorization'] = 'Bearer $token';
      request.files.add(http.MultipartFile.fromBytes(
        'file',
        fileBytes,
        filename: fileName,
        contentType: MediaType.parse(_mimeType(fileName)),
      ));
      final streamed = await request.send();
      final response = await http.Response.fromStream(streamed);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['photo_url'] as String?;
      }
      return null;
    } catch (e) {
      debugPrint('Network error (uploadAirfleetPhoto): $e');
      return null;
    }
  }

  String _mimeType(String fileName) {
    final ext = fileName.split('.').last.toLowerCase();
    switch (ext) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'webp':
        return 'image/webp';
      default:
        return 'image/jpeg';
    }
  }
}