import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

class CheckInStatusBar extends StatefulWidget {
  final Map<String, dynamic> flight;

  const CheckInStatusBar({super.key, required this.flight});

  @override
  State<CheckInStatusBar> createState() => _CheckInStatusBarState();
}

class _CheckInStatusBarState extends State<CheckInStatusBar> {
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

  String get _elapsedLabel {
    final boardingStartTime =
        widget.flight['boardingStartTime'] as String?;
    if (boardingStartTime == null) return '00:00';
    try {
      DateTime? start = DateTime.tryParse(boardingStartTime);
      if (start == null) {
        final parts = boardingStartTime.split(':');
        final now   = DateTime.now();
        start = DateTime(
          now.year, now.month, now.day,
          int.parse(parts[0]),
          int.parse(parts[1]),
          parts.length > 2
              ? int.parse(parts[2].split('.').first)
              : 0,
        );
      }
      final diff = _now.difference(start);
      final h    = diff.inHours;
      final m    = diff.inMinutes % 60;
      final s    = diff.inSeconds % 60;
      if (h > 0) {
        return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
      }
      return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
    } catch (_) {
      return '00:00';
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors       = Theme.of(context).colorScheme;
    final flightNumber = widget.flight['flightNumber']   as String? ?? '—';
    final depAirport   = widget.flight['departsAirport'] as String? ?? '—';
    final arrAirport   = widget.flight['arrivesAirport'] as String? ?? '—';
    final gate         = widget.flight['gateCode']       as String? ?? '—';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      decoration: BoxDecoration(
        color: colors.surfaceContainerHigh,
        border: Border(
          bottom: BorderSide(
            color: colors.outlineVariant.withValues(alpha: 0.5),
          ),
        ),
      ),
      child: Row(
        children: [
          // Status dot
          Container(
            width:  7,
            height: 7,
            decoration: BoxDecoration(
              color:  colors.primary,
              shape:  BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),

          // Boarding label
          Text(
            'Boarding',
            style: TextStyle(
              fontSize:   12,
              fontWeight: FontWeight.w600,
              color:      colors.primary,
            ),
          ),

          const SizedBox(width: 12),

          // Divider
          Container(
            width:  1,
            height: 14,
            color:  colors.outlineVariant,
          ),

          const SizedBox(width: 12),

          // Flight info
          Text(
            '$flightNumber · $depAirport → $arrAirport · Gate $gate · ${_formatTime(widget.flight['departsDatetime'] as String?)}',
            style: TextStyle(
              fontSize: 12,
              color:    colors.onSurface,
            ),
          ),

          const SizedBox(width: 16),

          Row(
            children: [
              Icon(Icons.timer_outlined,
                  size: 13, color: colors.onSurfaceVariant),
              const SizedBox(width: 4),
              Text(
                _elapsedLabel,
                style: TextStyle(
                  fontSize:   12,
                  fontWeight: FontWeight.w600,
                  color:      colors.onSurface,
                ),
              ),
            ],
          ),          
        ],
      ),
    );
  }

  String _formatTime(String? datetime) {
    if (datetime == null) return '—';
    try {
      return DateFormat('HH:mm').format(DateTime.parse(datetime));
    } catch (_) {
      return '—';
    }
  }
}