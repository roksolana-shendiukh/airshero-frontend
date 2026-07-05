import 'package:flutter/material.dart';
import '../../models/flight_crew_model.dart';

class CrewValidationBadge extends StatelessWidget {
  final CrewValidationModel validation;

  const CrewValidationBadge({
    super.key,
    required this.validation,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final color = validation.valid ? Colors.green : colors.error;
    final label = validation.valid
        ? 'Crew complete'
        : '${validation.missing.values.fold(0, (a, b) => a + b)} missing';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            validation.valid
                ? Icons.check_circle_outline
                : Icons.warning_amber_outlined,
            size: 13,
            color: color,
          ),
          const SizedBox(width: 5),
          Text(
            label,
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