import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import '../../models/airport_model.dart';
import '../../models/route_model.dart';
import '../../models/flight_operation_model.dart';
import '../../services/auth_service.dart';
import '../../services/flight_operation_api_service.dart';
import '../../services/weather_service.dart';
import 'flight_aircraft_layer.dart';
import 'flight_weather_layer.dart';

class FlightMap extends StatefulWidget {
  final FlightOperationModel? operation;
  final ValueChanged<List<WeatherAlert>>? onAlertsChanged;
  final ValueChanged<List<WeatherData>>?  onWeatherPointsChanged;
  final ValueChanged<LatLngCenter?>?      onWeatherCenterChanged;

  const FlightMap({
    super.key,
    this.operation,
    this.onAlertsChanged,
    this.onWeatherPointsChanged,
    this.onWeatherCenterChanged,
  });

  @override
  State<FlightMap> createState() => _FlightMapState();
}

class _FlightMapState extends State<FlightMap> {
  final _mapController = MapController();
  bool    _isDragging  = false;
  List<AirportModel> _airports = [];
  List<RouteModel>   _routes   = [];
  bool    _loading     = true;
  LatLng? _aircraftPosition;

  @override
  void initState() {
    super.initState();
    _loadData();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _mapController.mapEventStream.listen((event) {
        if (!mounted) return;
        if (event is MapEventMoveStart) {
          setState(() => _isDragging = true);
        } else if (event is MapEventMoveEnd) {
          setState(() => _isDragging = false);
        }
      });
    });
  }

  Future<void> _loadData() async {
    final authService = context.read<AuthService>();
    final service     = FlightOperationApiService(authService);
    final results     = await Future.wait([
      service.getAirports(),
      service.getRoutes(),
    ]);
    if (!mounted) return;
    setState(() {
      _airports = results[0] as List<AirportModel>;
      _routes   = results[1] as List<RouteModel>;
      _loading  = false;
    });
  }

  void _focusOnRoute() {
    final op = widget.operation;
    if (op == null) return;

    RouteModel? route;
    try {
      route = _routes.firstWhere(
        (r) => r.departsCode == op.departsCode && r.arrivesCode == op.arrivesCode,
      );
    } catch (_) {
      return;
    }

    final bounds = LatLngBounds(
      LatLng(route.departsLat, route.departsLng),
      LatLng(route.arrivesLat, route.arrivesLng),
    );
    _mapController.fitCamera(
      CameraFit.bounds(
        bounds: bounds,
        padding: const EdgeInsets.all(80),
      ),
    );
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colors = Theme.of(context).colorScheme;

    return Stack(
      children: [
        MouseRegion(
          cursor: _isDragging
              ? SystemMouseCursors.grabbing
              : SystemMouseCursors.grab,
          child: FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: const LatLng(49.5, 24.0),
              initialZoom:   5.0,
              minZoom:       3.0,
              maxZoom:       14.0,
              interactionOptions: const InteractionOptions(
                flags:                  InteractiveFlag.all,
                pinchZoomWinGestures:   MultiFingerGesture.pinchZoom,
              ),
            ),
            children: [
              TileLayer(
                urlTemplate: isDark
                    ? 'https://server.arcgisonline.com/ArcGIS/rest/services/Canvas/World_Dark_Gray_Base/MapServer/tile/{z}/{y}/{x}'
                    : 'https://server.arcgisonline.com/ArcGIS/rest/services/Canvas/World_Light_Gray_Base/MapServer/tile/{z}/{y}/{x}',
                userAgentPackageName: 'com.airshero.app',
              ),

              if (!_loading)
                PolylineLayer(
                  polylines: _routes
                      .where((r) =>
                          (r.arrivesLng - r.departsLng).abs() <= 180)
                      .map<Polyline>((r) => Polyline(
                            points: [
                              LatLng(r.departsLat, r.departsLng),
                              LatLng(r.arrivesLat, r.arrivesLng),
                            ],
                            color:           colors.primary.withValues(alpha: 0.35),
                            strokeWidth:     1.2,
                            pattern:         const StrokePattern.solid(),
                          ))
                      .toList(),
                ),

              if (!_loading)
                MarkerLayer(
                  markers: _airports
                      .map((a) => _buildAirportMarker(a, colors))
                      .toList(),
                ),

              if (!_loading)
                FlightWeatherLayer(
                  operation:               widget.operation,
                  routes:                  _routes,
                  aircraftPosition:        _aircraftPosition,
                  onAlertsChanged:         widget.onAlertsChanged,
                  onWeatherPointsChanged:  widget.onWeatherPointsChanged,
                  onCenterChanged:         widget.onWeatherCenterChanged,
                ),

              if (!_loading)
                FlightAircraftLayer(
                  operation:         widget.operation,
                  routes:            _routes,
                  onPositionChanged: (pos) =>
                      setState(() => _aircraftPosition = pos),
                ),
            ],
          ),
        ),

        Positioned(
          right: 16,
          bottom: 32,
          child: Column(
            children: [
              if (widget.operation != null) ...[
                _ZoomButton(
                  icon:   Icons.my_location,
                  onTap:  _focusOnRoute,
                  colors: colors,
                  tooltip: 'Focus on route',
                ),
                const SizedBox(height: 4),
              ],
              _ZoomButton(
                icon:   Icons.add,
                onTap:  () {
                  final z = _mapController.camera.zoom;
                  _mapController.move(
                      _mapController.camera.center, (z + 1).clamp(3.0, 14.0));
                },
                colors: colors,
              ),
              const SizedBox(height: 4),
              _ZoomButton(
                icon:   Icons.remove,
                onTap:  () {
                  final z = _mapController.camera.zoom;
                  _mapController.move(
                      _mapController.camera.center, (z - 1).clamp(3.0, 14.0));
                },
                colors: colors,
              ),
            ],
          ),
        ),

        if (_loading)
          Positioned(
            top: 16, right: 64,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color:        colors.surface.withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color:      Colors.black.withValues(alpha: 0.1),
                    blurRadius: 4,
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 14, height: 14,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: colors.primary),
                  ),
                  const SizedBox(width: 8),
                  Text('Loading map data...',
                      style: TextStyle(fontSize: 12, color: colors.onSurface)),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Marker _buildAirportMarker(AirportModel airport, ColorScheme colors) {
    if (airport.latitude == null || airport.longitude == null) {
      return Marker(
        point:  const LatLng(0, 0),
        width:  0,
        height: 0,
        child:  const SizedBox.shrink(),
      );
    }
    return Marker(
      point:  LatLng(airport.latitude!, airport.longitude!),
      width:  24,
      height: 24,
      child: Tooltip(
        message: airport.airportCode ?? '',
        child: GestureDetector(
          onTap: () => _mapController.move(
            LatLng(airport.latitude!, airport.longitude!), 8.0),
          child: Icon(
            Icons.location_on,
            size:  20,
            color: colors.primary,
            shadows: [
              Shadow(
                color:      Colors.black.withValues(alpha: 0.3),
                blurRadius: 4,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ZoomButton extends StatefulWidget {
  final IconData     icon;
  final VoidCallback onTap;
  final ColorScheme  colors;
  final String?      tooltip;

  const _ZoomButton({
    required this.icon,
    required this.onTap,
    required this.colors,
    this.tooltip,
  });

  @override
  State<_ZoomButton> createState() => _ZoomButtonState();
}

class _ZoomButtonState extends State<_ZoomButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final btn = MouseRegion(
      cursor:  SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit:  (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width:  36,
          height: 36,
          decoration: BoxDecoration(
            color: _hovered
                ? widget.colors.primaryContainer
                : widget.colors.surface,
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color:      Colors.black.withValues(alpha: 0.15),
                blurRadius: 6,
                offset:     const Offset(0, 2),
              ),
            ],
          ),
          child: Icon(
            widget.icon,
            size:  20,
            color: _hovered
                ? widget.colors.onPrimaryContainer
                : widget.colors.onSurface,
          ),
        ),
      ),
    );

    if (widget.tooltip != null) {
      return Tooltip(message: widget.tooltip!, child: btn);
    }
    return btn;
  }
}