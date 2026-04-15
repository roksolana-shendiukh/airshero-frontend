import 'dart:async';
import 'package:flutter/material.dart';

class CheckInStatusBar extends StatefulWidget {
  final Map<String, dynamic> flight;
  final VoidCallback? onBackToFlights;

  const CheckInStatusBar({super.key, required this.flight, this.onBackToFlights,});

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

  bool get _isInternational {
    final depCountry = widget.flight['departsCountryId'];
    final arrCountry = widget.flight['arrivesCountryId'];
    if (depCountry == null || arrCountry == null) return true;
    return depCountry != arrCountry;
  }

  int get _closeMinutes => _isInternational ? 60 : 40;

  DateTime? get _departsAt {
    final s = widget.flight['departsDatetime'] as String?;
    if (s == null) return null;
    try { return DateTime.parse(s); } catch (_) { return null; }
  }

  bool get _shouldWarn {
    final d = _departsAt;
    if (d == null) return false;
    return d.difference(_now).inMinutes <= _closeMinutes;
  }

  String get _countdownLabel {
    final d = _departsAt;
    if (d == null) return '—';
    final diff = d.difference(_now);
    if (diff.isNegative) return 'Departed';
    final h = diff.inHours;
    final m = diff.inMinutes % 60;
    final s = diff.inSeconds % 60;
    if (h > 0) return '${h}h ${m.toString().padLeft(2, '0')}m';
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final colors       = Theme.of(context).colorScheme;
    final flightNumber = widget.flight['flightNumber']   as String? ?? '—';
    final depAirport   = widget.flight['departsAirport'] as String? ?? '—';
    final arrAirport   = widget.flight['arrivesAirport'] as String? ?? '—';
    final gate         = widget.flight['gateCode']       as String? ?? '—';
    final sColor       = const Color(0xFF2196F3);
    final warnColor    = Colors.orange;
    final timerColor   = _shouldWarn ? warnColor : sColor;

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
          bottom: BorderSide(
            color: timerColor.withValues(alpha: 0.4),
            width: 2,
          ),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_shouldWarn)
            Container(
              width:   double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              color:   warnColor.withValues(alpha: 0.08),
              child: Row(
                children: [
                  Icon(Icons.warning_amber_outlined,
                      size: 14, color: warnColor),
                  const SizedBox(width: 6),
                  Text(
                    'Close boarding soon — less than $_closeMinutes min to departure',
                    style: TextStyle(
                      fontSize:   12,
                      fontWeight: FontWeight.w500,
                      color:      warnColor,
                    ),
                  ),
                ],
              ),
            ),

          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 12, 10),
            child: Row(
              children: [
                Icon(Icons.flight_takeoff_outlined,
                    size: 16, color: colors.onSurfaceVariant),
                const SizedBox(width: 10),

                Text(
                  flightNumber,
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(width: 10),

                Text(
                  '$depAirport → $arrAirport',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                ),
                const SizedBox(width: 8),

                Text(
                  '· Gate $gate',
                  style: TextStyle(
                      fontSize: 13, color: colors.onSurfaceVariant),
                ),
                const SizedBox(width: 12),

                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color:        sColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: sColor.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.door_sliding_outlined,
                          size: 13, color: sColor),
                      const SizedBox(width: 5),
                      Text(
                        'Boarding',
                        style: TextStyle(
                          color:      sColor,
                          fontSize:   12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),     

                const Spacer(),
                if (widget.onBackToFlights != null)
                  TextButton.icon(
                    onPressed: widget.onBackToFlights,
                    icon:  const Icon(Icons.people_outline, size: 15),
                    label: const Text('Passengers', style: TextStyle(fontSize: 13)),
                    style: TextButton.styleFrom(
                      padding:       const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      minimumSize:   Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),



              ],
            ),
          ),
        ],
      ),
    );
  }
}