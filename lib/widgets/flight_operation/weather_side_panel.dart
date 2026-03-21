import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../../models/flight_operation_model.dart';
import '../../models/route_model.dart';
import '../../services/weather_service.dart';

class WeatherSidePanel extends StatefulWidget {
  final FlightOperationModel operation;
  final List<RouteModel>     routes;
  final List<WeatherData>    weatherPoints;
  final List<WeatherAlert>   alerts;
  final LatLngCenter?        center;
  final VoidCallback         onClose;

  const WeatherSidePanel({
    super.key,
    required this.operation,
    required this.routes,
    required this.weatherPoints,
    required this.alerts,
    required this.onClose,
    this.center,
  });

  @override
  State<WeatherSidePanel> createState() => _WeatherSidePanelState();
}

class _WeatherSidePanelState extends State<WeatherSidePanel>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<Offset>   _slideAnim;

  final _service = WeatherService();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
    );
    _slideAnim = Tween<Offset>(
      begin: const Offset(1, 0),
      end:   Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _closePanel() {
    _controller.reverse().then((_) => widget.onClose());
  }

  RouteModel? get _route {
    try {
      return widget.routes.firstWhere(
        (r) =>
            r.departsCode == widget.operation.departsCode &&
            r.arrivesCode == widget.operation.arrivesCode,
      );
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return SlideTransition(
      position: _slideAnim,
      child: Container(
        width: 300,
        decoration: BoxDecoration(
          color:  colors.surface,
          border: Border(left: BorderSide(color: colors.outlineVariant)),
          boxShadow: [
            BoxShadow(
              color:      Colors.black.withValues(alpha: 0.12),
              blurRadius: 16,
              offset:     const Offset(-4, 0),
            ),
          ],
        ),
        child: Column(
          children: [
            _buildHeader(colors),
            if (widget.alerts.isNotEmpty) _buildAlertsBanner(colors),
            Expanded(
              child: widget.weatherPoints.isEmpty
                  ? _buildEmpty(colors)
                  : _buildContent(colors),
            ),
            _buildFooter(colors),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(ColorScheme colors) {
    final route = _route;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 8, 14),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: colors.outlineVariant)),
      ),
      child: Row(
        children: [
          Icon(Icons.cloud_outlined, size: 18, color: colors.primary),
          const SizedBox(width: 8),
          Text('Weather',
              style: Theme.of(context)
                  .textTheme
                  .titleSmall
                  ?.copyWith(fontWeight: FontWeight.w600)),
          if (route != null) ...[
            const SizedBox(width: 6),
            Text(
              '${route.departsCode} → ${route.arrivesCode}',
              style: TextStyle(fontSize: 11, color: colors.onSurfaceVariant),
            ),
          ],
          const Spacer(),
          IconButton(
            icon:          const Icon(Icons.close, size: 18),
            onPressed:     _closePanel,
            visualDensity: VisualDensity.compact,
          ),
        ],
      ),
    );
  }

  Widget _buildAlertsBanner(ColorScheme colors) {
    final hasCritical = widget.alerts
        .any((a) => a.level == WeatherAlertLevel.critical);
    final color = hasCritical ? Colors.red : Colors.orange;

    return Container(
      margin:  const EdgeInsets.fromLTRB(12, 8, 12, 0),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color:        color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border:       Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                hasCritical
                    ? Icons.warning_rounded
                    : Icons.warning_amber_outlined,
                size:  14,
                color: color,
              ),
              const SizedBox(width: 6),
              Text(
                '${widget.alerts.length} alert${widget.alerts.length > 1 ? 's' : ''}',
                style: TextStyle(
                  fontSize:   12,
                  fontWeight: FontWeight.w600,
                  color:      color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ...widget.alerts.map((a) {
            final isCrit = a.level == WeatherAlertLevel.critical;
            return Padding(
              padding: const EdgeInsets.only(bottom: 3),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    isCrit ? Icons.error_outline : Icons.info_outline,
                    size:  12,
                    color: isCrit ? Colors.red : Colors.orange,
                  ),
                  const SizedBox(width: 5),
                  Expanded(
                    child: Text(a.message,
                        style: TextStyle(
                            fontSize: 11, color: colors.onSurface)),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildContent(ColorScheme colors) {
    return ListView.separated(
      padding:          const EdgeInsets.all(12),
      itemCount:        widget.weatherPoints.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder:      (_, i) {
        final w          = widget.weatherPoints[i];
        final ptAlerts   = _service.analyzeAlerts([w]);
        final hasAlert   = ptAlerts.isNotEmpty;
        final isCritical = ptAlerts
            .any((a) => a.level == WeatherAlertLevel.critical);
        return _WeatherPointCard(
          weather:     w,
          alerts:      ptAlerts,
          hasAlert:    hasAlert,
          isCritical:  isCritical,
          colors:      colors,
          center:      widget.center,
        );
      },
    );
  }

  Widget _buildEmpty(ColorScheme colors) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.cloud_off_outlined,
              size:  36,
              color: colors.onSurfaceVariant.withValues(alpha: 0.4)),
          const SizedBox(height: 8),
          Text('No weather data in zone',
              style: TextStyle(
                  color: colors.onSurfaceVariant, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildFooter(ColorScheme colors) {
    final isDeparted = widget.operation.statusName == 'Departed';
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: colors.outlineVariant)),
      ),
      child: Row(
        children: [
          Icon(Icons.radar, size: 12, color: colors.onSurfaceVariant),
          const SizedBox(width: 4),
          Text(
            'Zone radius: 150 km',
            style:
                TextStyle(fontSize: 11, color: colors.onSurfaceVariant),
          ),
          const Spacer(),
          Text(
            isDeparted ? 'Updates every 10 min' : 'Updates every 30 min',
            style:
                TextStyle(fontSize: 10, color: colors.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}


class _WeatherPointCard extends StatelessWidget {
  final WeatherData        weather;
  final List<WeatherAlert> alerts;
  final bool               hasAlert;
  final bool               isCritical;
  final ColorScheme        colors;
  final LatLngCenter?      center;

  const _WeatherPointCard({
    required this.weather,
    required this.alerts,
    required this.hasAlert,
    required this.isCritical,
    required this.colors,
    this.center,
  });

  String get _label {
    if (center == null) {
      return '${weather.lat.toStringAsFixed(2)}°, ${weather.lon.toStringAsFixed(2)}°';
    }
    final dist = _distanceKm(center!.lat, center!.lon, weather.lat, weather.lon);
    final dir  = _bearing(center!.lat, center!.lon, weather.lat, weather.lon);
    return '$dir · ${dist.toStringAsFixed(0)} km';
  }

  double _distanceKm(double lat1, double lon1, double lat2, double lon2) {
    const R   = 6371.0;
    final p1  = lat1 * math.pi / 180;
    final p2  = lat2 * math.pi / 180;
    final dp  = (lat2 - lat1) * math.pi / 180;
    final dl  = (lon2 - lon1) * math.pi / 180;
    final a   = math.sin(dp / 2) * math.sin(dp / 2) +
                math.cos(p1) * math.cos(p2) *
                math.sin(dl / 2) * math.sin(dl / 2);
    return R * 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
  }

  String _bearing(double lat1, double lon1, double lat2, double lon2) {
    final p1  = lat1 * math.pi / 180;
    final p2  = lat2 * math.pi / 180;
    final dl  = (lon2 - lon1) * math.pi / 180;
    final y   = math.sin(dl) * math.cos(p2);
    final x   = math.cos(p1) * math.sin(p2) -
                math.sin(p1) * math.cos(p2) * math.cos(dl);
    final deg = (math.atan2(y, x) * 180 / math.pi + 360) % 360;
    const dirs = ['N', 'NE', 'E', 'SE', 'S', 'SW', 'W', 'NW'];
    return dirs[((deg + 22.5) / 45).floor() % 8];
  }

  IconData get _icon {
    switch (weather.weatherMain) {
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

  Color get _iconColor {
    if (isCritical) return Colors.red;
    if (hasAlert)   return Colors.orange;
    switch (weather.weatherMain) {
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
    final w           = weather;
    final borderColor = isCritical
        ? Colors.red.withValues(alpha: 0.4)
        : hasAlert
            ? Colors.orange.withValues(alpha: 0.3)
            : colors.outlineVariant;
    final bgColor = isCritical
        ? Colors.red.withValues(alpha: 0.06)
        : hasAlert
            ? Colors.orange.withValues(alpha: 0.05)
            : colors.surfaceContainerHighest;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color:        bgColor,
        borderRadius: BorderRadius.circular(8),
        border:       Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(_icon, size: 16, color: _iconColor),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  _label,
                  style: TextStyle(
                    fontSize:   12,
                    fontWeight: FontWeight.w600,
                    color:      colors.onSurface,
                  ),
                ),
              ),
              Text(
                '${w.temp.toStringAsFixed(1)}°C',
                style: TextStyle(
                  fontSize:   13,
                  fontWeight: FontWeight.w700,
                  color:      colors.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(w.weatherDescription,
              style: TextStyle(
                  fontSize: 11, color: colors.onSurfaceVariant)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 12, runSpacing: 4,
            children: [
              _chip(Icons.air,
                  '${w.windSpeed.toStringAsFixed(1)} m/s ${_windDir(w.windDeg)}'),
              _chip(Icons.visibility_outlined,
                  '${(w.visibility / 1000).toStringAsFixed(1)} km'),
              _chip(Icons.compress, '${w.pressure.toInt()} hPa'),
              _chip(Icons.cloud_outlined, '${w.cloudiness}%'),
              if (w.rain1h != null)
                _chip(Icons.grain,
                    '${w.rain1h!.toStringAsFixed(1)} mm/h'),
              if (w.snow1h != null)
                _chip(Icons.ac_unit,
                    '${w.snow1h!.toStringAsFixed(1)} mm/h'),
            ],
          ),
          if (alerts.isNotEmpty) ...[
            const Divider(height: 12),
            ...alerts.map((a) {
              final isCrit = a.level == WeatherAlertLevel.critical;
              return Padding(
                padding: const EdgeInsets.only(bottom: 3),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      isCrit
                          ? Icons.error_outline
                          : Icons.info_outline,
                      size:  12,
                      color: isCrit ? Colors.red : Colors.orange,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(a.message,
                          style: TextStyle(
                              fontSize: 11, color: colors.onSurface)),
                    ),
                  ],
                ),
              );
            }),
          ],
        ],
      ),
    );
  }

  Widget _chip(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 11, color: colors.onSurfaceVariant),
        const SizedBox(width: 3),
        Text(text,
            style: TextStyle(fontSize: 11, color: colors.onSurface)),
      ],
    );
  }
}