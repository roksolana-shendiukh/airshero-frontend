import 'package:flutter/material.dart';
import 'table_column_def.dart';

class GenericTableRow<T> extends StatefulWidget {
  final T item;
  final bool isSelected;
  final Map<String, double> columnWidths;
  final VoidCallback? onToggle; 
  final List<TableColumnDef<T>> columns;
  final bool showCheckbox;
  final double checkboxWidth;
  
  final Color? Function(T item)? leftBorderColorBuilder;
  final bool isLast;

  const GenericTableRow({
    super.key,
    required this.item,
    this.isSelected = false,
    required this.columnWidths,
    this.onToggle,
    required this.columns,
    this.showCheckbox = true,
    this.checkboxWidth = 48.0,
    this.leftBorderColorBuilder,
    this.isLast = false,
  });

  @override
  State<GenericTableRow<T>> createState() => _GenericTableRowState<T>();
}

class _GenericTableRowState<T> extends State<GenericTableRow<T>> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final leftBorderColor = widget.leftBorderColorBuilder?.call(widget.item);

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        height: 54, 
        decoration: BoxDecoration(
          color: widget.isSelected
              ? colors.primaryContainer.withValues(alpha: 0.2)
              : _hovered
                  ? colors.surfaceContainerHighest.withValues(alpha: 0.35)
                  : Colors.transparent,
          border: Border(
            bottom: widget.isLast
                ? BorderSide.none
                : BorderSide(color: colors.outline.withValues(alpha: 0.1)),
            left: BorderSide(
              color: leftBorderColor ?? Colors.transparent,
              width: leftBorderColor != null ? 2.5 : 0.0,
            ),
          ),
        ),
        child: Row(
          children: [
            if (widget.showCheckbox)
              SizedBox(
                width: widget.checkboxWidth,
                child: Checkbox(
                  value: widget.isSelected, 
                  onChanged: (_) => widget.onToggle?.call(),
                ),
              ),
              
            ...widget.columns.map((col) {
              final currentWidth = widget.columnWidths[col.key] ?? col.initialWidth;
              
              return SizedBox(
                width: currentWidth,
                child: ClipRect(
                  child: col.cellBuilder(context, widget.item),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}