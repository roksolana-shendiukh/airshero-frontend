import 'package:flutter/material.dart';


class AvailabilityBadge extends StatelessWidget {
  final List<Map<String, dynamic>> availability;
  final String className;

  const AvailabilityBadge({
    super.key,
    required this.availability,
    required this.className,
  });

  Map<String, dynamic>? _findAvail() {
    if (availability.isEmpty) return null;
    try {
      return availability.firstWhere(
        (a) => (a['className'] as String).toLowerCase() ==
            className.toLowerCase(),
      );
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final avail = _findAvail();
    if (avail == null) return const SizedBox.shrink();

    final colors = Theme.of(context).colorScheme;
    final available = avail['availableSeats'] as int? ?? 0;
    final total = avail['totalSeats'] as int? ?? 0;
    final cls = avail['className'] as String? ?? className;

    final Color badgeColor;
    final Color textColor;
    final IconData icon;
    final String label;

    if (available == 0) {
      badgeColor = colors.errorContainer;
      textColor = colors.onErrorContainer;
      icon = Icons.block_outlined;
      label = 'No seats available in $cls';
    } else if (available <= 5) {
      badgeColor = Colors.orange.withValues(alpha: 0.15);
      textColor = Colors.orange.shade700;
      icon = Icons.warning_amber_outlined;
      label = '$available seat${available == 1 ? '' : 's'} left in $cls';
    } else {
      badgeColor = colors.primaryContainer.withValues(alpha: 0.4);
      textColor = colors.primary;
      icon = Icons.event_seat_outlined;
      label = '$available of $total seats available in $cls';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: badgeColor,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: textColor),
          const SizedBox(width: 6),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: textColor,
                  fontWeight: FontWeight.w500,
                ),
          ),
        ],
      ),
    );
  }
}













