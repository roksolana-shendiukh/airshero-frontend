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
  final VoidCallback onNewPassenger;

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
    required this.onNewPassenger,
  });

  String _formatTime(String datetime) {
    try {
      return DateFormat('HH:mm').format(DateTime.parse(datetime));
    } catch (_) {
      return datetime.length >= 5 ? datetime.substring(0, 5) : datetime;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Success header
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width:  36,
                height: 36,
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check_rounded,
                    color: Colors.green, size: 20),
              ),
              const SizedBox(width: 10),
              const Text(
                'Check-In Complete',
                style: TextStyle(
                  fontSize:   16,
                  fontWeight: FontWeight.w700,
                  color:      Colors.green,
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Boarding pass card
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color:      Colors.black.withValues(alpha: isDark ? 0.4 : 0.12),
                  blurRadius: 24,
                  offset:     const Offset(0, 8),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Column(
                children: [
                  // Header — route + flight info
                  _BoardingPassHeader(
                    flightNumber:   flightNumber,
                    flightClass:    flightClass,
                    departsAirport: departsAirport,
                    arrivesAirport: arrivesAirport,
                    departsTime:    _formatTime(departsTime),
                    departDate:     departDate,
                    colors:         colors,
                    isDark:         isDark,
                  ),

                  // Body — passenger + seat info
                  _BoardingPassBody(
                    passengerName: passengerName,
                    seat:          seat,
                    flightClass:   flightClass,
                    bagCount:      bagCount,
                    colors:        colors,
                    isDark:        isDark,
                  ),

                  // Tear line
                  _TearLine(colors: colors, isDark: isDark),

                  // Footer — ticket number
                  _BoardingPassFooter(
                    ticketNumber: ticketNumber,
                    colors:       colors,
                    isDark:       isDark,
                  ),
                ],
              ),
            ),
          ),

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
      ),
    );
  }
}

class _BoardingPassHeader extends StatelessWidget {
  final String      flightNumber;
  final String      flightClass;
  final String      departsAirport;
  final String      arrivesAirport;
  final String      departsTime;
  final DateTime    departDate;
  final ColorScheme colors;
  final bool        isDark;

  const _BoardingPassHeader({
    required this.flightNumber,
    required this.flightClass,
    required this.departsAirport,
    required this.arrivesAirport,
    required this.departsTime,
    required this.departDate,
    required this.colors,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width:   double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 20),
      decoration: BoxDecoration(
        color: colors.primary,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top row — flight number + class badge
          Row(
            children: [
              Text(
                flightNumber,
                style: TextStyle(
                  color:         colors.onPrimary,
                  fontSize:      22,
                  fontWeight:    FontWeight.w800,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color:        colors.onPrimary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  flightClass.toUpperCase(),
                  style: TextStyle(
                    color:         colors.onPrimary.withValues(alpha: 0.85),
                    fontSize:      10,
                    fontWeight:    FontWeight.w600,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
              const Spacer(),
              // Date
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    DateFormat('dd MMM').format(departDate).toUpperCase(),
                    style: TextStyle(
                      color:         colors.onPrimary,
                      fontSize:      16,
                      fontWeight:    FontWeight.w700,
                      letterSpacing: 0.5,
                    ),
                  ),
                  Text(
                    DateFormat('yyyy').format(departDate),
                    style: TextStyle(
                      color:    colors.onPrimary.withValues(alpha: 0.6),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Route row
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Departs
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    departsAirport,
                    style: TextStyle(
                      color:         colors.onPrimary,
                      fontSize:      28,
                      fontWeight:    FontWeight.w800,
                      letterSpacing: 2,
                    ),
                  ),
                  Text(
                    departsTime,
                    style: TextStyle(
                      color:      colors.onPrimary.withValues(alpha: 0.7),
                      fontSize:   13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),

              // Flight path
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Row(
                    children: [
                      Expanded(
                        child: Container(
                          height: 1,
                          color: colors.onPrimary.withValues(alpha: 0.3),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Icon(
                          Icons.flight,
                          color: colors.onPrimary.withValues(alpha: 0.8),
                          size:  18,
                        ),
                      ),
                      Expanded(
                        child: Container(
                          height: 1,
                          color: colors.onPrimary.withValues(alpha: 0.3),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Arrives
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    arrivesAirport,
                    style: TextStyle(
                      color:         colors.onPrimary,
                      fontSize:      28,
                      fontWeight:    FontWeight.w800,
                      letterSpacing: 2,
                    ),
                  ),
                  Text(
                    '—',
                    style: TextStyle(
                      color:    colors.onPrimary.withValues(alpha: 0.7),
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BoardingPassBody extends StatelessWidget {
  final String      passengerName;
  final String      seat;
  final String      flightClass;
  final int         bagCount;
  final ColorScheme colors;
  final bool        isDark;

  const _BoardingPassBody({
    required this.passengerName,
    required this.seat,
    required this.flightClass,
    required this.bagCount,
    required this.colors,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final bg = isDark ? const Color(0xFF242938) : Colors.white;

    return Container(
      width:   double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 20),
      color:   bg,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'PASSENGER',
            style: TextStyle(
              fontSize:      10,
              fontWeight:    FontWeight.w600,
              letterSpacing: 1.2,
              color:         colors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            passengerName,
            style: TextStyle(
              fontSize:   20,
              fontWeight: FontWeight.w700,
              color:      colors.onSurface,
            ),
          ),

          const SizedBox(height: 20),

          Row(
            children: [
              Expanded(
                child: _PassInfo(
                  label:  'SEAT',
                  value:  seat,
                  large:  true,
                  colors: colors,
                ),
              ),
              Expanded(
                child: _PassInfo(
                  label:  'CLASS',
                  value:  flightClass,
                  colors: colors,
                ),
              ),
              Expanded(
                child: _PassInfo(
                  label:  'BAGS',
                  value:  '$bagCount',
                  colors: colors,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PassInfo extends StatelessWidget {
  final String      label;
  final String      value;
  final bool        large;
  final ColorScheme colors;

  const _PassInfo({
    required this.label,
    required this.value,
    required this.colors,
    this.large = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
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
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize:      large ? 28 : 16,
            fontWeight:    FontWeight.w800,
            color:         large ? colors.primary : colors.onSurface,
            letterSpacing: large ? 2 : 0,
          ),
        ),
      ],
    );
  }
}

class _TearLine extends StatelessWidget {
  final ColorScheme colors;
  final bool        isDark;

  const _TearLine({required this.colors, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final bg      = isDark ? const Color(0xFF242938) : Colors.white;
    final outerBg = isDark
        ? const Color(0xFF1A1F2E)
        : const Color(0xFFF0F4F8);

    return Container(
      color: outerBg,
      child: Row(
        children: [
          Container(
            width:  20,
            height: 20,
            decoration: BoxDecoration(
              color:        outerBg,
              borderRadius: const BorderRadius.only(
                topRight:    Radius.circular(10),
                bottomRight: Radius.circular(10),
              ),
            ),
          ),
          Expanded(
            child: Container(
              height: 20,
              color:  bg,
              child: CustomPaint(
                painter: _DashedLinePainter(
                  color: colors.outline.withValues(alpha: 0.3),
                ),
              ),
            ),
          ),
          Container(
            width:  20,
            height: 20,
            decoration: BoxDecoration(
              color:        outerBg,
              borderRadius: const BorderRadius.only(
                topLeft:    Radius.circular(10),
                bottomLeft: Radius.circular(10),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DashedLinePainter extends CustomPainter {
  final Color color;
  const _DashedLinePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color       = color
      ..strokeWidth = 1.5
      ..style       = PaintingStyle.stroke;

    const dashW = 6.0;
    const gapW  = 4.0;
    final y     = size.height / 2;
    double x    = 0;

    while (x < size.width) {
      canvas.drawLine(Offset(x, y), Offset(x + dashW, y), paint);
      x += dashW + gapW;
    }
  }

  @override
  bool shouldRepaint(_DashedLinePainter old) => old.color != color;
}

class _BoardingPassFooter extends StatelessWidget {
  final String      ticketNumber;
  final ColorScheme colors;
  final bool        isDark;

  const _BoardingPassFooter({
    required this.ticketNumber,
    required this.colors,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final bg = isDark ? const Color(0xFF242938) : Colors.white;

    return Container(
      width:   double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 20),
      color:   bg,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'TICKET NUMBER',
                style: TextStyle(
                  fontSize:      10,
                  fontWeight:    FontWeight.w600,
                  letterSpacing: 1.2,
                  color:         colors.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                ticketNumber,
                style: TextStyle(
                  fontSize:      16,
                  fontWeight:    FontWeight.w700,
                  letterSpacing: 2,
                  color:         colors.onSurface,
                ),
              ),
            ],
          ),
          Icon(
            Icons.airplane_ticket_outlined,
            size:  36,
            color: colors.primary.withValues(alpha: 0.2),
          ),
        ],
      ),
    );
  }
}