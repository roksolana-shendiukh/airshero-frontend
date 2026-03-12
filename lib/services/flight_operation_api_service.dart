import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';
import '../services/auth_service.dart';
import '../models/route_model.dart';

class AirportModel {
  final int airportId;
  final String airportName;
  final String airportCode;
  final String? airportAddress;
  final double latitude;
  final double longitude;

  const AirportModel({
    required this.airportId,
    required this.airportName,
    required this.airportCode,
    this.airportAddress,
    required this.latitude,
    required this.longitude,
  });

  factory AirportModel.fromJson(Map<String, dynamic> json) => AirportModel(
        airportId:      json['airportId'] as int,
        airportName:    json['airportName'] as String,
        airportCode:    json['airportCode'] as String,
        airportAddress: json['airportAddress'] as String?,
        latitude:       (json['latitude'] as num).toDouble(),
        longitude:      (json['longitude'] as num).toDouble(),
      );
}

class FlightOperationApiService {
  final AuthService authService;

  FlightOperationApiService(this.authService);

  Future<Map<String, String>> _headers() async {
    final token = await authService.getToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  Future<List<AirportModel>> getAirports() async {
    try {
      final response = await http.get(
        Uri.parse('${AppConfig.baseUrl}/airports'),
        headers: await _headers(),
      );
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((e) => AirportModel.fromJson(e)).toList();
      }
      return [];
    } catch (e) {
      debugPrint('Network error (getAirports): $e');
      return [];
    }
  }

  Future<List<RouteModel>> getRoutes() async {
    try {
      final response = await http.get(
        Uri.parse('${AppConfig.baseUrl}/routes'),
        headers: await _headers(),
      );
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((e) => RouteModel.fromJson(e)).toList();
      }
      return [];
    } catch (e) {
      debugPrint('Network error (getRoutes): $e');
      return [];
    }
  }
}