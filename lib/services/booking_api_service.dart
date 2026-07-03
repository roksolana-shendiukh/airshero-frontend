import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';
import '../models/city_model.dart';
import '../models/flight_model.dart';
import '../services/auth_service.dart';
import '../models/flight_alternatives_model.dart';

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
      return data.map((e) => CityModel.fromJson(e as Map<String, dynamic>)).toList();
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
      debugPrint('searchFlights called with: fromCityId=$fromCityId, toCityId=$toCityId, departDate=$dateStr');

      final uri = Uri.parse('${AppConfig.baseUrl}/flights/search').replace(
        queryParameters: {
          'from_city': fromCityId.toString(),
          'to_city': toCityId.toString(),
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
        'to_city': toCityId.toString(),
      },
    );

    final response = await http.get(uri, headers: await _headers());

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = json.decode(response.body);
      return FlightAlternatives.fromJson(data);
    } else {
      throw Exception('Failed to load alternatives');
    }
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
      }
      return [];
    } catch (e) {
      debugPrint('Network error (getAvailableDates): $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getPaymentMethods() async {
    final uri = Uri.parse('${AppConfig.baseUrl}/payment-methods');
    final response = await http.get(uri, headers: await _headers());
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    }
    throw Exception('Failed to load payment methods: ${response.statusCode}');
  }

  Future<Map<String, dynamic>> createBooking(Map<String, dynamic> body) async {
    final uri = Uri.parse('${AppConfig.baseUrl}/bookings');
    final response = await http.post(uri, headers: await _headers(), body: jsonEncode(body));
    if (response.statusCode == 201) {
      return Map<String, dynamic>.from(jsonDecode(response.body) as Map);
    }
    final error = jsonDecode(response.body);
    throw Exception((error['detail'] ?? 'Failed to create booking').toString());
  }

  Future<void> processPayment({
    required int bookingId,
    required int paymentMethodId,
    required String status,
    required double amount,
    String? email,
  }) async {
    final uri = Uri.parse('${AppConfig.baseUrl}/bookings/$bookingId/payment');
    final response = await http.post(
      uri,
      headers: await _headers(),
      body: jsonEncode({
        'payment_method_id': paymentMethodId,
        'status': status,
        'amount': amount,
        if (email != null) 'email': email,
      }),
    );
    if (response.statusCode != 200) {
      final error = jsonDecode(response.body);
      throw Exception((error['detail'] ?? 'Failed to process payment').toString());
    }
  }

  Future<String?> getPassengerEmail(int passengerId) async {
    final token = await _authService.getToken();
    final uri = Uri.parse('${AppConfig.baseUrl}/passengers/$passengerId'); 
    final response = await http.get(
      uri,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['email'] as String?;
    } else {
      debugPrint('Failed to fetch email for passenger $passengerId: ${response.statusCode}');
      return null;
    }
  }

  Future<Map<String, dynamic>> confirmPayment({
    required int bookingId,
    required Map<String, dynamic> data,
  }) async {
    final uri = Uri.parse('${AppConfig.baseUrl}/bookings/$bookingId/payment');
    final response = await http.post(
      uri,
      headers: await _headers(),
      body: jsonEncode(data),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }

    final error = jsonDecode(response.body);
    final detail = error['detail'] ?? 'payment_error';

    switch (detail) {
      case 'booking_expired':
        throw Exception('Your booking has expired. Please start a new search.');
      case 'booking_not_found':
        throw Exception('Booking not found. Please contact support.');
      default:
        throw Exception('Payment could not be processed. Please try again.');
    }
  }

  Future<List<Map<String, dynamic>>> getAdultPassengers(int bookingId) async {
    final uri = Uri.parse('${AppConfig.baseUrl}/bookings/$bookingId/adult-passengers');
    final response = await http.get(uri, headers: await _headers());
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    }
    throw Exception('Failed to load adult passengers: ${response.statusCode}');
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
        'sort_by': sortBy,
      };
      if (classNames != null && classNames.isNotEmpty) body['class_names'] = classNames;
      if (minPrice != null) body['min_price'] = minPrice;
      if (maxPrice != null) body['max_price'] = maxPrice;
      if (airlineNames != null && airlineNames.isNotEmpty) body['airline_names'] = airlineNames;
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

  Future<Map<String, dynamic>> createGroupBooking(Map<String, dynamic> body) async {
    final uri = Uri.parse('${AppConfig.baseUrl}/bookings/group');
    final response = await http.post(uri, headers: await _headers(), body: jsonEncode(body));
    if (response.statusCode == 201) {
      return Map<String, dynamic>.from(jsonDecode(response.body) as Map);
    }
    final error = jsonDecode(response.body);
    throw Exception((error['detail'] ?? 'Failed to create group booking').toString());
  }

  Future<List<String>> getLeg2AvailableDates({
    required int hubCityId,
    required int toCityId,
    required String leg1Date,
  }) async {
    try {
      final uri = Uri.parse('${AppConfig.baseUrl}/cities/available-dates/leg2').replace(
        queryParameters: {
          'hub_city': hubCityId.toString(),
          'to_city': toCityId.toString(),
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
        'hub_city': hubCityId.toString(),
        'to_city': toCityId.toString(),
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
      'hub_city': hubCityId.toString(),
      'to_city': toCityId.toString(),
    });
    final response = await http.get(uri, headers: await _headers());
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((e) => e.toString()).toList();
    }
    return [];
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

  Future<Map<String, dynamic>> reserveBooking(Map<String, dynamic> body) async {
    try {
      final uri = Uri.parse('${AppConfig.baseUrl}/bookings/reserve');
      final response = await http.post(
        uri,
        headers: await _headers(),
        body: jsonEncode(body),
      );
      if (response.statusCode == 201) {
        return jsonDecode(response.body);
      }
      throw Exception(jsonDecode(response.body)['detail'] ?? 'Reservation failed');
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> reserveGroupBooking(Map<String, dynamic> body) async {
    try {
      final uri = Uri.parse('${AppConfig.baseUrl}/bookings/reserve/group');
      final response = await http.post(
        uri,
        headers: await _headers(),
        body: jsonEncode(body),
      );
      if (response.statusCode == 201) {
        return jsonDecode(response.body);
      }
      throw Exception(jsonDecode(response.body)['detail'] ?? 'Group reservation failed');
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updateBookingPassengers(int bookingId, Map<String, dynamic> body) async {
    try {
      final uri = Uri.parse('${AppConfig.baseUrl}/bookings/$bookingId/passengers');
      final response = await http.patch(
        uri,
        headers: await _headers(),
        body: jsonEncode(body),
      );
      if (response.statusCode != 200) {
        throw Exception(jsonDecode(response.body)['detail'] ?? 'Update failed');
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getBookings({
    int skip = 0,
    int limit = 50,
    String? status,
    String? dateFilter = 'this_month',
  }) async {
    try {
      final params = {
        'skip': skip.toString(),
        'limit': limit.toString(),
        if (status != null) 'status': status,
        if (dateFilter != null) 'date_filter': dateFilter,
      };
      final uri = Uri.parse('${AppConfig.baseUrl}/bookings')
          .replace(queryParameters: params);
      final response = await http.get(uri, headers: await _headers());
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((e) => Map<String, dynamic>.from(e as Map)).toList();
      }
      return [];
    } catch (e) {
      debugPrint('Network error (getBookings): $e');
      return [];
    }
  }

  Future<void> cancelBooking(int bookingId) async {
    final uri = Uri.parse('${AppConfig.baseUrl}/bookings/$bookingId/cancel');
    final response = await http.post(uri, headers: await _headers());
    if (response.statusCode != 200) {
      final error = jsonDecode(response.body);
      throw Exception(error['detail'] ?? 'Failed to cancel booking');
    }
  }
  
}
