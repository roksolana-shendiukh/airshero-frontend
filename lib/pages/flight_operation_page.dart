import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/flight_operation_model.dart';
import '../models/route_model.dart';
import '../services/auth_service.dart';
import '../services/flight_operation_api_service.dart';
import '../services/weather_service.dart';
import '../widgets/responsive_layout.dart';
import '../widgets/flight_operation/flight_map.dart';
import '../widgets/flight_operation/crew_panel.dart';
import '../widgets/flight_operation/timeline_panel.dart';
import '../widgets/flight_operation/weather_side_panel.dart';
import '../widgets/flight_operation/operation_bottom_bar.dart';
import '../widgets/flight_operation/weather_alert_badge.dart';
import '../widgets/flight_operation/operation_info_bar.dart';

class FlightOperationPage extends StatefulWidget {
  const FlightOperationPage({super.key});

  @override
  State<FlightOperationPage> createState() => _FlightOperationPageState();
}

class _FlightOperationPageState extends State<FlightOperationPage> {
  late final FlightOperationApiService _apiService;
  FlightOperationModel? _operation;
  bool _isLoading = true;
  bool _crewVisible = false;
  bool _timelineVisible = false;
  bool _weatherVisible = false;
  List<WeatherAlert> _weatherAlerts = [];
  List<WeatherData> _weatherPoints = [];
  LatLngCenter? _weatherCenter;
  List<RouteModel> _routes = [];

  @override
  void initState() {
    super.initState();
    _apiService = FlightOperationApiService(context.read<AuthService>());
    _loadOperation();
    _loadRoutes();
  }

  Future<void> _loadRoutes() async {
    final routes = await _apiService.getRoutes();
    if (!mounted) return;
    setState(() => _routes = routes);
  }

  Future<void> _loadOperation({bool force = false}) async {
    final operationId = context.read<AuthService>().currentUser?.operationId;

    if (!force &&
        operationId != null &&
        _operation != null &&
        _operation!.flightOperationId == operationId &&
        _operation!.statusName != 'Completed' &&
        _operation!.statusName != 'Cancelled') {
      return;
    }

    if (operationId == null) {
      setState(() => _isLoading = false);
      return;
    }
    setState(() => _isLoading = true);
    final op = await _apiService.getFlightOperation(operationId);
    if (mounted) {
      setState(() {
        _operation = op;
        _isLoading = false;
      });
      if (op == null) {
        await context.read<AuthService>().refreshSession();
      }
    }
  }

  List<RouteModel> get _operationRoutes {
    if (_operation == null) return [];
    return _routes
        .where((r) =>
            r.departsCode == _operation!.departsCode &&
            r.arrivesCode == _operation!.arrivesCode)
        .toList();
  }

  bool get _hasOperation => _operation != null;

  bool get _isTerminal =>
      _operation?.statusName == 'Completed' ||
      _operation?.statusName == 'Cancelled';

  @override
  Widget build(BuildContext context) {
    return ResponsiveLayout(
      body: Stack(
        children: [
          Positioned.fill(
            child: FlightMap(
              operation: _operation,
              onAlertsChanged: (alerts) =>
                  setState(() => _weatherAlerts = alerts),
              onWeatherPointsChanged: (points) =>
                  setState(() => _weatherPoints = points),
              onWeatherCenterChanged: (center) =>
                  setState(() => _weatherCenter = center),
            ),
          ),

          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: _isLoading
                ? _loadingBar(context)
                : _operation == null
                    ? _noOperationBar(context)
                    : _isTerminal
                        ? _terminalOperationBar(context)
                        : OperationInfoBar(
                            op: _operation!,
                            onRefresh: () => _loadOperation(force: true),
                          ),
          ),

          if (_timelineVisible && _hasOperation && !_isTerminal)
            Positioned(
              top: 56,
              left: 0,
              bottom: 0,
              child: TimelinePanel(
                operation: _operation!,
                apiService: _apiService,
                onClose: () => setState(() => _timelineVisible = false),
                onOperationUpdated: (op) =>
                    setState(() => _operation = op),
              ),
            ),

          if (_crewVisible && _hasOperation && !_isTerminal)
            Positioned(
              top: 56,
              right: 0,
              bottom: 0,
              child: CrewSidePanel(
                operationId: _operation!.flightOperationId,
                apiService: _apiService,
                onClose: () => setState(() => _crewVisible = false),
              ),
            ),

          if (_weatherVisible &&
              _hasOperation &&
              !_isTerminal &&
              _operationRoutes.isNotEmpty)
            Positioned(
              top: 56,
              right: 0,
              bottom: 0,
              child: WeatherSidePanel(
                operation: _operation!,
                routes: _operationRoutes,
                weatherPoints: _weatherPoints,
                alerts: _weatherAlerts,
                center: _weatherCenter,
                onClose: () => setState(() => _weatherVisible = false),
              ),
            ),

          if (_weatherAlerts.isNotEmpty && _hasOperation && !_isTerminal)
            Positioned(
              top: 60,
              right: 16,
              child: WeatherAlertBadge(alerts: _weatherAlerts),
            ),

          if (_hasOperation && !_isTerminal)
            Positioned(
              bottom: 32,
              left: 0,
              right: 0,
              child: Center(
                child: OperationBottomBar(
                  weatherVisible: _weatherVisible,
                  timelineVisible: _timelineVisible,
                  crewVisible: _crewVisible,
                  hasAlerts: _weatherAlerts.isNotEmpty,
                  hasCritical: _weatherAlerts
                      .any((a) => a.level == WeatherAlertLevel.critical),
                  onWeatherToggle: () => setState(() {
                    _weatherVisible = !_weatherVisible;
                    if (_weatherVisible) {
                      _crewVisible = false;
                      _timelineVisible = false;
                    }
                  }),
                  onTimelineToggle: () => setState(() {
                    _timelineVisible = !_timelineVisible;
                    if (_timelineVisible) {
                      _crewVisible = false;
                      _weatherVisible = false;
                    }
                  }),
                  onCrewToggle: () => setState(() {
                    _crewVisible = !_crewVisible;
                    if (_crewVisible) {
                      _timelineVisible = false;
                      _weatherVisible = false;
                    }
                  }),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _loadingBar(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      color: colors.surface.withValues(alpha: 0.95),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
                strokeWidth: 2, color: colors.primary),
          ),
          const SizedBox(width: 12),
          Text('Loading operation...',
              style: TextStyle(color: colors.onSurfaceVariant)),
        ],
      ),
    );
  }

  Widget _terminalOperationBar(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final op = _operation!;
    final isCompleted = op.statusName == 'Completed';
    final color = isCompleted ? Colors.green : colors.error;
    final icon = isCompleted
        ? Icons.check_circle_outline
        : Icons.cancel_outlined;
    final label = isCompleted
        ? 'Operation completed'
        : 'Operation cancelled';

    return Container(
      color: colors.surface.withValues(alpha: 0.95),
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
      child: Row(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 10),
          Text(
            '${op.flightNumber ?? "—"} · ${op.departsCode ?? "—"} → ${op.arrivesCode ?? "—"} · $label',
            style: TextStyle(
                color: color,
                fontSize: 13,
                fontWeight: FontWeight.w500),
          ),
          const Spacer(),
        ],
      ),
    );
  }

  Widget _noOperationBar(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      color: colors.surface.withValues(alpha: 0.95),
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
      child: Row(
        children: [
          Icon(Icons.flight_outlined,
              color: colors.onSurfaceVariant, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'No operation assigned. Create a new one.',
              style: TextStyle(
                  color: colors.onSurfaceVariant, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}