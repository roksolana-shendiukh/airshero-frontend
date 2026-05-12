import 'package:flutter/material.dart';
import '../../models/board_row.dart';
import '../../constants/board_constants.dart';
import '../table_column_def.dart';
import 'board_widgets.dart';

class BoardTableColumns {
  static List<TableColumnDef<BoardRow>> buildColumns({
    required void Function(BoardRow) onStart,
    required void Function(BoardRow) onView,
    required void Function(BoardRow) onChangeGate,
  }) {
    return [
      TableColumnDef<BoardRow>(
        key: 'time',
        label: 'Time',
        initialWidth: 100,
        cellBuilder: (context, row) => Center(
          child: Text(
            row.timeLabel,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
        ),
      ),
      TableColumnDef<BoardRow>(
        key: 'flight',
        label: 'Flight',
        initialWidth: 100,
        cellBuilder: (context, row) {
          final colors = Theme.of(context).colorScheme;
          return Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: colors.primary.withOpacity(0.08),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                row.flightNumber,
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: colors.primary),
              ),
            ),
          );
        },
      ),
      TableColumnDef<BoardRow>(
        key: 'route',
        label: 'Route',
        initialWidth: 160,
        cellBuilder: (context, row) {
          return Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(row.departsCode, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8),
                  child: Icon(Icons.arrow_forward_rounded, size: 14, color: Colors.grey),
                ),
                Text(row.arrivesCode, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
              ],
            ),
          );
        },
      ),
      TableColumnDef<BoardRow>(
        key: 'aircraft',
        label: 'Aircraft',
        initialWidth: 180,
        cellBuilder: (context, row) => Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.airplanemode_active_rounded, size: 14, color: Colors.grey),
              const SizedBox(width: 8),
              Text(row.aircraftModel ?? '—', style: const TextStyle(fontSize: 13)),
            ],
          ),
        ),
      ),
      TableColumnDef<BoardRow>(
        key: 'status',
        label: 'Status',
        initialWidth: 150,
        cellBuilder: (context, row) {
          final colors = Theme.of(context).colorScheme;
          final statusColor = row.statusName == 'Scheduled'
              ? colors.primary
              : statusColors[row.statusName] ?? colors.onSurfaceVariant;
          return Center(child: StatusBadge(label: row.statusName, color: statusColor));
        },
      ),

      TableColumnDef<BoardRow>(
        key: 'gate',
        label: 'Gate',
        initialWidth: 120,
        cellBuilder: (context, row) {
          final colors = Theme.of(context).colorScheme;
          final bool canChange = row.operation != null && row.statusName == 'Waiting';
          final String gateDisplay = row.gateCode ?? '—';

          return Center(
            child: ActionBtn(
              label: gateDisplay,
              icon: Icons.door_sliding_outlined,
              primary: canChange,
              onTap: canChange ? () => onChangeGate(row) : () {}, // Передаємо порожню функцію замість null
              colors: colors,
            ),
          );
        },
      ),

      TableColumnDef<BoardRow>(
        key: 'actions',
        label: '',
        initialWidth: 180,
        cellBuilder: (context, row) {
          final colors = Theme.of(context).colorScheme;
          return Center(
            child: row.flight != null
                ? ActionBtn(
                    label: 'Start Operation',
                    icon: Icons.rocket_launch_rounded,
                    primary: true,
                    onTap: () => onStart(row),
                    colors: colors,
                  )
                : row.operation != null
                    ? ActionBtn(
                        label: 'View Details',
                        icon: Icons.open_in_new_rounded,
                        primary: false,
                        onTap: () => onView(row),
                        colors: colors,
                      )
                    : const SizedBox.shrink(),
          );
        },
      ),
    ];
  }
}