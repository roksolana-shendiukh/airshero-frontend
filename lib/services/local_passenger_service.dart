import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class LocalPassengerService {
  static const String _prefix = 'booking_passenger_';
  static const String _bookingKey = 'booking_session_id';

  static Future<void> savePassenger(String sessionId, int index, Map<String, dynamic> data) async {
    final prefs = await SharedPreferences.getInstance();
    final serialized = _serializePassenger(data);
    await prefs.setString('${_prefix}${sessionId}_$index', jsonEncode(serialized));
  }

  static Future<Map<String, dynamic>?> loadPassenger(String sessionId, int index) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('${_prefix}${sessionId}_$index');
    if (raw == null) return null;
    return _deserializePassenger(jsonDecode(raw));
  }

  static Future<Map<int, Map<String, dynamic>>> loadAllPassengers(String sessionId) async {
    final prefs = await SharedPreferences.getInstance();
    final result = <int, Map<String, dynamic>>{};
    final keys = prefs.getKeys().where((k) => k.startsWith('${_prefix}${sessionId}_'));
    for (final key in keys) {
      final indexStr = key.replaceFirst('${_prefix}${sessionId}_', '');
      final index = int.tryParse(indexStr);
      if (index == null) continue;
      final raw = prefs.getString(key);
      if (raw != null) {
        result[index] = _deserializePassenger(jsonDecode(raw));
      }
    }
    return result;
  }

  static Future<void> clearSession(String sessionId) async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys()
        .where((k) => k.startsWith('${_prefix}${sessionId}_'))
        .toList();
    for (final key in keys) {
      await prefs.remove(key);
    }
  }

  static Map<String, dynamic> _serializePassenger(Map<String, dynamic> data) {
    final result = Map<String, dynamic>.from(data);
    if (result['dateOfBirth'] is DateTime) {
      result['dateOfBirth'] = (result['dateOfBirth'] as DateTime).toIso8601String();
    }
    if (result['documentIssue'] is DateTime) {
      result['documentIssue'] = (result['documentIssue'] as DateTime).toIso8601String();
    }
    if (result['documentExpire'] is DateTime) {
      result['documentExpire'] = (result['documentExpire'] as DateTime).toIso8601String();
    }
    return result;
  }

  static Map<String, dynamic> _deserializePassenger(Map<String, dynamic> data) {
    final result = Map<String, dynamic>.from(data);
    if (result['dateOfBirth'] is String && (result['dateOfBirth'] as String).isNotEmpty) {
      result['dateOfBirth'] = DateTime.tryParse(result['dateOfBirth']);
    }
    if (result['documentIssue'] is String && (result['documentIssue'] as String).isNotEmpty) {
      result['documentIssue'] = DateTime.tryParse(result['documentIssue']);
    }
    if (result['documentExpire'] is String && (result['documentExpire'] as String).isNotEmpty) {
      result['documentExpire'] = DateTime.tryParse(result['documentExpire']);
    }
    return result;
  }
}