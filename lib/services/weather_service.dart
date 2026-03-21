import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';

class WeatherData {
  final double lat;
  final double lon;
  final double windSpeed;
  final double windDeg;
  final double visibility;
  final double temp;
  final double pressure;
  final String weatherMain;
  final String weatherDescription;
  final double? rain1h;
  final double? snow1h;
  final int cloudiness;

  const WeatherData({
    required this.lat,
    required this.lon,
    required this.windSpeed,
    required this.windDeg,
    required this.visibility,
    required this.temp,
    required this.pressure,
    required this.weatherMain,
    required this.weatherDescription,
    required this.cloudiness,
    this.rain1h,
    this.snow1h,
  });

  factory WeatherData.fromJson(Map<String, dynamic> json, double lat, double lon) {
    final wind    = json['wind'] as Map<String, dynamic>? ?? {};
    final main    = json['main'] as Map<String, dynamic>? ?? {};
    final weather = (json['weather'] as List?)?.first as Map<String, dynamic>? ?? {};
    final rain    = json['rain'] as Map<String, dynamic>?;
    final snow    = json['snow'] as Map<String, dynamic>?;
    final clouds  = json['clouds'] as Map<String, dynamic>? ?? {};

    return WeatherData(
      lat:                lat,
      lon:                lon,
      windSpeed:          (wind['speed'] as num?)?.toDouble() ?? 0,
      windDeg:            (wind['deg']   as num?)?.toDouble() ?? 0,
      visibility:         (json['visibility'] as num?)?.toDouble() ?? 10000,
      temp:               (main['temp']     as num?)?.toDouble() ?? 0,
      pressure:           (main['pressure'] as num?)?.toDouble() ?? 1013,
      weatherMain:        weather['main']        as String? ?? '',
      weatherDescription: weather['description'] as String? ?? '',
      cloudiness:         (clouds['all'] as num?)?.toInt() ?? 0,
      rain1h:             (rain?['1h'] as num?)?.toDouble(),
      snow1h:             (snow?['1h'] as num?)?.toDouble(),
    );
  }
}

enum WeatherAlertLevel { warning, critical }

class WeatherAlert {
  final WeatherAlertLevel level;
  final String message;
  final double lat;
  final double lon;

  const WeatherAlert({
    required this.level,
    required this.message,
    required this.lat,
    required this.lon,
  });
}

class WeatherService {
  static const String _baseUrl = 'https://api.openweathermap.org/data/2.5/weather';
  static const int _routePoints = 5;

  Future<WeatherData?> getWeather(double lat, double lon) async {
    try {
      final uri = Uri.parse(_baseUrl).replace(queryParameters: {
        'lat':   lat.toString(),
        'lon':   lon.toString(),
        'appid': AppConfig.openWeatherApiKey,
        'units': 'metric',
      });

      final response = await http.get(uri).timeout(const Duration(seconds: 8));
      if (response.statusCode == 200) {
        return WeatherData.fromJson(
          jsonDecode(response.body) as Map<String, dynamic>,
          lat, lon,
        );
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<List<WeatherData>> getRouteWeather({
    required double fromLat,
    required double fromLon,
    required double toLat,
    required double toLon,
  }) async {
    final points = <(double, double)>[];

    for (int i = 0; i <= _routePoints + 1; i++) {
      final t   = i / (_routePoints + 1);
      final lat = fromLat + (toLat - fromLat) * t;
      final lon = fromLon + (toLon - fromLon) * t;
      points.add((lat, lon));
    }

    final futures = points.map((p) => getWeather(p.$1, p.$2)).toList();
    final results = await Future.wait(futures);
    return results.whereType<WeatherData>().toList();
  }

  List<WeatherAlert> analyzeAlerts(List<WeatherData> weatherPoints) {
    final alerts = <WeatherAlert>[];

    for (final w in weatherPoints) {
      if (w.windSpeed >= 20) {
        alerts.add(WeatherAlert(
          level:   WeatherAlertLevel.critical,
          message: 'Critical wind: ${w.windSpeed.toStringAsFixed(1)} m/s',
          lat:     w.lat,
          lon:     w.lon,
        ));
      } else if (w.windSpeed >= 15) {
        alerts.add(WeatherAlert(
          level:   WeatherAlertLevel.warning,
          message: 'Strong wind: ${w.windSpeed.toStringAsFixed(1)} m/s',
          lat:     w.lat,
          lon:     w.lon,
        ));
      }

      if (w.visibility < 550) {
        alerts.add(WeatherAlert(
          level:   WeatherAlertLevel.critical,
          message: 'Visibility below CAT I minimum: ${w.visibility.toInt()} m',
          lat:     w.lat,
          lon:     w.lon,
        ));
      } else if (w.visibility < 1500) {
        alerts.add(WeatherAlert(
          level:   WeatherAlertLevel.warning,
          message: 'Low visibility: ${w.visibility.toInt()} m',
          lat:     w.lat,
          lon:     w.lon,
        ));
      }

      if (w.weatherMain == 'Thunderstorm') {
        alerts.add(WeatherAlert(
          level:   WeatherAlertLevel.critical,
          message: 'Thunderstorm: ${w.weatherDescription}',
          lat:     w.lat,
          lon:     w.lon,
        ));
      }

      final hasIcingRisk = (w.temp >= -2 && w.temp <= 2) &&
          (w.rain1h != null || w.snow1h != null || w.cloudiness > 70);
      if (hasIcingRisk) {
        alerts.add(WeatherAlert(
          level:   WeatherAlertLevel.warning,
          message: 'Icing risk: ${w.temp.toStringAsFixed(1)}°C with precipitation',
          lat:     w.lat,
          lon:     w.lon,
        ));
      }

      if (w.weatherMain == 'Fog' || w.weatherMain == 'Mist') {
        alerts.add(WeatherAlert(
          level:   WeatherAlertLevel.warning,
          message: 'Fog/Mist: ${w.weatherDescription}',
          lat:     w.lat,
          lon:     w.lon,
        ));
      }

      if (w.snow1h != null && w.snow1h! > 2) {
        alerts.add(WeatherAlert(
          level:   WeatherAlertLevel.warning,
          message: 'Heavy snow: ${w.snow1h!.toStringAsFixed(1)} mm/h',
          lat:     w.lat,
          lon:     w.lon,
        ));
      }
    }

    alerts.sort((a, b) => b.level.index.compareTo(a.level.index));
    return alerts;
  }
}

class LatLngCenter {
  final double lat;
  final double lon;
  const LatLngCenter(this.lat, this.lon);
}