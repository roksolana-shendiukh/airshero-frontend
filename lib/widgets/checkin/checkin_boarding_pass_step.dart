import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class CheckInBoardingPassStep extends StatelessWidget {
  final String    ticketNumber;
  final String    passengerName;
  final String    flightNumber;
  final String    flightClass;
  final String    seat;
  final DateTime  departDate;
  final int       bagCount;
  final String    departsAirport;
  final String    arrivesAirport;
  final String    departsTime;
  final String    arrivesTime;
  final String    gate;
  final VoidCallback onNewPassenger;
  final bool showActions;

  const CheckInBoardingPassStep({
    super.key,
    required this.ticketNumber,
    required this.passengerName,
    required this.flightNumber,
    required this.flightClass,
    required this.seat,
    required this.departDate,
    required this.bagCount,
    required this.departsAirport,
    required this.arrivesAirport,
    required this.departsTime,
    required this.arrivesTime,
    required this.gate,
    required this.onNewPassenger,
    this.showActions = true,
  });

  String _fmt(String raw) {
    try {
      return DateFormat('HH:mm').format(DateTime.parse(raw));
    } catch (_) {
      return raw.length >= 5 ? raw.substring(0, 5) : raw;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF1E2330) : Colors.white;
    final stripeBg = isDark ? const Color(0xFF252B3B) : const Color(0xFFF5F7FA);

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      child: Column(
        children: [
          Container(
            decoration: BoxDecoration(
              color:        cardBg,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color:      Colors.black.withValues(alpha: isDark ? 0.35 : 0.10),
                  blurRadius: 20,
                  offset:     const Offset(0, 6),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  Container(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 14),
                    color: colors.primary,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'BOARDING PASS',
                              style: TextStyle(
                                color:         colors.onPrimary.withValues(alpha: 0.7),
                                fontSize:      10,
                                fontWeight:    FontWeight.w600,
                                letterSpacing: 1.5,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              ticketNumber,
                              style: TextStyle(
                                color:         colors.onPrimary,
                                fontSize:      20,
                                fontWeight:    FontWeight.w800,
                                letterSpacing: 2,
                              ),
                            ),
                          ],
                        ),                        
                      ],
                    ),
                  ),

                  Container(
                    padding: const EdgeInsets.fromLTRB(20, 14, 20, 14),
                    color: cardBg,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'NAME',
                          style: TextStyle(
                            fontSize:      10,
                            fontWeight:    FontWeight.w600,
                            letterSpacing: 1.2,
                            color:         colors.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          passengerName,
                          style: TextStyle(
                            fontSize:   18,
                            fontWeight: FontWeight.w700,
                            color:      colors.onSurface,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // ── ROUTE ──
                  Container(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
                    color: stripeBg,
                    child: Row(
                      children: [
                        // From
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'FROM',
                              style: TextStyle(
                                fontSize:      10,
                                fontWeight:    FontWeight.w600,
                                letterSpacing: 1.2,
                                color:         colors.onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              departsAirport,
                              style: TextStyle(
                                fontSize:      30,
                                fontWeight:    FontWeight.w800,
                                color:         colors.primary,
                                letterSpacing: 2,
                              ),
                            ),
                            Text(
                              _fmt(departsTime),
                              style: TextStyle(
                                fontSize:   13,
                                fontWeight: FontWeight.w500,
                                color:      colors.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),

                        // Arrow
                        Expanded(
                          child: Column(
                            children: [
                              Icon(Icons.flight, color: colors.primary.withValues(alpha: 0.4), size: 22),
                            ],
                          ),
                        ),

                        // To
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              'TO',
                              style: TextStyle(
                                fontSize:      10,
                                fontWeight:    FontWeight.w600,
                                letterSpacing: 1.2,
                                color:         colors.onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              arrivesAirport,
                              style: TextStyle(
                                fontSize:      30,
                                fontWeight:    FontWeight.w800,
                                color:         colors.primary,
                                letterSpacing: 2,
                              ),
                            ),
                            Text(
                              _fmt(arrivesTime),
                              style: TextStyle(
                                fontSize:   13,
                                fontWeight: FontWeight.w500,
                                color:      colors.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // ── FLIGHT INFO ROW ──
                  Container(
                    padding: const EdgeInsets.fromLTRB(20, 14, 20, 14),
                    color: cardBg,
                    child: Row(
                      children: [
                        _InfoCell(label: 'FLIGHT',    value: flightNumber, colors: colors),
                        _InfoCell(label: 'DATE',      value: DateFormat('dd MMM yyyy').format(departDate), colors: colors),
                        _InfoCell(label: 'GATE',      value: gate.isNotEmpty ? gate : '—', colors: colors),
                      ],
                    ),
                  ),

                  // ── TEAR LINE ──
                  _TearLine(colors: colors, isDark: isDark),

                  // ── SEAT + BAGS ──
                  Container(
                    padding: const EdgeInsets.fromLTRB(20, 14, 20, 18),
                    color: cardBg,
                    child: Row(
                      children: [
                        _InfoCell(
                          label:   'SEAT',
                          value:   seat,
                          large:   true,
                          colors:  colors,
                        ),
                        _InfoCell(
                          label:  'CLASS',
                          value:  flightClass,
                          colors: colors,
                        ),
                        _InfoCell(
                          label:  'BAGS',
                          value:  '$bagCount',
                          colors: colors,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          if (showActions) ...[
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: onNewPassenger,
                icon:  const Icon(Icons.person_add_outlined, size: 18),
                label: const Text('Check In Next Passenger'),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape:   RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _InfoCell extends StatelessWidget {
  final String      label;
  final String      value;
  final bool        large;
  final ColorScheme colors;

  const _InfoCell({
    required this.label,
    required this.value,
    required this.colors,
    this.large = false,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize:      10,
              fontWeight:    FontWeight.w600,
              letterSpacing: 1.2,
              color:         colors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            value,
            style: TextStyle(
              fontSize:      large ? 26 : 14,
              fontWeight:    FontWeight.w700,
              color:         large ? colors.primary : colors.onSurface,
              letterSpacing: large ? 1.5 : 0,
            ),
          ),
        ],
      ),
    );
  }
}

class _TearLine extends StatelessWidget {
  final ColorScheme colors;
  final bool        isDark;
  const _TearLine({required this.colors, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final bg      = isDark ? const Color(0xFF1E2330) : Colors.white;
    final outerBg = isDark ? const Color(0xFF141822) : const Color(0xFFEEF1F6);

    return Container(
      color: outerBg,
      child: Row(
        children: [
          Container(
            width: 18, height: 18,
            decoration: BoxDecoration(
              color: outerBg,
              borderRadius: const BorderRadius.only(
                topRight:    Radius.circular(9),
                bottomRight: Radius.circular(9),
              ),
            ),
          ),
          Expanded(
            child: Container(
              height: 18,
              color: bg,
              child: CustomPaint(
                painter: _DashPainter(color: colors.outline.withValues(alpha: 0.25)),
              ),
            ),
          ),
          Container(
            width: 18, height: 18,
            decoration: BoxDecoration(
              color: outerBg,
              borderRadius: const BorderRadius.only(
                topLeft:    Radius.circular(9),
                bottomLeft: Radius.circular(9),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DashPainter extends CustomPainter {
  final Color color;
  const _DashPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()..color = color..strokeWidth = 1.5..style = PaintingStyle.stroke;
    double x = 0;
    final y = size.height / 2;
    while (x < size.width) {
      canvas.drawLine(Offset(x, y), Offset(x + 5, y), p);
      x += 9;
    }
  }

  @override
  bool shouldRepaint(_DashPainter o) => o.color != color;
}