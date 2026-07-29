import 'package:flutter/material.dart';
import '../../../services/planning_service.dart';
import 'pricing_edit_panel.dart';

class PricingRouteCard extends StatefulWidget {
  final Map<String, dynamic> route;
  final PlanningService service;

  const PricingRouteCard({
    super.key,
    required this.route,
    required this.service,
  });

  @override
  State<PricingRouteCard> createState() => _PricingRouteCardState();
}

class _PricingRouteCardState extends State<PricingRouteCard> {
  bool _expanded = false;
  List<Map<String, dynamic>> _flights = [];
  bool _loadingFlights = false;

  Future<void> _toggle() async {
    if (_expanded) {
      setState(() => _expanded = false);
      return;
    }
    setState(() { _expanded = true; _loadingFlights = true; });
    try {
      final flights = await widget.service.getPricingFlightsForRoute(
          widget.route['routeId'] as int);
      if (mounted) setState(() { _flights = flights; _loadingFlights = false; });
    } catch (e) {
      if (mounted) setState(() => _loadingFlights = false);
    }
  }

  void _onPricesUpdated(int flightId, List<Map<String, dynamic>> newPrices) {
    setState(() {
      final idx = _flights.indexWhere((f) => f['flightId'] == flightId);
      if (idx != -1) {
        _flights[idx] = {
          ..._flights[idx],
          'prices': newPrices,
          'flightStatus': 'Scheduled',
        };
      }
    });
  }

  void _openEditModal(Map<String, dynamic> flight) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Theme.of(context).colorScheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        insetPadding: const EdgeInsets.symmetric(horizontal: 40, vertical: 40),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: PricingEditPanel(
            flight: flight,
            service: widget.service,
            onPricesUpdated: (id, prices) => _onPricesUpdated(id, prices),
            onClose: () => Navigator.of(ctx).pop(),
          ),
        ),
      ),
    );
  }

  String _fmtDate(String iso) {
    final dt = DateTime.parse(iso);
    return '${dt.day.toString().padLeft(2, '0')}.${dt.month.toString().padLeft(2, '0')}.${dt.year}';
  }


  Set<String> _allClasses() {
    final classes = <String>{};
    for (final f in _flights) {
      final prices = f['prices'] as List<dynamic>? ?? [];
      for (final p in prices) {
        classes.add(p['className'] as String);
      }
    }
    return classes;
  }


  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final confirmedCount = widget.route['confirmedCount'] as int;

    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: colors.outline.withValues(alpha: 0.15)),
      ),
      child: Column(
        children: [
          _buildHeader(colors, confirmedCount),
          AnimatedSize(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeInOut,
            child: _expanded ? _buildContent(colors) : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(ColorScheme colors, int confirmedCount) {
    return InkWell(
      onTap: _toggle,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: colors.primaryContainer.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.airplanemode_active_outlined,
                  color: colors.primary, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.route['flightNumber'] as String,
                    style: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Icon(Icons.airplanemode_active_outlined,
                          size: 12, color: colors.onSurfaceVariant),
                      const SizedBox(width: 4),
                      Text(
                        '${widget.route['aircraftModel']}  ·  '
                        '${widget.route['departsCode']} → ${widget.route['arrivesCode']}',
                        style: TextStyle(
                            fontSize: 12, color: colors.onSurfaceVariant),
                      ),
                      if (widget.route['departsTime'] != null) ...[
                        const SizedBox(width: 12),
                        Icon(Icons.schedule_outlined,
                            size: 12, color: colors.onSurfaceVariant),
                        const SizedBox(width: 4),
                        Text(
                          '${widget.route['departsTime']} → ${widget.route['arrivesTime']}',
                          style: TextStyle(
                              fontSize: 12, color: colors.onSurfaceVariant),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            if (confirmedCount > 0)
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFEAF3DE),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '$confirmedCount confirmed',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF3B6D11),
                  ),
                ),
              ),
            const SizedBox(width: 10),
            AnimatedRotation(
              turns: _expanded ? 0.5 : 0,
              duration: const Duration(milliseconds: 200),
              child: Icon(Icons.keyboard_arrow_down,
                  color: colors.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(ColorScheme colors) {
    return Container(
      decoration: BoxDecoration(
        border: Border(
            top: BorderSide(
                color: colors.outline.withValues(alpha: 0.15))),
      ),
      child: _loadingFlights
          ? const Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: CircularProgressIndicator()))
          : _flights.isEmpty
              ? Padding(
                  padding: const EdgeInsets.all(24),
                  child: Center(
                    child: Text('No flights',
                        style: TextStyle(color: colors.onSurfaceVariant)),
                  ),
                )
              : Column(
                  children: [
                    _buildTableHeader(colors),
                    ..._flights.map((f) => _buildFlightRow(colors, f)),
                  ],
                ),
    );
  }

  Widget _buildTableHeader(ColorScheme colors) {
    final classes = _allClasses().toList()..sort();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: colors.surfaceContainerHighest.withValues(alpha: 0.3),
        border: Border(
            bottom:
                BorderSide(color: colors.outline.withValues(alpha: 0.1))),
      ),
      child: Row(
        children: [
          const SizedBox(width: 14),
          Expanded(
            flex: 2,
            child: Text('Date',
                style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: colors.onSurfaceVariant)),
          ),
          ...classes.map((c) => Expanded(
                flex: 2,
                child: Text(c,
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: colors.onSurfaceVariant)),
              )),
          const SizedBox(width: 110),
        ],
      ),
    );
  }

  Widget _buildFlightRow(ColorScheme colors, Map<String, dynamic> flight) {
    final classes = _allClasses().toList()..sort();
    final prices = (flight['prices'] as List<dynamic>? ?? [])
        .cast<Map<String, dynamic>>();
    final priceMap = {
      for (final p in prices)
        p['className'] as String: (p['price'] as num).toDouble()
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
      decoration: BoxDecoration(
        border: Border(
            bottom:
                BorderSide(color: colors.outline.withValues(alpha: 0.08))),
      ),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            margin: const EdgeInsets.only(right: 6),
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Color(0xFF639922),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              _fmtDate(flight['departsDatetime'] as String),
              style: const TextStyle(fontSize: 13),
            ),
          ),
          ...classes.map((c) {
            final price = priceMap[c];
            return Expanded(
              flex: 2,
              child: price != null
                  ? Text('\$${price.toStringAsFixed(0)}',
                      style: const TextStyle(
                          fontSize: 13, fontWeight: FontWeight.w500))
                  : Text('—',
                      style: TextStyle(
                          fontSize: 13, color: colors.onSurfaceVariant)),
            );
          }),
          SizedBox(
            width: 110,
            child: FilledButton(
              onPressed: () => _openEditModal(flight),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 8),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6)),
                textStyle: const TextStyle(fontSize: 12),
              ),
              child: const Text('Edit prices'),
            ),
          ),
        ],
      ),
    );
  }
}