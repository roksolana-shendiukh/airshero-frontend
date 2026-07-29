import 'package:flutter/material.dart';
import '../../models/schedule_group_model.dart';
import 'schedule_time_input_field.dart';

class ScheduleGroupCard extends StatelessWidget {
  final ScheduleGroup group;
  final int index;
  final List<({int id, String label})> days;
  final Set<int> usedDayIds;
  final bool canRemove;
  final VoidCallback onRemove;
  final VoidCallback onChanged;
  final String Function(String) calcArrival;

  const ScheduleGroupCard({
    super.key,
    required this.group,
    required this.index,
    required this.days,
    required this.usedDayIds,
    required this.canRemove,
    required this.onRemove,
    required this.onChanged,
    required this.calcArrival,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final arrivalTime = calcArrival(group.departureTime);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: colors.outline.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Group ${index + 1}',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: colors.onSurfaceVariant,
                ),
              ),
              const Spacer(),
              if (canRemove)
                IconButton(
                  onPressed: onRemove,
                  icon: const Icon(Icons.close, size: 16),
                  style: IconButton.styleFrom(
                    foregroundColor: colors.onSurfaceVariant,
                    minimumSize: const Size(28, 28),
                    padding: EdgeInsets.zero,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          _buildDayPicker(colors),
          const SizedBox(height: 14),
          _buildTimeRow(colors, arrivalTime),
        ],
      ),
    );
  }

  Widget _buildDayPicker(ColorScheme colors) {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: days.map((d) {
        final isSelected = group.dayIds.contains(d.id);
        final isDisabled = !isSelected && usedDayIds.contains(d.id);
        return MouseRegion(
          cursor: isDisabled
              ? SystemMouseCursors.basic
              : SystemMouseCursors.click,
          child: GestureDetector(
            onTap: isDisabled
                ? null
                : () {
                    if (isSelected) {
                      group.dayIds.remove(d.id);
                    } else {
                      group.dayIds.add(d.id);
                    }
                    onChanged();
                  },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 120),
              width: 44,
              height: 36,
              decoration: BoxDecoration(
                color: isSelected
                    ? colors.primary
                    : isDisabled
                        ? colors.surfaceContainerHighest
                            .withValues(alpha: 0.3)
                        : colors.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: isSelected
                      ? colors.primary
                      : colors.outline.withValues(alpha: 0.2),
                ),
              ),
              child: Center(
                child: Text(
                  d.label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight:
                        isSelected ? FontWeight.w600 : FontWeight.normal,
                    color: isSelected
                        ? colors.onPrimary
                        : isDisabled
                            ? colors.onSurfaceVariant
                                .withValues(alpha: 0.35)
                            : colors.onSurface,
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildTimeRow(ColorScheme colors, String arrivalTime) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: ScheduleTimeInputField(
            label: 'Departure',
            value: group.departureTime,
            onChanged: (v) {
              group.departureTime = v;
              onChanged();
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 18, left: 12, right: 12),
          child: Icon(Icons.arrow_forward,
              size: 16, color: colors.onSurfaceVariant),
        ),
        Expanded(
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: colors.surfaceContainerHighest.withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          children: [
            Icon(Icons.access_time_outlined,
                size: 20, color: colors.onSurfaceVariant),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Arrival',
                  style: TextStyle(
                      fontSize: 12, color: colors.onSurfaceVariant),
                ),
                Text(
                  arrivalTime.isNotEmpty
                      ? arrivalTime.replaceAll(' (+1)', '')
                      : '—',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: arrivalTime.isNotEmpty
                        ? colors.onSurface
                        : colors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      if (arrivalTime.contains('+1'))
        Padding(
          padding: const EdgeInsets.only(left: 4, top: 4),
          child: Text(
            'Arrives next day',
            style: TextStyle(
              fontSize: 11,
              color: colors.primary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
    ],
  ),
),
      
      ],
    );
  }
}