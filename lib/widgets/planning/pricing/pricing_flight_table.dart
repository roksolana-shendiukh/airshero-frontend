import 'package:flutter/material.dart';

class PricingFlightTable extends StatelessWidget {
  final List<Map<String, dynamic>> flights;
  final void Function(Map<String, dynamic>) onEditPressed;

  const PricingFlightTable({
    super.key,
    required this.flights,
    required this.onEditPressed,
  });

  String _fmtDate(String iso) {
    final dt = DateTime.parse(iso);
    return '${dt.day.toString().padLeft(2, '0')}.${dt.month.toString().padLeft(2, '0')}.${dt.year}';
  }

  String _fmtTime(String iso) {
    final dt = DateTime.parse(iso);
    return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  Set<String> _allClasses() {
    final classes = <String>{};
    for (final f in flights) {
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
    final classes = _allClasses().toList()..sort();

    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: colors.outline.withValues(alpha: 0.15)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          _buildTableHeader(colors, classes),
          Expanded(
            child: ListView.builder(
              itemCount: flights.length,
              itemBuilder: (context, i) =>
                  _buildRow(context, colors, flights[i], classes),
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildTableHeader(ColorScheme colors, List<String> classes) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: colors.surfaceContainerHighest.withValues(alpha: 0.4),
        border: Border(
            bottom: BorderSide(
                color: colors.outline.withValues(alpha: 0.1))),
      ),
      child: Row(
        children: [
          _headerCell('Flight', flex: 2, colors: colors),
          _headerCell('Date', flex: 2, colors: colors),
          _headerCell('Time', flex: 3, colors: colors),
          ...classes.map((c) => _headerCell(c, flex: 2, colors: colors)),
          const SizedBox(width: 110),
        ],
      ),
    );
  }

  Widget _headerCell(String label,
      {required int flex, required ColorScheme colors}) {
    return Expanded(
      flex: flex,
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: colors.onSurfaceVariant,
        ),
      ),
    );
  }

  Widget _buildRow(BuildContext context, ColorScheme colors,
      Map<String, dynamic> flight, List<String> classes) {
    final prices = (flight['prices'] as List<dynamic>? ?? [])
        .cast<Map<String, dynamic>>();
    final priceMap = {
      for (final p in prices)
        p['className'] as String: (p['price'] as num).toDouble()
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
              color: colors.outline.withValues(alpha: 0.08)),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              flight['flightNumber'] as String,
              style: const TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              _fmtDate(flight['departsDatetime'] as String),
              style: const TextStyle(fontSize: 13),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              '${_fmtTime(flight['departsDatetime'] as String)} → ${_fmtTime(flight['arrivesDatetime'] as String)}',
              style: TextStyle(
                  fontSize: 13, color: colors.onSurfaceVariant),
            ),
          ),
          ...classes.map((c) {
            final price = priceMap[c];
            return Expanded(
              flex: 2,
              child: price != null
                  ? Text(
                      '\$${price.toStringAsFixed(0)}',
                      style: const TextStyle(
                          fontSize: 13, fontWeight: FontWeight.w500),
                    )
                  : Text('—',
                      style: TextStyle(
                          fontSize: 13,
                          color: colors.onSurfaceVariant)),
            );
          }),
          SizedBox(
            width: 110,
            child: FilledButton(
              onPressed: () => onEditPressed(flight),
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