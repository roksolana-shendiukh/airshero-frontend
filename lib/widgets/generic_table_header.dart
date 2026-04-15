import 'package:flutter/material.dart';
import 'table_column_def.dart';

class GenericTableHeader<T> extends StatelessWidget {
  final bool selectAll;
  final VoidCallback onToggleSelectAll;
  final Map<String, double> columnWidths;
  final void Function(String key, double delta) onColumnResize;
  final List<TableColumnDef<T>> columns;
  final bool showCheckbox;
  final double checkboxWidth;

  const GenericTableHeader({
    super.key,
    required this.selectAll,
    required this.onToggleSelectAll,
    required this.columnWidths,
    required this.onColumnResize,
    required this.columns,
    this.showCheckbox = true,
    this.checkboxWidth = 48.0, 
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
          if (showCheckbox)
            SizedBox(
              width: checkboxWidth,
              child: Checkbox(value: selectAll, onChanged: (_) => onToggleSelectAll()),
            ),
            
          ...columns.map((col) => _resizableCell(context, col)),
        ],
      ),
    );
  }

  Widget _resizableCell(BuildContext context, TableColumnDef<T> col) {
    final currentWidth = columnWidths[col.key] ?? col.initialWidth;

    return SizedBox(
      width: currentWidth,
      child: Row(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4), 
              child: Text(
                col.label,
                textAlign: TextAlign.center,
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
            onHorizontalDragUpdate: (details) => onColumnResize(col.key, details.delta.dx),
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