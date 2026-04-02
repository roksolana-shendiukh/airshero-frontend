import 'package:flutter/material.dart';

class Step4Confirm extends StatelessWidget {
  final Map<String, dynamic> route;
  final DateTime date;
  final String departsTime;
  final String arrivesTime;
  final Map<int, int> classSeats;
  final Map<int, String> classNames;
  final Map<int, double> classPrices;
  final Map<int, Map<int, double>> baggagePrices;
  final Map<int, Set<int>> enabledBaggageRules;
  final int blockedSeatCount;

  const Step4Confirm({
    super.key,
    required this.route,
    required this.date,
    required this.departsTime,
    required this.arrivesTime,
    required this.classSeats,
    required this.classNames,
    required this.classPrices,
    required this.baggagePrices,
    required this.enabledBaggageRules,
    this.blockedSeatCount = 0,
  });

  static const _classColors = [
    Color(0xFF2196F3),
    Color(0xFFFF6B9D),
    Color(0xFF00BCD4),
    Color(0xFFFFD700),
    Color(0xFF4CAF50),
    Color(0xFFFF9800),
  ];

  Color _colorFor(int classId) {
    final ids = classSeats.keys.toList()..sort();
    final i = ids.indexOf(classId);
    return i >= 0 ? _classColors[i % _classColors.length] : const Color(0xFF9E9E9E);
  }

  String _formatDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}.${d.year}';

  bool get _hasBaggage =>
      enabledBaggageRules.values.any((s) => s.isNotEmpty);

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader(context, 'Review & confirm',
            'Please check all details before creating the flight.'),
        const SizedBox(height: 24),

        _Card(
          title: 'Flight details',
          icon: Icons.flight_outlined,
          colors: colors,
          child: Column(
            children: [
              _Row('Route',
                  '${route['flightNumber']}  ·  ${route['departsCode']} → ${route['arrivesCode']}',
                  colors),
              _Row('Aircraft',
                  '${route['aircraftModel']}  ·  ${route['seatCapacity']} seats',
                  colors),
              _Row('Date', _formatDate(date), colors),
              _Row('Departure', departsTime, colors),
              _Row('Arrival', arrivesTime, colors),
            ],
          ),
        ),
        const SizedBox(height: 12),

        _Card(
          title: 'Classes & ticket prices',
          icon: Icons.confirmation_number_outlined,
          colors: colors,
          child: Column(
            children: [
              ...classSeats.entries.map((e) {
                final classId = e.key;
                final color = _colorFor(classId);
                final name = classNames[classId] ?? 'Class $classId';
                final price = classPrices[classId] ?? 0;
                final seats = e.value;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: color,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(name,
                            style: const TextStyle(
                                fontSize: 13, fontWeight: FontWeight.w500)),
                      ),
                      Text(
                        '$seats seats',
                        style: TextStyle(
                            fontSize: 12, color: colors.onSurfaceVariant),
                      ),
                      const SizedBox(width: 20),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 3),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '€${price.toStringAsFixed(0)}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: color.withValues(alpha: 0.85),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),
              const SizedBox(height: 4),
              Divider(height: 1, color: colors.outline.withValues(alpha: 0.12)),
              const SizedBox(height: 10),
              Row(
                children: [
                  Icon(Icons.airline_seat_recline_normal_outlined,
                      size: 14, color: colors.onSurfaceVariant),
                  const SizedBox(width: 6),
                  Text(
                    'Total available: ${classSeats.values.fold(0, (a, b) => a + b)} seats',
                    style: TextStyle(
                        fontSize: 12, color: colors.onSurfaceVariant),
                  ),
                  if (blockedSeatCount > 0) ...[
                    const SizedBox(width: 16),
                    Icon(Icons.block_rounded,
                        size: 14, color: colors.onSurfaceVariant),
                    const SizedBox(width: 6),
                    Text(
                      'Blocked: $blockedSeatCount',
                      style: TextStyle(
                          fontSize: 12, color: colors.onSurfaceVariant),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        if (_hasBaggage) ...[
          _Card(
            title: 'Baggage options',
            icon: Icons.luggage_outlined,
            colors: colors,
            child: Column(
              children: classSeats.keys.map((classId) {
                final ruleIds = enabledBaggageRules[classId] ?? {};
                if (ruleIds.isEmpty) return const SizedBox.shrink();

                final className = classNames[classId] ?? 'Class $classId';
                final color = _colorFor(classId);
                final prices = baggagePrices[classId] ?? {};

                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: color,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            className,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: color,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ...ruleIds.map((ruleId) {
                        final price = prices[ruleId] ?? 0.0;
                        return Padding(
                          padding: const EdgeInsets.only(
                              bottom: 6, left: 14),
                          child: Row(
                            children: [
                              Icon(Icons.check,
                                  size: 13,
                                  color: colors.onSurfaceVariant),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  'Rule #$ruleId',
                                  style: TextStyle(
                                      fontSize: 12,
                                      color: colors.onSurface),
                                ),
                              ),
                              if (price == 0.0)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.green
                                        .withValues(alpha: 0.1),
                                    borderRadius:
                                        BorderRadius.circular(5),
                                  ),
                                  child: const Text('Free',
                                      style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.green)),
                                )
                              else
                                Text(
                                  '€${price.toStringAsFixed(0)}',
                                  style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500),
                                ),
                            ],
                          ),
                        );
                      }),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 12),
        ],

        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: colors.primaryContainer.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
                color: colors.primary.withValues(alpha: 0.15)),
          ),
          child: Row(
            children: [
              Icon(Icons.info_outline, size: 16, color: colors.primary),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Once created, the flight will be set to Scheduled status and visible to passengers.',
                  style: TextStyle(
                      fontSize: 12, color: colors.onSurfaceVariant),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _sectionHeader(BuildContext context, String title, String subtitle) {
    final colors = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.w600)),
        const SizedBox(height: 4),
        Text(subtitle,
            style: TextStyle(fontSize: 12, color: colors.onSurfaceVariant)),
      ],
    );
  }
}

class _Card extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;
  final ColorScheme colors;

  const _Card({
    required this.title,
    required this.icon,
    required this.child,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surfaceContainerHighest.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: colors.outline.withValues(alpha: 0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: colors.onSurfaceVariant),
              const SizedBox(width: 6),
              Text(
                title,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: colors.onSurfaceVariant,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  final String label;
  final String value;
  final ColorScheme colors;

  const _Row(this.label, this.value, this.colors);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          SizedBox(
            width: 96,
            child: Text(label,
                style: TextStyle(
                    fontSize: 13, color: colors.onSurfaceVariant)),
          ),
          Expanded(
            child: Text(value,
                style: const TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w500)),
          ),
        ],
      ),
    );
  }
}