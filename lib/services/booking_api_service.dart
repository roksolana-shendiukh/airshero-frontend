import 'dart:convert';
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
    DateTime? returnDate,
    required int adults,
    int children = 0,
    int infants = 0,
  }) async {
    final params = {
      'from': fromCity,
      'to': toCity,
      'departDate':
          '${departDate.year}-${departDate.month.toString().padLeft(2, '0')}-${departDate.day.toString().padLeft(2, '0')}',
      'adults': adults.toString(),
      'children': children.toString(),
      'infants': infants.toString(),
      if (returnDate != null)
        'returnDate':
            '${returnDate.year}-${returnDate.month.toString().padLeft(2, '0')}-${returnDate.day.toString().padLeft(2, '0')}',
    };

    final uri = Uri.parse('${AppConfig.baseUrl}/bookings/search')
        .replace(queryParameters: params);

    final response = await http.get(uri, headers: await _headers());

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = jsonDecode(response.body);
      final List<dynamic> flights = data['flights'];
      return flights
          .map((e) => FlightModel.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    throw Exception('Failed to search flights: ${response.statusCode}');
  }
}