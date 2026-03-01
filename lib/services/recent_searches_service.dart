import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class RecentSearchesService {
  static const _citiesKey = 'recent_cities';
  static const _routesKey = 'recent_routes';
  static const _lastSearchKey = 'last_search';

  Future<List<String>> loadCities() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_citiesKey);
    if (raw == null) return [];
    return List<String>.from(jsonDecode(raw));
  }

  Future<void> _saveCity(String city) async {
    final cities = await loadCities();
    cities.removeWhere((c) => c.toLowerCase() == city.toLowerCase());
    cities.insert(0, city);
    final trimmed = cities.take(5).toList();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_citiesKey, jsonEncode(trimmed));
  }

  Future<List<Map<String, String>>> loadRoutes() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_routesKey);
    if (raw == null) return [];
    final List<dynamic> list = jsonDecode(raw);
    return list.map((e) => Map<String, String>.from(e)).toList();
  }

  Future<void> _saveRoute(String from, String to) async {
    final routes = await loadRoutes();
    routes.removeWhere((r) => r['from'] == from && r['to'] == to);
    routes.insert(0, {'from': from, 'to': to});
    final trimmed = routes.take(5).toList();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_routesKey, jsonEncode(trimmed));
  }

  Future<void> add(String from, String to) async {
    await _saveCity(from);
    await _saveCity(to);
    await _saveRoute(from, to);
  }

  Future<List<Map<String, String>>> load() async => loadRoutes();

  Future<void> saveLastSearch({
    required int fromCityId,
    required String fromCity,
    required int toCityId,
    required String toCity,
    required DateTime departDate,
    DateTime? returnDate,
    required Map<String, int> passengers,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final data = {
      'fromCityId': fromCityId,
      'fromCity': fromCity,
      'toCityId': toCityId,
      'toCity': toCity,
      'departDate': departDate.toIso8601String(),
      if (returnDate != null) 'returnDate': returnDate.toIso8601String(),
      'adults': passengers['adults'] ?? 1,
      'children': passengers['children'] ?? 0,
      'infants': passengers['infants'] ?? 0,
    };
    await prefs.setString(_lastSearchKey, jsonEncode(data));
  }

  Future<Map<String, dynamic>?> loadLastSearch() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_lastSearchKey);
    if (raw == null) return null;
    return jsonDecode(raw) as Map<String, dynamic>;
  }
  
  Future<void> clearLastSearch() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_lastSearchKey);
  }
}