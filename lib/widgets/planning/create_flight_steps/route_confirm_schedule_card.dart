import 'package:flutter/material.dart';

class RouteConfirmScheduleCard extends StatelessWidget {
  final List<Map<String, dynamic>> scheduleGroups;
  final DateTime flightStartDate;
  final DateTime flightEndDate;

  static const _dayNames = {
    1: 'Mon', 2: 'Tue', 3: 'Wed',
    4: 'Thu', 5: 'Fri', 6: 'Sat', 7: 'Sun',
  };

  const RouteConfirmScheduleCard({
    super.key,
    required this.scheduleGroups,
    required this.flightStartDate,
    required this.flightEndDate,
  });

  String _fmt(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}.${d.year}';

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

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
          // Period
          Row(
            children: [
              Icon(Icons.date_range_outlined,
                  size: 15, color: colors.onSurfaceVariant),
              const SizedBox(width: 8),
              Text(
                '${_fmt(flightStartDate)}  →  ${_fmt(flightEndDate)}',
                style: const TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(height: 1),
          const SizedBox(height: 14),

          // Groups
          ...scheduleGroups.asMap().entries.map((entry) {
            final i = entry.key;
            final group = entry.value;
            final dayIds =
                List<int>.from(group['dayIds'] as List)..sort();
            final depTime = group['departureTime'] as String;

            return Padding(
              padding: EdgeInsets.only(top: i > 0 ? 10 : 0),
              child: Row(
                children: [
                  // Group number
                  Container(
                    width: 22,
                    height: 22,
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

                  // Days chips
                  Expanded(
                    child: Wrap(
                      spacing: 4,
                      runSpacing: 4,
                      children: dayIds.map((d) {
                        return Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: colors.primaryContainer
                                .withValues(alpha: 0.4),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            _dayNames[d] ?? '',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: colors.primary,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Departure time
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.flight_takeoff_outlined,
                          size: 13, color: colors.onSurfaceVariant),
                      const SizedBox(width: 4),
                      Text(
                        depTime,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: colors.primary,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}