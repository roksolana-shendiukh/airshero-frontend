import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/checkin_api_service.dart';

class CheckInService extends ChangeNotifier {
  Map<String, dynamic>? _activeFlight;
  final _db = FirebaseFirestore.instance;

  Map<String, dynamic>? get activeFlight => _activeFlight;
  bool get hasActiveFlight => _activeFlight != null;

  Future<void> init(String userId, CheckInApiService apiService) async {
    final doc = await _db
        .collection('checkin_agents')
        .doc(userId)
        .get();
    if (doc.exists && doc.data() != null) {
      final flight = doc.data()!;
      final operationId = flight['flightOperationId'] as int?;
      if (operationId != null) {
        final activeFlights = await apiService.getActiveFlights();
        final stillActive = activeFlights.any(
          (f) => f['flightOperationId'] == operationId,
        );
        if (stillActive) {
          _activeFlight = flight;
        } else {
          await _db.collection('checkin_agents').doc(userId).delete();
        }
      }
      notifyListeners();
    }
  }


  Future<void> setActiveFlight(Map<String, dynamic> flight, String userId) async {
    _activeFlight = flight;
    await _db
        .collection('checkin_agents')
        .doc(userId)
        .set(flight);
    notifyListeners();
  }

  Future<void> clearActiveFlight(String userId) async {
    _activeFlight = null;
    await _db
        .collection('checkin_agents')
        .doc(userId)
        .delete();
    notifyListeners();
  }
}


