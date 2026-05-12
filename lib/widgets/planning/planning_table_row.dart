import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/planning_overview_model.dart';

class PlanningTableRow extends StatelessWidget {
  final OverviewFlight flight;
  final Map<String, double> columnWidths;
  final void Function(OverviewFlight flight) onStatusTap;
  final void Function(OverviewFlight flight) onEditTap;

  const PlanningTableRow({
    super.key,
    required this.flight,
    required this.columnWidths,
    required this.onStatusTap,
    required this.onEditTap,
  });


  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final bool isActionable = flight.flightStatusName == 'Scheduled' || 
                              flight.flightStatusName == 'Boarding';

    return Container(
      constraints: const BoxConstraints(minHeight: 70),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: colors.outline.withValues(alpha: 0.1))),
      ),
      child: IntrinsicHeight(
        child: Row(
          children: [
            _buildCenteredCell('flight_number', Text(
              flight.flightNumber,
              style: TextStyle(color: colors.primary, fontWeight: FontWeight.bold),
            )),

            _buildCenteredCell('route', Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(flight.departsAirportCode, style: const TextStyle(fontWeight: FontWeight.w600)),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 4),
                  child: Icon(Icons.arrow_right_alt, size: 16, color: Colors.grey),
                ),
                Text(flight.arrivesAirportCode, style: const TextStyle(fontWeight: FontWeight.w600)),
              ],
            )),

            _buildCenteredCell('date', Text(
              DateFormat('dd.MM.yyyy').format(flight.departsDatetime),
              style: const TextStyle(fontWeight: FontWeight.w500),
            )),

            

            _buildCenteredCell('schedule', Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '${_fmtTime(flight.departsDatetime)} — ${_fmtTime(flight.arrivesDattime)}',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
                if (flight.arrivesDattime.day != flight.departsDatetime.day)
                  Text('+1 day', style: TextStyle(fontSize: 10, color: colors.error)),
              ],
            )),

            _buildCenteredCell('aircraft', Text(flight.aircraftModel, textAlign: TextAlign.center)),

            _buildCenteredCell('classes', Wrap(
              spacing: 4, runSpacing: 4,
              alignment: WrapAlignment.center,
              children: flight.classNames.map((c) => _ClassChip(className: c)).toList(),
            )),

            _buildCenteredCell('load', _LoadBar(percent: flight.loadPercent)),

            _buildCenteredCell('status', InkWell(
              onTap: isActionable ? () => onStatusTap(flight) : null,
              child: _StatusBadge(status: flight.flightStatusName, isInteractive: isActionable),
            )),

            if (columnWidths.containsKey('actions'))
              _buildCenteredCell('actions', IconButton(
                icon: Icon(Icons.edit_calendar_rounded, size: 20, 
                      color: isActionable ? colors.primary : Colors.grey.withOpacity(0.3)),
                onPressed: isActionable ? () => onEditTap(flight) : null,
              )),
          ],
        ),
      ),
    );
  }

  String _fmtTime(DateTime dt) =>
      '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';


  Widget _buildCenteredCell(String key, Widget child) {
    return SizedBox(
      width: columnWidths[key],
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
          child: child,
        ),
      ),
    );
  }

}

class _LoadBar extends StatelessWidget {
  final double percent;
  const _LoadBar({required this.percent});

  @override
  Widget build(BuildContext context) {
    final Color barColor = percent >= 85 ? Colors.green : (percent >= 55 ? Colors.orange : Colors.red);

    return Container(
      width: 100, 
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('${percent.toStringAsFixed(0)}%', 
               style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: barColor)),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: percent / 100,
              minHeight: 6, // Трішки товща лінія
              backgroundColor: Colors.grey.withOpacity(0.2),
              valueColor: AlwaysStoppedAnimation<Color>(barColor),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;
  final bool isInteractive;
  const _StatusBadge({required this.status, required this.isInteractive});

  @override
  Widget build(BuildContext context) {
    final color = _resolveColor(status);
    return Opacity(
      opacity: isInteractive ? 1.0 : 0.6, // Приглушуємо неактивні статуси
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withValues(alpha: 0.4), width: 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              status,
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color),
            ),
            if (isInteractive) ...[
              const SizedBox(width: 4),
              Icon(Icons.keyboard_arrow_down_rounded, size: 14, color: color),
            ],
          ],
        ),
      ),
    );
  }

  Color _resolveColor(String s) {
    switch (s) {
      case 'Scheduled': return const Color(0xFF4CAF50); // Зелений
      case 'Boarding':  return const Color(0xFF2196F3); // Синій
      case 'Departed':  return const Color(0xFFFF9800); // Помаранчевий
      case 'Arrived':   return const Color(0xFF00BCD4); // Блакитний
      case 'Cancelled': return const Color(0xFFF44336); // Червоний
      case 'Auto-scheduled': return Colors.purple;    // Фіолетовий
      case 'Delayed':   return Colors.amber;          // Жовтий
      default:          return Colors.grey;
    }
  }
}

class _ClassChip extends StatelessWidget {
  final String className;
  const _ClassChip({required this.className});

  @override
  Widget build(BuildContext context) {
    final color = _getClassColor(className);
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1), 
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        className,
        style: TextStyle(
          fontSize: 9, 
          fontWeight: FontWeight.bold, 
          color: color, 
        ),
      ),
    );
  }

  Color _getClassColor(String name) {
    switch (name.trim()) {
      case 'Economy':
        return const Color(0xFF00BCD4); 
      case 'Premium Economy':
        return const Color(0xFF2196F3);
      case 'Business':
        return const Color(0xFFFF6B9D); 
      case 'First':
        return const Color(0xFFFFD700); 
      default:
        return Colors.grey;
    }
  }
}


