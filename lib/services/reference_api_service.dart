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

  Future<List<Map<String, dynamic>>> getCitizenships({String? query}) async {
    try {
      final params = <String, String>{};
      if (query != null && query.isNotEmpty) {
        params['q'] = query;
      }
      final uri = Uri.parse('${AppConfig.baseUrl}/citizenships')
          .replace(queryParameters: params.isEmpty ? null : params);
      final response = await http.get(uri, headers: await _headers());
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

  Future<List<Map<String, dynamic>>> getDocumentTypes({
    int? flightId,
  }) async {
    final uri = Uri.parse('${AppConfig.baseUrl}/document-types').replace(
      queryParameters: flightId != null
          ? {'flight_id': flightId.toString()}
          : null,
    );
    final response = await http.get(uri, headers: await _headers());
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as List;
      return data.cast<Map<String, dynamic>>();
    }
    return [];
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