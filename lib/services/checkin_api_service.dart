import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';
import '../services/auth_service.dart';

class CheckInApiService {
  final AuthService _authService;

  CheckInApiService(this._authService);

  Future<Map<String, String>> _headers() async {
    final token = await _authService.getToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  Future<List<Map<String, dynamic>>> searchBooking({
    required String documentNumber,
    required String flightNumber,
    required DateTime departsDate,
  }) async {
    try {
      final uri = Uri.parse('${AppConfig.baseUrl}/checkin/booking').replace(
        queryParameters: {
          'document_number': documentNumber,
          'flight_number':   flightNumber,
          'departs_date':    departsDate.toIso8601String().split('T')[0],
        },
      );

      final response = await http.get(uri, headers: await _headers());

      if (response.statusCode == 200) {
        debugPrint('CHECKIN BOOKING: ${response.body}');
        final List<dynamic> data = jsonDecode(response.body);
        return data.cast<Map<String, dynamic>>();
      } else if (response.statusCode == 404) {
        return [];
      } else {
        debugPrint('CheckIn booking error: ${response.statusCode} ${response.body}');
        return [];
      }
    } catch (e) {
      debugPrint('Network error (searchBooking): $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getSeatMap(int flightOperationId) async {
    try {
      final uri = Uri.parse(
        '${AppConfig.baseUrl}/checkin/seat-map/$flightOperationId',
      );
      final response = await http.get(uri, headers: await _headers());

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else {
        debugPrint('SeatMap error: ${response.statusCode} ${response.body}');
        return {};
      }
    } catch (e) {
      debugPrint('Network error (getSeatMap): $e');
      rethrow;
    }
  }
  
  Future<List<Map<String, dynamic>>> getActiveFlights() async {
    try {
      final uri = Uri.parse('${AppConfig.baseUrl}/checkin/active-flights');
      final response = await http.get(uri, headers: await _headers());

      if (response.statusCode == 200) {
        debugPrint('ACTIVE FLIGHTS: ${response.body}');
        final List<dynamic> data = jsonDecode(response.body);
        return data.cast<Map<String, dynamic>>();
      } else {
        debugPrint('Active flights error: ${response.statusCode} ${response.body}');
        return [];
      }
    } catch (e) {
      debugPrint('Network error (getActiveFlights): $e');
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getFlightPassengerSuggestions({
    required String query,
    required String flightNumber,
    required DateTime departsDate,
  }) async {
    final uri = Uri.parse('${AppConfig.baseUrl}/checkin/flight-passengers/suggestions').replace(
      queryParameters: {
        'q': query,
        'flight_number': flightNumber,
        'departs_date': departsDate.toIso8601String().split('T')[0],
      },
    );

    final response = await http.get(uri, headers: await _headers());
    if (response.statusCode == 200) {
      return List<Map<String, dynamic>>.from(jsonDecode(response.body));
    }
    return [];
  }

  Future<Map<String, dynamic>> getBaggageInfo(int bookingItemId) async {
    final uri = Uri.parse(
        '${AppConfig.baseUrl}/checkin/baggage-info/$bookingItemId');
    final response = await http.get(uri, headers: await _headers());
    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    throw Exception('Failed to load baggage info');
  }

  Future<List<Map<String, dynamic>>> getBaggageTypes() async {
    final uri = Uri.parse('${AppConfig.baseUrl}/checkin/baggage-types');
    final response = await http.get(uri, headers: await _headers());
    if (response.statusCode == 200) {
      return List<Map<String, dynamic>>.from(jsonDecode(response.body));
    }
    return [];
  }

  Future<Map<String, dynamic>> calculateBaggageSurcharge({
    required int bookingItemId,
    required List<double> bagWeights,
  }) async {
    try {
      final uri = Uri.parse(
        '${AppConfig.baseUrl}/checkin/baggage/$bookingItemId/calculate',
      );

      final response = await http.post(
        uri,
        headers: await _headers(),
        body: jsonEncode({
          'bagWeights': bagWeights,
        }),
      );

      if (response.statusCode == 200) {
        debugPrint('BAGGAGE CALCULATION RESULT: ${response.body}');
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else {
        debugPrint('Baggage calculation error: ${response.statusCode} ${response.body}');
        throw Exception('Failed to calculate baggage: ${response.body}');
      }
    } catch (e) {
      debugPrint('Network error (calculateBaggageSurcharge): $e');
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getPaymentMethods() async {
    final uri = Uri.parse('${AppConfig.baseUrl}/checkin/payment-methods');
    final response = await http.get(uri, headers: await _headers());
    if (response.statusCode == 200) {
      return List<Map<String, dynamic>>.from(jsonDecode(response.body));
    }
    return [];
  }

  Future<Map<String, dynamic>> issueWithBaggage({
    required int bookingItemId,
    required int seatLayoutId,
    required int flightOperationId,
    required List<Map<String, dynamic>> bags,
    int? paymentMethodId,
    double totalSurcharge = 0.0,
    required String status,
  }) async {
    final uri = Uri.parse(
      '${AppConfig.baseUrl}/checkin/issue-with-baggage',
    ).replace(queryParameters: {'flight_operation_id': flightOperationId.toString()});

    final response = await http.post(
      uri,
      headers: await _headers(),
      body: jsonEncode({
        'booking_item_id':   bookingItemId,
        'seat_layout_id':    seatLayoutId,
        'bags':              bags,
        'payment_method_id': paymentMethodId,
        'total_surcharge':   totalSurcharge,
        'status':            status,
      }),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    throw Exception('Failed to issue boarding pass: ${response.body}');
  }

  Future<Map<String, dynamic>> checkAlreadyCheckedIn(int bookingItemId) async {
    final uri = Uri.parse('${AppConfig.baseUrl}/checkin/check-already-checked-in/$bookingItemId');
    final response = await http.get(uri, headers: await _headers());
    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    return {'alreadyCheckedIn': false};
  }

  Future<Map<String, dynamic>> getCheckedBaggageWeight(int flightOperationId) async {
    final uri = Uri.parse(
      '${AppConfig.baseUrl}/checkin/checked-baggage-weight/$flightOperationId',
    );
    final response = await http.get(uri, headers: await _headers());
    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    return {'totalCheckedWeightKg': 0.0};
  }

}