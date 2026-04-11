import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CheckInService extends ChangeNotifier {
  Map<String, dynamic>? _activeFlight;
  final _db = FirebaseFirestore.instance;

  Map<String, dynamic>? get activeFlight => _activeFlight;
  bool get hasActiveFlight => _activeFlight != null;

  Future<void> init(String userId) async {
    final doc = await _db
        .collection('checkin_agents')
        .doc(userId)
        .get();
    if (doc.exists && doc.data() != null) {
      _activeFlight = doc.data();
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