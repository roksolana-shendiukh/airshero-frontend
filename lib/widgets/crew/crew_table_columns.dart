import 'package:flutter/material.dart';
import '../table_column_def.dart';
import '../../models/flight_crew_model.dart';

class CrewTableColumns {
  static List<TableColumnDef<FlightCrewModel>> buildColumns({
    required void Function(FlightCrewModel) onEdit,
    required void Function(FlightCrewModel) onDelete,
  }) {
    return [
      TableColumnDef(
        key:          'name',
        label:        'NAME',
        initialWidth: 250,
        cellBuilder:  (context, c) => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            children: [
              CircleAvatar(
                radius: 15,
                backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                child: Text(
                  c.firstName?.isNotEmpty == true ? c.firstName![0] : '?',
                  style: TextStyle(
                    fontSize:   12,
                    fontWeight: FontWeight.w700,
                    color:      Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  c.fullName,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),

      TableColumnDef(
        key:          'position',
        label:        'POSITION',
        initialWidth: 180,
        cellBuilder:  (context, c) => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: _PositionBadge(position: c.position),
        ),
      ),

      TableColumnDef(
        key:          'license',
        label:        'LICENSE',
        initialWidth: 380,
        cellBuilder:  (context, c) => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            c.licenseType ?? '—',
            style: const TextStyle(fontSize: 13),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ),

      TableColumnDef(
        key:          'experience',
        label:        'EXPERIENCE',
        initialWidth: 160,
        cellBuilder:  (context, c) => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            c.experienceYears != null ? '${c.experienceYears} yrs' : '—',
            style: const TextStyle(fontSize: 13),
          ),
        ),
      ),

      TableColumnDef(
        key:          'actions',
        label:        'ACTIONS',
        initialWidth: 120,
        cellBuilder:  (context, c) => Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              icon:          const Icon(Icons.edit_outlined, size: 16),
              onPressed:     () => onEdit(c),
              tooltip:       'Edit',
              visualDensity: VisualDensity.compact,
              color:         Theme.of(context).colorScheme.primary,
            ),
            IconButton(
              icon:          const Icon(Icons.delete_outline, size: 16),
              onPressed:     () => onDelete(c),
              tooltip:       'Delete',
              visualDensity: VisualDensity.compact,
              color:         Theme.of(context).colorScheme.error,
            ),
          ],
        ),
      ),
    ];
  }
}

class _PositionBadge extends StatelessWidget {
  final String? position;
  const _PositionBadge({this.position});

  Color _color(BuildContext context) {
    switch (position) {
      case 'Pilot':            return Colors.indigo;
      case 'Co-Pilot':         return Colors.blue;
      case 'Flight Attendant': return Colors.teal;
      case 'Engineer':         return Colors.orange;
      default:                 return Theme.of(context).colorScheme.outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _color(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color:        color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border:       Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        position ?? '—',
        style: TextStyle(
          fontSize:   11,
          fontWeight: FontWeight.w600,
          color:      color,
        ),
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}


