import 'package:flutter/material.dart';
import '../../models/board_row.dart';
import '../../constants/board_constants.dart';
import '../table_column_def.dart';
import 'board_widgets.dart'; 

class BoardTableColumns {
  static List<TableColumnDef<BoardRow>> buildColumns({
    required void Function(BoardRow) onStart,
    required void Function(BoardRow) onView,
  }) {
    return [
      TableColumnDef<BoardRow>(
        key: 'time',
        label: 'Time',
        initialWidth: 100,
        cellBuilder: (context, row) => Padding(
          padding: const EdgeInsets.only(left: 20, right: 8),
          child: Text(
            row.timeLabel,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              fontFeatures: const [FontFeature.tabularFigures()],
              color: Theme.of(context).colorScheme.onSurface,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ),
      TableColumnDef<BoardRow>(
        key: 'flight',
        label: 'Flight',
        initialWidth: 100,
        cellBuilder: (context, row) {
          final colors = Theme.of(context).colorScheme;
          return Align(
            alignment: Alignment.center,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
              decoration: BoxDecoration(
                color: colors.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                row.flightNumber,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: colors.primary,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          );
        },
      ),
      TableColumnDef<BoardRow>(
        key: 'route',
        label: 'Route',
        initialWidth: 140,
        cellBuilder: (context, row) {
          final colors = Theme.of(context).colorScheme;
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                row.departsCode,
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: colors.onSurface),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 5),
                child: Icon(Icons.arrow_forward_rounded,
                    size: 12, color: colors.onSurfaceVariant.withValues(alpha: 0.5)),
              ),
              Text(
                row.arrivesCode,
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: colors.onSurface),
              ),
            ],
          );
        },
      ),
      TableColumnDef<BoardRow>(
        key: 'airline',
        label: 'Airline',
        initialWidth: 160,
        cellBuilder: (context, row) {
          final colors = Theme.of(context).colorScheme;
          return Text(
            row.airlineName ?? '—',
            style: TextStyle(
              fontSize: 13,
              color: row.airlineName != null
                  ? colors.onSurface
                  : colors.onSurfaceVariant.withValues(alpha: 0.4),
            ),
            overflow: TextOverflow.ellipsis,
          );
        },
      ),
      TableColumnDef<BoardRow>(
        key: 'aircraft',
        label: 'Aircraft',
        initialWidth: 140,
        cellBuilder: (context, row) {
          final colors = Theme.of(context).colorScheme;
          if (row.aircraftModel != null) {
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.airplanemode_active_rounded,
                    size: 12, color: colors.onSurfaceVariant.withValues(alpha: 0.5)),
                const SizedBox(width: 5),
                Flexible(
                  child: Text(
                    row.aircraftModel!,
                    style: TextStyle(fontSize: 13, color: colors.onSurface),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            );
          }
          return Text('—', style: TextStyle(fontSize: 13, color: colors.onSurfaceVariant.withValues(alpha: 0.4)));
        },
      ),
      TableColumnDef<BoardRow>(
        key: 'status',
        label: 'Status',
        initialWidth: 130,
        cellBuilder: (context, row) {
          final colors = Theme.of(context).colorScheme;
          final statusColor = row.statusName == 'Scheduled'
              ? colors.primary
              : statusColors[row.statusName] ?? colors.onSurfaceVariant;

          return Align(
            alignment: Alignment.center,
            child: StatusBadge(label: row.statusName, color: statusColor),
          );
        },
      ),
      TableColumnDef<BoardRow>(
        key: 'actions',
        label: '',
        initialWidth: 160,
        cellBuilder: (context, row) {
          final colors = Theme.of(context).colorScheme;
          
          final canStart = row.flight != null;
          final canView = row.operation != null;

          return Align(
            alignment: Alignment.center,
            child: Padding(
              padding: const EdgeInsets.only(right: 16),
              child: canStart
                  ? ActionBtn(
                      label: 'Start Operation',
                      icon: Icons.rocket_launch_rounded,
                      primary: true,
                      onTap: () => onStart(row),
                      colors: colors,
                    )
                  : canView
                      ? ActionBtn(
                          label: 'View',
                          icon: Icons.open_in_new_rounded,
                          primary: false,
                          onTap: () => onView(row),
                          colors: colors,
                        )
                      : const SizedBox.shrink(),
            ),
          );
        },
      ),
    
    ];
  }
}