import 'package:flutter/material.dart';

class TableHeader extends StatelessWidget {
  final bool selectAll;
  final VoidCallback onToggleSelectAll;
  final Map<String, double> columnWidths;
  final void Function(String key, double delta) onColumnResize;

  const TableHeader({
    super.key,
    required this.selectAll,
    required this.onToggleSelectAll,
    required this.columnWidths,
    required this.onColumnResize,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
          ),
        ),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(6),
          topRight: Radius.circular(6),
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: columnWidths['checkbox'],
            child: Checkbox(value: selectAll, onChanged: (_) => onToggleSelectAll()),
          ),
          _resizableCell(context, 'name', 'Name'),
          _resizableCell(context, 'email', 'Email'),
          _resizableCell(context, 'airline', 'Airline'),
          _resizableCell(context, 'role', 'Role'),
          _resizableCell(context, 'status', 'Status'),
          SizedBox(width: columnWidths['actions']),
        ],
      ),
    );
  }

  Widget _resizableCell(BuildContext context, String key, String label) {
    return SizedBox(
      width: columnWidths[key],
      child: Row(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(left: 4),
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
          ),
          GestureDetector(
            onHorizontalDragUpdate: (details) => onColumnResize(key, details.delta.dx),
            child: MouseRegion(
              cursor: SystemMouseCursors.resizeColumn,
              child: Container(
                width: 8,
                height: 48,
                color: Colors.transparent,
                child: Center(
                  child: Container(
                    width: 1,
                    height: 24,
                    color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}