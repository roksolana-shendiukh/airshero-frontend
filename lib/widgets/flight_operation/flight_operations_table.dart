import 'package:flutter/material.dart';
import '../../models/board_row.dart';
import 'board_table_columns.dart'; 
import '../table_column_def.dart'; 
import 'board_widgets.dart'; 
import '../generic_table_header.dart';
import '../generic_table_row.dart'; 
import '../../constants/board_constants.dart';

class FlightOperationsTable extends StatefulWidget {
  final List<BoardRow> rows;
  final bool isLoading;
  final String? error;
  
  final int currentPage;
  final int totalPages;
  final int totalItems;
  final int itemsPerPage;
  
  final bool hasFiltersApplied;

  final VoidCallback onRetry;
  final VoidCallback onClearFilters;
  final ValueChanged<int> onPageChanged;
  final void Function(BoardRow) onStartOperation;
  final void Function(BoardRow) onViewOperation;
  final void Function(BoardRow) onChangeGate;

  const FlightOperationsTable({
    super.key,
    required this.rows,
    required this.isLoading,
    this.error,
    required this.currentPage,
    required this.totalPages,
    required this.totalItems,
    required this.itemsPerPage,
    required this.hasFiltersApplied,
    required this.onRetry,
    required this.onClearFilters,
    required this.onPageChanged,
    required this.onStartOperation,
    required this.onViewOperation,
    required this.onChangeGate,
  });

  @override
  State<FlightOperationsTable> createState() => _FlightOperationsTableState();
}

class _FlightOperationsTableState extends State<FlightOperationsTable> {
  final _horizontalScroll = ScrollController();
  late Map<String, double> _colWidths;
  late List<TableColumnDef<BoardRow>> _columns;

  @override
  void initState() {
    super.initState();
    _columns = BoardTableColumns.buildColumns(
      onStart: widget.onStartOperation,
      onView: widget.onViewOperation,
      onChangeGate: widget.onChangeGate,
    );
    
    _colWidths = {for (final c in _columns) c.key: c.initialWidth};
  }

  @override
  void dispose() {
    _horizontalScroll.dispose();
    super.dispose();
  }

  void _onResize(String key, double delta) {
    setState(() {
      final cur = _colWidths[key] ?? 100;
      _colWidths[key] = (cur + delta).clamp(60.0, 400.0);
    });
  }

  double get _totalWidth => _colWidths.values.fold(0.0, (s, w) => s + w);

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: Column(
        children: [
          Expanded(
            child: widget.isLoading
                ? Center(child: CircularProgressIndicator(color: colors.primary, strokeWidth: 2))
                : widget.error != null
                    ? _buildError(colors)
                    : _buildContent(colors),
          ),
          _buildPagination(colors),
        ],
      ),
    );
  }

  Widget _buildContent(ColorScheme colors) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double totalColWidth = _colWidths.values.fold(0.0, (s, w) => s + w);
        
        final double tableWidth = totalColWidth < constraints.maxWidth 
            ? constraints.maxWidth 
            : totalColWidth;

        Widget content = Column(
          children: [
            GenericTableHeader<BoardRow>(
              columns: _columns,
              columnWidths: _colWidths,
              selectAll: false,
              showCheckbox: false,
              onToggleSelectAll: () {},
              onColumnResize: _onResize,
            ),
            Expanded(child: _buildRows(colors)),
          ],
        );

        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          controller: _horizontalScroll,
          child: SizedBox(
            width: tableWidth, 
            child: content,
          ),
        );
      },
    );
  }

  Widget _buildRows(ColorScheme colors) {
    if (widget.rows.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.flight_outlined, size: 40, color: colors.onSurfaceVariant.withValues(alpha: 0.3)),
            const SizedBox(height: 12),
            Text('No flights found', style: TextStyle(fontWeight: FontWeight.w500, color: colors.onSurface)),
            const SizedBox(height: 4),
            Text(
              widget.hasFiltersApplied
                  ? 'Try clearing the filters'
                  : 'No active or upcoming flights',
              style: TextStyle(fontSize: 12, color: colors.onSurfaceVariant),
            ),
            if (widget.hasFiltersApplied) ...[
              const SizedBox(height: 14),
              OutlinedButton(
                onPressed: widget.onClearFilters,
                style: OutlinedButton.styleFrom(
                  foregroundColor: colors.primary,
                  side: BorderSide(color: colors.primary.withValues(alpha: 0.4)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(7)),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                ),
                child: const Text('Clear filters', style: TextStyle(fontSize: 12)),
              ),
            ],
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: widget.rows.length,
      itemBuilder: (context, i) {
        final row = widget.rows[i];

        return GenericTableRow<BoardRow>(
          item: row,
          columns: _columns,
          columnWidths: _colWidths,
          isLast: i == widget.rows.length - 1,
          showCheckbox: false,
          leftBorderColorBuilder: (item) {
            if (item.operation != null) {
              final statusColor = item.statusName == 'Scheduled'
                  ? colors.primary
                  : statusColors[item.statusName] ?? colors.onSurfaceVariant;
              return statusColor.withValues(alpha: 0.8);
            }
            return null;
          },
        );
      },
    );
  }

  Widget _buildError(ColorScheme colors) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.error_outline_rounded, size: 40, color: colors.error),
          const SizedBox(height: 12),
          Text(widget.error!, style: TextStyle(color: colors.error, fontSize: 13)),
          const SizedBox(height: 14),
          OutlinedButton.icon(
            onPressed: widget.onRetry,
            icon: const Icon(Icons.refresh_rounded, size: 14),
            label: const Text('Retry', style: TextStyle(fontSize: 12)),
            style: OutlinedButton.styleFrom(
              foregroundColor: colors.primary,
              side: BorderSide(color: colors.primary.withValues(alpha: 0.4)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(7)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPagination(ColorScheme colors) {
    final start = widget.totalItems == 0 ? 0 : ((widget.currentPage - 1) * widget.itemsPerPage) + 1;
    final end = (start + widget.itemsPerPage - 1).clamp(0, widget.totalItems);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: colors.outlineVariant)),
      ),
      child: Row(
        children: [
          Text(
            widget.totalItems == 0
                ? 'No results'
                : 'Showing $start–$end of ${widget.totalItems} flights',
            style: TextStyle(fontSize: 12, color: colors.onSurfaceVariant),
          ),
          const Spacer(),
          PageBtn(
            icon: Icons.chevron_left_rounded,
            enabled: widget.currentPage > 1,
            onTap: () => widget.onPageChanged(widget.currentPage - 1),
            colors: colors,
          ),
          const SizedBox(width: 8),
          Text('Page ${widget.currentPage} of ${widget.totalPages}',
              style: TextStyle(fontSize: 12, color: colors.onSurfaceVariant)),
          const SizedBox(width: 8),
          PageBtn(
            icon: Icons.chevron_right_rounded,
            enabled: widget.currentPage < widget.totalPages,
            onTap: () => widget.onPageChanged(widget.currentPage + 1),
            colors: colors,
          ),
        ],
      ),
    );
  }
}







