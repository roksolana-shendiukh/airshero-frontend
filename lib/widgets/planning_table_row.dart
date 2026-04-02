import 'package:flutter/material.dart';
import '../../models/planning_overview_model.dart';

class PlanningTableRow extends StatelessWidget {
  final OverviewFlight flight;
  final Map<String, double> columnWidths;

  const PlanningTableRow({
    super.key,
    required this.flight,
    required this.columnWidths,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 64),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.1),
          ),
        ),
      ),
    child: IntrinsicHeight(
      child: Row(
        children: [
          SizedBox(
            width: columnWidths['flight_number'],
            child: Padding(
              padding: const EdgeInsets.only(left: 16, right: 8),
              child: Text(
                flight.flightNumber,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),

          SizedBox(
            width: columnWidths['route'],
            child: Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    flight.departsAirportCode,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: Icon(
                      Icons.arrow_forward_rounded,
                      size: 14,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  Text(
                    flight.arrivesAirportCode,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                  ),
                ],
              ),
            ),
          ),

          SizedBox(
            width: columnWidths['departs'],
            child: Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Text(
                _fmtTime(flight.departsDatetime),
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
          ),

          SizedBox(
            width: columnWidths['arrives'],
            child: Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Text(
                _fmtTime(flight.arrivesDattime),
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
          ),

          SizedBox(
            width: columnWidths['aircraft'],
            child: ClipRect(
              child: Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Text(
                  flight.aircraftModel,
                  style: Theme.of(context).textTheme.bodyMedium,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
            ),
          ),

          SizedBox(
            width: columnWidths['classes'],
            child: Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Wrap(
                spacing: 4,
                runSpacing: 4,
                children: flight.classNames
                    .map((c) => _ClassChip(className: c))
                    .toList(),
              ),
            ),
          ),

          SizedBox(
            width: columnWidths['load'],
            child: Padding(
              padding: const EdgeInsets.only(right: 12),
              child: _LoadBar(percent: flight.loadPercent),
            ),
          ),

          SizedBox(
            width: columnWidths['status'],
            child: ClipRect(
              child: Padding(
                padding: const EdgeInsets.only(right: 8),
                child: _StatusBadge(status: flight.flightStatusName),
              ),
            ),
          ),
        ],
      ),
    )
    );
  }

  String _fmtTime(DateTime dt) =>
      '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
}


class _LoadBar extends StatelessWidget {
  final double percent;
  const _LoadBar({required this.percent});

  @override
  Widget build(BuildContext context) {
    final Color barColor;
    if (percent >= 85) {
      barColor = Colors.green.shade600;
    } else if (percent >= 55) {
      barColor = Colors.orange.shade600;
    } else {
      barColor = Theme.of(context).colorScheme.error;
    }

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${percent.toStringAsFixed(0)}%',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: barColor,
          ),
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: percent / 100,
            minHeight: 5,
            backgroundColor:
                Theme.of(context).colorScheme.outlineVariant,
            valueColor: AlwaysStoppedAnimation<Color>(barColor),
          ),
        ),
      ],
    );
  }
}


class _StatusBadge extends StatelessWidget {
  final String status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final color = _resolveColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
        ),
        overflow: TextOverflow.ellipsis,
        maxLines: 1,
      ),
    );
  }

  Color _resolveColor(String s) {
    switch (s) {
      case 'Scheduled': return const Color(0xFF4CAF50);
      case 'Boarding':  return const Color(0xFF2196F3);
      case 'Departed':  return const Color(0xFFFF9800);
      case 'Arrived':   return const Color(0xFF00BCD4);
      case 'Delayed':   return const Color(0xFFFF9800);
      case 'Cancelled': return const Color(0xFFF44336);
      default:          return const Color(0xFF9E9E9E);
    }
  }
}

class _ClassChip extends StatelessWidget {
  final String className;
  const _ClassChip({required this.className});

  static const _classColors = {
    'Economy':         Color(0xFF00BCD4),
    'Premium Economy': Color(0xFF2196F3),
    'Business':        Color(0xFFFF6B9D),
    'First':           Color(0xFFFFD700),
  };

  @override
  Widget build(BuildContext context) {
    final color = _classColors[className] ?? const Color(0xFF9E9E9E);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        className,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}


