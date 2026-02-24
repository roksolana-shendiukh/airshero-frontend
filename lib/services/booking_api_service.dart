import 'dart:convert';
import 'package:flutter/foundation.dart'; // Додано для debugPrint
import 'package:http/http.dart' as http;
import '../config/app_config.dart';
import '../models/city_model.dart';
import '../models/flight_model.dart';
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

  Future<List<CityModel>> searchCities(String query) async {
    if (query.trim().isEmpty) return [];

    final uri = Uri.parse('${AppConfig.baseUrl}/cities/search')
        .replace(queryParameters: {'q': query});

    final response = await http.get(uri, headers: await _headers());

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data
          .map((e) => CityModel.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    throw Exception('Failed to search cities: ${response.statusCode}');
  }

  Future<List<FlightModel>> searchFlights({
    required int fromCityId,
    required int toCityId,
    required DateTime departDate,
  }) async {
    try {
      final dateStr = departDate.toIso8601String().split('T')[0];
      
      final uri = Uri.parse('${AppConfig.baseUrl}/flights/search').replace(
        queryParameters: {
          'from_city': fromCityId.toString(),
          'to_city': toCityId.toString(),
          'depart_date': dateStr,
        },
      );

      final response = await http.get(uri, headers: await _headers());

      if (response.statusCode == 200) {
        debugPrint('RESPONSE DATA: ${response.body}');
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => FlightModel.fromJson(json)).toList();
      } else {
        debugPrint('Search error: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      debugPrint('Network error (searchFlights): $e');
      return [];
    }
  }

  Future<List<CityModel>> getAlternativeDestinations(int fromCityId) async {
    final uri = Uri.parse('${AppConfig.baseUrl}/flights/alternatives/$fromCityId');
    final response = await http.get(uri, headers: await _headers());

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((e) => CityModel.fromJson(e)).toList();
    }
    return [];
  }

  Future<List<CityModel>> getAlternatives(int fromCityId) async {
    final uri = Uri.parse('${AppConfig.baseUrl}/cities/alternatives/$fromCityId');
    final response = await http.get(uri, headers: await _headers());

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((e) => CityModel.fromJson(e)).toList();
    }
    return [];
  }

  Future<List<String>> getAvailableDates(int fromCityId, int toCityId) async {
    try {
      final uri = Uri.parse('${AppConfig.baseUrl}/cities/available-dates').replace(
        queryParameters: {
          'from_city': fromCityId.toString(),
          'to_city': toCityId.toString(),
        },
      );
      
      final response = await http.get(uri, headers: await _headers());

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((date) => date.toString()).toList();
      } else {
        debugPrint('Помилка сервера при отриманні дат: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      debugPrint('Помилка мережі (getAvailableDates): $e');
      return [];
    }
  }


} 