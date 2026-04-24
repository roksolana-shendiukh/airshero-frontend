import 'package:flutter/material.dart';
import '../../../services/planning_service.dart';
import 'setup_configure_modal.dart';

class SetupRouteCard extends StatefulWidget {
  final Map<String, dynamic> route;
  final PlanningService service;

  const SetupRouteCard({
    super.key,
    required this.route,
    required this.service,
  });

  @override
  State<SetupRouteCard> createState() => _SetupRouteCardState();
}

class _SetupRouteCardState extends State<SetupRouteCard> {
  bool _expanded = false;
  List<Map<String, dynamic>> _flights = [];
  bool _loadingFlights = false;
  Set<int> _selected = {};

  Future<void> _toggle() async {
    if (_expanded) {
      setState(() => _expanded = false);
      return;
    }
    setState(() { _expanded = true; _loadingFlights = true; });
    try {
      final flights = await widget.service.getPlannedFlightsForRoute(
          widget.route['routeId'] as int);
      if (mounted) setState(() { _flights = flights; _loadingFlights = false; });
    } catch (e) {
      if (mounted) setState(() => _loadingFlights = false);
    }
  }

  String _fmtDate(String iso) {
    final dt = DateTime.parse(iso);
    return '${dt.day.toString().padLeft(2, '0')}.${dt.month.toString().padLeft(2, '0')}.${dt.year}';
  }

  String _fmtTime(String iso) {
    final dt = DateTime.parse(iso);
    return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  bool get _allSelected =>
      _flights.isNotEmpty &&
      _flights.every((f) => _selected.contains(f['flightId'] as int));

  void _toggleAll() {
    setState(() {
      if (_allSelected) {
        _selected.clear();
      } else {
        _selected = _flights.map((f) => f['flightId'] as int).toSet();
      }
    });
  }

  void _openConfigureModal() {
    if (_selected.isEmpty) return;
    final selectedFlights =
        _flights.where((f) => _selected.contains(f['flightId'] as int)).toList();

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        insetPadding: const EdgeInsets.symmetric(horizontal: 40, vertical: 40),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 960),
          child: SetupConfigureModal(
            flights: selectedFlights,
            service: widget.service,
            airfleetId: widget.route['airfleetId'] as int? ??
                (_flights.isNotEmpty ? _flights.first['airfleetId'] as int : 0),
            onDone: (confirmedIds) {
              setState(() {
                _flights.removeWhere(
                    (f) => confirmedIds.contains(f['flightId'] as int));
                _selected.removeAll(confirmedIds);
                widget.route['plannedCount'] = _flights.length;
              });
            },
            onClose: () => Navigator.of(ctx).pop(),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final plannedCount = widget.route['plannedCount'] as int;

    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: colors.outline.withValues(alpha: 0.15)),
      ),
      child: Column(
        children: [
          _buildHeader(colors, plannedCount),
          AnimatedSize(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeInOut,
            child: _expanded ? _buildContent(colors) : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(ColorScheme colors, int plannedCount) {
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
                  Text(widget.route['flightNumber'] as String,
                      style: const TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w600)),
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
                    ],
                  ),
                ],
              ),
            ),
            if (plannedCount > 0)
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFFAEEDA),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '$plannedCount auto-scheduled',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF854F0B),
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
                        style:
                            TextStyle(color: colors.onSurfaceVariant)),
                  ),
                )
              : Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildTimeInfo(colors),
                      const SizedBox(height: 16),
                      _buildSelectAll(colors),
                      const SizedBox(height: 8),
                      _buildDatesWrap(colors),
                      if (_selected.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        _buildActionBar(colors),
                      ],
                    ],
                  ),
                ),
    );
  }

  Widget _buildTimeInfo(ColorScheme colors) {
    if (_flights.isEmpty) return const SizedBox.shrink();
    final first = _flights.first;
    final depTime = _fmtTime(first['departsDatetime'] as String);
    final arrTime = _fmtTime(first['arrivesDatetime'] as String);
    final duration = first['flightDuration'] as String? ?? '—';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: colors.surfaceContainerHighest.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.flight_takeoff_outlined,
              size: 14, color: colors.onSurfaceVariant),
          const SizedBox(width: 6),
          Text(depTime,
              style: const TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w600)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Icon(Icons.arrow_forward,
                size: 14, color: colors.onSurfaceVariant),
          ),
          Icon(Icons.flight_land_outlined,
              size: 14, color: colors.onSurfaceVariant),
          const SizedBox(width: 6),
          Text(arrTime,
              style: const TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w600)),
          const SizedBox(width: 16),
          Icon(Icons.schedule_outlined,
              size: 14, color: colors.onSurfaceVariant),
          const SizedBox(width: 6),
          Text(duration,
              style: TextStyle(
                  fontSize: 13, color: colors.onSurfaceVariant)),
        ],
      ),
    );
  }

  Widget _buildSelectAll(ColorScheme colors) {
    if (_flights.isEmpty) return const SizedBox.shrink();
    return InkWell(
      onTap: _toggleAll,
      borderRadius: BorderRadius.circular(4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Checkbox(
            value: _allSelected,
            tristate: _selected.isNotEmpty && !_allSelected,
            onChanged: (_) => _toggleAll(),
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            visualDensity: VisualDensity.compact,
          ),
          const SizedBox(width: 4),
          Text('Select all',
              style: TextStyle(
                  fontSize: 12, color: colors.onSurfaceVariant)),
        ],
      ),
    );
  }

  Widget _buildDatesWrap(ColorScheme colors) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _flights.map((f) {
        final id = f['flightId'] as int;
        final isSelected = _selected.contains(id);
        final date = _fmtDate(f['departsDatetime'] as String);

        return GestureDetector(
          onTap: () {
            setState(() {
              if (isSelected) {
                _selected.remove(id);
              } else {
                _selected.add(id);
              }
            });
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 120),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: isSelected
                  ? const Color(0xFFFAC775).withValues(alpha: 0.4)
                  : const Color(0xFFFAEEDA),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: isSelected
                    ? const Color(0xFFBA7517)
                    : const Color(0xFFEF9F27).withValues(alpha: 0.5),
                width: isSelected ? 1.5 : 1,
              ),
            ),
            child: Text(
              date,
              style: TextStyle(
                fontSize: 12,
                fontWeight:
                    isSelected ? FontWeight.w600 : FontWeight.normal,
                color: const Color(0xFF854F0B),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildActionBar(ColorScheme colors) {
    return Row(
      children: [
        Text('${_selected.length} selected',
            style:
                TextStyle(fontSize: 13, color: colors.onSurfaceVariant)),
        const Spacer(),
        TextButton(
          onPressed: () => setState(() => _selected.clear()),
          style: TextButton.styleFrom(
            foregroundColor: colors.onSurfaceVariant,
            padding: const EdgeInsets.symmetric(
                horizontal: 12, vertical: 8),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(6)),
          ),
          child: const Text('Clear'),
        ),
        const SizedBox(width: 8),
        FilledButton.icon(
          onPressed: _openConfigureModal,
          icon: const Icon(Icons.tune_outlined, size: 15),
          label: Text('Configure ${_selected.length} flights'),
          style: FilledButton.styleFrom(
            padding: const EdgeInsets.symmetric(
                horizontal: 14, vertical: 10),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(6)),
            textStyle: const TextStyle(fontSize: 13),
          ),
        ),
      ],
    );
  }
}