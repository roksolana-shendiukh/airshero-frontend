import 'package:flutter/material.dart';
import '../../services/airfleet_api_service.dart';
import '../../services/seat_layout_api_service.dart';
import 'seat_class_form_dialog.dart';

class SeatLayoutPanel extends StatefulWidget {
  final Map<String, dynamic> airfleet;
  final AirfleetApiService airfleetApi;
  final SeatLayoutApiService seatLayoutApi;

  const SeatLayoutPanel({
    super.key,
    required this.airfleet,
    required this.airfleetApi,
    required this.seatLayoutApi,
  });

  @override
  State<SeatLayoutPanel> createState() => _SeatLayoutPanelState();
}

class _SeatLayoutPanelState extends State<SeatLayoutPanel> {
  List<Map<String, dynamic>> _layouts   = [];
  List<Map<String, dynamic>> _seatTypes = [];
  bool _loading = true;

  static const _classColors = [
    Color(0xFF2196F3),
    Color(0xFFFF6B9D),
    Color(0xFF00BCD4),
    Color(0xFFFFD700),
    Color(0xFF4CAF50),
    Color(0xFFFF9800),
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final seatTypes = await widget.seatLayoutApi.getSeatTypes();
      final airfleets = await widget.airfleetApi.getAirfleets();
      final updated = airfleets.firstWhere(
        (a) => a['airfleet_id'] == widget.airfleet['airfleet_id'],
        orElse: () => widget.airfleet,
      );
      if (!mounted) return;
      setState(() {
        _layouts   = List<Map<String, dynamic>>.from(
            updated['seat_layouts'] ?? widget.airfleet['seat_layouts'] ?? []);
        _seatTypes = seatTypes;
        _loading   = false;
      });
    } catch (_) {
      if (mounted) {
        setState(() {
          _layouts = List<Map<String, dynamic>>.from(
              widget.airfleet['seat_layouts'] ?? []);
          _loading = false;
        });
      }
    }
  }

  void _showClassForm([Map<String, dynamic>? layout]) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (_) => SeatClassFormDialog(
        api:        widget.seatLayoutApi,
        airfleetId: widget.airfleet['airfleet_id'] as int,
        layout:     layout,
        seatTypes:  _seatTypes,
      ),
    );
    if (result == true) _load();
  }

  Future<void> _deleteLayout(Map<String, dynamic> layout) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title:   const Text('Delete class?'),
        content: Text('Remove "${layout['class_name']}"?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.error),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok == true) {
      await widget.seatLayoutApi.deleteSeatLayout(layout['seat_layout_id'] as int);
      _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final model  = widget.airfleet['aircraft_model'] ?? '—';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(20, 14, 16, 14),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                  color: colors.outlineVariant.withValues(alpha: 0.5)),
            ),
          ),
          child: Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(model,
                      style: const TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w600)),
                  Text('Seat layout configuration',
                      style: TextStyle(
                          fontSize: 11, color: colors.onSurfaceVariant)),
                ],
              ),
              const Spacer(),
              OutlinedButton.icon(
                onPressed: () => _showClassForm(),
                icon:  const Icon(Icons.add, size: 15),
                label: const Text('Add class', style: TextStyle(fontSize: 12)),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : _layouts.isEmpty
                  ? _buildEmpty(colors)
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildLegend(colors),
                          const SizedBox(height: 20),
                          _buildSeatMap(colors),
                          const SizedBox(height: 20),
                          _buildStats(colors),
                        ],
                      ),
                    ),
        ),
      ],
    );
  }

  Widget _buildLegend(ColorScheme colors) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _layouts.asMap().entries.map((e) {
        final i     = e.key;
        final l     = e.value;
        final color = _classColors[i % _classColors.length];
        final rows  = (l['seat_layout_rows'] as num?)?.toInt() ?? 0;
        final colsRaw = l['seat_layout_columns']?.toString() ?? '';
        final seatsPerRow = colsRaw
            .split(' ')
            .where((s) => s.trim().isNotEmpty)
            .fold(0, (s, c) => s + (int.tryParse(c.trim()) ?? 0));
        final total = rows * seatsPerRow;

        return Container(
          padding: const EdgeInsets.fromLTRB(10, 6, 6, 6),
          decoration: BoxDecoration(
            color:        color.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(10),
            border:       Border.all(color: color.withValues(alpha: 0.35)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 14, height: 14,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.7),
                  borderRadius: const BorderRadius.only(
                    topLeft:     Radius.circular(2),
                    bottomLeft:  Radius.circular(2),
                    topRight:    Radius.circular(5),
                    bottomRight: Radius.circular(5),
                  ),
                ),
              ),
              const SizedBox(width: 7),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l['class_name'] ?? '—',
                      style: TextStyle(
                          fontSize:   12,
                          fontWeight: FontWeight.w600,
                          color:      color)),
                  Text('$rows rows · $total seats',
                      style: TextStyle(
                          fontSize: 10,
                          color:    color.withValues(alpha: 0.75))),
                ],
              ),
              const SizedBox(width: 6),
              SizedBox(
                width: 24, height: 24,
                child: IconButton(
                  padding:  EdgeInsets.zero,
                  icon:     Icon(Icons.edit_outlined,
                      size: 12, color: color.withValues(alpha: 0.8)),
                  onPressed: () => _showClassForm(l),
                ),
              ),
              SizedBox(
                width: 24, height: 24,
                child: IconButton(
                  padding:  EdgeInsets.zero,
                  icon:     const Icon(Icons.close,
                      size: 12, color: Color(0xFFE24B4A)),
                  onPressed: () => _deleteLayout(l),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSeatMap(ColorScheme colors) {
    final blocks = _layouts.asMap().entries.map((e) {
      final i       = e.key;
      final l       = e.value;
      final color   = _classColors[i % _classColors.length];
      final rows    = (l['seat_layout_rows'] as num?)?.toInt() ?? 0;
      final colsRaw = l['seat_layout_columns']?.toString() ?? '';
      final colGroups = colsRaw
          .split(' ')
          .where((s) => s.trim().isNotEmpty)
          .map((s) => int.tryParse(s.trim()) ?? 0)
          .where((n) => n > 0)
          .toList();

      return _SeatBlock(
        className: l['class_name'] ?? '—',
        color:     color,
        rows:      rows,
        colGroups: colGroups,
      );
    }).toList();

    if (blocks.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color:        colors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
        border:       Border.all(
            color: colors.outlineVariant.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildColHeader(blocks, colors),
          const SizedBox(height: 6),
          ...blocks.map((b) => _buildBlock(b, colors)),
        ],
      ),
    );
  }

  Widget _buildColHeader(List<_SeatBlock> blocks, ColorScheme colors) {
    if (blocks.isEmpty) return const SizedBox.shrink();
    final ref = blocks.reduce((a, b) =>
        a.colGroups.fold(0, (s, c) => s + c) >
                b.colGroups.fold(0, (s, c) => s + c)
            ? a
            : b);

    const seatGap  = 4.0;
    const groupGap = 10.0;
    const seatW    = 28.0;

    return Padding(
      padding: const EdgeInsets.only(left: 32),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: () {
          final widgets = <Widget>[];
          int col = 0;
          for (var gi = 0; gi < ref.colGroups.length; gi++) {
            if (gi > 0) widgets.add(const SizedBox(width: groupGap));
            for (var ci = 0; ci < ref.colGroups[gi]; ci++) {
              final letter = String.fromCharCode(65 + col);
              widgets.add(SizedBox(
                width: seatW,
                child: Center(
                  child: Text(letter,
                      style: TextStyle(
                          fontSize:   11,
                          fontWeight: FontWeight.w600,
                          color:      colors.onSurfaceVariant)),
                ),
              ));
              if (ci < ref.colGroups[gi] - 1) {
                widgets.add(const SizedBox(width: seatGap));
              }
              col++;
            }
          }
          return widgets;
        }(),
      ),
    );
  }

  Widget _buildBlock(_SeatBlock block, ColorScheme colors) {
    const seatGap  = 4.0;
    const groupGap = 10.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: List.generate(block.rows, (rowIdx) {
        final rowNum = rowIdx + 1;
        return Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: () {
              final widgets = <Widget>[];
              widgets.add(SizedBox(
                width: 28,
                child: Text('$rowNum',
                    style: TextStyle(
                        fontSize: 10, color: colors.onSurfaceVariant),
                    textAlign: TextAlign.right),
              ));
              widgets.add(const SizedBox(width: 4));
              for (var gi = 0; gi < block.colGroups.length; gi++) {
                if (gi > 0) widgets.add(const SizedBox(width: groupGap));
                for (var ci = 0; ci < block.colGroups[gi]; ci++) {
                  widgets.add(_buildSeat(block.color));
                  if (ci < block.colGroups[gi] - 1) {
                    widgets.add(const SizedBox(width: seatGap));
                  }
                }
              }
              return widgets;
            }(),
          ),
        );
      }),
    );
  }

  Widget _buildSeat(Color color) {
    return Container(
      width:  28,
      height: 28,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: const BorderRadius.only(
          topLeft:     Radius.circular(3),
          bottomLeft:  Radius.circular(3),
          topRight:    Radius.circular(8),
          bottomRight: Radius.circular(8),
        ),
        border: Border.all(color: color.withValues(alpha: 0.6), width: 1),
      ),
    );
  }

  Widget _buildStats(ColorScheme colors) {
    int total      = 0;
    final rows     = <Widget>[];

    for (var i = 0; i < _layouts.length; i++) {
      final l       = _layouts[i];
      final color   = _classColors[i % _classColors.length];
      final rowCount = (l['seat_layout_rows'] as num?)?.toInt() ?? 0;
      final colsRaw  = l['seat_layout_columns']?.toString() ?? '';
      final seatsPerRow = colsRaw
          .split(' ')
          .where((s) => s.trim().isNotEmpty)
          .fold(0, (s, c) => s + (int.tryParse(c.trim()) ?? 0));
      final count = rowCount * seatsPerRow;
      total += count;

      rows.add(Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Row(
          children: [
            Container(
              width: 10, height: 10,
              decoration: BoxDecoration(
                  color:        color,
                  borderRadius: BorderRadius.circular(2)),
            ),
            const SizedBox(width: 8),
            Text(l['class_name'] ?? '—',
                style: const TextStyle(fontSize: 13)),
            const Spacer(),
            Text('$count seats',
                style: const TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w600)),
          ],
        ),
      ));
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color:        colors.surfaceContainerHigh.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          ...rows,
          Divider(
              height: 16,
              color:  colors.outlineVariant.withValues(alpha: 0.5)),
          Row(
            children: [
              Text('Total capacity',
                  style: TextStyle(
                      fontSize:   13,
                      fontWeight: FontWeight.w600,
                      color:      colors.onSurface)),
              const Spacer(),
              Text('$total seats',
                  style: TextStyle(
                      fontSize:   13,
                      fontWeight: FontWeight.w700,
                      color:      colors.primary)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty(ColorScheme colors) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.airline_seat_recline_normal_outlined,
              size: 44, color: colors.outline.withValues(alpha: 0.2)),
          const SizedBox(height: 12),
          Text('No cabin classes configured',
              style: TextStyle(fontSize: 14, color: colors.onSurfaceVariant)),
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: () => _showClassForm(),
            icon:  const Icon(Icons.add, size: 15),
            label: const Text('Add first class'),
          ),
        ],
      ),
    );
  }
}

class _SeatBlock {
  final String    className;
  final Color     color;
  final int       rows;
  final List<int> colGroups;

  _SeatBlock({
    required this.className,
    required this.color,
    required this.rows,
    required this.colGroups,
  });
}