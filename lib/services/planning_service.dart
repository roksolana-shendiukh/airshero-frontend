import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';
import '../services/auth_service.dart';
import '../models/planning_overview_model.dart';

class PlanningService {
  final AuthService _authService;

  PlanningService(this._authService);

  Future<Map<String, String>> _headers() async {
    final token = await _authService.getToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  Future<PlanningOverviewStats> getOverviewStats() async {
    final uri = Uri.parse('${AppConfig.baseUrl}/planning/overview/stats');
    final response = await http.get(uri, headers: await _headers());
    if (response.statusCode == 200) {
      return PlanningOverviewStats.fromJson(
        jsonDecode(response.body) as Map<String, dynamic>,
      );
    }
    throw Exception('Stats error: ${response.statusCode} ${response.body}');
  }

  Future<List<OverviewFlight>> getOverviewFlights({
    String mode = 'day',
    DateTime? date,
    int? month,
    int? year,
  }) async {
    try {
      final params = <String, String>{'mode': mode};
      if (mode == 'day' && date != null) {
        params['date'] = date.toIso8601String().split('T')[0];
      } else if (mode == 'month') {
        final now = date ?? DateTime.now();
        params['month'] = (month ?? now.month).toString();
        params['year'] = (year ?? now.year).toString();
      }

      final uri =
          Uri.parse('${AppConfig.baseUrl}/planning/overview/flights')
              .replace(queryParameters: params);

      final response = await http.get(uri, headers: await _headers());
      if (response.statusCode == 200) {
        debugPrint('FLIGHTS RAW: ${response.body.substring(0, response.body.length.clamp(0, 500))}');
        final List<dynamic> data = jsonDecode(response.body);
        return data
            .cast<Map<String, dynamic>>()
            .map(OverviewFlight.fromJson)
            .toList();
      }
      throw Exception('Flights error: ${response.statusCode} ${response.body}');
    } catch (e) {
      debugPrint('Network error (getOverviewFlights): $e');
      rethrow;
    }
  }

  Future<List<String>> getAvailableDates() async {
    try {
      final uri = Uri.parse(
          '${AppConfig.baseUrl}/planning/overview/available-dates');
      final response = await http.get(uri, headers: await _headers());
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.cast<String>();
      }
      debugPrint('Available dates error: ${response.statusCode} ${response.body}');
      return [];
    } catch (e) {
      debugPrint('Network error (getAvailableDates): $e');
      return [];
    }
  }

  Future<List<String>> getAvailableMonths() async {
    try {
      final uri = Uri.parse(
          '${AppConfig.baseUrl}/planning/overview/available-months');
      final response = await http.get(uri, headers: await _headers());
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.cast<String>();
      }
      return [];
    } catch (e) {
      debugPrint('Network error (getAvailableMonths): $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getRoutes() async {
    final uri = Uri.parse('${AppConfig.baseUrl}/planning/routes');
    final response = await http.get(uri, headers: await _headers());
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.cast<Map<String, dynamic>>();
    }
    throw Exception('Failed to load routes: ${response.statusCode}');
  }

  Future<List<Map<String, dynamic>>> getRouteSchedules(int routeId) async {
    final uri = Uri.parse(
        '${AppConfig.baseUrl}/planning/routes/$routeId/schedules');
    final response = await http.get(uri, headers: await _headers());
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.cast<Map<String, dynamic>>();
    }
    throw Exception('Failed to load schedules: ${response.statusCode}');
  }

  Future<List<Map<String, dynamic>>> getSeatLayout(int airfleetId) async {
    try {
      final uri = Uri.parse(
          '${AppConfig.baseUrl}/planning/seat-layout/$airfleetId');
      final response = await http.get(uri, headers: await _headers());
      if (response.statusCode == 200) {
        debugPrint('SEAT LAYOUT: ${response.body}');
        final List<dynamic> data = jsonDecode(response.body);
        return data.cast<Map<String, dynamic>>();
      }
      debugPrint('Seat layout error: ${response.statusCode} ${response.body}');
      return [];
    } catch (e) {
      debugPrint('Network error (getSeatLayout): $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> createFlight({
    required int flightScheduleId,
    required String departsDatetime,
    required String arrivesDatetime,
    required List<Map<String, dynamic>> classPrices, 
  }) async {
    final uri = Uri.parse('${AppConfig.baseUrl}/planning/flights');
    
    final response = await http.post(
      uri,
      headers: await _headers(),
      body: jsonEncode({
        'flightScheduleId': flightScheduleId,
        'departsDatetime': departsDatetime,
        'arrivesDatetime': arrivesDatetime,
        'classPrices': classPrices,
      }),
    );
    
    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    throw Exception('Failed to create flight: ${response.body}');
  }

  Future<List<Map<String, dynamic>>> getBaggageRules() async {
    final uri = Uri.parse('${AppConfig.baseUrl}/planning/baggage-rules');
    final response = await http.get(uri, headers: await _headers());
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.cast<Map<String, dynamic>>();
    }
    throw Exception('Failed to load baggage rules: ${response.statusCode}');
  }

  Future<Map<String, dynamic>> addBaggageToFlight({
    required int flightId,
    required List<Map<String, dynamic>> options,
  }) async {
    final uri = Uri.parse('${AppConfig.baseUrl}/planning/flights/$flightId/baggage');
    final response = await http.post(
      uri,
      headers: await _headers(),
      body: jsonEncode({'baggageOptions': options}),  
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    throw Exception('Failed to add baggage: ${response.body}');
  }

  Future<List<String>> getBookedDatesForSchedule(int flightScheduleId) async {
    try {
      final uri = Uri.parse(
          '${AppConfig.baseUrl}/planning/schedules/$flightScheduleId/booked-dates');
      final response = await http.get(uri, headers: await _headers());
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.cast<String>();
      }
      return [];
    } catch (e) {
      debugPrint('Network error (getBookedDatesForSchedule): $e');
      return [];
    }
  }

}