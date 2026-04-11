import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../models/flight_without_operation_model.dart';
import '../../models/flight_operation_model.dart';
import '../../services/auth_service.dart';
import '../../services/flight_operation_api_service.dart';
import '../../widgets/responsive_layout.dart';
import '../../widgets/flight_operation/operation_status_bar.dart';
import '../widgets/custom/custom_select_field.dart';

const _activeStatuses = {
  'Waiting', 'Boarding', 'Baggage Loading', 'Departed', 'Arrived'
};

const _statusColors = {
  'Scheduled':       Color(0xFF4ADE80), 
  'Waiting':         Color(0xFF94A3B8),
  'Boarding':        Color(0xFF818CF8),
  'Baggage Loading': Color(0xFFA78BFA),
  'Departed':        Color(0xFFFBBF24),
  'Arrived':         Color(0xFF34D399),
  'Completed':       Color(0xFF4ADE80),
  'Cancelled':       Color(0xFFF87171),
};

const _colDefs = <({String key, String label, double width})>[
  (key: 'time',     label: 'TIME',     width: 90.0),
  (key: 'flight',   label: 'FLIGHT',   width: 110.0),
  (key: 'route',    label: 'ROUTE',    width: 160.0),
  (key: 'aircraft', label: 'AIRCRAFT', width: 180.0),
  (key: 'status',   label: 'STATUS',   width: 160.0),
];

const _itemsPerPage = 15;

class FlightOperationsBoardPage extends StatefulWidget {
  const FlightOperationsBoardPage({super.key});

  @override
  State<FlightOperationsBoardPage> createState() =>
      _FlightOperationsBoardPageState();
}

class _FlightOperationsBoardPageState
    extends State<FlightOperationsBoardPage> {
  late final FlightOperationApiService _apiService;
  final _horizontalScroll = ScrollController();

  List<_BoardRow> _rows           = [];
  bool            _isLoading      = true;
  String?         _error;
  String?         _filterStatus;
  String?         _filterAircraft;
  int             _currentPage    = 1;
  late Map<String, double> _colWidths;

  @override
  void initState() {
    super.initState();
    _colWidths  = {for (final c in _colDefs) c.key: c.width};
    _apiService = FlightOperationApiService(context.read<AuthService>());
    _load();
  }

  @override
  void dispose() {
    _horizontalScroll.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      final results = await Future.wait([
        _apiService.getFlightsWithoutOperation(),
        _apiService.getFlightOperations(),
      ]);

      final flights    = results[0] as List<FlightWithoutOperationModel>;
      final operations = results[1] as List<FlightOperationModel>;

      final activeOps = operations
          .where((o) => _activeStatuses.contains(o.statusName))
          .toList();

      final rows = <_BoardRow>[
        ...activeOps.map(_BoardRow.fromOperation),
        ...flights.map(_BoardRow.fromFlight),
      ]..sort((a, b) => a.departsDatetime.compareTo(b.departsDatetime));

      if (mounted) setState(() { _rows = rows; _isLoading = false; });
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _isLoading = false; });
    }
  }

  // ── Derived ────────────────────────────────────────────────────────────────

  List<_BoardRow> get _filtered => _rows.where((r) {
        if (_filterStatus != null &&
            _filterStatus != 'All' &&
            r.statusName != _filterStatus) return false;
        if (_filterAircraft != null &&
            _filterAircraft != 'All' &&
            (r.aircraftModel ?? '—') != _filterAircraft) return false;
        return true;
      }).toList();

  int get _totalPages =>
      (_filtered.length / _itemsPerPage).ceil().clamp(1, 9999);

  List<_BoardRow> get _paginated {
    final start = (_currentPage - 1) * _itemsPerPage;
    final end   = (start + _itemsPerPage).clamp(0, _filtered.length);
    return _filtered.isEmpty ? [] : _filtered.sublist(start, end);
  }

  List<String> get _statusOptions =>
      ['All', ..._rows.map((r) => r.statusName).toSet().toList()..sort()];

  List<String> get _aircraftOptions => [
        'All',
        ..._rows
            .map((r) => r.aircraftModel ?? '—')
            .where((a) => a != '—')
            .toSet()
            .toList()
              ..sort(),
      ];

  void _onResize(String key, double delta) {
    setState(() {
      final cur       = _colWidths[key] ?? 100;
      _colWidths[key] = (cur + delta).clamp(60.0, 400.0);
    });
  }

  @override
  Widget build(BuildContext context) {
    return ResponsiveLayout(
      header: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const OperatorStatusBar(),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize:       MainAxisSize.min,
              children: [
                _buildPageHeader(),
                const SizedBox(height: 16),
                if (!_isLoading && _error == null) _buildFilters(),
              ],
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        child: _buildTable(),
      ),
    );
  }

  Widget _buildPageHeader() {
    final colors = Theme.of(context).colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Flight Operations',
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 3),
            Row(
              children: [
                Container(
                  width:  6,
                  height: 6,
                  decoration: const BoxDecoration(
                    color: Color(0xFF4ADE80),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  '${_rows.where((r) => _activeStatuses.contains(r.statusName)).length} active'
                  '  ·  '
                  '${_rows.where((r) => r.statusName == 'Scheduled').length} scheduled',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ],
        ),
        const Spacer(),
        _IconBtn(
          icon:    Icons.refresh_rounded,
          tooltip: 'Refresh',
          onTap:   _load,
          colors:  colors,
        ),
      ],
    );
  }

  Widget _buildFilters() {
    return Row(
      children: [
        SizedBox(
          width: 180,
          child: CustomSelectField(
            label:     'Status',
            value:     _filterStatus ?? 'All',
            icon:      Icons.circle_outlined,
            items:     _statusOptions,
            onChanged: (v) => setState(() {
              _filterStatus = v == 'All' ? null : v;
              _currentPage  = 1;
            }),
          ),
        ),
        const SizedBox(width: 10),
        SizedBox(
          width: 180,
          child: CustomSelectField(
            label:     'Aircraft',
            value:     _filterAircraft ?? 'All',
            icon:      Icons.airplanemode_active_rounded,
            items:     _aircraftOptions,
            onChanged: (v) => setState(() {
              _filterAircraft = v == 'All' ? null : v;
              _currentPage    = 1;
            }),
          ),
        ),
        const Spacer(),
        if (_filterStatus != null)
          _ActiveChip(
            label:   _filterStatus!,
            onClear: () => setState(() { _filterStatus = null; _currentPage = 1; }),
            colors:  Theme.of(context).colorScheme,
          ),
        if (_filterStatus != null && _filterAircraft != null)
          const SizedBox(width: 6),
        if (_filterAircraft != null)
          _ActiveChip(
            label:   _filterAircraft!,
            onClear: () => setState(() { _filterAircraft = null; _currentPage = 1; }),
            colors:  Theme.of(context).colorScheme,
          ),
      ],
    );
  }


  Widget _buildTable() {
    final colors = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color:        colors.surface,
        borderRadius: BorderRadius.circular(10),
        border:       Border.all(color: colors.outlineVariant),
      ),
      child: Column(
        children: [
          Expanded(
            child: _isLoading
                ? Center(
                    child: CircularProgressIndicator(
                        color: colors.primary, strokeWidth: 2))
                : _error != null
                    ? _buildError(colors)
                    : _buildContent(colors),
          ),
          _buildPagination(colors),
        ],
      ),
    );
  }

  Widget _buildError(ColorScheme colors) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.error_outline_rounded, size: 40, color: colors.error),
          const SizedBox(height: 12),
          Text(_error!,
              style: TextStyle(color: colors.error, fontSize: 13)),
          const SizedBox(height: 14),
          OutlinedButton.icon(
            onPressed: _load,
            icon:  const Icon(Icons.refresh_rounded, size: 14),
            label: const Text('Retry', style: TextStyle(fontSize: 12)),
            style: OutlinedButton.styleFrom(
              foregroundColor: colors.primary,
              side: BorderSide(color: colors.primary.withValues(alpha: 0.4)),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(7)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(ColorScheme colors) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final totalW      = _colWidths.values.fold(0.0, (s, w) => s + w);
        final needsScroll = totalW > constraints.maxWidth;

        Widget content = Column(
          children: [
            _buildTableHeader(colors),
            Expanded(child: _buildRows(colors)),
          ],
        );

        if (needsScroll) {
          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            controller:      _horizontalScroll,
            child: SizedBox(width: totalW, child: content),
          );
        }
        return ClipRect(
          child: SizedBox(width: constraints.maxWidth, child: content),
        );
      },
    );
  }

  Widget _buildTableHeader(ColorScheme colors) {
    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: colors.surfaceContainerHighest.withValues(alpha: 0.6),
        border: Border(bottom: BorderSide(color: colors.outlineVariant)),
        borderRadius: const BorderRadius.only(
          topLeft:  Radius.circular(10),
          topRight: Radius.circular(10),
        ),
      ),
      child: Row(
        children: [
          ..._colDefs.map((col) {
            final isLast = col == _colDefs.last;
            return SizedBox(
              width: _colWidths[col.key],
              child: Row(
                children: [
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(
                          left: col == _colDefs.first ? 20 : 8),
                      child: Text(
                        col.label,
                        style: TextStyle(
                          fontSize:      10,
                          fontWeight:    FontWeight.w700,
                          letterSpacing: 1.1,
                          color:         colors.onSurfaceVariant,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                  if (!isLast)
                    GestureDetector(
                      onHorizontalDragUpdate: (d) =>
                          _onResize(col.key, d.delta.dx),
                      child: MouseRegion(
                        cursor: SystemMouseCursors.resizeColumn,
                        child: SizedBox(
                          width: 8, height: 44,
                          child: Center(
                            child: Container(
                              width: 1, height: 18,
                              color: colors.outlineVariant,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            );
          }),

          Expanded(
            child: Row(
              children: [
                SizedBox(
                  width: 8, height: 44,
                  child: Center(
                    child: Container(
                      width: 1, height: 18,
                      color: colors.outlineVariant,
                    ),
                  ),
                ),
                Expanded(
                  child: Center(
                    child: Text(
                      'ACTION',
                      style: TextStyle(
                        fontSize:      10,
                        fontWeight:    FontWeight.w700,
                        letterSpacing: 1.1,
                        color:         colors.onSurfaceVariant,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildRows(ColorScheme colors) {
    final rows = _paginated;
    if (rows.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.flight_outlined,
                size: 40,
                color: colors.onSurfaceVariant.withValues(alpha: 0.3)),
            const SizedBox(height: 12),
            Text('No flights found',
                style: TextStyle(
                    fontWeight: FontWeight.w500, color: colors.onSurface)),
            const SizedBox(height: 4),
            Text(
              (_filterStatus != null || _filterAircraft != null)
                  ? 'Try clearing the filters'
                  : 'No active or upcoming flights',
              style: TextStyle(fontSize: 12, color: colors.onSurfaceVariant),
            ),
            if (_filterStatus != null || _filterAircraft != null) ...[
              const SizedBox(height: 14),
              OutlinedButton(
                onPressed: () => setState(() {
                  _filterStatus   = null;
                  _filterAircraft = null;
                  _currentPage    = 1;
                }),
                style: OutlinedButton.styleFrom(
                  foregroundColor: colors.primary,
                  side: BorderSide(
                      color: colors.primary.withValues(alpha: 0.4)),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(7)),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 8),
                ),
                child: const Text('Clear filters',
                    style: TextStyle(fontSize: 12)),
              ),
            ],
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: rows.length,
      itemBuilder: (_, i) => _BoardTableRow(
        row:       rows[i],
        colWidths: _colWidths,
        isLast:    i == rows.length - 1,
        onStart:   rows[i].flight != null
            ? () => context.go('/flight-operations/create',
                extra: rows[i].flight!)
            : null,
        onView: rows[i].operation != null
            ? () => context.go('/flight-operations/active')
            : null,
      ),
    );
  }

  Widget _buildPagination(ColorScheme colors) {
    final total = _filtered.length;
    final start = total == 0 ? 0 : (_currentPage - 1) * _itemsPerPage + 1;
    final end   = (start + _itemsPerPage - 1).clamp(0, total);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: colors.outlineVariant)),
      ),
      child: Row(
        children: [
          Text(
            total == 0
                ? 'No results'
                : 'Showing $start–$end of $total flights',
            style: TextStyle(fontSize: 12, color: colors.onSurfaceVariant),
          ),
          const Spacer(),
          _PageBtn(
            icon:    Icons.chevron_left_rounded,
            enabled: _currentPage > 1,
            onTap:   () => setState(() => _currentPage--),
            colors:  colors,
          ),
          const SizedBox(width: 8),
          Text('Page $_currentPage of $_totalPages',
              style: TextStyle(
                  fontSize: 12, color: colors.onSurfaceVariant)),
          const SizedBox(width: 8),
          _PageBtn(
            icon:    Icons.chevron_right_rounded,
            enabled: _currentPage < _totalPages,
            onTap:   () => setState(() => _currentPage++),
            colors:  colors,
          ),
        ],
      ),
    );
  }
}

class _BoardTableRow extends StatefulWidget {
  final _BoardRow           row;
  final Map<String, double> colWidths;
  final bool                isLast;
  final VoidCallback?       onStart;
  final VoidCallback?       onView;

  const _BoardTableRow({
    required this.row,
    required this.colWidths,
    required this.isLast,
    this.onStart,
    this.onView,
  });

  @override
  State<_BoardTableRow> createState() => _BoardTableRowState();
}

class _BoardTableRowState extends State<_BoardTableRow> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final colors      = Theme.of(context).colorScheme;
    final row         = widget.row;
    final statusColor = row.statusName == 'Scheduled'
        ? colors.primary
        : _statusColors[row.statusName] ?? colors.onSurfaceVariant;
    final isActive    = row.operation != null;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit:  (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        height:   54,
        decoration: BoxDecoration(
          color: _hovered
              ? colors.surfaceContainerHighest.withValues(alpha: 0.35)
              : Colors.transparent,
          border: Border(
            bottom: widget.isLast
                ? BorderSide.none
                : BorderSide(
                    color: colors.outlineVariant.withValues(alpha: 0.5)),
            left: BorderSide(
              color: isActive
                  ? statusColor.withValues(alpha: 0.8)
                  : Colors.transparent,
              width: 2.5,
            ),
          ),
        ),
        child: Row(
          children: [
            // TIME
            SizedBox(
              width: widget.colWidths['time'],
              child: Padding(
                padding: const EdgeInsets.only(left: 20),
                child: Text(
                  row.timeLabel,
                  style: TextStyle(
                    fontSize:     13,
                    fontWeight:   FontWeight.w600,
                    fontFeatures: const [FontFeature.tabularFigures()],
                    color:        colors.onSurface,
                  ),
                ),
              ),
            ),

            // FLIGHT
            SizedBox(
              width: widget.colWidths['flight'],
              child: Padding(
                padding: const EdgeInsets.only(left: 8),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(
                    color:        colors.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    row.flightNumber,
                    style: TextStyle(
                      fontSize:   12,
                      fontWeight: FontWeight.w700,
                      color:      colors.primary,
                    ),
                  ),
                ),
              ),
            ),

            // ROUTE
            SizedBox(
              width: widget.colWidths['route'],
              child: Padding(
                padding: const EdgeInsets.only(left: 8, right: 8),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(row.departsCode,
                        style: TextStyle(
                          fontSize:   13,
                          fontWeight: FontWeight.w600,
                          color:      colors.onSurface,
                        )),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 5),
                      child: Icon(Icons.arrow_forward_rounded,
                          size:  12,
                          color: colors.onSurfaceVariant
                              .withValues(alpha: 0.5)),
                    ),
                    Text(row.arrivesCode,
                        style: TextStyle(
                          fontSize:   13,
                          fontWeight: FontWeight.w600,
                          color:      colors.onSurface,
                        )),
                  ],
                ),
              ),
            ),

            // AIRCRAFT
            SizedBox(
              width: widget.colWidths['aircraft'],
              child: Padding(
                padding: const EdgeInsets.only(left: 8, right: 8),
                child: row.aircraftModel != null
                    ? Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.airplanemode_active_rounded,
                              size:  12,
                              color: colors.onSurfaceVariant
                                  .withValues(alpha: 0.5)),
                          const SizedBox(width: 5),
                          Flexible(
                            child: Text(
                              row.aircraftModel!,
                              style: TextStyle(
                                  fontSize: 13, color: colors.onSurface),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      )
                    : Text('—',
                        style: TextStyle(
                            fontSize: 13,
                            color: colors.onSurfaceVariant
                                .withValues(alpha: 0.4))),
              ),
            ),

            // STATUS
            SizedBox(
              width: widget.colWidths['status'],
              child: Padding(
                padding: const EdgeInsets.only(left: 8),
                child: _StatusBadge(
                    label: row.statusName, color: statusColor),
              ),
            ),

            // ACTION — завжди справа
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(right: 16),
                child: Align(
                  alignment: Alignment.centerRight,
                  child: widget.onStart != null
                      ? _ActionBtn(
                          label:   'Start Operation',
                          icon:    Icons.rocket_launch_rounded,
                          primary: true,
                          onTap:   widget.onStart!,
                          colors:  colors,
                        )
                      : widget.onView != null
                          ? _ActionBtn(
                              label:   'View',
                              icon:    Icons.open_in_new_rounded,
                              primary: false,
                              onTap:   widget.onView!,
                              colors:  colors,
                            )
                          : const SizedBox.shrink(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActiveChip extends StatelessWidget {
  final String       label;
  final VoidCallback onClear;
  final ColorScheme  colors;

  const _ActiveChip({
    required this.label,
    required this.onClear,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color:        colors.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colors.primary.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label,
              style: TextStyle(
                fontSize:   11,
                fontWeight: FontWeight.w500,
                color:      colors.primary,
              )),
          const SizedBox(width: 5),
          GestureDetector(
            onTap: onClear,
            child: Icon(Icons.close_rounded,
                size: 13, color: colors.primary),
          ),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String label;
  final Color  color;

  const _StatusBadge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color:        color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border:       Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Text(
        label,
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

class _ActionBtn extends StatefulWidget {
  final String       label;
  final IconData     icon;
  final bool         primary;
  final VoidCallback onTap;
  final ColorScheme  colors;

  const _ActionBtn({
    required this.label,
    required this.icon,
    required this.primary,
    required this.onTap,
    required this.colors,
  });

  @override
  State<_ActionBtn> createState() => _ActionBtnState();
}

class _ActionBtnState extends State<_ActionBtn> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final color = widget.primary
        ? widget.colors.primary
        : widget.colors.onSurfaceVariant;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit:  (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 130),
          padding: const EdgeInsets.symmetric(
              horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: widget.primary
                ? (_hovered
                    ? color.withValues(alpha: 0.18)
                    : color.withValues(alpha: 0.1))
                : (_hovered
                    ? widget.colors.surfaceContainerHighest
                    : Colors.transparent),
            borderRadius: BorderRadius.circular(7),
            border: Border.all(
              color: widget.primary
                  ? color.withValues(alpha: _hovered ? 0.5 : 0.3)
                  : widget.colors.outlineVariant,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(widget.icon, size: 13, color: color),
              const SizedBox(width: 5),
              Text(widget.label,
                  style: TextStyle(
                    fontSize:   12,
                    fontWeight: FontWeight.w500,
                    color:      color,
                  )),
            ],
          ),
        ),
      ),
    );
  }
}

class _IconBtn extends StatelessWidget {
  final IconData     icon;
  final String       tooltip;
  final VoidCallback onTap;
  final ColorScheme  colors;

  const _IconBtn({
    required this.icon,
    required this.tooltip,
    required this.onTap,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width:  36,
          height: 36,
          decoration: BoxDecoration(
            color: colors.surfaceContainerHighest.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: colors.outlineVariant),
          ),
          child: Icon(icon, size: 17, color: colors.onSurfaceVariant),
        ),
      ),
    );
  }
}

class _PageBtn extends StatelessWidget {
  final IconData     icon;
  final bool         enabled;
  final VoidCallback onTap;
  final ColorScheme  colors;

  const _PageBtn({
    required this.icon,
    required this.enabled,
    required this.onTap,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        width:  28,
        height: 28,
        decoration: BoxDecoration(
          color: colors.surfaceContainerHighest.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: colors.outlineVariant),
        ),
        child: Icon(icon,
            size:  16,
            color: enabled
                ? colors.onSurface
                : colors.onSurfaceVariant.withValues(alpha: 0.3)),
      ),
    );
  }
}

class _BoardRow {
  final String   flightNumber;
  final String   departsCode;
  final String   arrivesCode;
  final DateTime departsDatetime;
  final String?  aircraftModel;
  final String   statusName;

  final FlightWithoutOperationModel? flight;
  final FlightOperationModel?        operation;

  const _BoardRow({
    required this.flightNumber,
    required this.departsCode,
    required this.arrivesCode,
    required this.departsDatetime,
    required this.aircraftModel,
    required this.statusName,
    this.flight,
    this.operation,
  });

  factory _BoardRow.fromFlight(FlightWithoutOperationModel f) => _BoardRow(
        flightNumber:    f.flightNumber,
        departsCode:     f.departsCode,
        arrivesCode:     f.arrivesCode,
        departsDatetime: f.departsDatetime,
        aircraftModel:   null,
        statusName:      'Scheduled',
        flight:          f,
      );

  factory _BoardRow.fromOperation(FlightOperationModel o) => _BoardRow(
        flightNumber:    o.flightNumber ?? '—',
        departsCode:     o.departsCode ?? '—',
        arrivesCode:     o.arrivesCode ?? '—',
        departsDatetime: o.departsDatetime ?? DateTime.now(),
        aircraftModel:   o.aircraftModel,
        statusName:      o.statusName ?? '—',
        operation:       o,
      );

  String get timeLabel {
    final h = departsDatetime.hour.toString().padLeft(2, '0');
    final m = departsDatetime.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }
}