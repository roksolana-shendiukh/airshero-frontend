import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../models/flight_operation_model.dart';
import '../../models/route_model.dart';
import '../../services/weather_service.dart';

class FlightWeatherLayer extends StatefulWidget {
  final FlightOperationModel? operation;
  final List<RouteModel> routes;
  final LatLng? aircraftPosition;
  final ValueChanged<List<WeatherAlert>>? onAlertsChanged;
  final ValueChanged<List<WeatherData>>?  onWeatherPointsChanged;
  final ValueChanged<LatLngCenter?>?      onCenterChanged;

  const FlightWeatherLayer({
    super.key,
    required this.operation,
    required this.routes,
    required this.aircraftPosition,
    this.onAlertsChanged,
    this.onWeatherPointsChanged,
    this.onCenterChanged,
  });

  @override
  State<FlightWeatherLayer> createState() => _FlightWeatherLayerState();
}

class _FlightWeatherLayerState extends State<FlightWeatherLayer> {
  final _service = WeatherService();

  static const double _radiusKm = 150.0;

  List<WeatherData> _allPoints   = [];
  Timer?            _refreshTimer;
  LatLng?           _lastCenter;

  final Map<String, _CachedWeather> _cache = {};
  static const Duration _cacheTtl = Duration(minutes: 20);

  @override
  void initState() {
    super.initState();
    _scheduleLoad();
  }

  @override
  void didUpdateWidget(FlightWeatherLayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    final oldPos = oldWidget.aircraftPosition;
    final newPos = widget.aircraftPosition;
    if (newPos != null && _lastCenter != null) {
      if (_distanceKm(_lastCenter!, newPos) > 20) _scheduleLoad();
    } else if (newPos != oldPos) {
      _scheduleLoad();
    }
    if (oldWidget.operation?.statusName != widget.operation?.statusName) {
      _refreshTimer?.cancel();
      _scheduleLoad();
    }
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  LatLng? get _center {
    final pos   = widget.aircraftPosition;
    if (pos != null) return pos;
    final op    = widget.operation;
    final route = _findRoute();
    if (op == null || route == null) return null;
    switch (op.statusName) {
      case 'Waiting':
      case 'Boarding':
        return LatLng(route.departsLat, route.departsLng);
      case 'Arrived':
        return LatLng(route.arrivesLat, route.arrivesLng);
      default:
        return null;
    }
  }

  RouteModel? _findRoute() {
    final op = widget.operation;
    if (op == null) return null;
    try {
      return widget.routes.firstWhere(
        (r) => r.departsCode == op.departsCode && r.arrivesCode == op.arrivesCode,
      );
    } catch (_) {
      return null;
    }
  }

  void _scheduleLoad() {
    _refreshTimer?.cancel();
    _load();
    final isDeparted = widget.operation?.statusName == 'Departed';
    _refreshTimer = Timer(
      isDeparted ? const Duration(minutes: 10) : const Duration(minutes: 30),
      _scheduleLoad,
    );
  }

  // Розмір сітки залежить від zoom — більший zoom = більше точок
  int _gridSizeForZoom(double zoom) {
    if (zoom >= 10) return 7;
    if (zoom >= 8)  return 5;
    if (zoom >= 6)  return 4;
    return 3;
  }

  Future<void> _load({double zoom = 5.0}) async {
    final center = _center;
    if (center == null) return;
    _lastCenter = center;

    final gridSize = _gridSizeForZoom(zoom);
    final points   = _buildGrid(center, gridSize);
    final futures  = points.map((p) => _getWeatherCached(p)).toList();
    final results  = await Future.wait(futures);

    if (!mounted) return;

    final weatherList = results.whereType<WeatherData>().toList();
    final alerts      = _service.analyzeAlerts(weatherList);

    setState(() => _allPoints = weatherList);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      widget.onAlertsChanged?.call(alerts);
      widget.onWeatherPointsChanged?.call(weatherList);
      widget.onCenterChanged?.call(
        LatLngCenter(center.latitude, center.longitude));
    });
  }

  Future<WeatherData?> _getWeatherCached(LatLng point) async {
    final key    = '${point.latitude.toStringAsFixed(2)}_${point.longitude.toStringAsFixed(2)}';
    final cached = _cache[key];
    final now    = DateTime.now();
    if (cached != null && now.difference(cached.fetchedAt) < _cacheTtl) {
      return cached.data;
    }
    final data = await _service.getWeather(point.latitude, point.longitude);
    if (data != null) _cache[key] = _CachedWeather(data: data, fetchedAt: now);
    return data;
  }

  List<LatLng> _buildGrid(LatLng center, int gridSize) {
    final points   = <LatLng>[];
    final latDelta = _radiusKm / 111.0;
    final lonDelta = _radiusKm /
        (111.0 * math.cos(center.latitude * math.pi / 180));

    for (int row = 0; row < gridSize; row++) {
      for (int col = 0; col < gridSize; col++) {
        final t   = gridSize == 1 ? 0.5 : row / (gridSize - 1);
        final s   = gridSize == 1 ? 0.5 : col / (gridSize - 1);
        final lat = center.latitude  - latDelta + 2 * latDelta * t;
        final lon = center.longitude - lonDelta + 2 * lonDelta * s;
        final p   = LatLng(lat, lon);
        if (_distanceKm(center, p) <= _radiusKm) points.add(p);
      }
    }
    return points;
  }

  List<LatLng> _buildCirclePolygon(LatLng center, {int steps = 64}) {
    final latDelta = _radiusKm / 111.0;
    final lonDelta = _radiusKm /
        (111.0 * math.cos(center.latitude * math.pi / 180));
    return List.generate(steps, (i) {
      final angle = 2 * math.pi * i / steps;
      return LatLng(
        center.latitude  + latDelta * math.sin(angle),
        center.longitude + lonDelta * math.cos(angle),
      );
    });
  }

  double _distanceKm(LatLng a, LatLng b) {
    const R    = 6371.0;
    final lat1 = a.latitude  * math.pi / 180;
    final lat2 = b.latitude  * math.pi / 180;
    final dLat = (b.latitude  - a.latitude)  * math.pi / 180;
    final dLon = (b.longitude - a.longitude) * math.pi / 180;
    final sinA = math.sin(dLat / 2);
    final sinO = math.sin(dLon / 2);
    final h    = sinA * sinA +
                 math.cos(lat1) * math.cos(lat2) * sinO * sinO;
    return R * 2 * math.atan2(math.sqrt(h), math.sqrt(1 - h));
  }

  @override
  Widget build(BuildContext context) {
    final center = _center;
    if (center == null) return const SizedBox.shrink();

    final colors       = Theme.of(context).colorScheme;
    final circlePoints = _buildCirclePolygon(center);

    return Stack(
      children: [
        // Напівпрозора зона з курсором
        MouseRegion(
          cursor: SystemMouseCursors.precise,
          child: PolygonLayer(
            polygons: [
              Polygon(
                points:            circlePoints,
                color:             colors.primary.withValues(alpha: 0.06),
                borderColor:       colors.primary.withValues(alpha: 0.25),
                borderStrokeWidth: 1.5,
              ),
            ],
          ),
        ),

        // Всі маркери погоди
        if (_allPoints.isNotEmpty)
          MarkerLayer(
            markers: _allPoints.map((w) {
              final pointAlerts = _service.analyzeAlerts([w]);
              final hasAlert    = pointAlerts.isNotEmpty;
              final isCritical  = pointAlerts.any(
                  (a) => a.level == WeatherAlertLevel.critical);
              return Marker(
                point:  LatLng(w.lat, w.lon),
                width:  36,
                height: 36,
                child:  _WeatherMarker(
                  weather:    w,
                  hasAlert:   hasAlert,
                  isCritical: isCritical,
                  alerts:     pointAlerts,
                ),
              );
            }).toList(),
          ),
      ],
    );
  }
}


class _WeatherMarker extends StatefulWidget {
  final WeatherData        weather;
  final bool               hasAlert;
  final bool               isCritical;
  final List<WeatherAlert> alerts;

  const _WeatherMarker({
    required this.weather,
    required this.hasAlert,
    required this.isCritical,
    required this.alerts,
  });

  @override
  State<_WeatherMarker> createState() => _WeatherMarkerState();
}

class _WeatherMarkerState extends State<_WeatherMarker>
    with SingleTickerProviderStateMixin {
  bool _expanded = false;
  AnimationController? _pulse;
  Animation<double>?   _scale;

  @override
  void initState() {
    super.initState();
    if (widget.hasAlert) {
      _pulse = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 800),
      )..repeat(reverse: true);
      _scale = Tween<double>(begin: 0.9, end: 1.15).animate(
        CurvedAnimation(parent: _pulse!, curve: Curves.easeInOut),
      );
    }
  }

  @override
  void dispose() {
    _pulse?.dispose();
    super.dispose();
  }

  IconData get _icon {
    if (widget.hasAlert) {
      return widget.isCritical
          ? Icons.warning_rounded
          : Icons.warning_amber_outlined;
    }
    switch (widget.weather.weatherMain) {
      case 'Clear':        return Icons.wb_sunny_outlined;
      case 'Clouds':       return Icons.cloud_outlined;
      case 'Rain':         return Icons.grain;
      case 'Drizzle':      return Icons.grain;
      case 'Thunderstorm': return Icons.thunderstorm_outlined;
      case 'Snow':         return Icons.ac_unit;
      case 'Fog':
      case 'Mist':         return Icons.blur_on;
      default:             return Icons.cloud_outlined;
    }
  }

  Color _color(ColorScheme colors) {
    if (widget.isCritical) return Colors.red;
    if (widget.hasAlert)   return Colors.orange;
    switch (widget.weather.weatherMain) {
      case 'Clear':        return Colors.amber;
      case 'Thunderstorm': return Colors.deepOrange;
      case 'Snow':         return Colors.lightBlue;
      case 'Fog':
      case 'Mist':         return colors.onSurfaceVariant;
      default:             return colors.primary;
    }
  }

  String _windDir(double deg) {
    const dirs = ['N', 'NE', 'E', 'SE', 'S', 'SW', 'W', 'NW'];
    return dirs[((deg + 22.5) / 45).floor() % 8];
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final color  = _color(colors);
    final w      = widget.weather;

    Widget icon = Container(
      width:  32,
      height: 32,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: widget.hasAlert
            ? color.withValues(alpha: 0.15)
            : colors.surface.withValues(alpha: 0.88),
        border: widget.hasAlert
            ? Border.all(color: color, width: 1.5)
            : null,
        boxShadow: [
          BoxShadow(
            color:      widget.hasAlert
                ? color.withValues(alpha: 0.35)
                : Colors.black.withValues(alpha: 0.12),
            blurRadius: widget.hasAlert ? 6 : 3,
            spreadRadius: widget.hasAlert ? 1 : 0,
          ),
        ],
      ),
      child: Icon(_icon, size: 16, color: color),
    );

    if (widget.hasAlert && _scale != null) {
      icon = ScaleTransition(scale: _scale!, child: icon);
    }

    return GestureDetector(
      onTap: () => setState(() => _expanded = !_expanded),
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          icon,
          if (_expanded)
            Positioned(
              top:  36,
              left: -60,
              child: Material(
                color:        colors.surface,
                borderRadius: BorderRadius.circular(8),
                elevation:    6,
                child: Container(
                  width:   190,
                  padding: const EdgeInsets.all(10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize:       MainAxisSize.min,
                    children: [
                      Text(
                        w.weatherDescription,
                        style: TextStyle(
                          fontSize:   11,
                          fontWeight: FontWeight.w600,
                          color:      colors.onSurface,
                        ),
                      ),
                      const SizedBox(height: 6),
                      _row(Icons.thermostat_outlined,
                          '${w.temp.toStringAsFixed(1)}°C', colors),
                      _row(Icons.air,
                          '${w.windSpeed.toStringAsFixed(1)} m/s ${_windDir(w.windDeg)}',
                          colors),
                      _row(Icons.visibility_outlined,
                          '${(w.visibility / 1000).toStringAsFixed(1)} km',
                          colors),
                      _row(Icons.compress,
                          '${w.pressure.toInt()} hPa', colors),
                      if (widget.hasAlert) ...[
                        const Divider(height: 10),
                        ...widget.alerts.map((a) {
                          final isCrit =
                              a.level == WeatherAlertLevel.critical;
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 3),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(
                                  isCrit
                                      ? Icons.error_outline
                                      : Icons.info_outline,
                                  size:  11,
                                  color: isCrit
                                      ? Colors.red
                                      : Colors.orange,
                                ),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    a.message,
                                    style: TextStyle(
                                        fontSize: 11,
                                        color:    colors.onSurface),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),
                      ],
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _row(IconData icon, String text, ColorScheme colors) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 3),
      child: Row(
        children: [
          Icon(icon, size: 11, color: colors.onSurfaceVariant),
          const SizedBox(width: 4),
          Text(text,
              style: TextStyle(fontSize: 11, color: colors.onSurface)),
        ],
      ),
    );
  }
}

class _CachedWeather {
  final WeatherData data;
  final DateTime    fetchedAt;
  const _CachedWeather({required this.data, required this.fetchedAt});
}