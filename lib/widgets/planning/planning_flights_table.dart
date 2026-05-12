import 'package:flutter/material.dart';
import '../../models/planning_overview_model.dart';
import '../../widgets/admin/user_table_pagination.dart';
import 'planning_table_row.dart';
import 'planning_error_banner.dart';

class PlanningFlightsTable extends StatefulWidget {
  final bool isLoading;
  final String? error;
  final List<OverviewFlight> flights;
  final Map<String, double> colWidths;
  final List<({String key, String label, double width})> colDefs;
  final ScrollController horizontalScroll;
  final int currentPage;
  final int totalPages;
  final int totalCount;
  final int itemsPerPage;
  final bool hasActiveFilters;
  final void Function(String key, double delta) onColumnResize;
  final VoidCallback onRetry;
  final VoidCallback onPreviousPage;
  final VoidCallback onNextPage;

  final void Function(OverviewFlight flight) onStatusTap;
  final void Function(OverviewFlight flight) onEditTap;

  const PlanningFlightsTable({
    super.key,
    required this.isLoading,
    required this.error,
    required this.flights,
    required this.colWidths,
    required this.colDefs,
    required this.horizontalScroll,
    required this.currentPage,
    required this.totalPages,
    required this.totalCount,
    required this.itemsPerPage,
    required this.hasActiveFilters,
    required this.onColumnResize,
    required this.onRetry,
    required this.onPreviousPage,
    required this.onNextPage,
    required this.onStatusTap,
    required this.onEditTap,
  });

  @override
  State<PlanningFlightsTable> createState() => _PlanningFlightsTableState();
}

class _PlanningFlightsTableState extends State<PlanningFlightsTable> {
  late Map<String, double> _localWidths;
  double? _lastAvailableWidth;

  @override
  void initState() {
    super.initState();
    _localWidths = Map.from(widget.colWidths);
  }

  void _initWidthsForAvailable(double availableWidth) {
    if (_lastAvailableWidth == availableWidth) return;
    _lastAvailableWidth = availableWidth;

    final totalDefault =
        widget.colDefs.fold<double>(0, (s, c) => s + c.width);

    _localWidths = {
      for (final c in widget.colDefs)
        c.key: (c.width / totalDefault) * availableWidth,
    };
  }

  void _onResize(String key, double delta) {
    setState(() {
      final current = _localWidths[key] ?? 100;
      _localWidths[key] = (current + delta).clamp(60.0, 600.0);
    });
    widget.onColumnResize(key, delta);
  }

  double get _totalWidth =>
      _localWidths.values.fold(0, (s, w) => s + w);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color:
              Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        children: [
          Expanded(
            child: widget.isLoading
                ? const Center(child: CircularProgressIndicator())
                : widget.error != null
                    ? Center(
                        child: PlanningErrorBanner(
                          message: 'Could not load flights',
                          onRetry: widget.onRetry,
                        ),
                      )
                    : LayoutBuilder(
                        builder: (context, constraints) {
                          _initWidthsForAvailable(constraints.maxWidth);

                          final needsScroll =
                              _totalWidth > constraints.maxWidth;

                          Widget tableContent = Column(
                            children: [
                              _buildTableHeader(context),
                              Expanded(
                                child: widget.flights.isEmpty
                                    ? _buildEmptyState(context)
                                    : ListView.builder(
                                        itemCount: widget.flights.length,
                                        itemBuilder: (context, index) =>
                                            PlanningTableRow(
                                          flight: widget.flights[index],
                                          columnWidths: _localWidths,
                                          onStatusTap: widget.onStatusTap,
                                          onEditTap: widget.onEditTap,
                                        ),
                                      ),
                              ),
                            ],
                          );

                          if (needsScroll) {
                            return SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              controller: widget.horizontalScroll,
                              child: SizedBox(
                                width: _totalWidth,
                                child: tableContent,
                              ),
                            );
                          }

                          return SizedBox(
                            width: constraints.maxWidth,
                            child: tableContent,
                          );
                        },
                      ),
          ),
          UserTablePagination(
            currentPage: widget.currentPage,
            totalPages: widget.totalPages,
            totalUsers: widget.totalCount,
            itemsPerPage: widget.itemsPerPage,
            onPrevious: widget.onPreviousPage,
            onNext: widget.onNextPage,
          ),
        ],
      ),
    );
  }

  Widget _buildTableHeader(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: colors.surfaceContainerHighest.withValues(alpha: 0.5),
        border: Border(
            bottom:
                BorderSide(color: colors.outline.withValues(alpha: 0.2))),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(6),
          topRight: Radius.circular(6),
        ),
      ),
      child: Row(
        children: widget.colDefs.map((col) {
          final isFirst = col == widget.colDefs.first;
          final isLast = col == widget.colDefs.last;
          return SizedBox(
            width: _localWidths[col.key],
            child: Row(
              children: [
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(left: isFirst ? 16 : 4),
                    child: Text(
                      col.label,
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
                if (!isLast)
                  GestureDetector(
                    onHorizontalDragUpdate: (d) =>
                        _onResize(col.key, d.delta.dx),
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
                            color: colors.outline.withValues(alpha: 0.3),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.flight_rounded,
            size: 64,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 16),
          Text(
            widget.hasActiveFilters
                ? 'No flights match the selected filters'
                : 'No flights for the selected period',
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ],
      ),
    );
  }
}