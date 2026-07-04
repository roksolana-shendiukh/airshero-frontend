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
    required String mode,
    required DateTime date,
    required int month,
    required int year,
    String? flightNumber,
  }) async {
    try {
      final params = {
        'mode': mode,
        'date': '${date.year}-${date.month.toString().padLeft(2,'0')}-${date.day.toString().padLeft(2,'0')}',
        'month': month.toString(),
        'year': year.toString(),
        if (flightNumber != null && flightNumber.isNotEmpty)
          'flight_number': flightNumber,
      };

      final uri =
          Uri.parse('${AppConfig.baseUrl}/planning/overview/flights')
              .replace(queryParameters: params);
      debugPrint('URL: $uri');
      final response = await http.get(uri, headers: await _headers());
      
      if (response.statusCode == 200) {
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
      final uri = Uri.parse('${AppConfig.baseUrl}/planning/airfleet/$airfleetId/seat-layout');
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
      'flight_schedule_id': flightScheduleId,
      'departs_datetime':   departsDatetime,
      'arrives_datetime':   arrivesDatetime,
      'class_prices':       classPrices,
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
      body: jsonEncode({'baggage_options': options}),  
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

  Future<List<Map<String, dynamic>>> getAirfleets() async {
    final uri = Uri.parse('${AppConfig.baseUrl}/planning/airfleets');
    final response = await http.get(uri, headers: await _headers());
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.cast<Map<String, dynamic>>();
    }
    throw Exception('Failed to load airfleets: ${response.statusCode}');
  }

  Future<List<Map<String, dynamic>>> getAirports() async {
    final uri = Uri.parse('${AppConfig.baseUrl}/planning/airports');
    final response = await http.get(uri, headers: await _headers());
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.cast<Map<String, dynamic>>();
    }
    throw Exception('Failed to load airports: ${response.statusCode}');
  }

  Future<Map<String, dynamic>> createRoute({
    required int airfleetId,
    required int departsAirportId,
    required int arrivesAirportId,
    required String flightStartDate,
    required String flightEndDate,
    required List<Map<String, dynamic>> scheduleGroups,
  }) async {
    final uri = Uri.parse('${AppConfig.baseUrl}/planning/routes');
    final response = await http.post(
      uri,
      headers: await _headers(),
      body: jsonEncode({
        'airfleet_id':         airfleetId,
        'departs_airport_id':  departsAirportId,
        'arrives_airport_id':  arrivesAirportId,
        'flight_start_date':   flightStartDate,
        'flight_end_date':     flightEndDate,
        'schedule_groups':     scheduleGroups,
      }),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    final body = jsonDecode(response.body);
    throw Exception(body['detail'] ?? 'Failed to create route');
  }

  Future<Map<String, dynamic>> addScheduleToRoute({
    required int routeId,
    required String flightStartDate,
    required String flightEndDate,
    required List<Map<String, dynamic>> scheduleGroups,
  }) async {
    final uri = Uri.parse(
        '${AppConfig.baseUrl}/planning/routes/$routeId/schedules');
    final response = await http.post(
      uri,
      headers: await _headers(),
      body: jsonEncode({
        'flight_start_date': flightStartDate,
        'flight_end_date':   flightEndDate,
        'schedule_groups':   scheduleGroups,
      }),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    final body = jsonDecode(response.body);
    throw Exception(body['detail'] ?? 'Failed to add schedule');
  }

  Future<String> generateFlightNumber() async {
    final uri = Uri.parse('${AppConfig.baseUrl}/planning/routes/generate-flight-number');
    final response = await http.get(uri, headers: await _headers());
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return data['flight_number'] as String;
    }
    throw Exception('Failed to generate flight number');
  }

  Future<List<String>> getAirfleetPhotos(int airfleetId) async {
    try {
      final uri = Uri.parse('${AppConfig.baseUrl}/airfleets/$airfleetId/photos');
      final response = await http.get(uri, headers: await _headers());
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.cast<String>();
      }
      return [];
    } catch (e) {
      debugPrint('Network error (getAirfleetPhotos): $e');
      return [];
    }
  }

  Future<List<String>> getAllFlightNumbers() async {
    final uri = Uri.parse('${AppConfig.baseUrl}/planning/routes/flight-numbers');
    final response = await http.get(uri, headers: await _headers());
    if (response.statusCode == 200) {
      return List<String>.from(jsonDecode(response.body));
    }
    return [];
  }

  Future<Duration?> getRouteDuration({
    required int airfleetId,
    required int departsAirportId,
    required int arrivesAirportId,
  }) async {
    try {
      final uri = Uri.parse('${AppConfig.baseUrl}/planning/routes/duration')
          .replace(queryParameters: {
        'airfleet_id': airfleetId.toString(),
        'departs_airport_id': departsAirportId.toString(),
        'arrives_airport_id': arrivesAirportId.toString(),
      });
      final response = await http.get(uri, headers: await _headers());
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final duration = data['duration'] as String; // "HH:MM:SS"
        final parts = duration.split(':');
        return Duration(
          hours: int.parse(parts[0]),
          minutes: int.parse(parts[1]),
        );
      }
      return null;
    } catch (e) {
      debugPrint('Network error (getRouteDuration): $e');
      return null;
    }
  }

  Future<List<Map<String, dynamic>>> getRoutesWithPlannedFlights() async {
    final uri = Uri.parse(
        '${AppConfig.baseUrl}/planning/setup/routes');
    final response = await http.get(uri, headers: await _headers());
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.cast<Map<String, dynamic>>();
    }
    throw Exception('Failed to load routes: ${response.statusCode}');
  }

  Future<List<Map<String, dynamic>>> getPlannedFlightsForRoute(
      int routeId) async {
    final uri = Uri.parse(
        '${AppConfig.baseUrl}/planning/setup/routes/$routeId/flights');
    final response = await http.get(uri, headers: await _headers());
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.cast<Map<String, dynamic>>();
    }
    throw Exception('Failed to load flights: ${response.statusCode}');
  }

  Future<void> configureFlight({
    required int flightId,
    required List<Map<String, dynamic>> classPrices,
  }) async {
    final uri = Uri.parse(
        '${AppConfig.baseUrl}/planning/flights/$flightId/configure');
    final response = await http.post(
      uri,
      headers: await _headers(),
      body: jsonEncode({'class_prices': classPrices}),
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to configure flight: ${response.body}');
    }
  }

  Future<List<Map<String, dynamic>>> getFlightsForPricing() async {
    final uri = Uri.parse('${AppConfig.baseUrl}/planning/pricing/flights');
    final response = await http.get(uri, headers: await _headers());
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.cast<Map<String, dynamic>>();
    }
    throw Exception('Failed to load flights: ${response.statusCode}');
  }

  Future<List<Map<String, dynamic>>> getFlightPriceHistory(
      int flightId) async {
    final uri = Uri.parse(
        '${AppConfig.baseUrl}/planning/pricing/flights/$flightId/history');
    final response = await http.get(uri, headers: await _headers());
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.cast<Map<String, dynamic>>();
    }
    throw Exception('Failed to load price history: ${response.statusCode}');
  }

  Future<void> updateFlightPrices({
    required int flightId,
    required List<Map<String, dynamic>> classPrices,
  }) async {
    final uri = Uri.parse(
        '${AppConfig.baseUrl}/planning/pricing/flights/$flightId/prices');
    final response = await http.post(
      uri,
      headers: await _headers(),
      body: jsonEncode({'class_prices': classPrices}),
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to update prices: ${response.body}');
    }
  }

  Future<List<Map<String, dynamic>>> getRoutesWithPricingFlights() async {
    final uri = Uri.parse(
        '${AppConfig.baseUrl}/planning/pricing/routes');
    final response = await http.get(uri, headers: await _headers());
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.cast<Map<String, dynamic>>();
    }
    throw Exception('Failed to load routes: ${response.statusCode}');
  }

  Future<List<Map<String, dynamic>>> getPricingFlightsForRoute(
      int routeId) async {
    final uri = Uri.parse(
        '${AppConfig.baseUrl}/planning/pricing/routes/$routeId/flights');
    final response = await http.get(uri, headers: await _headers());
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.cast<Map<String, dynamic>>();
    }
    throw Exception('Failed to load flights: ${response.statusCode}');
  }

  Future<List<Map<String, dynamic>>> getAllFlightsForRoute(int routeId) async {
    final uri = Uri.parse(
        '${AppConfig.baseUrl}/planning/setup/routes/$routeId/all-flights');
    final response = await http.get(uri, headers: await _headers());
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.cast<Map<String, dynamic>>();
    }
    throw Exception('Failed to load flights: ${response.statusCode}');
  }

  Future<void> confirmFlights(List<int> flightIds) async {
    final uri = Uri.parse(
        '${AppConfig.baseUrl}/planning/setup/flights/confirm');
    final response = await http.post(
      uri,
      headers: await _headers(),
      body: jsonEncode({'flight_ids': flightIds}),
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to confirm flights: ${response.body}');
    }
  }

  Future<void> updateFlightClasses({
    required int flightId,
    required List<int> classIds,
  }) async {
    final uri = Uri.parse(
        '${AppConfig.baseUrl}/planning/setup/flights/$flightId/classes');
    final response = await http.post(
      uri,
      headers: await _headers(),
      body: jsonEncode({'flight_ids': classIds}),
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to update classes: ${response.body}');
    }
  }

  Future<void> cancelFlight(int flightId) async {
    final uri = Uri.parse(
        '${AppConfig.baseUrl}/planning/flights/$flightId/cancel');
    
    final response = await http.post(
      uri,
      headers: await _headers(),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to cancel flight: ${response.body}');
    }
  }

  Future<void> updateFlightTimes({
    required int flightId,
    required DateTime departsDatetime,
    required DateTime arrivesDatetime,
  }) async {
    final uri = Uri.parse(
        '${AppConfig.baseUrl}/planning/flights/$flightId/times');
    
    final response = await http.put(
      uri,
      headers: await _headers(),
      body: jsonEncode({
        'departs_datetime': departsDatetime.toIso8601String(),
        'arrives_datetime': arrivesDatetime.toIso8601String(),
      }),
    );

    // if (response.statusCode != 200) {
    //   throw Exception('Failed to update flight times');
    // }
  }

}

