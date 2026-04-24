import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';
import '../services/auth_service.dart';
import '../models/flight_crew_model.dart';

class CrewApiService {
  final AuthService _authService;

  CrewApiService(this._authService);

  Future<Map<String, String>> _headers() async {
    final token = await _authService.getToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  Future<List<FlightCrewModel>> getAll({
    String? search,
    String? position,
  }) async {
    try {
      final uri = Uri.parse('${AppConfig.baseUrl}/crew').replace(
        queryParameters: {
          if (search   != null && search.isNotEmpty)   'search':   search,
          if (position != null && position.isNotEmpty) 'position': position,
        },
      );
      final response = await http.get(uri, headers: await _headers());
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((e) => FlightCrewModel.fromJson(e)).toList();
      }
      return [];
    } catch (e) {
      debugPrint('Network error (crew getAll): $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getPositions() async {
    try {
      final response = await http.get(
        Uri.parse('${AppConfig.baseUrl}/crew/positions'),
        headers: await _headers(),
      );
      if (response.statusCode == 200) {
        return List<Map<String, dynamic>>.from(jsonDecode(response.body));
      }
      return [];
    } catch (e) {
      debugPrint('Network error (crew getPositions): $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getLicenseTypes() async {
    try {
      final response = await http.get(
        Uri.parse('${AppConfig.baseUrl}/crew/license-types'),
        headers: await _headers(),
      );
      if (response.statusCode == 200) {
        return List<Map<String, dynamic>>.from(jsonDecode(response.body));
      }
      return [];
    } catch (e) {
      debugPrint('Network error (crew getLicenseTypes): $e');
      return [];
    }
  }

  Future<FlightCrewModel?> create({
    required String firstName,
    required String lastName,
    required int    positionId,
    required int    licenseTypeId,
    required int    experienceYears,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('${AppConfig.baseUrl}/crew'),
        headers: await _headers(),
        body: jsonEncode({
          'firstName':       firstName,
          'lastName':        lastName,
          'positionId':      positionId,
          'licenseTypeId':   licenseTypeId,
          'experienceYears': experienceYears,
        }),
      );
      if (response.statusCode == 201) {
        return FlightCrewModel.fromJson(jsonDecode(response.body));
      }
      debugPrint('Crew create error: ${response.statusCode} ${response.body}');
      return null;
    } catch (e) {
      debugPrint('Network error (crew create): $e');
      return null;
    }
  }

  Future<FlightCrewModel?> update({
    required int     crewId,
    String?  firstName,
    String?  lastName,
    int?     positionId,
    int?     licenseTypeId,
    int?     experienceYears,
  }) async {
    try {
      final response = await http.put(
        Uri.parse('${AppConfig.baseUrl}/crew/$crewId'),
        headers: await _headers(),
        body: jsonEncode({
          if (firstName       != null) 'firstName':       firstName,
          if (lastName        != null) 'lastName':        lastName,
          if (positionId      != null) 'positionId':      positionId,
          if (licenseTypeId   != null) 'licenseTypeId':   licenseTypeId,
          if (experienceYears != null) 'experienceYears': experienceYears,
        }),
      );
      if (response.statusCode == 200) {
        return FlightCrewModel.fromJson(jsonDecode(response.body));
      }
      debugPrint('Crew update error: ${response.statusCode} ${response.body}');
      return null;
    } catch (e) {
      debugPrint('Network error (crew update): $e');
      return null;
    }
  }

  Future<bool> delete(int crewId) async {
    try {
      final response = await http.delete(
        Uri.parse('${AppConfig.baseUrl}/crew/$crewId'),
        headers: await _headers(),
      );
      return response.statusCode == 204;
    } catch (e) {
      debugPrint('Network error (crew delete): $e');
      return false;
    }
  }
}