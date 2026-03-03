import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';
import '../services/auth_service.dart';

class ReferenceApiService {
  final AuthService _authService;

  ReferenceApiService(this._authService);

  Future<Map<String, String>> _headers() async {
    final token = await _authService.getToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  Future<List<Map<String, dynamic>>> getCitizenships() async {
    try {
      final response = await http.get(
        Uri.parse('${AppConfig.baseUrl}/citizenships'),
        headers: await _headers(),
      );
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.cast<Map<String, dynamic>>();
      }
      return [];
    } catch (e) {
      debugPrint('Network error (getCitizenships): $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getDocumentTypes() async {
    try {
      final response = await http.get(
        Uri.parse('${AppConfig.baseUrl}/document-types'),
        headers: await _headers(),
      );
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.cast<Map<String, dynamic>>();
      }
      return [];
    } catch (e) {
      debugPrint('Network error (getDocumentTypes): $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getSexes() async {
    try {
      final response = await http.get(
        Uri.parse('${AppConfig.baseUrl}/sexes'),
        headers: await _headers(),
      );
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.cast<Map<String, dynamic>>();
      }
      return [];
    } catch (e) {
      debugPrint('Network error (getSexes): $e');
      return [];
    }
  }
}