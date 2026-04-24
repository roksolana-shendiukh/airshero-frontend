import 'package:flutter/material.dart';

class FlightConfigConfirm extends StatelessWidget {
  final List<Map<String, dynamic>> flights;
  final Map<int, int> classSeats;
  final Map<int, String> classNames;
  final Map<int, double> classPrices;
  final Map<int, Map<int, double>> baggagePrices;
  final Map<int, Set<int>> enabledBaggageRules;

  static const _palette = [
    Color(0xFF2196F3),
    Color(0xFFFF6B9D),
    Color(0xFF00BCD4),
    Color(0xFFFFD700),
    Color(0xFF4CAF50),
    Color(0xFFFF9800),
  ];

  const FlightConfigConfirm({
    super.key,
    required this.flights,
    required this.classSeats,
    required this.classNames,
    required this.classPrices,
    required this.baggagePrices,
    required this.enabledBaggageRules,
  });

  Color _colorFor(int classId) {
    final ids = classSeats.keys.toList()..sort();
    final i = ids.indexOf(classId);
    return i >= 0 ? _palette[i % _palette.length] : const Color(0xFF9E9E9E);
  }

  String _fmtDate(String iso) {
    final dt = DateTime.parse(iso);
    return '${dt.day.toString().padLeft(2, '0')}.${dt.month.toString().padLeft(2, '0')}.${dt.year}';
  }

  String _fmtTime(String iso) {
    final dt = DateTime.parse(iso);
    return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  bool get _hasBaggage =>
      enabledBaggageRules.values.any((s) => s.isNotEmpty);

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final first = flights.first;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeader(context, colors),
        const SizedBox(height: 24),

        _buildSection(context,
            icon: Icons.flight_outlined,
            title: 'Flights to configure',
            child: _buildFlightsList(colors, first)),
        const SizedBox(height: 16),

        _buildSection(context,
            icon: Icons.confirmation_number_outlined,
            title: 'Classes & ticket prices',
            child: _buildClassesCard(colors)),
        const SizedBox(height: 16),

        if (_hasBaggage) ...[
          _buildSection(context,
              icon: Icons.luggage_outlined,
              title: 'Baggage options',
              child: _buildBaggageCard(colors)),
          const SizedBox(height: 16),
        ],

        _buildInfoBanner(colors),
      ],
    );
  }

  Widget _buildHeader(BuildContext context, ColorScheme colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.primaryContainer.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(10),
        border:
            Border.all(color: colors.primary.withValues(alpha: 0.15)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: colors.primaryContainer.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.fact_check_outlined,
                color: colors.primary, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Review & confirm',
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.w600),
                ),
                Text(
                  'Configuration will be applied to all ${flights.length} selected flights',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(
    BuildContext context, {
    required IconData icon,
    required String title,
    required Widget child,
  }) {
    final colors = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 15, color: colors.onSurfaceVariant),
            const SizedBox(width: 6),
            Text(
              title.toUpperCase(),
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: colors.onSurfaceVariant,
                letterSpacing: 0.8,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        child,
      ],
    );
  }

  Widget _buildFlightsList(ColorScheme colors, Map<String, dynamic> first) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surfaceContainerHighest.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: colors.outline.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                first['flightNumber'] as String,
                style: const TextStyle(
                    fontSize: 15, fontWeight: FontWeight.w700),
              ),
              const SizedBox(width: 10),
              Text(
                '${first['departsCode']} → ${first['arrivesCode']}',
                style: TextStyle(
                    fontSize: 13, color: colors.onSurfaceVariant),
              ),
              const Spacer(),
              Row(
                children: [
                  Icon(Icons.flight_takeoff_outlined,
                      size: 13, color: colors.onSurfaceVariant),
                  const SizedBox(width: 4),
                  Text(
                    _fmtTime(first['departsDatetime'] as String),
                    style: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: Icon(Icons.arrow_forward,
                        size: 12, color: colors.onSurfaceVariant),
                  ),
                  Icon(Icons.flight_land_outlined,
                      size: 13, color: colors.onSurfaceVariant),
                  const SizedBox(width: 4),
                  Text(
                    _fmtTime(first['arrivesDatetime'] as String),
                    style: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Divider(
              height: 1,
              color: colors.outline.withValues(alpha: 0.15)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: flights.map((f) {
              return Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: colors.primaryContainer
                      .withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                      color: colors.primary.withValues(alpha: 0.2)),
                ),
                child: Text(
                  _fmtDate(f['departsDatetime'] as String),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: colors.primary,
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildClassesCard(ColorScheme colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surfaceContainerHighest.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: colors.outline.withValues(alpha: 0.15)),
      ),
      child: Column(
        children: [
          ...classSeats.entries.map((e) {
            final classId = e.key;
            final color = _colorFor(classId);
            final name = classNames[classId] ?? 'Class $classId';
            final price = classPrices[classId] ?? 0;

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
                  Text('${e.value} seats',
                      style: TextStyle(
                          fontSize: 12,
                          color: colors.onSurfaceVariant)),
                  const SizedBox(width: 16),
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
                        color: color,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
          Divider(
              height: 1,
              color: colors.outline.withValues(alpha: 0.12)),
          const SizedBox(height: 10),
          Row(
            children: [
              Icon(Icons.airline_seat_recline_normal_outlined,
                  size: 14, color: colors.onSurfaceVariant),
              const SizedBox(width: 6),
              Text(
                'Total: ${classSeats.values.fold(0, (a, b) => a + b)} seats',
                style: TextStyle(
                    fontSize: 12, color: colors.onSurfaceVariant),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBaggageCard(ColorScheme colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surfaceContainerHighest.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: colors.outline.withValues(alpha: 0.15)),
      ),
      child: Column(
        children: classSeats.keys.map((classId) {
          final ruleIds = enabledBaggageRules[classId] ?? {};
          if (ruleIds.isEmpty) return const SizedBox.shrink();

          final name = classNames[classId] ?? 'Class $classId';
          final color = _colorFor(classId);
          final prices = baggagePrices[classId] ?? {};

          return Padding(
            padding: const EdgeInsets.only(bottom: 14),
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
                            borderRadius: BorderRadius.circular(2))),
                    const SizedBox(width: 8),
                    Text(name,
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: color)),
                  ],
                ),
                const SizedBox(height: 8),
                ...ruleIds.map((ruleId) {
                  final price = prices[ruleId] ?? 0.0;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 4, left: 14),
                    child: Row(
                      children: [
                        Icon(Icons.check,
                            size: 13,
                            color: colors.onSurfaceVariant),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text('Rule #$ruleId',
                              style: TextStyle(
                                  fontSize: 12, color: colors.onSurface)),
                        ),
                        price == 0.0
                            ? Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.green.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(5),
                                ),
                                child: const Text('Free',
                                    style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.green)),
                              )
                            : Text('€${price.toStringAsFixed(0)}',
                                style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500)),
                      ],
                    ),
                  );
                }),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildInfoBanner(ColorScheme colors) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.primaryContainer.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
        border:
            Border.all(color: colors.primary.withValues(alpha: 0.15)),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, size: 16, color: colors.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'All ${flights.length} flights will be set to Scheduled status and become available for booking.',
              style: TextStyle(
                  fontSize: 12, color: colors.onSurfaceVariant),
            ),
          ),
        ],
      ),
    );
  }
}