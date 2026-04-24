import 'package:flutter/material.dart';

import 'passenger_popup.dart';

class BookingsTable extends StatefulWidget {
  final List<Map<String, dynamic>> bookings;
  final void Function(Map<String, dynamic> booking) onCancel;
  final bool Function(Map<String, dynamic> booking) canCancel;
  final String searchQuery;

  const BookingsTable({
    super.key,
    required this.bookings,
    required this.onCancel,
    required this.canCancel,
    this.searchQuery = '',
  });

  @override
  State<BookingsTable> createState() => _BookingsTableState();
}

class _BookingsTableState extends State<BookingsTable> {
  static const int _pageSize = 20;
  int _currentPage = 0;

  Map<String, double> _columnWidths = {
    'number': 150,
    'route': 180,
    'bookingDate': 140,
    'departure': 160,
    'passengers': 100,
    'amount': 130,
    'status': 150,
    'actions': 64,
  };

  double get _totalWidth =>
      _columnWidths.values.fold(0.0, (sum, w) => sum + w);

  List<Map<String, dynamic>> get _filtered {
  debugPrint('searchQuery: "${widget.searchQuery}", bookings: ${widget.bookings.length}');
  if (widget.searchQuery.isEmpty) return widget.bookings;
  final q = widget.searchQuery.toLowerCase();
  final result = widget.bookings.where((b) {
    final number = (b['booking_number'] ?? '').toString().toLowerCase();
    final from = (b['from_city'] ?? '').toString().toLowerCase();
    final to = (b['to_city'] ?? '').toString().toLowerCase();
    final passengers = (b['passengers_list'] ?? '').toString().toLowerCase();
    return number.contains(q) ||
        from.contains(q) ||
        to.contains(q) ||
        passengers.contains(q);
  }).toList();
  debugPrint('filtered result: ${result.length}');
  return result;
}

  List<Map<String, dynamic>> get _currentPageItems {
    final filtered = _filtered;
    final start = _currentPage * _pageSize;
    final end = (start + _pageSize).clamp(0, filtered.length);
    return filtered.sublist(start, end);
  }

  int get _totalPages =>
      (_filtered.length / _pageSize).ceil().clamp(1, 9999);

  void _onColumnResize(String key, double delta) {
    setState(() {
      final current = _columnWidths[key] ?? 100;
      _columnWidths[key] = (current + delta).clamp(60.0, 400.0);
    });
  }

  String _formatDate(dynamic raw) {
    if (raw == null) return '—';
    final dt = DateTime.tryParse(raw.toString());
    if (dt == null) return '—';
    return '${dt.day.toString().padLeft(2, '0')}.${dt.month.toString().padLeft(2, '0')}.${dt.year}  '
        '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  String _formatDateOnly(dynamic raw) {
    if (raw == null) return '—';
    final dt = DateTime.tryParse(raw.toString());
    if (dt == null) return '—';
    return '${dt.day.toString().padLeft(2, '0')}.${dt.month.toString().padLeft(2, '0')}.${dt.year}';
  }

  String _formatAmount(dynamic raw) {
    if (raw == null) return '—';
    final amount = double.tryParse(raw.toString());
    if (amount == null) return '—';
    return '\$${amount.toStringAsFixed(2)}';
  }

  Color _statusColor(String status, ColorScheme colors) {
    switch (status) {
      case 'Confirmed':
        return Colors.green;
      case 'Pending':
        return Colors.orange;
      case 'PartiallyPaid':
        return Colors.blue;
      case 'Cancelled':
        return colors.onSurfaceVariant;
      case 'Failed':
        return colors.error;
      default:
        return colors.onSurfaceVariant;
    }
  }
  
  @override
  void didUpdateWidget(BookingsTable old) {
    super.didUpdateWidget(old);
    if (widget.searchQuery != old.searchQuery) {
      setState(() => _currentPage = 0);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final pageItems = _currentPageItems;

    return Column(
      children: [        
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SizedBox(
              width: _totalWidth,
              child: Column(
                children: [
                  _BookingsTableHeader(
                    columnWidths: _columnWidths,
                    onColumnResize: _onColumnResize,
                  ),
                  Expanded(
                    child: pageItems.isEmpty
                        ? Center(
                            child: Text(
                              'No bookings match your search',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(
                                    color: colors.onSurfaceVariant,
                                  ),
                            ),
                          )
                        : ListView.builder(
                            itemCount: pageItems.length,
                            itemBuilder: (context, index) {
                              final booking = pageItems[index];
                              final status =
                                  booking['booking_status_name'] as String? ??
                                      '';
                              final statusColor =
                                  _statusColor(status, colors);
                              final canCancel = widget.canCancel(booking);

                              return Container(
                                height: 44,
                                decoration: BoxDecoration(
                                  color: index.isEven
                                      ? null
                                      : colors.surfaceContainerLow
                                          .withOpacity(0.3),
                                  border: Border(
                                    bottom: BorderSide(
                                      color:
                                          colors.outline.withOpacity(0.08),
                                    ),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    _cell(
                                      _columnWidths['number']!,
                                      Text(
                                        '#${booking['booking_number'] ?? '—'}',
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
                                      _columnWidths['route']!,
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Flexible(
                                            child: Text(
                                              booking['from_city'] ?? '—',
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .bodyMedium,
                                              overflow:
                                                  TextOverflow.ellipsis,
                                            ),
                                          ),
                                          Padding(
                                            padding:
                                                const EdgeInsets.symmetric(
                                                    horizontal: 4),
                                            child: Icon(
                                              Icons.arrow_forward,
                                              size: 14,
                                              color:
                                                  colors.onSurfaceVariant,
                                            ),
                                          ),
                                          Flexible(
                                            child: Text(
                                              booking['to_city'] ?? '—',
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .bodyMedium,
                                              overflow:
                                                  TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    _cell(
                                      _columnWidths['bookingDate']!,
                                      Text(
                                        _formatDateOnly(
                                            booking['booking_date_time']),
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall
                                            ?.copyWith(
                                              color:
                                                  colors.onSurfaceVariant,
                                            ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    _cell(
                                      _columnWidths['departure']!,
                                      Text(
                                        _formatDate(
                                            booking['departs_datetime']),
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    _cell(
                                      _columnWidths['passengers']!,
                                      PassengerCountCell(
                                        count: (booking['passenger_count']
                                                    as num?)
                                                ?.toInt() ??
                                            0,
                                        passengersList:
                                            booking['passengers_list']
                                                as String?,
                                      ),
                                    ),
                                    _cell(
                                      _columnWidths['amount']!,
                                      Text(
                                        _formatAmount(
                                            booking['booking_total_amount']),
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyMedium
                                            ?.copyWith(
                                              fontWeight: FontWeight.w600,
                                            ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    _cell(
                                      _columnWidths['status']!,
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 8, vertical: 3),
                                        decoration: BoxDecoration(
                                          color:
                                              statusColor.withOpacity(0.1),
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(Icons.circle,
                                                size: 7,
                                                color: statusColor),
                                            const SizedBox(width: 5),
                                            Text(
                                              status,
                                              style: TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w500,
                                                color: statusColor,
                                              ),
                                              overflow:
                                                  TextOverflow.ellipsis,
                                              maxLines: 1,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    SizedBox(
                                      width: _columnWidths['actions']!,
                                      child: canCancel
                                          ? Tooltip(
                                              message: 'Cancel booking',
                                              child: IconButton(
                                                icon: Icon(
                                                  Icons.cancel_outlined,
                                                  color: colors.error,
                                                  size: 18,
                                                ),
                                                onPressed: () =>
                                                    widget.onCancel(booking),
                                              ),
                                            )
                                          : const SizedBox.shrink(),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
          ),
        ),
        if (_totalPages > 1)
          Container(
            height: 52,
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(color: colors.outline.withOpacity(0.15)),
              ),
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
                      ? () =>
                          setState(() => _currentPage = _totalPages - 1)
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

class _BookingsTableHeader extends StatelessWidget {
  final Map<String, double> columnWidths;
  final void Function(String key, double delta) onColumnResize;

  const _BookingsTableHeader({
    required this.columnWidths,
    required this.onColumnResize,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: colors.surfaceContainerHighest.withOpacity(0.5),
        border: Border(
          bottom: BorderSide(color: colors.outline.withOpacity(0.2)),
        ),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(8),
          topRight: Radius.circular(8),
        ),
      ),
      child: Row(
        children: [
          _resizableCell(context, 'number', 'Booking #'),
          _resizableCell(context, 'route', 'Route'),
          _resizableCell(context, 'bookingDate', 'Booked On'),
          _resizableCell(context, 'departure', 'Departure'),
          _resizableCell(context, 'passengers', 'Pax'),
          _resizableCell(context, 'amount', 'Amount'),
          _resizableCell(context, 'status', 'Status'),
          SizedBox(width: columnWidths['actions']!),
        ],
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
                  letterSpacing: 0.5,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
          GestureDetector(
            onHorizontalDragUpdate: (details) =>
                onColumnResize(key, details.delta.dx),
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
                    color: colors.outline.withOpacity(0.3),
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


