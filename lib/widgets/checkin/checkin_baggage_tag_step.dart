import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class CheckInBaggageTagStep extends StatelessWidget {
  final List<Map<String, dynamic>> bags;
  final String   passengerName;
  final String   flightNumber;
  final DateTime departDate;

  const CheckInBaggageTagStep({
    super.key,
    required this.bags,
    required this.passengerName,
    required this.flightNumber,
    required this.departDate,
  });

  @override
  Widget build(BuildContext context) {
    final checkedBags = bags.where((b) =>
        (b['baggageTypeName'] as String? ?? '') != 'Carry-on baggage').toList();
    
    if (checkedBags.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      child: Column(
        children: checkedBags.asMap().entries.map((entry) {
          final i   = entry.key;
          final bag = entry.value;
          return Padding(
            padding: EdgeInsets.only(top: i == 0 ? 0 : 12),
            child: _BaggageTag(
              bag:           bag,
              passengerName: passengerName,
              flightNumber:  flightNumber,
              departDate:    departDate,
              tagNumber:     i + 1,
              totalTags:     checkedBags.length,
            ),
          );
        }).toList(),
      ),
    );
  }

}

class _BaggageTag extends StatelessWidget {
  final Map<String, dynamic> bag;
  final String               passengerName;
  final String               flightNumber;
  final DateTime             departDate;
  final int                  tagNumber;
  final int                  totalTags;

  const _BaggageTag({
    required this.bag,
    required this.passengerName,
    required this.flightNumber,
    required this.departDate,
    required this.tagNumber,
    required this.totalTags,
  });

  @override
  Widget build(BuildContext context) {
    final colors  = Theme.of(context).colorScheme;
    final isDark  = Theme.of(context).brightness == Brightness.dark;
    final cardBg  = isDark ? const Color(0xFF1E2330) : Colors.white;
    final stripeBg = isDark ? const Color(0xFF252B3B) : const Color(0xFFF5F7FA);

    final trackingNumber = bag['trackingNumber'] as String? ?? '—';
    final typeName       = bag['baggageTypeName'] as String? ?? '—';
    final weightKg       = (bag['weightKg'] as num?)?.toDouble() ?? 0.0;
    final isCarryOn      = typeName == 'Carry-on baggage';

    return Container(
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

            // Header
            Container(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 14),
              color: isCarryOn
                  ? colors.secondary
                  : colors.tertiary,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'BAGGAGE TAG',
                        style: TextStyle(
                          color:         Colors.white.withValues(alpha: 0.7),
                          fontSize:      10,
                          fontWeight:    FontWeight.w600,
                          letterSpacing: 1.5,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        trackingNumber,
                        style: const TextStyle(
                          color:         Colors.white,
                          fontSize:      20,
                          fontWeight:    FontWeight.w800,
                          letterSpacing: 2,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color:        Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '$tagNumber / $totalTags',
                      style: const TextStyle(
                        color:      Colors.white,
                        fontSize:   12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Passenger name
            Container(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 14),
              color: cardBg,
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

            // Baggage type + flight
            Container(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
              color: stripeBg,
              child: Row(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'TYPE',
                        style: TextStyle(
                          fontSize:      10,
                          fontWeight:    FontWeight.w600,
                          letterSpacing: 1.2,
                          color:         colors.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            isCarryOn
                                ? Icons.backpack_outlined
                                : Icons.luggage_outlined,
                            size:  22,
                            color: isCarryOn ? colors.secondary : colors.tertiary,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            typeName,
                            style: TextStyle(
                              fontSize:   16,
                              fontWeight: FontWeight.w700,
                              color:      colors.onSurface,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const Spacer(),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'FLIGHT',
                        style: TextStyle(
                          fontSize:      10,
                          fontWeight:    FontWeight.w600,
                          letterSpacing: 1.2,
                          color:         colors.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        flightNumber,
                        style: TextStyle(
                          fontSize:      22,
                          fontWeight:    FontWeight.w800,
                          color:         colors.primary,
                          letterSpacing: 1,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Tear line
            _TearLine(colors: colors, isDark: isDark),

            // Weight + date
            Container(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 18),
              color: cardBg,
              child: Row(
                children: [
                  _InfoCell(
                    label:  'WEIGHT',
                    value:  isCarryOn ? '—' : '${weightKg.toStringAsFixed(1)} kg',
                    large:  true,
                    colors: colors,
                  ),
                  _InfoCell(
                    label:  'DATE',
                    value:  DateFormat('dd MMM yyyy').format(departDate),
                    colors: colors,
                  ),
                ],
              ),
            ),
          ],
        ),
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
              fontSize:      large ? 24 : 14,
              fontWeight:    FontWeight.w700,
              color:         large ? colors.primary : colors.onSurface,
              letterSpacing: large ? 1 : 0,
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
              color:  bg,
              child:  CustomPaint(
                painter: _DashPainter(
                    color: colors.outline.withValues(alpha: 0.25)),
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
    final p = Paint()
      ..color       = color
      ..strokeWidth = 1.5
      ..style       = PaintingStyle.stroke;
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