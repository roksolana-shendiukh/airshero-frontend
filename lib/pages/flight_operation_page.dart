import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import '../models/flight_operation_model.dart';
import '../models/route_model.dart';
import '../services/auth_service.dart';
import '../services/flight_operation_api_service.dart';
import '../services/weather_service.dart';
import '../widgets/responsive_layout.dart';
import '../widgets/flight_operation/flight_map.dart';
import '../widgets/flight_operation/create_flight_operation_form.dart';
import '../widgets/flight_operation/crew_panel.dart';
import '../widgets/flight_operation/timeline_panel.dart';
import '../widgets/flight_operation/weather_side_panel.dart';
import '../widgets/custom/custom_button.dart';

class FlightOperationPage extends StatefulWidget {
  const FlightOperationPage({super.key});

  @override
  State<FlightOperationPage> createState() => _FlightOperationPageState();
}

class _FlightOperationPageState extends State<FlightOperationPage> {
  late final FlightOperationApiService _apiService;
  FlightOperationModel? _operation;
  bool _isLoading       = true;
  bool _crewVisible     = false;
  bool _timelineVisible = false;
  bool _weatherVisible  = false;
  List<WeatherAlert> _weatherAlerts = [];
  List<WeatherData>  _weatherPoints = [];
  LatLngCenter?      _weatherCenter;
  List<RouteModel>   _routes        = [];

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

    if (!force && operationId != null &&
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
    debugPrint('[loadOp] fetched status=${op?.statusName}');
    if (mounted) {
      setState(() {
        _operation = op;
        _isLoading  = false;
      });
      if (op == null) {
        await context.read<AuthService>().refreshSession();
      }
    }
  }

  void _openCreateForm() {
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.4),
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 780),
          child: CreateFlightOperationForm(
            apiService: _apiService,
            onSuccess: () async {
              Navigator.of(ctx).pop();
              await context.read<AuthService>().refreshSession();
              await _loadOperation();
            },
            onCancel: () => Navigator.of(ctx).pop(),
          ),
        ),
      ),
    );
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
              operation:              _operation,
              onAlertsChanged:        (alerts) =>
                  setState(() => _weatherAlerts = alerts),
              onWeatherPointsChanged: (points) =>
                  setState(() => _weatherPoints = points),
              onWeatherCenterChanged: (center) =>
                  setState(() => _weatherCenter = center),
            ),
          ),

          Positioned(
            top: 0, left: 0, right: 0,
            child: _isLoading
                ? _loadingBar(context)
                : _operation == null
                    ? _noOperationBar(context)
                    : _isTerminal
                        ? _terminalOperationBar(context)
                        : _OperationInfoBar(
                            op:        _operation!,
                            onRefresh: () => _loadOperation(force: true),
                          ),
          ),

          if (_timelineVisible && _hasOperation && !_isTerminal)
            Positioned(
              top: 56, left: 0, bottom: 0,
              child: TimelinePanel(
                operation:          _operation!,
                apiService:         _apiService,
                onClose:            () => setState(() => _timelineVisible = false),
                onOperationUpdated: (op) => setState(() => _operation = op),
              ),
            ),

          if (_crewVisible && _hasOperation && !_isTerminal)
            Positioned(
              top: 56, right: 0, bottom: 0,
              child: CrewSidePanel(
                operationId: _operation!.flightOperationId,
                apiService:  _apiService,
                onClose:     () => setState(() => _crewVisible = false),
              ),
            ),

          if (_weatherVisible && _hasOperation && !_isTerminal && _operationRoutes.isNotEmpty)
            Positioned(
              top: 56, right: 0, bottom: 0,
              child: WeatherSidePanel(
                operation:     _operation!,
                routes:        _operationRoutes,
                weatherPoints: _weatherPoints,
                alerts:        _weatherAlerts,
                center:        _weatherCenter,
                onClose:       () => setState(() => _weatherVisible = false),
              ),
            ),

          if (_weatherAlerts.isNotEmpty && _hasOperation && !_isTerminal)
            Positioned(
              top: 60, right: 16,
              child: _WeatherAlertBadge(alerts: _weatherAlerts),
            ),

          if (_hasOperation && !_isTerminal)
            Positioned(
              bottom: 32,
              left: 0, right: 0,
              child: Center(
                child: _BottomBar(
                  weatherVisible:  _weatherVisible,
                  timelineVisible: _timelineVisible,
                  crewVisible:     _crewVisible,
                  hasAlerts:       _weatherAlerts.isNotEmpty,
                  hasCritical:     _weatherAlerts.any(
                      (a) => a.level == WeatherAlertLevel.critical),
                  onWeatherToggle:  () => setState(() {
                    _weatherVisible = !_weatherVisible;
                    if (_weatherVisible) {
                      _crewVisible     = false;
                      _timelineVisible = false;
                    }
                  }),
                  onTimelineToggle: () => setState(() {
                    _timelineVisible = !_timelineVisible;
                    if (_timelineVisible) {
                      _crewVisible    = false;
                      _weatherVisible = false;
                    }
                  }),
                  onCrewToggle: () => setState(() {
                    _crewVisible = !_crewVisible;
                    if (_crewVisible) {
                      _timelineVisible = false;
                      _weatherVisible  = false;
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
            width: 16, height: 16,
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
    final icon  = isCompleted ? Icons.check_circle_outline : Icons.cancel_outlined;
    final label = isCompleted ? 'Operation completed' : 'Operation cancelled';

    return Container(
      color: colors.surface.withValues(alpha: 0.95),
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
      child: Row(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 10),
          Text(
            '${op.flightNumber ?? "—"} · ${op.departsCode ?? "—"} → ${op.arrivesCode ?? "—"} · $label',
            style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.w500),
          ),          const Spacer(),
         
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
          Icon(Icons.flight_outlined, color: colors.onSurfaceVariant, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'No operation assigned. Create a new one.',
              style: TextStyle(color: colors.onSurfaceVariant, fontSize: 13),
            ),
          ),         
        ],
      ),
    );
  }
}


class _BottomBar extends StatelessWidget {
  final bool weatherVisible;
  final bool timelineVisible;
  final bool crewVisible;
  final bool hasAlerts;
  final bool hasCritical;
  final VoidCallback onWeatherToggle;
  final VoidCallback onTimelineToggle;
  final VoidCallback onCrewToggle;

  const _BottomBar({
    required this.weatherVisible,
    required this.timelineVisible,
    required this.crewVisible,
    required this.hasAlerts,
    required this.hasCritical,
    required this.onWeatherToggle,
    required this.onTimelineToggle,
    required this.onCrewToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      decoration: BoxDecoration(
        color:        const Color(0xFF1E1E1E).withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(40),
        boxShadow: [
          BoxShadow(
            color:      Colors.black.withValues(alpha: 0.3),
            blurRadius: 20,
            offset:     const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _BarItem(
            icon:      weatherVisible ? Icons.cloud : Icons.cloud_outlined,
            label:     'Weather',
            isActive:  weatherVisible,
            badgeColor: hasAlerts
                ? (hasCritical ? Colors.red : Colors.orange)
                : null,
            onTap:     onWeatherToggle,
          ),
          const SizedBox(width: 8),
          _BarItem(
            icon:     timelineVisible ? Icons.timeline : Icons.timeline_outlined,
            label:    'Timeline',
            isActive: timelineVisible,
            onTap:    onTimelineToggle,
          ),
          const SizedBox(width: 8),
          _BarItem(
            icon:     crewVisible ? Icons.people : Icons.people_outline,
            label:    'Crew',
            isActive: crewVisible,
            onTap:    onCrewToggle,
          ),
        ],
      ),
    );
  }
}

class _BarItem extends StatefulWidget {
  final IconData    icon;
  final String      label;
  final bool        isActive;
  final Color?      badgeColor;
  final VoidCallback onTap;

  const _BarItem({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.onTap,
    this.badgeColor,
  });

  @override
  State<_BarItem> createState() => _BarItemState();
}

class _BarItemState extends State<_BarItem> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final activeColor = Colors.white;
    final inactiveColor = Colors.white.withValues(alpha: 0.5);
    final color = widget.isActive || _hovered ? activeColor : inactiveColor;

    return MouseRegion(
      cursor:  SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit:  (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color:        widget.isActive
                ? Colors.white.withValues(alpha: 0.12)
                : _hovered
                    ? Colors.white.withValues(alpha: 0.06)
                    : Colors.transparent,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(widget.icon, size: 22, color: color),
                  const SizedBox(height: 4),
                  Text(
                    widget.label,
                    style: TextStyle(
                      fontSize:   11,
                      color:      color,
                      fontWeight: widget.isActive
                          ? FontWeight.w600
                          : FontWeight.normal,
                    ),
                  ),
                ],
              ),
              if (widget.badgeColor != null)
                Positioned(
                  top:   -2,
                  right: -2,
                  child: Container(
                    width:  8,
                    height: 8,
                    decoration: BoxDecoration(
                      color:  widget.badgeColor,
                      shape:  BoxShape.circle,
                      border: Border.all(
                          color: const Color(0xFF1E1E1E), width: 1.5),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _WeatherAlertBadge extends StatelessWidget {
  final List<WeatherAlert> alerts;

  const _WeatherAlertBadge({required this.alerts});

  @override
  Widget build(BuildContext context) {
    final hasCritical = alerts.any((a) => a.level == WeatherAlertLevel.critical);
    final color       = hasCritical ? Colors.red : Colors.orange;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color:        color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
        border:       Border.all(color: color.withValues(alpha: 0.4)),
        boxShadow: [
          BoxShadow(
            color:      Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            hasCritical ? Icons.warning_rounded : Icons.warning_amber_outlined,
            size:  13,
            color: color,
          ),
          const SizedBox(width: 5),
          Text(
            '${alerts.length} weather alert${alerts.length > 1 ? 's' : ''}',
            style: TextStyle(
              fontSize:   11,
              fontWeight: FontWeight.w600,
              color:      color,
            ),
          ),
        ],
      ),
    );
  }
}


class _OperationInfoBar extends StatefulWidget {
  final FlightOperationModel op;
  final VoidCallback         onRefresh;

  const _OperationInfoBar({
    required this.op,
    required this.onRefresh,
  });

  @override
  State<_OperationInfoBar> createState() => _OperationInfoBarState();
}

class _OperationInfoBarState extends State<_OperationInfoBar> {
  bool     _expanded = false;
  Timer?   _ticker;
  DateTime _now = DateTime.now();

  @override
  void initState() {
    super.initState();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _now = DateTime.now());
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  DateTime? get _processStart {
    final op = widget.op;
    switch (op.statusName) {
      case 'Boarding':
        if (op.boardingStartTime != null && op.boardingEndTime == null)
          return _parseTime(op.boardingStartTime);
        if (op.baggageLoadingStartTime != null && op.baggageLoadingEndTime == null)
          return _parseTime(op.baggageLoadingStartTime);
        return null;
      case 'Baggage Loading':
        if (op.baggageLoadingStartTime != null && op.baggageLoadingEndTime == null)
          return _parseTime(op.baggageLoadingStartTime);
        return null;
      case 'Departed':
        return _parseDatetime(op.actualDepartureDatetime);
      default:
        return null;
    }
  }

  DateTime? _parseTime(String? t) {
    if (t == null) return null;
    try {
      final parts = t.split(':');
      final now   = DateTime.now();
      return DateTime(now.year, now.month, now.day,
          int.parse(parts[0]), int.parse(parts[1]),
          parts.length > 2 ? int.parse(parts[2]) : 0);
    } catch (_) { return null; }
  }

  DateTime? _parseDatetime(String? t) {
    if (t == null) return null;
    try { return DateTime.parse(t); } catch (_) { return null; }
  }

  String _elapsed(DateTime start) {
    final diff = DateTime.now().difference(start);
    if (diff.isNegative) return '00:00';
    final h = diff.inHours;
    final m = diff.inMinutes % 60;
    final s = diff.inSeconds % 60;
    if (h > 0) {
      return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
    }
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  Color _statusColor(String? status, ColorScheme colors) {
    switch (status) {
      case 'Waiting':   return colors.onSurfaceVariant;
      case 'Boarding':  return const Color(0xFF2196F3);
      case 'Baggage Loading': return const Color.fromARGB(255, 25, 68, 223);
      case 'Departed':  return const Color(0xFFFF9800);
      case 'Arrived':   return const Color(0xFF00BCD4);
      case 'Completed': return const Color(0xFF4CAF50);
      case 'Cancelled': return colors.error;
      default:          return colors.onSurfaceVariant;
    }
  }

  IconData _statusIcon(String? status) {
    switch (status) {
      case 'Waiting':         return Icons.schedule_outlined;
      case 'Boarding':        return Icons.door_sliding_outlined;
      case 'Baggage Loading': return Icons.luggage_outlined;
      case 'Departed':        return Icons.flight_takeoff_outlined;
      case 'Arrived':         return Icons.flight_land_outlined;
      case 'Completed':       return Icons.check_circle_outline;
      case 'Cancelled':       return Icons.cancel_outlined;
      default:                return Icons.info_outline;
    }
  }

  String _fmtTime(String? t) {
    if (t == null) return '—';
    try {
      final dt = DateTime.parse(t);
      final h = dt.hour.toString().padLeft(2, '0');
      final m = dt.minute.toString().padLeft(2, '0');
      return '$h:$m';
    } catch (_) {}
    return t.length >= 5 ? t.substring(0, 5) : t;
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final op     = widget.op;
    final sColor = _statusColor(op.statusName, colors);
    final start  = _processStart;

    return Container(
      decoration: BoxDecoration(
        color: colors.surface.withValues(alpha: 0.97),
        boxShadow: [
          BoxShadow(
            color:      Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset:     const Offset(0, 2),
          ),
        ],
        border: Border(
          bottom: BorderSide(color: sColor.withValues(alpha: 0.4), width: 2),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 12, 10),
              child: Row(
                children: [
                  Text(op.flightNumber ?? '—',
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontWeight: FontWeight.w700)),
                  const SizedBox(width: 10),
                  Text(
                    '${op.departsCode ?? "—"} → ${op.arrivesCode ?? "—"}',
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.copyWith(color: colors.onSurfaceVariant),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color:        sColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                      border:       Border.all(
                          color: sColor.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(_statusIcon(op.statusName),
                            size: 13, color: sColor),
                        const SizedBox(width: 5),
                        Text(op.statusName ?? '—',
                            style: TextStyle(
                                color:      sColor,
                                fontSize:   12,
                                fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                  if (start != null) ...[
                    const SizedBox(width: 10),
                    Icon(Icons.timer_outlined,
                        size: 13, color: colors.onSurfaceVariant),
                    const SizedBox(width: 4),
                    Text(_elapsed(start),
                        style: TextStyle(
                            fontSize:   12,
                            fontWeight: FontWeight.w600,
                            color:      sColor)),
                  ],
                  const Spacer(),
                  IconButton(
                    icon:          const Icon(Icons.refresh_outlined, size: 18),
                    onPressed:     widget.onRefresh,
                    tooltip:       'Refresh',
                    visualDensity: VisualDensity.compact,
                  ),
                  Icon(
                    _expanded
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    color: colors.onSurfaceVariant,
                  ),
                ],
              ),
            ),
          ),
          if (_expanded) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              child: Wrap(
                spacing: 32, runSpacing: 8,
                children: [
                  _infoItem(context, Icons.airplanemode_active_outlined,
                      'Aircraft', op.aircraftModel ?? '—', colors),
                  _infoItem(context, Icons.door_sliding_outlined, 'Gate',
                      op.gateCode != null ? 'Gate ${op.gateCode}' : '—', colors),
                  _infoItem(context, Icons.flight_takeoff_outlined,
                      'Actual Dep', _fmtTime(op.actualDepartureDatetime), colors),
                  _infoItem(context, Icons.flight_land_outlined,
                      'Actual Arr', _fmtTime(op.actualArrivalDatetime), colors),
                  _infoItem(context, Icons.people_outline, 'Boarding',
                      '${_fmtTime(op.boardingStartTime)} – ${_fmtTime(op.boardingEndTime)}',
                      colors),
                  _infoItem(context, Icons.luggage_outlined, 'Baggage',
                      '${_fmtTime(op.baggageLoadingStartTime)} – ${_fmtTime(op.baggageLoadingEndTime)}',
                      colors),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _infoItem(BuildContext context, IconData icon, String label,
      String value, ColorScheme colors) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: colors.onSurfaceVariant),
        const SizedBox(width: 6),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: TextStyle(
                    fontSize:   10,
                    color:      colors.onSurfaceVariant,
                    fontWeight: FontWeight.w500)),
            Text(value,
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(fontWeight: FontWeight.w600)),
          ],
        ),
      ],
    );
  }
}