import 'package:flutter/material.dart';
import '../../table_column_def.dart';

List<TableColumnDef<Map<String, dynamic>>> buildAirportColumns({
  required BuildContext context,
  required void Function(Map<String, dynamic>) onEdit,
  required void Function(Map<String, dynamic>) onDelete,
}) {
  final colors = Theme.of(context).colorScheme;

  return [
    TableColumnDef(
      key: 'code',
      label: 'CODE',
      initialWidth: 80,
      cellBuilder: (context, airport) => Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: colors.primaryContainer.withValues(alpha: 0.4),
            borderRadius: BorderRadius.circular(4),
            border: Border.all(
              color: colors.primary.withValues(alpha: 0.3),
            ),
          ),
          child: Text(
            airport['airportCode'] ?? '—',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: colors.primary,
              letterSpacing: 0.5,
            ),
          ),
        ),
      ),
    ),

    TableColumnDef(
      key: 'name',
      label: 'AIRPORT',
      initialWidth: 280,
      cellBuilder: (context, airport) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              airport['airportName'] ?? '—',
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
            const SizedBox(height: 2),
            Text(
              airport['airportAddress'] ?? '—',
              style: TextStyle(
                fontSize: 11,
                color: colors.onSurfaceVariant,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ],
        ),
      ),
    ),

    TableColumnDef(
      key: 'city',
      label: 'CITY',
      initialWidth: 140,
      cellBuilder: (context, airport) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Text(
          airport['cityName'] ?? '—',
          style: const TextStyle(fontSize: 13),
          overflow: TextOverflow.ellipsis,
          maxLines: 1,
        ),
      ),
    ),

    TableColumnDef(
      key: 'terminals',
      label: 'TERMINALS',
      initialWidth: 90,
      cellBuilder: (context, airport) => Center(
        child: Text(
          '${airport['terminalCount'] ?? 0}',
          style: const TextStyle(fontSize: 13),
        ),
      ),
    ),

    TableColumnDef(
      key: 'gates',
      label: 'GATES',
      initialWidth: 90,
      cellBuilder: (context, airport) => Center(
        child: Text(
          '${airport['gateCount'] ?? 0}',
          style: const TextStyle(fontSize: 13),
        ),
      ),
    ),

    TableColumnDef(
      key: 'actions',
      label: '',
      initialWidth: 48,
      cellBuilder: (context, airport) => Center(
        child: PopupMenuButton<String>(
          icon: Icon(
            Icons.more_vert,
            size: 18,
            color: colors.onSurfaceVariant,
          ),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          itemBuilder: (_) => [
            PopupMenuItem(
              value: 'edit',
              child: Row(
                children: [
                  Icon(Icons.edit_outlined, size: 16, color: colors.onSurface),
                  const SizedBox(width: 8),
                  const Text('Edit', style: TextStyle(fontSize: 13)),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete_outline, size: 16, color: colors.error),
                  const SizedBox(width: 8),
                  Text('Delete',
                      style: TextStyle(fontSize: 13, color: colors.error)),
                ],
              ),
            ),
          ],
          onSelected: (val) {
            if (val == 'edit') onEdit(airport);
            if (val == 'delete') onDelete(airport);
          },
        ),
      ),
    ),
  ];
}