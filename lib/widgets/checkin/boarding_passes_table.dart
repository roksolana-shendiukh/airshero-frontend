import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../services/checkin_api_service.dart';

class BoardingPassesTable extends StatefulWidget {
  final List<Map<String, dynamic>> passes;
  final AuthService authService;
  final String searchQuery;

  const BoardingPassesTable({
    super.key,
    required this.passes,
    required this.authService,
    this.searchQuery = '',
  });

  @override
  State<BoardingPassesTable> createState() => _BoardingPassesTableState();
}

class _BoardingPassesTableState extends State<BoardingPassesTable> {
  static const int _pageSize = 20;
  int _currentPage = 0;
  final Set<int> _expandedRows = {};
  final Map<int, List<Map<String, dynamic>>> _baggageCache = {};
  final Map<int, bool> _loadingBaggage = {};

  Map<String, double> _columnWidths = {
    'expand': 48,
    'ticket': 150,
    'passenger': 180,
    'flight': 100,
    'route': 180,
    'departure': 160,
    'seat': 80,
    'class': 120,
    'issuedAt': 160,
    'bags': 80,
  };

  double get _totalWidth =>
      _columnWidths.values.fold(0.0, (sum, w) => sum + w);

  int get _totalPages =>
      (widget.passes.length / _pageSize).ceil().clamp(1, 9999);

  List<Map<String, dynamic>> get _currentPageItems {
    final start = _currentPage * _pageSize;
    final end = (start + _pageSize).clamp(0, widget.passes.length);
    return widget.passes.sublist(start, end);
  }

  @override
  void didUpdateWidget(BoardingPassesTable old) {
    super.didUpdateWidget(old);
    if (widget.passes != old.passes) {
      setState(() {
        _currentPage = 0;
        _expandedRows.clear();
      });
    }
  }

  Future<void> _loadBaggage(int boardingPassId) async {
    if (_baggageCache.containsKey(boardingPassId)) return;
    setState(() => _loadingBaggage[boardingPassId] = true);
    try {
      final api = CheckInApiService(widget.authService);
      final bags = await api.getBoardingPassBaggage(boardingPassId);
      if (mounted) {
        setState(() {
          _baggageCache[boardingPassId] = bags;
          _loadingBaggage[boardingPassId] = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _loadingBaggage[boardingPassId] = false);
    }
  }

  void _toggleRow(int boardingPassId) {
    setState(() {
      if (_expandedRows.contains(boardingPassId)) {
        _expandedRows.remove(boardingPassId);
      } else {
        _expandedRows.add(boardingPassId);
        _loadBaggage(boardingPassId);
      }
    });
  }

  String _formatDate(dynamic raw) {
    if (raw == null) return '—';
    final dt = DateTime.tryParse(raw.toString());
    if (dt == null) return '—';
    return '${dt.day.toString().padLeft(2, '0')}.${dt.month.toString().padLeft(2, '0')}.${dt.year}  '
        '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final pageItems = _currentPageItems;

    return Column(
      children: [
        _BoardingPassesHeader(
          columnWidths: _columnWidths,
          onColumnResize: (key, delta) {
            setState(() {
              final current = _columnWidths[key] ?? 100;
              _columnWidths[key] = (current + delta).clamp(40.0, 400.0);
            });
          },
        ),

        Expanded(
          child: pageItems.isEmpty
              ? Center(
                  child: Text(
                    'No boarding passes found',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: colors.onSurfaceVariant,
                        ),
                  ),
                )
              : SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: SizedBox(
                    width: _totalWidth,
                    child: ListView.builder(
                      itemCount: pageItems.length,
                      itemBuilder: (context, index) {
                        final pass = pageItems[index];
                        final id = pass['boardingPassId'] as int;
                        final isExpanded = _expandedRows.contains(id);
                        final isLoading = _loadingBaggage[id] == true;
                        final bags = _baggageCache[id] ?? [];

                        return Column(
                          children: [
                            // Main row
                            InkWell(
                              onTap: () => _toggleRow(id),
                              child: Container(
                                height: 44,
                                decoration: BoxDecoration(
                                  color: isExpanded
                                      ? colors.primaryContainer
                                          .withOpacity(0.15)
                                      : index.isEven
                                          ? null
                                          : colors.surfaceContainerLow
                                              .withOpacity(0.3),
                                  border: Border(
                                    bottom: BorderSide(
                                      color: colors.outline.withOpacity(0.08),
                                    ),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    SizedBox(
                                      width: _columnWidths['expand']!,
                                      child: Center(
                                        child: AnimatedRotation(
                                          turns: isExpanded ? 0.25 : 0,
                                          duration: const Duration(
                                              milliseconds: 150),
                                          child: Icon(
                                            Icons.chevron_right,
                                            size: 18,
                                            color: colors.onSurfaceVariant,
                                          ),
                                        ),
                                      ),
                                    ),

                                    _cell(
                                      _columnWidths['ticket']!,
                                      Text(
                                        pass['ticketNumber'] ?? '—',
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyMedium
                                            ?.copyWith(
                                              fontWeight: FontWeight.w600,
                                              color: colors.primary,
                                            ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),

                                    _cell(
                                      _columnWidths['passenger']!,
                                      Text(
                                        pass['passengerName'] ?? '—',
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyMedium,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),

                                    _cell(
                                      _columnWidths['flight']!,
                                      Text(
                                        pass['flightNumber'] ?? '—',
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyMedium
                                            ?.copyWith(
                                                fontWeight: FontWeight.w500),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),

                                    _cell(
                                      _columnWidths['route']!,
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Flexible(
                                            child: Text(
                                              pass['departsAirport'] ?? '—',
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .bodyMedium,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          Padding(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 4),
                                            child: Icon(Icons.arrow_forward,
                                                size: 14,
                                                color: colors.onSurfaceVariant),
                                          ),
                                          Flexible(
                                            child: Text(
                                              pass['arrivesAirport'] ?? '—',
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .bodyMedium,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),

                                    _cell(
                                      _columnWidths['departure']!,
                                      Text(
                                        _formatDate(pass['departsDatetime']),
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),

                                    _cell(
                                      _columnWidths['seat']!,
                                      Text(
                                        pass['seat'] ?? '—',
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyMedium,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),

                                    _cell(
                                      _columnWidths['class']!,
                                      pass['className'] != null
                                          ? _ClassChip(className: pass['className'] as String)
                                          : const Text('—'),
                                    ),

                                    _cell(
                                      _columnWidths['issuedAt']!,
                                      Text(
                                        _formatDate(pass['issuedAt']),
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall
                                            ?.copyWith(
                                                color: colors.onSurfaceVariant),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),

                                    _cell(
                                      _columnWidths['bags']!,
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(Icons.luggage_outlined,
                                              size: 14,
                                              color: colors.onSurfaceVariant),
                                          const SizedBox(width: 4),
                                          Text(
                                            '${pass['bagCount'] ?? 0}',
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodyMedium,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),

                            // Expanded baggage rows
                            if (isExpanded)
                              Container(
                                decoration: BoxDecoration(
                                  color: colors.surfaceContainerLowest,
                                  border: Border(
                                    bottom: BorderSide(
                                        color: colors.outline.withOpacity(0.12)),
                                  ),
                                ),
                                child: isLoading
                                    ? const Padding(
                                        padding: EdgeInsets.all(12),
                                        child: Center(
                                            child: SizedBox(
                                                width: 18,
                                                height: 18,
                                                child:
                                                    CircularProgressIndicator(
                                                        strokeWidth: 2))),
                                      )
                                    : bags.isEmpty
                                        ? Padding(
                                            padding: const EdgeInsets.fromLTRB(
                                                48, 8, 16, 8),
                                            child: Text(
                                              'No baggage registered',
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .bodySmall
                                                  ?.copyWith(
                                                      color: colors
                                                          .onSurfaceVariant),
                                            ),
                                          )
                                        : Column(
                                            children: [
                                              Padding(
                                                padding:
                                                    const EdgeInsets.fromLTRB(
                                                        48, 8, 16, 4),
                                                child: Row(
                                                  children: [
                                                    SizedBox(
                                                      width: 200,
                                                      child: Text(
                                                        'Tracking #',
                                                        style: Theme.of(context)
                                                            .textTheme
                                                            .labelSmall
                                                            ?.copyWith(
                                                              color: colors
                                                                  .onSurfaceVariant,
                                                              letterSpacing: 0.5,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w600,
                                                            ),
                                                      ),
                                                    ),
                                                    SizedBox(
                                                      width: 180,
                                                      child: Text(
                                                        'Type',
                                                        style: Theme.of(context)
                                                            .textTheme
                                                            .labelSmall
                                                            ?.copyWith(
                                                              color: colors
                                                                  .onSurfaceVariant,
                                                              letterSpacing: 0.5,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w600,
                                                            ),
                                                      ),
                                                    ),
                                                    Text(
                                                      'Weight',
                                                      style: Theme.of(context)
                                                          .textTheme
                                                          .labelSmall
                                                          ?.copyWith(
                                                            color: colors
                                                                .onSurfaceVariant,
                                                            letterSpacing: 0.5,
                                                            fontWeight:
                                                                FontWeight.w600,
                                                          ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              ...bags.map((bag) => Padding(
                                                    padding:
                                                        const EdgeInsets.fromLTRB(
                                                            48, 4, 16, 4),
                                                    child: Row(
                                                      children: [
                                                        SizedBox(
                                                          width: 200,
                                                          child: Row(
                                                            children: [
                                                              Icon(
                                                                Icons
                                                                    .qr_code_outlined,
                                                                size: 14,
                                                                color: colors
                                                                    .primary,
                                                              ),
                                                              const SizedBox(
                                                                  width: 6),
                                                              Text(
                                                                bag['trackingNumber'] ??
                                                                    '—',
                                                                style: Theme.of(
                                                                        context)
                                                                    .textTheme
                                                                    .bodySmall
                                                                    ?.copyWith(
                                                                      fontWeight:
                                                                          FontWeight
                                                                              .w500,
                                                                    ),
                                                              ),
                                                            ],
                                                          ),
                                                        ),
                                                        SizedBox(
                                                          width: 180,
                                                          child: Text(
                                                            bag['baggageTypeName'] ??
                                                                '—',
                                                            style:
                                                                Theme.of(context)
                                                                    .textTheme
                                                                    .bodySmall,
                                                          ),
                                                        ),
                                                        Text(
                                                          '${(bag['weightKg'] as num?)?.toStringAsFixed(1) ?? '—'} kg',
                                                          style:
                                                              Theme.of(context)
                                                                  .textTheme
                                                                  .bodySmall,
                                                        ),
                                                      ],
                                                    ),
                                                  )),
                                              const SizedBox(height: 8),
                                            ],
                                          ),
                              ),
                          ],
                        );
                      },
                    ),
                  ),
                ),
        ),

        // Pagination
        if (_totalPages > 1)
          Container(
            height: 52,
            decoration: BoxDecoration(
              border: Border(
                  top: BorderSide(color: colors.outline.withOpacity(0.15))),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: const Icon(Icons.first_page),
                  onPressed: _currentPage > 0
                      ? () => setState(() => _currentPage = 0)
                      : null,
                  iconSize: 18,
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_left),
                  onPressed: _currentPage > 0
                      ? () => setState(() => _currentPage--)
                      : null,
                  iconSize: 18,
                ),
                const SizedBox(width: 8),
                Text(
                  'Page ${_currentPage + 1} of $_totalPages',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.chevron_right),
                  onPressed: _currentPage < _totalPages - 1
                      ? () => setState(() => _currentPage++)
                      : null,
                  iconSize: 18,
                ),
                IconButton(
                  icon: const Icon(Icons.last_page),
                  onPressed: _currentPage < _totalPages - 1
                      ? () => setState(() => _currentPage = _totalPages - 1)
                      : null,
                  iconSize: 18,
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _cell(double width, Widget child) {
    return SizedBox(
      width: width,
      child: Padding(
        padding: const EdgeInsets.only(left: 12),
        child: ClipRect(child: child),
      ),
    );
  }
}

class _ClassChip extends StatelessWidget {
  final String className;
  const _ClassChip({required this.className});

  static const _classColors = {
    'Economy':         Color(0xFF00BCD4),
    'Premium Economy': Color(0xFF2196F3),
    'Business':        Color(0xFFFF6B9D),
    'First':           Color(0xFFFFD700),
  };

  @override
  Widget build(BuildContext context) {
    final color = _classColors[className] ?? const Color(0xFF9E9E9E);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        className,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}


class _BoardingPassesHeader extends StatelessWidget {
  final Map<String, double> columnWidths;
  final void Function(String key, double delta) onColumnResize;

  const _BoardingPassesHeader({
    required this.columnWidths,
    required this.onColumnResize,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Container(
        width: columnWidths.values.fold<double>(0.0, (s, w) => s + (w ?? 0.0)),
        height: 44,
        decoration: BoxDecoration(
          color: colors.surfaceContainerHighest.withOpacity(0.5),
          border:
              Border(bottom: BorderSide(color: colors.outline.withOpacity(0.2))),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(8),
            topRight: Radius.circular(8),
          ),
        ),
        child: Row(
          children: [
            SizedBox(width: columnWidths['expand']!),
            _resizableCell(context, 'ticket', 'Ticket #'),
            _resizableCell(context, 'passenger', 'Passenger'),
            _resizableCell(context, 'flight', 'Flight'),
            _resizableCell(context, 'route', 'Route'),
            _resizableCell(context, 'departure', 'Departure'),
            _resizableCell(context, 'seat', 'Seat'),
            _resizableCell(context, 'class', 'Class'),
            _resizableCell(context, 'issuedAt', 'Issued At'),
            _resizableCell(context, 'bags', 'Bags'),
          ],
        ),
      ),
    
    
    );
  }

  Widget _resizableCell(BuildContext context, String key, String label) {
    final colors = Theme.of(context).colorScheme;
    return SizedBox(
      width: columnWidths[key],
      child: Row(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(left: 12),
              child: Text(
                label,
                style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
          GestureDetector(
            onHorizontalDragUpdate: (d) => onColumnResize(key, d.delta.dx),
            child: MouseRegion(
              cursor: SystemMouseCursors.resizeColumn,
              child: Container(
                width: 8,
                height: 44,
                color: Colors.transparent,
                child: Center(
                  child: Container(
                      width: 1,
                      height: 20,
                      color: colors.outline.withOpacity(0.3)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}