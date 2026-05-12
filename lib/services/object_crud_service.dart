import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';
import 'auth_service.dart';

class ApiValidationException implements Exception {
  final Map<String, String> fieldErrors;
  ApiValidationException(this.fieldErrors);
}

Map<String, String> _parsePydanticErrors(List detail) {
  final errors = <String, String>{};
  for (final err in detail) {
    final loc = err['loc'] as List?;
    final field = loc != null && loc.length > 1 ? loc.last.toString() : 'general';
    final msg = err['msg']?.toString() ?? 'Invalid value';
    errors[field] = msg;
  }
  return errors;
}

class ObjectCrudService {
  final AuthService _authService;
  
  final String _baseRoute = '${AppConfig.baseUrl}/crud/objects';

  ObjectCrudService(this._authService);

  Future<Map<String, String>> _headers() async {
    final token = await _authService.getToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  dynamic _handleResponse(http.Response response, String action) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) return null;
      return jsonDecode(response.body);
    } else if (response.statusCode == 422) {
      final body = jsonDecode(response.body);
      if (body['detail'] is List) {
        throw ApiValidationException(_parsePydanticErrors(body['detail']));
      }
      throw Exception('Validation error');
    } else {
      String message = 'Failed to $action: ${response.statusCode}';
      try {
        final body = jsonDecode(response.body);
        if (body['detail'] != null) {
          message = body['detail'].toString();
        }
      } catch (_) {}
      throw Exception(message);
    }
  }

  Future<List<Map<String, dynamic>>> getTerminalTypes() async {
    final response = await http.get(
      Uri.parse('$_baseRoute/terminal-types'),
      headers: await _headers(),
    );
    final data = _handleResponse(response, 'load terminal types');
    return (data as List).cast<Map<String, dynamic>>();
  }
  
  Future<List<Map<String, dynamic>>> getAirports() async {
    final response = await http.get(Uri.parse('$_baseRoute/airports'), headers: await _headers());
    final data = _handleResponse(response, 'load airports');
    return (data as List).cast<Map<String, dynamic>>();
  }

  Future<List<Map<String, dynamic>>> getCities() async {
    final response = await http.get(Uri.parse('$_baseRoute/cities'), headers: await _headers());
    final data = _handleResponse(response, 'load cities');
    return (data as List).cast<Map<String, dynamic>>();
  }

  Future<Map<String, dynamic>> createAirport(Map<String, dynamic> data) async {
    final response = await http.post(
      Uri.parse('$_baseRoute/airports'),
      headers: await _headers(),
      body: jsonEncode(data),
    );
    return _handleResponse(response, 'create airport') as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> updateAirport(int id, Map<String, dynamic> data) async {
    final response = await http.put(
      Uri.parse('$_baseRoute/airports/$id'),
      headers: await _headers(),
      body: jsonEncode(data),
    );
    return _handleResponse(response, 'update airport') as Map<String, dynamic>;
  }

  Future<void> deleteAirport(int id) async {
    final response = await http.delete(Uri.parse('$_baseRoute/airports/$id'), headers: await _headers());
    _handleResponse(response, 'delete airport');
  }


  Future<List<Map<String, dynamic>>> getTerminals(int airportId) async {
    final response = await http.get(Uri.parse('$_baseRoute/airports/$airportId/terminals'), headers: await _headers());
    final data = _handleResponse(response, 'load terminals');
    return (data as List).cast<Map<String, dynamic>>();
  }

  Future<Map<String, dynamic>> createTerminal(int airportId, Map<String, dynamic> data) async {
    final response = await http.post(
      Uri.parse('$_baseRoute/airports/$airportId/terminals'),
      headers: await _headers(),
      body: jsonEncode(data),
    );
    return _handleResponse(response, 'create terminal') as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> updateTerminal(int id, Map<String, dynamic> data) async {
    final response = await http.put(
      Uri.parse('$_baseRoute/terminals/$id'),
      headers: await _headers(),
      body: jsonEncode(data),
    );
    return _handleResponse(response, 'update terminal') as Map<String, dynamic>;
  }

  Future<void> deleteTerminal(int id) async {
    final response = await http.delete(Uri.parse('$_baseRoute/terminals/$id'), headers: await _headers());
    _handleResponse(response, 'delete terminal');
  }


  Future<List<Map<String, dynamic>>> getGates(int terminalId) async {
    final response = await http.get(Uri.parse('$_baseRoute/terminals/$terminalId/gates'), headers: await _headers());
    final data = _handleResponse(response, 'load gates');
    return (data as List).cast<Map<String, dynamic>>();
  }

  Future<Map<String, dynamic>> createGate(int terminalId, Map<String, dynamic> data) async {
    final response = await http.post(
      Uri.parse('$_baseRoute/terminals/$terminalId/gates'),
      headers: await _headers(),
      body: jsonEncode(data),
    );
    return _handleResponse(response, 'create gate') as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> updateGate(int id, Map<String, dynamic> data) async {
    final response = await http.put(
      Uri.parse('$_baseRoute/gates/$id'),
      headers: await _headers(),
      body: jsonEncode(data),
    );
    return _handleResponse(response, 'update gate') as Map<String, dynamic>;
  }

  Future<void> deleteGate(int id) async {
    final response = await http.delete(Uri.parse('$_baseRoute/gates/$id'), headers: await _headers());
    _handleResponse(response, 'delete gate');
  }


  Future<List<Map<String, dynamic>>> getAirlines() async {
    final response = await http.get(Uri.parse('$_baseRoute/airlines'), headers: await _headers());
    final data = _handleResponse(response, 'load airlines');
    return (data as List).cast<Map<String, dynamic>>();
  }

  Future<Map<String, dynamic>> createAirline(Map<String, dynamic> data) async {
    final response = await http.post(
      Uri.parse('$_baseRoute/airlines'),
      headers: await _headers(),
      body: jsonEncode(data),
    );
    return _handleResponse(response, 'create airline') as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> updateAirline(int id, Map<String, dynamic> data) async {
    final response = await http.put(
      Uri.parse('$_baseRoute/airlines/$id'),
      headers: await _headers(),
      body: jsonEncode(data),
    );
    return _handleResponse(response, 'update airline') as Map<String, dynamic>;
  }

  Future<void> deleteAirline(int id) async {
    final response = await http.delete(Uri.parse('$_baseRoute/airlines/$id'), headers: await _headers());
    _handleResponse(response, 'delete airline');
  }

  Future<List<Map<String, dynamic>>> getAirfleets() async {
    final response = await http.get(Uri.parse('$_baseRoute/airfleets'), headers: await _headers());
    final data = _handleResponse(response, 'load airfleets');
    return (data as List).cast<Map<String, dynamic>>();
  }

  Future<Map<String, dynamic>> createAirfleet(Map<String, dynamic> data) async {
    final response = await http.post(
      Uri.parse('$_baseRoute/airfleets'),
      headers: await _headers(),
      body: jsonEncode(data),
    );
    return _handleResponse(response, 'create airfleet') as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> updateAirfleet(int id, Map<String, dynamic> data) async {
    final response = await http.put(
      Uri.parse('$_baseRoute/airfleets/$id'),
      headers: await _headers(),
      body: jsonEncode(data),
    );
    return _handleResponse(response, 'update airfleet') as Map<String, dynamic>;
  }

  Future<void> deleteAirfleet(int id) async {
    final response = await http.delete(Uri.parse('$_baseRoute/airfleets/$id'), headers: await _headers());
    _handleResponse(response, 'delete airfleet');
  }


  Future<List<Map<String, dynamic>>> getManufacturers() async {
    final response = await http.get(Uri.parse('$_baseRoute/manufacturers'), headers: await _headers());
    final data = _handleResponse(response, 'load manufacturers');
    return (data as List).cast<Map<String, dynamic>>();
  }

  Future<Map<String, dynamic>> createManufacturer(Map<String, dynamic> data) async {
    final response = await http.post(
      Uri.parse('$_baseRoute/manufacturers'),
      headers: await _headers(),
      body: jsonEncode(data),
    );
    return _handleResponse(response, 'create manufacturer') as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> updateManufacturer(int id, Map<String, dynamic> data) async {
    final response = await http.put(
      Uri.parse('$_baseRoute/manufacturers/$id'),
      headers: await _headers(),
      body: jsonEncode(data),
    );
    return _handleResponse(response, 'update manufacturer') as Map<String, dynamic>;
  }

  Future<void> deleteManufacturer(int id) async {
    final response = await http.delete(Uri.parse('$_baseRoute/manufacturers/$id'), headers: await _headers());
    _handleResponse(response, 'delete manufacturer');
  }

  Future<List<Map<String, dynamic>>> getRoutes() async {
    final response = await http.get(Uri.parse('$_baseRoute/routes'), headers: await _headers());
    final data = _handleResponse(response, 'load routes');
    return (data as List).cast<Map<String, dynamic>>();
  }

  Future<void> deleteRoute(int id) async {
    final response = await http.delete(Uri.parse('$_baseRoute/routes/$id'), headers: await _headers());
    _handleResponse(response, 'delete route');
  }

  Future<List<Map<String, dynamic>>> getCountries() async {
    final response = await http.get(
      Uri.parse('$_baseRoute/countries'), 
      headers: await _headers()
    );
    final data = _handleResponse(response, 'load countries');
    return (data as List).cast<Map<String, dynamic>>();
  }

}