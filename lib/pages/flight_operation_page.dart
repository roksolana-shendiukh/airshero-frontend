import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import '../models/flight_operation_model.dart';
import '../services/auth_service.dart';
import '../services/flight_operation_api_service.dart';
import '../widgets/responsive_layout.dart';
import '../widgets/flight_operation/flight_map.dart';
import '../widgets/flight_operation/create_flight_operation_form.dart';
import '../widgets/flight_operation/crew_panel.dart';
import '../widgets/custom/custom_button.dart';
import '../widgets/flight_operation/timeline_panel.dart';


class FlightOperationPage extends StatefulWidget {
  const FlightOperationPage({super.key});

  @override
  State<FlightOperationPage> createState() => _FlightOperationPageState();
}

class _FlightOperationPageState extends State<FlightOperationPage> {
  late final FlightOperationApiService _apiService;
  FlightOperationModel? _operation;
  bool _isLoading   = true;
  bool _crewVisible     = false;
  bool _timelineVisible = false;

  @override
  void initState() {
    super.initState();
    _apiService = FlightOperationApiService(context.read<AuthService>());
    _loadOperation();
  }

  Future<void> _loadOperation() async {
    final operationId = context.read<AuthService>().currentUser?.operationId;
    debugPrint('[OP] operationId from claims: $operationId');
    if (operationId == null) {
      setState(() => _isLoading = false);
      return;
    }
    setState(() => _isLoading = true);
    final op = await _apiService.getFlightOperation(operationId);
    if (mounted) {
      if (op?.statusName == 'Completed' || op?.statusName == 'Cancelled') {
        await context.read<AuthService>().refreshSession();
      }
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
        insetPadding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
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

  @override
  Widget build(BuildContext context) {
    return ResponsiveLayout(
      body: Stack(
        children: [
          Positioned.fill(child: FlightMap()),

          Positioned(
            top: 0, left: 0, right: 0,
            child: _isLoading
                ? _loadingBar(context)
                : _operation == null || 
                  _operation!.statusName == 'Completed' || 
                  _operation!.statusName == 'Cancelled'
                    ? _noOperationBar(context)
                    : _OperationInfoBar(
                        op:               _operation!,
                        onRefresh:        _loadOperation,
                        crewVisible:      _crewVisible,
                        onCrewToggle:     () =>
                            setState(() => _crewVisible = !_crewVisible),
                        timelineVisible:  _timelineVisible,
                        onTimelineToggle: () =>
                            setState(() => _timelineVisible = !_timelineVisible),
                      ),
          ),

          if (_timelineVisible && _operation != null)
            Positioned(
              top: 56, left: 0, bottom: 0,
              child: TimelinePanel(
                operation:          _operation!,
                apiService:         _apiService,
                onClose: () => setState(() => _timelineVisible = false),
                onOperationUpdated: (op) => setState(() => _operation = op),
              ),
            ),

          if (_crewVisible && _operation != null)
            Positioned(
              top: 56, right: 0, bottom: 0,
              child: CrewSidePanel(
                operationId: _operation!.flightOperationId,
                apiService:  _apiService,
                onClose: () => setState(() => _crewVisible = false),
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
          CustomButton(
            label: 'New Operation',
            icon: Icons.add,
            isIconAfterLabel: false,
            verticalPadding: 10,
            horizontalPadding: 14,
            onPressed: _openCreateForm,
          ),
        ],
      ),
    );
  }
}

class _OperationInfoBar extends StatefulWidget {
  final FlightOperationModel op;
  final VoidCallback         onRefresh;
  final bool                 crewVisible;
  final VoidCallback         onCrewToggle;
  final bool                 timelineVisible;
  final VoidCallback         onTimelineToggle;

  const _OperationInfoBar({
    required this.op,
    required this.onRefresh,
    required this.crewVisible,
    required this.onCrewToggle,
    required this.timelineVisible,
    required this.onTimelineToggle,
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
        // Якщо boarding ще не завершений — від boarding start
        if (op.boardingStartTime != null && op.boardingEndTime == null) {
          return _parseTime(op.boardingStartTime);
        }
        // Якщо boarding завершений але baggage ще йде
        if (op.baggageLoadingStartTime != null && op.baggageLoadingEndTime == null) {
          return _parseTime(op.baggageLoadingStartTime);
        }
        return null;
      case 'Departed':
        return _parseDatetime(op.actualDepartureDatetime);
      case 'Arrived':
        return _parseDatetime(op.actualArrivalDatetime);
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
    final diff = _now.difference(start);
    if (diff.isNegative) return '00:00';
    final h = diff.inHours;
    final m = diff.inMinutes % 60;
    final s = diff.inSeconds % 60;
    if (h > 0) {
      return '${h.toString().padLeft(2,'0')}:${m.toString().padLeft(2,'0')}:${s.toString().padLeft(2,'0')}';
    }
    return '${m.toString().padLeft(2,'0')}:${s.toString().padLeft(2,'0')}';
  }

  Color _statusColor(String? status, ColorScheme colors) {
    switch (status) {
      case 'Waiting':   return colors.onSurfaceVariant;
      case 'Boarding':  return const Color(0xFF2196F3);
      case 'Departed':  return const Color(0xFFFF9800);
      case 'Arrived':   return const Color(0xFF00BCD4);
      case 'Completed': return const Color(0xFF4CAF50);
      case 'Cancelled': return colors.error;
      default:          return colors.onSurfaceVariant;
    }
  }

  IconData _statusIcon(String? status) {
    switch (status) {
      case 'Waiting':   return Icons.schedule_outlined;
      case 'Boarding':  return Icons.door_sliding_outlined;
      case 'Departed':  return Icons.flight_takeoff_outlined;
      case 'Arrived':   return Icons.flight_land_outlined;
      case 'Completed': return Icons.check_circle_outline;
      case 'Cancelled': return Icons.cancel_outlined;
      default:          return Icons.info_outline;
    }
  }

  String _fmtTime(String? t) {
    if (t == null) return '—';
    return t.length >= 5 ? t.substring(0, 5) : t;
  }

  @override
  Widget build(BuildContext context) {
    final colors  = Theme.of(context).colorScheme;
    final op      = widget.op;
    final sColor  = _statusColor(op.statusName, colors);
    final start   = _processStart;

    return Container(
      decoration: BoxDecoration(
        color: colors.surface.withValues(alpha: 0.97),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
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
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: colors.onSurfaceVariant),
                  ),
                  const SizedBox(width: 12),

                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: sColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: sColor.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(_statusIcon(op.statusName),
                            size: 13, color: sColor),
                        const SizedBox(width: 5),
                        Text(op.statusName ?? '—',
                            style: TextStyle(
                                color: sColor,
                                fontSize: 12,
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
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: sColor)),
                  ],

                  const Spacer(),

                  CustomButton(
                    label: 'Timeline',
                    icon: widget.timelineVisible
                        ? Icons.timeline
                        : Icons.timeline_outlined,
                    isIconAfterLabel: false,
                    verticalPadding: 8,
                    horizontalPadding: 12,
                    onPressed: widget.onTimelineToggle,
                  ),
                  const SizedBox(width: 8),

                  CustomButton(
                    label: 'Crew',
                    icon: widget.crewVisible
                        ? Icons.people
                        : Icons.people_outline,
                    isIconAfterLabel: false,
                    verticalPadding: 8,
                    horizontalPadding: 12,
                    onPressed: widget.onCrewToggle,
                  ),
                  const SizedBox(width: 8),

                  IconButton(
                    icon: const Icon(Icons.refresh_outlined, size: 18),
                    onPressed: widget.onRefresh,
                    tooltip: 'Refresh',
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
                spacing: 32,
                runSpacing: 8,
                children: [
                  _infoItem(context, Icons.airplanemode_active_outlined,
                      'Aircraft', op.aircraftModel ?? '—', colors),
                  _infoItem(context, Icons.door_sliding_outlined, 'Gate',
                      op.gateCode != null ? 'Gate ${op.gateCode}' : '—',
                      colors),
                  _infoItem(context, Icons.flight_takeoff_outlined,
                      'Actual Dep',
                      _fmtTime(op.actualDepartureDatetime), colors),
                  _infoItem(context, Icons.flight_land_outlined,
                      'Actual Arr',
                      _fmtTime(op.actualArrivalDatetime), colors),
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
                    fontSize: 10,
                    color: colors.onSurfaceVariant,
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


