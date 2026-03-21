import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class NavigationStorageService {
  static const _baggageKey = 'nav_baggage_args';
  static const _paymentKey = 'nav_payment_args';

  
  static Future<void> saveBaggageArgs(Map<String, dynamic> args) async {
    final prefs = await SharedPreferences.getInstance();
    final serialized = _serializeDates(args);
    await prefs.setString(_baggageKey, jsonEncode(serialized));
  }

  static Future<Map<String, dynamic>?> loadBaggageArgs() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_baggageKey);
    if (raw == null) return null;
    return _deserializeDates(jsonDecode(raw) as Map<String, dynamic>);
  }

  static Future<void> clearBaggageArgs() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_baggageKey);
  }

  
  static Future<void> savePaymentArgs(Map<String, dynamic> args) async {
    final prefs = await SharedPreferences.getInstance();
    final serialized = _serializeDates(args);
    await prefs.setString(_paymentKey, jsonEncode(serialized));
  }

  static Future<Map<String, dynamic>?> loadPaymentArgs() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_paymentKey);
    if (raw == null) return null;
    return _deserializeDates(jsonDecode(raw) as Map<String, dynamic>);
  }

  static Future<void> clearPaymentArgs() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_paymentKey);
  }

  
  static Map<String, dynamic> _serializeDates(Map<String, dynamic> data) {
    final result = <String, dynamic>{};
    for (final entry in data.entries) {
      if (entry.value is DateTime) {
        result[entry.key] = (entry.value as DateTime).toIso8601String();
      } else if (entry.value is Map) {
        result[entry.key] = _serializeMapKeys(entry.value as Map);
      } else {
        result[entry.key] = entry.value;
      }
    }
    return result;
  }

  static Map<String, dynamic> _serializeMapKeys(Map map) {
    final result = <String, dynamic>{};
    for (final entry in map.entries) {
      final key = entry.key.toString();
      if (entry.value is Map) {
        result[key] = _serializeMapKeys(entry.value as Map);
      } else {
        result[key] = entry.value;
      }
    }
    return result;
  }

  static Map<String, dynamic> _deserializeDates(Map<String, dynamic> data) {
    final result = <String, dynamic>{};
    for (final entry in data.entries) {
      if (entry.value is String && _isIso8601(entry.value as String)) {
        result[entry.key] = DateTime.tryParse(entry.value as String) ?? entry.value;
      } else if (entry.value is Map) {
        result[entry.key] = entry.value;
      } else {
        result[entry.key] = entry.value;
      }
    }
    return result;
  }

  static bool _isIso8601(String s) {
    return RegExp(r'^\d{4}-\d{2}-\d{2}(T.*)?$').hasMatch(s);
  }
}