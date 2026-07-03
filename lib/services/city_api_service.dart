import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';
import '../models/city_model.dart';
import '../services/auth_service.dart';

class CityApiService {
  final AuthService _authService;

  CityApiService(this._authService);

  Future<Map<String, String>> _headers() async {
    final token = await _authService.getToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  Future<List<CityModel>> searchCities(String query) async {
    if (query.trim().isEmpty) return [];
    final uri = Uri.parse('${AppConfig.baseUrl}/cities/search')
        .replace(queryParameters: {'q': query});
    final response = await http.get(uri, headers: await _headers());
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((e) => CityModel.fromJson(e as Map<String, dynamic>)).toList();
    }
    throw Exception('Failed to search cities: ${response.statusCode}');
  }

  Future<List<String>> getAvailableDates(int fromCityId, int toCityId) async {
    try {
      final uri = Uri.parse('${AppConfig.baseUrl}/cities/available-dates').replace(
        queryParameters: {
          'from_city': fromCityId.toString(),
          'to_city':   toCityId.toString(),
        },
      );
      final response = await http.get(uri, headers: await _headers());
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((date) => date.toString()).toList();
      }
      return [];
    } catch (e) {
      debugPrint('Network error (getAvailableDates): $e');
      return [];
    }
  }

  Future<List<String>> getLeg2AvailableDates({
    required int hubCityId,
    required int toCityId,
    required String leg1Date,
  }) async {
    try {
      final uri = Uri.parse('${AppConfig.baseUrl}/cities/available-dates/leg2').replace(
        queryParameters: {
          'hub_city':  hubCityId.toString(),
          'to_city':   toCityId.toString(),
          'leg1_date': leg1Date,
        },
      );
      final response = await http.get(uri, headers: await _headers());
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((date) => date.toString()).toList();
      }
      return [];
    } catch (e) {
      debugPrint('Network error (getLeg2AvailableDates): $e');
      return [];
    }
  }

  Future<Map<String, dynamic>> getLeg2DatesWithSuggestions({
    required int fromCityId,
    required int hubCityId,
    required int toCityId,
    required String leg1Date,
  }) async {
    final uri = Uri.parse('${AppConfig.baseUrl}/cities/available-dates/leg2').replace(
      queryParameters: {
        'from_city': fromCityId.toString(),
        'hub_city':  hubCityId.toString(),
        'to_city':   toCityId.toString(),
        'leg1_date': leg1Date,
      },
    );
    final response = await http.get(uri, headers: await _headers());
    if (response.statusCode == 200) {
      return Map<String, dynamic>.from(jsonDecode(response.body));
    }
    return {'leg2_dates': [], 'suggested_leg1_dates': []};
  }

  Future<List<String>> getLeg1ConnectingDates({
    required int fromCityId,
    required int hubCityId,
    required int toCityId,
  }) async {
    final uri = Uri.parse('${AppConfig.baseUrl}/cities/available-dates/leg1-connecting')
        .replace(queryParameters: {
      'from_city': fromCityId.toString(),
      'hub_city':  hubCityId.toString(),
      'to_city':   toCityId.toString(),
    });
    final response = await http.get(uri, headers: await _headers());
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((e) => e.toString()).toList();
    }
    return [];
  }
}