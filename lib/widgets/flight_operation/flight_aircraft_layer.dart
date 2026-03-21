import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../models/flight_operation_model.dart';
import '../../models/route_model.dart';

class FlightAircraftLayer extends StatefulWidget {
  final FlightOperationModel? operation;
  final List<RouteModel> routes;
  final ValueChanged<LatLng?>? onPositionChanged;

  const FlightAircraftLayer({
    super.key,
    required this.operation,
    required this.routes,
    this.onPositionChanged,
  });

  @override
  State<FlightAircraftLayer> createState() => _FlightAircraftLayerState();
}

class _FlightAircraftLayerState extends State<FlightAircraftLayer>
    with SingleTickerProviderStateMixin {
  Timer? _ticker;
  LatLng? _currentPosition;
  double _bearing = 0.0;

  late AnimationController _arrivalController;
  late Animation<double> _arrivalAnimation;
  bool _isPlayingArrival = false;
  LatLng? _arrivalStart;
  LatLng? _arrivalEnd;

  @override
  void initState() {
    super.initState();
    _arrivalController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    );
    _arrivalAnimation = CurvedAnimation(
      parent: _arrivalController,
      curve: Curves.easeInOut,
    );
    _arrivalController.addListener(_onArrivalTick);
    _arrivalController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        setState(() {
          _currentPosition = _arrivalEnd;
          _isPlayingArrival = false;
        });
        widget.onPositionChanged?.call(_arrivalEnd);
      }
    });
    _startTicker();
    _update();
  }

  @override
  void didUpdateWidget(FlightAircraftLayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    final wasArrived = oldWidget.operation?.statusName == 'Arrived';
    final isArrived  = widget.operation?.statusName == 'Arrived';
    if (!wasArrived && isArrived && !_isPlayingArrival) {
      _triggerArrivalAnimation();
    } else {
      _update();
    }
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _arrivalController.dispose();
    super.dispose();
  }

  void _startTicker() {
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) _update();
    });
  }

  void _update() {
    final op = widget.operation;
    if (op == null) {
      _setPosition(null);
      return;
    }

    final status = op.statusName;

    if (status == 'Departed' && !_isPlayingArrival) {
      _updateInFlight(op);
      return;
    }

    if (status == 'Arrived' && !_isPlayingArrival) {
      final route = _findRoute(op);
      if (route != null) {
        _setPosition(LatLng(route.arrivesLat, route.arrivesLng));
      }
      return;
    }

    if (status == 'Waiting' || status == 'Boarding') {
      final route = _findRoute(op);
      if (route != null) {
        _setPosition(LatLng(route.departsLat, route.departsLng));
      }
      return;
    }

    if (status != 'Departed' && status != 'Arrived' && !_isPlayingArrival) {
      _setPosition(null);
    }
  }

  void _setPosition(LatLng? pos) {
    if (_currentPosition?.latitude != pos?.latitude ||
        _currentPosition?.longitude != pos?.longitude) {
      setState(() => _currentPosition = pos);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) widget.onPositionChanged?.call(pos);
      });
    }
  }

  void _updateInFlight(FlightOperationModel op) {
    final route = _findRoute(op);
    if (route == null) return;

    final departure = _parseActualDeparture(op.actualDepartureDatetime);
    if (departure == null) return;

    final scheduledDuration =
        op.arrivesDatetime != null && op.departsDatetime != null
            ? op.arrivesDatetime!.difference(op.departsDatetime!)
            : const Duration(hours: 2);

    final elapsed  = DateTime.now().toUtc().difference(departure);
    final progress =
        (elapsed.inSeconds / scheduledDuration.inSeconds).clamp(0.0, 1.0);

    final from = LatLng(route.departsLat, route.departsLng);
    final to   = LatLng(route.arrivesLat, route.arrivesLng);
    final pos  = _interpolate(from, to, progress);

    setState(() {
      _bearing = _calcBearing(from, to);
    });
    _setPosition(pos);
  }

  void _triggerArrivalAnimation() {
    final op    = widget.operation;
    final route = op != null ? _findRoute(op) : null;
    if (route == null) return;

    final to = LatLng(route.arrivesLat, route.arrivesLng);
    _arrivalStart = _currentPosition ??
        _interpolate(
          LatLng(route.departsLat, route.departsLng),
          to,
          0.9,
        );
    _arrivalEnd = to;

    setState(() => _isPlayingArrival = true);
    _arrivalController.forward(from: 0.0);
  }

  void _onArrivalTick() {
    if (!mounted || _arrivalStart == null || _arrivalEnd == null) return;
    final pos = _interpolate(_arrivalStart!, _arrivalEnd!, _arrivalAnimation.value);
    setState(() {
      _currentPosition = pos;
      _bearing = _calcBearing(_arrivalStart!, _arrivalEnd!);
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) widget.onPositionChanged?.call(pos);
    });
  }

  RouteModel? _findRoute(FlightOperationModel op) {
    try {
      return widget.routes.firstWhere(
        (r) => r.departsCode == op.departsCode && r.arrivesCode == op.arrivesCode,
      );
    } catch (_) {
      return null;
    }
  }

  DateTime? _parseActualDeparture(String? raw) {
    if (raw == null) return null;
    try {
      if (raw.contains('T') || raw.contains('-')) {
        return DateTime.parse(raw); 
      }
      final parts = raw.split(':');
      final now   = DateTime.now();
      return DateTime(
        now.year, now.month, now.day,
        int.parse(parts[0]),
        int.parse(parts[1]),
        parts.length > 2 ? int.parse(parts[2]) : 0,
      );
    } catch (_) {
      return null;
    }
  }

  LatLng _interpolate(LatLng from, LatLng to, double t) => LatLng(
        from.latitude  + (to.latitude  - from.latitude)  * t,
        from.longitude + (to.longitude - from.longitude) * t,
      );

  double _calcBearing(LatLng from, LatLng to) {
    final lat1 = from.latitude  * math.pi / 180;
    final lat2 = to.latitude    * math.pi / 180;
    final dLng = (to.longitude - from.longitude) * math.pi / 180;
    final y    = math.sin(dLng) * math.cos(lat2);
    final x    = math.cos(lat1) * math.sin(lat2) -
                 math.sin(lat1) * math.cos(lat2) * math.cos(dLng);
    return math.atan2(y, x);
  }

  @override
  Widget build(BuildContext context) {
    final pos = _currentPosition;
    if (pos == null) return const SizedBox.shrink();

    return MarkerLayer(
      markers: [
        Marker(
          point:  pos,
          width:  32,
          height: 32,
          child: Transform.rotate(
            angle: _bearing,
            child: _AircraftIcon(isArriving: _isPlayingArrival),
          ),
        ),
      ],
    );
  }
}

class _AircraftIcon extends StatefulWidget {
  final bool isArriving;
  const _AircraftIcon({required this.isArriving});

  @override
  State<_AircraftIcon> createState() => _AircraftIconState();
}

class _AircraftIconState extends State<_AircraftIcon>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double>   _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.9, end: 1.1).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return ScaleTransition(
      scale: _pulseAnimation,
      child: Container(
        width:  32,
        height: 32,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: widget.isArriving
              ? Colors.green.withValues(alpha: 0.15)
              : colors.primary.withValues(alpha: 0.15),
          boxShadow: [
            BoxShadow(
              color: widget.isArriving
                  ? Colors.green.withValues(alpha: 0.4)
                  : colors.primary.withValues(alpha: 0.4),
              blurRadius: 8,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Icon(
          Icons.flight,
          size:  18,
          color: widget.isArriving ? Colors.green : colors.primary,
        ),
      ),
    );
  }
}