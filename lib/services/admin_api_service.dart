import 'dart:convert';
import 'package:http/http.dart' as http;
import 'auth_service.dart';

class ApiValidationException implements Exception {
  final Map<String, String> fieldErrors;
  ApiValidationException(this.fieldErrors);
}

Map<String, String> _parsePydanticErrors(List detail) {
  final errors = <String, String>{};
  for (final err in detail) {
    final loc = err['loc'] as List?;
    final field = loc != null && loc.length > 1 ? loc.last.toString() : 'general';
    final msg = err['msg']?.toString() ?? 'Invalid value';
    errors[field] = msg;
  }
  return errors;
}

class AdminApiService {
  static const String _baseUrl = 'http://localhost:8000';

  final AuthService _authService;

  AdminApiService(this._authService);

  Future<Map<String, String>> _headers() async {
    final token = await _authService.getToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  Future<List<Map<String, dynamic>>> getUsers() async {
    final response = await http.get(
      Uri.parse('$_baseUrl/admin/users'),
      headers: await _headers(),
    );
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.cast<Map<String, dynamic>>();
    }
    throw Exception('Failed to load users: ${response.statusCode}');
  }

  Future<Map<String, dynamic>> createUser({
    required String email,
    required String firstName,
    required String lastName,
    required String airlineName,
    required int roleId,
  }) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/admin/users'),
      headers: await _headers(),
      body: jsonEncode({
        'email': email,
        'firstName': firstName,
        'lastName': lastName,
        'airlineName': airlineName,
        'roleId': roleId,
      }),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return jsonDecode(response.body);
    }

    final error = jsonDecode(response.body);
    final detail = error['detail'];

    if (detail is List) {
      throw ApiValidationException(_parsePydanticErrors(detail));
    } else if (detail is String) {
      throw Exception(detail);
    } else {
      throw Exception('Server error: ${response.statusCode}');
    }
  }

  Future<void> changePassword(String password) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/change-password'),
      headers: await _headers(),
      body: jsonEncode({'password': password}),
    );
    if (response.statusCode != 200) {
      final error = jsonDecode(response.body);
      final detail = error['detail'];
      if (detail is List) {
        throw ApiValidationException(_parsePydanticErrors(detail));
      }
      throw Exception(detail ?? 'Failed to change password');
    }
  }

  Future<void> setRole(String uid, int roleId) async {
    final response = await http.patch(
      Uri.parse('$_baseUrl/admin/users/$uid/role'),
      headers: await _headers(),
      body: jsonEncode({'roleId': roleId}),
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to set role: ${response.statusCode}');
    }
  }

  Future<void> setStatus(String uid, String status) async {
    final response = await http.patch(
      Uri.parse('$_baseUrl/admin/users/$uid/status'),
      headers: await _headers(),
      body: jsonEncode({'status': status}),
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to set status: ${response.statusCode}');
    }
  }
}