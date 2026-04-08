import 'package:flutter/material.dart';

class Step3RouteConfirm extends StatelessWidget {
  final Map<String, dynamic> airfleet;
  final Map<String, dynamic> departsAirport;
  final Map<String, dynamic> arrivesAirport;
  final List<Map<String, dynamic>> scheduleGroups;
  final DateTime flightStartDate;
  final DateTime flightEndDate;

  static const _dayNames = {
    1: 'Mon', 2: 'Tue', 3: 'Wed',
    4: 'Thu', 5: 'Fri', 6: 'Sat', 7: 'Sun',
  };

  const Step3RouteConfirm({
    super.key,
    required this.airfleet,
    required this.departsAirport,
    required this.arrivesAirport,
    required this.scheduleGroups,
    required this.flightStartDate,
    required this.flightEndDate,
  });

  String _fmt(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}.${d.year}';

  int _estimatedFlights() {
    int count = 0;
    for (final group in scheduleGroups) {
      final dayIds = Set<int>.from(group['dayIds'] as List);
      var current = flightStartDate;
      while (!current.isAfter(flightEndDate)) {
        if (dayIds.contains(current.weekday)) count++;
        current = current.add(const Duration(days: 1));
      }
    }
    return count;
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeader(context, colors),
        const SizedBox(height: 24),
        _buildSection(
          context,
          icon: Icons.airplanemode_active_outlined,
          title: 'Aircraft',
          child: _buildAircraftCard(colors),
        ),
        const SizedBox(height: 16),
        _buildSection(
          context,
          icon: Icons.connecting_airports_outlined,
          title: 'Route',
          child: _buildRouteCard(colors),
        ),
        const SizedBox(height: 16),
        _buildSection(
          context,
          icon: Icons.schedule_outlined,
          title: 'Schedule',
          child: _buildScheduleCard(colors),
        ),
        const SizedBox(height: 16),
        _buildFlightsEstimate(context, colors),
      ],
    );
  }

  Widget _buildHeader(BuildContext context, ColorScheme colors) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: colors.primaryContainer.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(Icons.add_road,
              color: colors.primary, size: 24),
        ),
        const SizedBox(width: 14),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Review route',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            Text(
              'Please review all details before creating',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
            ),
          ],
        ),
      ],
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
              title,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: colors.onSurfaceVariant,
                letterSpacing: 0.4,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        child,
      ],
    );
  }

  Widget _buildAircraftCard(ColorScheme colors) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.surfaceContainerHighest.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
            color: colors.outline.withValues(alpha: 0.15)),
      ),
      child: Row(
        children: [
          Icon(Icons.flight,
              size: 20, color: colors.onSurfaceVariant),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  airfleet['aircraftModel'] as String,
                  style: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 2),
                Text(
                  '${airfleet['manufacturerName']}  ·  '
                  '${airfleet['seatCapacity']} seats  ·  '
                  '${(airfleet['aircraftRangeKm'] as num?)?.toStringAsFixed(0) ?? '—'} km range',
                  style: TextStyle(
                      fontSize: 12, color: colors.onSurfaceVariant),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRouteCard(ColorScheme colors) {
    final isInternational =
        departsAirport['countryName'] != arrivesAirport['countryName'];

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.surfaceContainerHighest.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
            color: colors.outline.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _buildAirportInfo(
                  code: departsAirport['airportCode'] as String,
                  city: departsAirport['cityName'] as String,
                  country: departsAirport['countryName'] as String,
                  colors: colors),
              const SizedBox(width: 12),
              Column(
                children: [
                  Icon(Icons.arrow_forward,
                      size: 18, color: colors.onSurfaceVariant),
                  const SizedBox(height: 2),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: isInternational
                          ? colors.primaryContainer
                              .withValues(alpha: 0.5)
                          : colors.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      isInternational ? 'Intl' : 'Dom',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: isInternational
                            ? colors.primary
                            : colors.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 12),
              _buildAirportInfo(
                  code: arrivesAirport['airportCode'] as String,
                  city: arrivesAirport['cityName'] as String,
                  country: arrivesAirport['countryName'] as String,
                  colors: colors),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAirportInfo({
    required String code,
    required String city,
    required String country,
    required ColorScheme colors,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          code,
          style: const TextStyle(
              fontSize: 20, fontWeight: FontWeight.w700),
        ),
        Text(
          city,
          style: const TextStyle(fontSize: 12),
        ),
        Text(
          country,
          style: TextStyle(
              fontSize: 11, color: colors.onSurfaceVariant),
        ),
      ],
    );
  }

  Widget _buildScheduleCard(ColorScheme colors) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.surfaceContainerHighest.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
            color: colors.outline.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.date_range_outlined,
                  size: 16, color: colors.onSurfaceVariant),
              const SizedBox(width: 6),
              Text(
                '${_fmt(flightStartDate)}  →  ${_fmt(flightEndDate)}',
                style: const TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w500),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...scheduleGroups.asMap().entries.map((entry) {
            final i = entry.key;
            final group = entry.value;
            final dayIds =
                List<int>.from(group['dayIds'] as List)..sort();
            final dayLabels =
                dayIds.map((d) => _dayNames[d] ?? '').join(', ');
            final depTime = group['departureTime'] as String;
            final arrTime = group['arrivalTime'] as String;

            return Padding(
              padding: EdgeInsets.only(
                  top: i > 0 ? 10 : 0),
              child: Row(
                children: [
                  Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      color: colors.primary.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        '${i + 1}',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: colors.primary,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      dayLabels,
                      style: const TextStyle(
                          fontSize: 13, fontWeight: FontWeight.w500),
                    ),
                  ),
                  Text(
                    '$depTime  →  $arrTime',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: colors.primary,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildFlightsEstimate(
      BuildContext context, ColorScheme colors) {
    final count = _estimatedFlights();
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.primaryContainer.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
            color: colors.primary.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Icon(Icons.flight_takeoff,
              size: 18, color: colors.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Flights to be generated',
                  style: TextStyle(
                      fontSize: 12, color: colors.onSurfaceVariant),
                ),
                Text(
                  '$count flights',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: colors.primary,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '${_fmt(flightStartDate)} – ${_fmt(flightEndDate)}',
            style: TextStyle(
                fontSize: 12, color: colors.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}