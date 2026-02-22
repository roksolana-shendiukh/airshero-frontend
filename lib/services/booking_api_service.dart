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
    required String fromCity,
    required String toCity,
    required DateTime departDate,
  }) async {
    final String formattedDate =
        "${departDate.year}-${departDate.month.toString().padLeft(2, '0')}-${departDate.day.toString().padLeft(2, '0')}";

    final uri = Uri.parse('${AppConfig.baseUrl}/flights/search').replace(
      queryParameters: {
        'from_city': fromCity,
        'to_city': toCity,
        'depart_date': formattedDate,
      },
    );

    final response = await http.get(uri, headers: await _headers());

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((json) => FlightModel.fromJson(json as Map<String, dynamic>)).toList();
    } 
    
    if (response.statusCode == 404) {
      return [];
    }

    throw Exception('Server error: ${response.statusCode}');
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