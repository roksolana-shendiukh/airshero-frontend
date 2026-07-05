import 'package:flutter/material.dart';
import '../../services/weather_service.dart';

class WeatherAlertBadge extends StatelessWidget {
  final List<WeatherAlert> alerts;

  const WeatherAlertBadge({
    super.key,
    required this.alerts,
  });

  @override
  Widget build(BuildContext context) {
    final hasCritical =
        alerts.any((a) => a.level == WeatherAlertLevel.critical);
    final color = hasCritical ? Colors.red : Colors.orange;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.4)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            hasCritical
                ? Icons.warning_rounded
                : Icons.warning_amber_outlined,
            size: 13,
            color: color,
          ),
          const SizedBox(width: 5),
          Text(
            '${alerts.length} weather alert${alerts.length > 1 ? 's' : ''}',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}