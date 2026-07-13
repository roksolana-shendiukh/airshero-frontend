import 'package:flutter/material.dart';

class PassengerCountCell extends StatelessWidget {
  final int count;
  final String? passengersList;

  const PassengerCountCell({
    super.key,
    required this.count,
    this.passengersList,
  });

  List<String> get _passengers {
    if (passengersList == null || passengersList!.isEmpty) return [];
    return passengersList!.split(', ').map((e) => e.trim()).toList();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final passengers = _passengers;

    if (passengers.isEmpty) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.person_outline, size: 14, color: colors.onSurfaceVariant),
          const SizedBox(width: 4),
          Text('$count', style: Theme.of(context).textTheme.bodyMedium),
        ],
      );
    }

    return GestureDetector(
      onTap: () => _showPassengersPopup(context, passengers),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: Tooltip(
          message: 'Click to see passengers',
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.person_outline, size: 14, color: colors.primary),
              const SizedBox(width: 4),
              Text(
                '$count',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: colors.primary,
                      decoration: TextDecoration.underline,
                      decorationColor: colors.primary.withValues(alpha: 0.5),
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showPassengersPopup(BuildContext context, List<String> passengers) {
    final colors = Theme.of(context).colorScheme;
    final renderBox = context.findRenderObject() as RenderBox?;
    final offset = renderBox?.localToGlobal(Offset.zero) ?? Offset.zero;
    final size = renderBox?.size ?? Size.zero;

    showMenu(
      context: context,
      color: colors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: colors.outline.withValues(alpha: 0.2)),
      ),
      elevation: 8,
      position: RelativeRect.fromLTRB(
        offset.dx,
        offset.dy + size.height + 4,
        offset.dx + 240,
        offset.dy + size.height + 4 + (passengers.length * 44.0 + 52).clamp(0, 320),
      ),
      items: [
        PopupMenuItem(
          enabled: false,
          height: 36,
          child: Text(
            'Passengers',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
              color: colors.onSurfaceVariant,
            ),
          ),
        ),
        ...passengers.map(
          (name) => PopupMenuItem(
            enabled: false,
            height: 40,
            child: Row(
              children: [
                CircleAvatar(
                  radius: 14,
                  backgroundColor: colors.primaryContainer,
                  child: Text(
                    name.isNotEmpty ? name[0].toUpperCase() : '?',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: colors.primary,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    name,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: colors.onSurface,
                          fontWeight: FontWeight.w500,
                        ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}


