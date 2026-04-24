import 'package:flutter/material.dart';

class RouteConfirmAircraftCard extends StatelessWidget {
  final Map<String, dynamic> airfleet;

  const RouteConfirmAircraftCard({
    super.key,
    required this.airfleet,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    final specs = <({IconData icon, String label, String value})>[
      if (airfleet['seatCapacity'] != null)
        (
          icon: Icons.airline_seat_recline_normal_outlined,
          label: 'Seats',
          value: '${airfleet['seatCapacity']}',
        ),
      if (airfleet['aircraftRangeKm'] != null)
        (
          icon: Icons.route_outlined,
          label: 'Range',
          value:
              '${(airfleet['aircraftRangeKm'] as num).toStringAsFixed(0)} km',
        ),
      if (airfleet['aircraftSpeed'] != null)
        (
          icon: Icons.speed_outlined,
          label: 'Speed',
          value:
              '${(airfleet['aircraftSpeed'] as num).toStringAsFixed(0)} km/h',
        ),
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surfaceContainerHighest.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: colors.outline.withValues(alpha: 0.15)),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: colors.primaryContainer.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.airplanemode_active_outlined,
                color: colors.primary, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  airfleet['aircraftModel'] as String,
                  style: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w600),
                ),
                if (airfleet['manufacturerName'] != null)
                  Text(
                    airfleet['manufacturerName'] as String,
                    style: TextStyle(
                        fontSize: 12, color: colors.onSurfaceVariant),
                  ),
              ],
            ),
          ),
          Wrap(
            spacing: 16,
            children: specs
                .map((s) => Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(s.icon,
                            size: 13, color: colors.onSurfaceVariant),
                        const SizedBox(width: 4),
                        Text(
                          s.value,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: colors.onSurface,
                          ),
                        ),
                      ],
                    ))
                .toList(),
          ),
        ],
      ),
    );
  }
}