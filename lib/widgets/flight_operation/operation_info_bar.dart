import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import '../../models/flight_operation_model.dart';
import '../../services/auth_service.dart';
import '../../services/flight_operation_api_service.dart';
import 'gate_picker_dialog.dart';

class OperationInfoBar extends StatefulWidget {
  final FlightOperationModel op;
  final VoidCallback onRefresh;

  const OperationInfoBar({
    super.key,
    required this.op,
    required this.onRefresh,
  });

  @override
  State<OperationInfoBar> createState() => _OperationInfoBarState();
}

class _OperationInfoBarState extends State<OperationInfoBar> {
  bool _expanded = false;
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
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
        if (op.boardingStartTime != null && op.boardingEndTime == null) {
          return _parseTime(op.boardingStartTime);
        }
        if (op.baggageLoadingStartTime != null &&
            op.baggageLoadingEndTime == null) {
          return _parseTime(op.baggageLoadingStartTime);
        }
        return null;
      case 'Baggage Loading':
        if (op.baggageLoadingStartTime != null &&
            op.baggageLoadingEndTime == null) {
          return _parseTime(op.baggageLoadingStartTime);
        }
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
      final now = DateTime.now();
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

  DateTime? _parseDatetime(String? t) {
    if (t == null) return null;
    try {
      return DateTime.parse(t);
    } catch (_) {
      return null;
    }
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
      case 'Waiting':         return colors.onSurfaceVariant;
      case 'Boarding':        return const Color(0xFF2196F3);
      case 'Baggage Loading': return const Color.fromARGB(255, 25, 68, 223);
      case 'Departed':        return const Color(0xFFFF9800);
      case 'Arrived':         return const Color(0xFF00BCD4);
      case 'Completed':       return const Color(0xFF4CAF50);
      case 'Cancelled':       return colors.error;
      default:                return colors.onSurfaceVariant;
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

  void _openGatePicker(BuildContext context) async {
    final api = FlightOperationApiService(context.read<AuthService>());
    final bool? updated = await showDialog<bool>(
      context: context,
      builder: (context) => GatePickerDialog(
        operationId: widget.op.flightOperationId,
        api: api,
      ),
    );
    if (updated == true) widget.onRefresh();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final op = widget.op;
    final sColor = _statusColor(op.statusName, colors);
    final start = _processStart;

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
          bottom:
              BorderSide(color: sColor.withValues(alpha: 0.4), width: 2),
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
                  Text(
                    op.flightNumber ?? '—',
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    '${op.departsCode ?? "—"} → ${op.arrivesCode ?? "—"}',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: colors.onSurfaceVariant,
                        ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: sColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                      border:
                          Border.all(color: sColor.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(_statusIcon(op.statusName),
                            size: 13, color: sColor),
                        const SizedBox(width: 5),
                        Text(
                          op.statusName ?? '—',
                          style: TextStyle(
                            color: sColor,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (start != null) ...[
                    const SizedBox(width: 10),
                    Icon(Icons.timer_outlined,
                        size: 13, color: colors.onSurfaceVariant),
                    const SizedBox(width: 4),
                    Text(
                      _elapsed(start),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: sColor,
                      ),
                    ),
                  ],
                  const Spacer(),
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
                  _infoItem(
                      context,
                      Icons.flight_takeoff_outlined,
                      'Actual Dep',
                      _fmtTime(op.actualDepartureDatetime),
                      colors),
                  _infoItem(
                      context,
                      Icons.flight_land_outlined,
                      'Actual Arr',
                      _fmtTime(op.actualArrivalDatetime),
                      colors),
                  _infoItem(
                      context,
                      Icons.people_outline,
                      'Boarding',
                      '${_fmtTime(op.boardingStartTime)} – ${_fmtTime(op.boardingEndTime)}',
                      colors),
                  _infoItem(
                      context,
                      Icons.luggage_outlined,
                      'Baggage',
                      '${_fmtTime(op.baggageLoadingStartTime)} – ${_fmtTime(op.baggageLoadingEndTime)}',
                      colors),
                  _infoItem(
                    context,
                    Icons.door_sliding_outlined,
                    'Gate',
                    op.gateCode != null
                        ? 'Gate ${op.gateCode}'
                        : 'Select Gate',
                    colors,
                    onEdit: op.boardingStartTime == null
                        ? () => _openGatePicker(context)
                        : null,
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _infoItem(
    BuildContext context,
    IconData icon,
    String label,
    String value,
    ColorScheme colors, {
    VoidCallback? onEdit,
  }) {
    return InkWell(
      onTap: onEdit,
      borderRadius: BorderRadius.circular(4),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 14,
              color: onEdit != null
                  ? colors.primary
                  : colors.onSurfaceVariant,
            ),
            const SizedBox(width: 6),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 10,
                    color: colors.onSurfaceVariant,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  value,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: onEdit != null ? colors.primary : null,
                      ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}