import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';
import '../services/auth_service.dart';
import '../models/route_model.dart';
import '../models/airport_model.dart';
import '../models/gate_model.dart';
import '../models/airfleet_model.dart';
import '../models/flight_without_operation_model.dart';
import '../models/flight_operation_status_model.dart';
import '../schemas/create_flight_operation_dto.dart';
import '../models/flight_operation_model.dart';
import '../models/flight_crew_model.dart';
import '../models/flight_operation_state_model.dart';

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

  Future<List<FlightWithoutOperationModel>> getFlightsWithoutOperation() async {
    try {
      final response = await http.get(
        Uri.parse('${AppConfig.baseUrl}/flights/without-operation'),
        headers: await _headers(),
      );
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((e) => FlightWithoutOperationModel.fromJson(e)).toList();
      }
      return [];
    } catch (e) {
      debugPrint('Network error (getFlightsWithoutOperation): $e');
      return [];
    }
  }

  Future<List<GateModel>> getGates({
    int? airportId,
    int? minCapacity,
    int? flightId,
  }) async {
    try {
      final uri = Uri.parse('${AppConfig.baseUrl}/gates').replace(
        queryParameters: {
          if (airportId != null) 'airport_id': airportId.toString(),
          if (minCapacity != null) 'min_capacity': minCapacity.toString(),
          if (flightId != null) 'flight_id': flightId.toString(),
        },
      );
      final response = await http.get(uri, headers: await _headers());
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((e) => GateModel.fromJson(e)).toList();
      }
      return [];
    } catch (e) {
      debugPrint('Network error (getGates): $e');
      return [];
    }
  }
  
  Future<List<AirfleetModel>> getAirfleets({int? flightId}) async {
    try {
      final uri = Uri.parse('${AppConfig.baseUrl}/airfleets')
          .replace(queryParameters: {
        if (flightId != null) 'flight_id': flightId.toString(),
      });
      final response = await http.get(uri, headers: await _headers());
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((e) => AirfleetModel.fromJson(e)).toList();
      }
      return [];
    } catch (e) {
      debugPrint('Network error (getAirfleets): $e');
      return [];
    }
  }

  Future<List<FlightOperationStatusModel>> getOperationStatuses() async {
    try {
      final response = await http.get(
        Uri.parse('${AppConfig.baseUrl}/flight-operations/statuses'),
        headers: await _headers(),
      );
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((e) => FlightOperationStatusModel.fromJson(e)).toList();
      }
      return [];
    } catch (e) {
      debugPrint('Network error (getOperationStatuses): $e');
      return [];
    }
  }
  
  Future<({bool success, String? error})> createFlightOperation(
      CreateFlightOperationDTO dto) async {
    try {
      final response = await http.post(
        Uri.parse('${AppConfig.baseUrl}/flight-operations'),
        headers: await _headers(),
        body: jsonEncode(dto.toJson()),
      );
      if (response.statusCode == 201) {
        return (success: true, error: null);
      }
      try {
        final body = jsonDecode(response.body);
        final detail = body['detail'] as String?;
        return (success: false, error: detail);
      } catch (_) {
        return (success: false, error: 'Failed to create operation');
      }
    } catch (e) {
      debugPrint('Network error (createFlightOperation): $e');
      return (success: false, error: 'Network error');
    }
  }

  Future<List<FlightOperationModel>> getFlightOperations() async {
    try {
      final response = await http.get(
        Uri.parse('${AppConfig.baseUrl}/flight-operations'),
        headers: await _headers(),
      );
      if (response.statusCode == 200) {
         debugPrint('[API response] ${response.body}');
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((e) => FlightOperationModel.fromJson(e)).toList();
      }
      return [];
    } catch (e) {
      debugPrint('Network error (getFlightOperations): $e');
      return [];
    }
  }

  Future<FlightOperationModel?> getFlightOperation(int id) async {
    try {
      final response = await http.get(
        Uri.parse('${AppConfig.baseUrl}/flight-operations/$id'),
        headers: await _headers(),
      );
      if (response.statusCode == 200) {
        return FlightOperationModel.fromJson(jsonDecode(response.body));
      }
      return null;
    } catch (e) {
      debugPrint('Network error (getFlightOperation): $e');
      return null;
    }
  }


  Future<List<FlightCrewModel>> getCrew(int operationId) async {
    try {
      final response = await http.get(
        Uri.parse('${AppConfig.baseUrl}/flight-operations/$operationId/crew'),
        headers: await _headers(),
      );
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((e) => FlightCrewModel.fromJson(e)).toList();
      }
      return [];
    } catch (e) {
      debugPrint('Network error (getCrew): $e');
      return [];
    }
  }

  Future<List<FlightCrewModel>> getAvailableCrew(
    int operationId, {
    String? search,
  }) async {
    try {
      final uri = Uri.parse(
        '${AppConfig.baseUrl}/flight-operations/$operationId/crew/available',
      ).replace(queryParameters: {
        if (search != null && search.isNotEmpty) 'search': search,
      });
      final response = await http.get(uri, headers: await _headers());
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((e) => FlightCrewModel.fromJson(e)).toList();
      }
      return [];
    } catch (e) {
      debugPrint('Network error (getAvailableCrew): $e');
      return [];
    }
  }
  
  Future<CrewValidationModel?> validateCrew(int operationId) async {
    try {
      final response = await http.get(
        Uri.parse('${AppConfig.baseUrl}/flight-operations/$operationId/crew/validate'),
        headers: await _headers(),
      );
      if (response.statusCode == 200) {
        return CrewValidationModel.fromJson(jsonDecode(response.body));
      }
      return null;
    } catch (e) {
      debugPrint('Network error (validateCrew): $e');
      return null;
    }
  }

  Future<({bool success, String? error})> assignCrew(
      int operationId, int crewId) async {
    try {
      final response = await http.post(
        Uri.parse('${AppConfig.baseUrl}/flight-operations/$operationId/crew'),
        headers: await _headers(),
        body: jsonEncode({'crewId': crewId}),
      );
      if (response.statusCode == 201) {
        return (success: true, error: null);
      }
      try {
        final body = jsonDecode(response.body);
        return (success: false, error: body['detail'] as String?);
      } catch (_) {
        return (success: false, error: 'Failed to assign crew');
      }
    } catch (e) {
      debugPrint('Network error (assignCrew): $e');
      return (success: false, error: 'Network error');
    }
  }
  Future<bool> removeCrew(int operationId, int crewId) async {
    try {
      final response = await http.delete(
        Uri.parse('${AppConfig.baseUrl}/flight-operations/$operationId/crew/$crewId'),
        headers: await _headers(),
      );
      return response.statusCode == 204;
    } catch (e) {
      debugPrint('Network error (removeCrew): $e');
      return false;
    }
  }

  Future<List<GateModel>> getAvailableGates(int operationId) async {
    try {
      final response = await http.get(
        Uri.parse('${AppConfig.baseUrl}/flight-operations/$operationId/gates'),
        headers: await _headers(),
      );
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((e) => GateModel.fromJson(e)).toList();
      }
      return [];
    } catch (e) {
      debugPrint('Network error (getAvailableGates): $e');
      return [];
    }
  }

  Future<({FlightOperationModel? operation, String? error, bool isWarning})>
      setTimelineStep(int operationId, String step) async {
    try {
    final response = await http.post(
      Uri.parse('${AppConfig.baseUrl}/flight-operations/$operationId/timeline/$step'),
      headers: await _headers(),
    );
    if (response.statusCode == 200) {
      debugPrint('[setTimelineStep response] ${response.body}'); // ← тут
      return (
        operation: FlightOperationModel.fromJson(jsonDecode(response.body)),
        error: null,
        isWarning: false,
      );
    }
      try {
        final body    = jsonDecode(response.body);
        final detail  = body['detail'] as String? ?? 'Unknown error';
        final isWarn  = detail.contains('Are you sure');
        return (operation: null, error: detail, isWarning: isWarn);
      } catch (_) {
        return (operation: null, error: 'Failed', isWarning: false);
      }
    } catch (e) {
      debugPrint('Network error (setTimelineStep): $e');
      return (operation: null, error: 'Network error', isWarning: false);
    }
  }
 
  Future<FlightOperationModel?> forceTimelineStep(
      int operationId, String step) async {
    try {
      final response = await http.post(
        Uri.parse(
            '${AppConfig.baseUrl}/flight-operations/$operationId/timeline/$step/force'),
        headers: await _headers(),
      );
      if (response.statusCode == 200) {
        return FlightOperationModel.fromJson(jsonDecode(response.body));
      }
      return null;
    } catch (e) {
      debugPrint('Network error (forceTimelineStep): $e');
      return null;
    }
  }

  Future<FlightOperationModel?> assignGate(
      int operationId, int gateId) async {
    try {
      final response = await http.put(
        Uri.parse(
            '${AppConfig.baseUrl}/flight-operations/$operationId'),
        headers: await _headers(),
        body: jsonEncode({'gate_id': gateId}),
      );
      if (response.statusCode == 200) {
        return FlightOperationModel.fromJson(jsonDecode(response.body));
      }
      return null;
    } catch (e) {
      debugPrint('Network error (assignGate): $e');
      return null;
    }
  }

  Future<List<String>> getAirfleetPhotos(int airfleetId) async {
    try {
      final response = await http.get(
        Uri.parse('${AppConfig.baseUrl}/airfleets/$airfleetId/photos'),
        headers: await _headers(),
      );
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

  Future<FlightOperationModel?> cancelOperation(
    int operationId, {int? stateId, String? customReason}) async {
  try {
      final response = await http.post(
        Uri.parse('${AppConfig.baseUrl}/flight-operations/$operationId/cancel'),
        headers: await _headers(),
        body: jsonEncode({
          if (stateId != null) 'state_id': stateId,
          if (customReason != null) 'custom_reason': customReason,
        }),
      );
      if (response.statusCode == 200) {
        return FlightOperationModel.fromJson(jsonDecode(response.body));
      }
      return null;
    } catch (e) {
      debugPrint('Network error (cancelOperation): $e');
      return null;
    }
  }

  Future<FlightOperationModel?> completeOperation(
      int operationId, {int? stateId, String? customReason}) async {
    try {
      final response = await http.post(
        Uri.parse('${AppConfig.baseUrl}/flight-operations/$operationId/complete'),
        headers: await _headers(),
        body: jsonEncode({
          if (stateId != null) 'state_id': stateId,
          if (customReason != null) 'custom_reason': customReason,
        }),
      );
      if (response.statusCode == 200) {
        return FlightOperationModel.fromJson(jsonDecode(response.body));
      }
      return null;
    } catch (e) {
      debugPrint('Network error (completeOperation): $e');
      return null;
    }
  }
  
  Future<List<FlightOperationStateModel>> getOperationStates() async {
    try {
      final response = await http.get(
        Uri.parse('${AppConfig.baseUrl}/flight-operations/states'),
        headers: await _headers(),
      );
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((e) => FlightOperationStateModel.fromJson(e)).toList();
      }
      return [];
    } catch (e) {
      debugPrint('Network error (getOperationStates): $e');
      return [];
    }
  }
}