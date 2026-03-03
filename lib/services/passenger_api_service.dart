import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';
import '../models/passenger_model.dart';
import '../services/auth_service.dart';

class PassengerApiService {
  final AuthService _authService;

  PassengerApiService(this._authService);

  Future<Map<String, String>> _headers() async {
    final token = await _authService.getToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  Future<List<PassengerModel>> getPassengers({
    int skip = 0,
    int limit = 50,
  }) async {
    try {
      final uri = Uri.parse('${AppConfig.baseUrl}/passengers').replace(
        queryParameters: {
          'skip': skip.toString(),
          'limit': limit.toString(),
        },
      );

      final response = await http.get(uri, headers: await _headers());

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data
            .map((e) => PassengerModel.fromJson(e as Map<String, dynamic>))
            .toList();
      } else {
        debugPrint('Failed to fetch passengers: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      debugPrint('Network error (getPassengers): $e');
      return [];
    }
  }

  Future<PassengerModel?> getPassengerById(int passengerId) async {
    try {
      final uri = Uri.parse('${AppConfig.baseUrl}/passengers/$passengerId');
      final response = await http.get(uri, headers: await _headers());

      if (response.statusCode == 200) {
        return PassengerModel.fromJson(
          jsonDecode(response.body) as Map<String, dynamic>,
        );
      } else if (response.statusCode == 404) {
        debugPrint('Passenger not found: $passengerId');
        return null;
      } else {
        debugPrint('Failed to fetch passenger: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      debugPrint('Network error (getPassengerById): $e');
      return null;
    }
  }

  Future<PassengerModel?> searchPassengerByDocument(
      String documentNumber) async {
    try {
      final uri =
          Uri.parse('${AppConfig.baseUrl}/passengers/search').replace(
        queryParameters: {'document_number': documentNumber},
      );

      final response = await http.get(uri, headers: await _headers());

      if (response.statusCode == 200) {
        return PassengerModel.fromJson(
          jsonDecode(response.body) as Map<String, dynamic>,
        );
      } else if (response.statusCode == 404) {
        return null;
      } else {
        debugPrint('Failed to search passenger: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      debugPrint('Network error (searchPassengerByDocument): $e');
      return null;
    }
  }

  Future<PassengerModel?> createPassenger({
    required String firstName,
    required String lastName,
    required String sex,
    String? email,
    DateTime? dateOfBirth,
    int? citizenshipId,
    int? documentTypeId,
    String? documentNumber,
    DateTime? documentDateOfIssue,
    DateTime? documentDateOfExpire,
  }) async {
    try {
      final body = {
        'first_name': firstName,
        'last_name': lastName,
        'sex': PassengerModel.sexToBool(sex),
        if (email != null) 'email': email,
        if (dateOfBirth != null)
          'date_of_birth': dateOfBirth.toIso8601String().split('T')[0],
        if (citizenshipId != null) 'citizenship_id': citizenshipId,
        if (documentTypeId != null) 'document_type_id': documentTypeId,
        if (documentNumber != null) 'document_number': documentNumber,
        if (documentDateOfIssue != null)
          'document_date_of_issue':
              documentDateOfIssue.toIso8601String().split('T')[0],
        if (documentDateOfExpire != null)
          'document_date_of_expire':
              documentDateOfExpire.toIso8601String().split('T')[0],
      };

      final response = await http.post(
        Uri.parse('${AppConfig.baseUrl}/passengers'),
        headers: await _headers(),
        body: jsonEncode(body),
      );

      if (response.statusCode == 201) {
        debugPrint('Passenger created: ${response.body}');
        return PassengerModel.fromJson(
          jsonDecode(response.body) as Map<String, dynamic>,
        );
      } else {
        debugPrint(
            'Failed to create passenger: ${response.statusCode} ${response.body}');
        return null;
      }
    } catch (e) {
      debugPrint('Network error (createPassenger): $e');
      return null;
    }
  }

  Future<PassengerModel?> updatePassenger(
    int passengerId, {
    String? firstName,
    String? lastName,
    String? sex,
    String? email,
    DateTime? dateOfBirth,
    int? citizenshipId,
    int? documentTypeId,
    String? documentNumber,
    DateTime? documentDateOfIssue,
    DateTime? documentDateOfExpire,
  }) async {
    try {
      final body = {
        if (firstName != null) 'first_name': firstName,
        if (lastName != null) 'last_name': lastName,
        if (sex != null) 'sex': PassengerModel.sexToBool(sex),
        if (email != null) 'email': email,
        if (dateOfBirth != null)
          'date_of_birth': dateOfBirth.toIso8601String().split('T')[0],
        if (citizenshipId != null) 'citizenship_id': citizenshipId,
        if (documentTypeId != null) 'document_type_id': documentTypeId,
        if (documentNumber != null) 'document_number': documentNumber,
        if (documentDateOfIssue != null)
          'document_date_of_issue':
              documentDateOfIssue.toIso8601String().split('T')[0],
        if (documentDateOfExpire != null)
          'document_date_of_expire':
              documentDateOfExpire.toIso8601String().split('T')[0],
      };

      final response = await http.put(
        Uri.parse('${AppConfig.baseUrl}/passengers/$passengerId'),
        headers: await _headers(),
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        return PassengerModel.fromJson(
          jsonDecode(response.body) as Map<String, dynamic>,
        );
      } else if (response.statusCode == 404) {
        debugPrint('Passenger not found: $passengerId');
        return null;
      } else {
        debugPrint(
            'Failed to update passenger: ${response.statusCode} ${response.body}');
        return null;
      }
    } catch (e) {
      debugPrint('Network error (updatePassenger): $e');
      return null;
    }
  }

  Future<bool> deletePassenger(int passengerId) async {
    try {
      final response = await http.delete(
        Uri.parse('${AppConfig.baseUrl}/passengers/$passengerId'),
        headers: await _headers(),
      );

      if (response.statusCode == 200) {
        debugPrint('Passenger deleted: $passengerId');
        return true;
      } else if (response.statusCode == 404) {
        debugPrint('Passenger not found: $passengerId');
        return false;
      } else {
        debugPrint('Failed to delete passenger: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      debugPrint('Network error (deletePassenger): $e');
      return false;
    }
  }

  Future<List<Map<String, dynamic>>> getDocumentSuggestions(
      String query) async {
    try {
      final uri =
          Uri.parse('${AppConfig.baseUrl}/passengers/search/suggestions')
              .replace(queryParameters: {'q': query});
      final response = await http.get(uri, headers: await _headers());
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.cast<Map<String, dynamic>>();
      }
      return [];
    } catch (e) {
      debugPrint('Network error (getDocumentSuggestions): $e');
      return [];
    }
  }
}