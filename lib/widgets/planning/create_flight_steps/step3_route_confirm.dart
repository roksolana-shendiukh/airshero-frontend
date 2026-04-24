import 'package:flutter/material.dart';
import 'route_confirm_aircraft_card.dart';
import 'route_confirm_route_card.dart';
import 'route_confirm_schedule_card.dart';

class Step3RouteConfirm extends StatelessWidget {
  final Map<String, dynamic> airfleet;
  final Map<String, dynamic> departsAirport;
  final Map<String, dynamic> arrivesAirport;
  final List<Map<String, dynamic>> scheduleGroups;
  final DateTime flightStartDate;
  final DateTime flightEndDate;

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
        const SizedBox(height: 28),

        _buildSection(context,
            icon: Icons.airplanemode_active_outlined,
            title: 'Aircraft',
            child: RouteConfirmAircraftCard(airfleet: airfleet)),
        const SizedBox(height: 16),

        _buildSection(context,
            icon: Icons.connecting_airports_outlined,
            title: 'Route',
            child: RouteConfirmRouteCard(
              departsAirport: departsAirport,
              arrivesAirport: arrivesAirport,
            )),
        const SizedBox(height: 16),

        _buildSection(context,
            icon: Icons.schedule_outlined,
            title: 'Schedule',
            child: RouteConfirmScheduleCard(
              scheduleGroups: scheduleGroups,
              flightStartDate: flightStartDate,
              flightEndDate: flightEndDate,
            )),
        const SizedBox(height: 16),

        _buildEstimate(context, colors),
      ],
    );
  }

  Widget _buildHeader(BuildContext context, ColorScheme colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.primaryContainer.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: colors.primary.withValues(alpha: 0.15)),
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
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                Text(
                  'Please review all details before creating the route',
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

  Widget _buildEstimate(BuildContext context, ColorScheme colors) {
    final count = _estimatedFlights();
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.primaryContainer.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: colors.primary.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Icon(Icons.flight_takeoff, size: 20, color: colors.primary),
          const SizedBox(width: 14),
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
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: colors.primary,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                _fmt(flightStartDate),
                style: const TextStyle(
                    fontSize: 12, fontWeight: FontWeight.w500),
              ),
              Text(
                '↓',
                style: TextStyle(
                    fontSize: 12, color: colors.onSurfaceVariant),
              ),
              Text(
                _fmt(flightEndDate),
                style: const TextStyle(
                    fontSize: 12, fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ],
      ),
    );
  }
}