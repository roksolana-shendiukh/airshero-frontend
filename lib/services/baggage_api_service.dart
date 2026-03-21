import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';
import '../models/baggage_models.dart';
import '../services/auth_service.dart';

class BaggageApiService {
  final AuthService _authService;

  BaggageApiService(this._authService);

  Future<Map<String, String>> _headers() async {
    final token = await _authService.getToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  Future<List<BaggagePricingInFlight>> getBaggageOptions({
    required int flightClassId,
  }) async {
    try {
      final uri = Uri.parse('${AppConfig.baseUrl}/baggage/options').replace(
        queryParameters: {
          'flight_class_id': flightClassId.toString(),
        },
      );

      final response = await http.get(uri, headers: await _headers());

      if (response.statusCode == 200) {
        debugPrint('BAGGAGE OPTIONS: ${response.body}');
        final List<dynamic> data = jsonDecode(response.body);
        return data
            .map((e) => BaggagePricingInFlight.fromJson(e as Map<String, dynamic>))
            .toList();
      } else {
        debugPrint('Baggage options error: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      debugPrint('Network error (getBaggageOptions): $e');
      rethrow;
    }
  }
}
