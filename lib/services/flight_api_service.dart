import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';
import '../models/city_model.dart';
import '../models/flight_model.dart';
import '../models/flight_alternatives_model.dart';
import '../services/auth_service.dart';

class FlightApiService {
  final AuthService _authService;

  FlightApiService(this._authService);

  Future<Map<String, String>> _headers() async {
    final token = await _authService.getToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  Future<List<FlightModel>> searchFlights({
    required int fromCityId,
    required int toCityId,
    required DateTime departDate,
  }) async {
    try {
      final dateStr = departDate.toIso8601String().split('T')[0];
      debugPrint('searchFlights called with: fromCityId=$fromCityId, toCityId=$toCityId, departDate=$dateStr');

      final uri = Uri.parse('${AppConfig.baseUrl}/flights/search').replace(
        queryParameters: {
          'from_city':   fromCityId.toString(),
          'to_city':     toCityId.toString(),
          'depart_date': dateStr,
        },
      );
      final response = await http.get(uri, headers: await _headers());
      debugPrint('Response body (raw): ${response.body}');
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => FlightModel.fromJson(json)).toList();
      }
      return [];
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

  Future<FlightAlternatives> getAlternatives(int fromCityId, int toCityId) async {
    final uri = Uri.parse('${AppConfig.baseUrl}/alternatives').replace(
      queryParameters: {
        'from_city': fromCityId.toString(),
        'to_city':   toCityId.toString(),
      },
    );
    final response = await http.get(uri, headers: await _headers());
    if (response.statusCode == 200) {
      final Map<String, dynamic> data = jsonDecode(response.body);
      return FlightAlternatives.fromJson(data);
    }
    throw Exception('Failed to load alternatives');
  }

  Future<List<FlightModel>> filterFlights({
    required List<int> flightIds,
    List<String>? classNames,
    double? minPrice,
    double? maxPrice,
    List<String>? airlineNames,
    String sortBy = 'price_asc',
    List<String>? departureSlots,
  }) async {
    try {
      final uri = Uri.parse('${AppConfig.baseUrl}/flights/filter');

      final Map<String, dynamic> body = {
        'flight_ids': flightIds,
        'sort_by':    sortBy,
      };
      if (classNames != null && classNames.isNotEmpty)     body['class_names']     = classNames;
      if (minPrice != null)                                body['min_price']        = minPrice;
      if (maxPrice != null)                                body['max_price']        = maxPrice;
      if (airlineNames != null && airlineNames.isNotEmpty) body['airline_names']   = airlineNames;
      if (departureSlots != null && departureSlots.isNotEmpty) body['departure_slots'] = departureSlots;

      debugPrint('filterFlights body: ${jsonEncode(body)}');

      final response = await http.post(
        uri,
        headers: await _headers(),
        body: jsonEncode(body),
      );

      debugPrint('filterFlights response: ${response.statusCode} ${response.body}');

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => FlightModel.fromJson(json as Map<String, dynamic>)).toList();
      }
      return [];
    } catch (e) {
      debugPrint('Network error (filterFlights): $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getFlightAvailability(int flightId) async {
    try {
      final uri = Uri.parse('${AppConfig.baseUrl}/flights/$flightId/availability');
      final response = await http.get(uri, headers: await _headers());
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((e) => Map<String, dynamic>.from(e)).toList();
      }
      return [];
    } catch (e) {
      debugPrint('Network error (getFlightAvailability): $e');
      return [];
    }
  }

  Future<Map<int, List<Map<String, dynamic>>>> getFlightsAvailability(
      List<int> flightIds) async {
    try {
      final uri = Uri.parse('${AppConfig.baseUrl}/flights/availability');
      final response = await http.post(
        uri,
        headers: await _headers(),
        body: jsonEncode(flightIds),
      );
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        return data.map((key, value) => MapEntry(
              int.parse(key),
              (value as List).map((e) => Map<String, dynamic>.from(e)).toList(),
            ));
      }
      return {};
    } catch (e) {
      debugPrint('Network error (getFlightsAvailability): $e');
      return {};
    }
  }
}