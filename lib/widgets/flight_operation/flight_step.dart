import 'package:flutter/material.dart';
import '../../models/flight_without_operation_model.dart';
import '../custom/custom_input_field.dart';
import '../custom/custom_select_field.dart';

class FlightStep extends StatefulWidget {
  final List<FlightWithoutOperationModel> flights;
  final FlightWithoutOperationModel? selected;
  final ValueChanged<FlightWithoutOperationModel?> onChanged;

  const FlightStep({
    super.key,
    required this.flights,
    required this.selected,
    required this.onChanged,
  });

  @override
  State<FlightStep> createState() => _FlightStepState();
}

class _FlightStepState extends State<FlightStep> {
  String  _search      = '';
  String? _filterDate;  
  String? _filterDeparts;
  String? _filterArrives;

  List<FlightWithoutOperationModel> get _filtered {
    return widget.flights.where((f) {
      if (_search.isNotEmpty &&
          !f.flightNumber.toLowerCase().contains(_search.toLowerCase()))
        return false;
      if (_filterDeparts != null && f.departsCode != _filterDeparts)
        return false;
      if (_filterArrives != null && f.arrivesCode != _filterArrives)
        return false;
      if (_filterDate != null) {
        final d = f.departsDatetime;
        final label =
            '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
        if (label != _filterDate) return false;
      }
      return true;
    }).toList();
  }

  List<String> get _uniqueDepartures => widget.flights
      .map((f) => f.departsCode)
      .toSet()
      .toList()
    ..sort();

  List<String> get _uniqueArrivals => widget.flights
      .map((f) => f.arrivesCode)
      .toSet()
      .toList()
    ..sort();

  List<String> get _uniqueDates {
    final dates = widget.flights.map((f) {
      final d = f.departsDatetime;
      return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
    }).toSet().toList()
      ..sort();
    return dates;
  }

  List<String> get _uniqueDateLabels => _uniqueDates.map((d) {
        final parts = d.split('-');
        return '${parts[2]}.${parts[1]}.${parts[0]}';
      }).toList();

  bool get _hasFilters =>
      _search.isNotEmpty ||
      _filterDate != null ||
      _filterDeparts != null ||
      _filterArrives != null;

  @override
  Widget build(BuildContext context) {
    final colors  = Theme.of(context).colorScheme;
    final filtered = _filtered;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CustomInputField(
          label: 'Search by flight number',
          value: _search,
          icon: Icons.search,
          onChanged: (v) => setState(() => _search = v),
        ),
        const SizedBox(height: 10),

        Row(
          children: [
            Expanded(
              child: CustomSelectField(
                label: 'Date',
                icon: Icons.calendar_today_outlined,
                value: _filterDate ?? '',
                items: ['', ..._uniqueDates],
                itemLabels: ['All', ..._uniqueDateLabels],
                searchable: false,
                onChanged: (v) => setState(
                    () => _filterDate = (v == null || v.isEmpty) ? null : v),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: CustomSelectField(
                label: 'From',
                icon: Icons.flight_takeoff_outlined,
                value: _filterDeparts ?? '',
                items: ['', ..._uniqueDepartures],
                itemLabels: ['All', ..._uniqueDepartures],
                searchable: false,
                onChanged: (v) => setState(
                    () => _filterDeparts = (v == null || v.isEmpty) ? null : v),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: CustomSelectField(
                label: 'To',
                icon: Icons.flight_land_outlined,
                value: _filterArrives ?? '',
                items: ['', ..._uniqueArrivals],
                itemLabels: ['All', ..._uniqueArrivals],
                searchable: false,
                onChanged: (v) => setState(
                    () => _filterArrives = (v == null || v.isEmpty) ? null : v),
              ),
            ),
            if (_hasFilters) ...[
              const SizedBox(width: 8),
              IconButton(
                icon: Icon(Icons.refresh, size: 16, color: colors.onSurfaceVariant),
                onPressed: () => setState(() {
                  _search        = '';
                  _filterDate    = null;
                  _filterDeparts = null;
                  _filterArrives = null;
                }),
                tooltip: 'Reset filters',
                visualDensity: VisualDensity.compact,
              ),
            ],
          ],
        ),
        const SizedBox(height: 12),

        if (filtered.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Center(
              child: Text('No flights match filters',
                  style: TextStyle(color: colors.onSurfaceVariant)),
            ),
          )
        else
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 320),
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: filtered.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (_, i) => _FlightCard(
                flight:     filtered[i],
                isSelected: widget.selected?.flightId == filtered[i].flightId,
                onTap: () => widget.onChanged(
                  widget.selected?.flightId == filtered[i].flightId
                      ? null
                      : filtered[i],
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _FlightCard extends StatelessWidget {
  final FlightWithoutOperationModel flight;
  final bool isSelected;
  final VoidCallback onTap;

  const _FlightCard({
    required this.flight,
    required this.isSelected,
    required this.onTap,
  });

  String _formatTime(DateTime dt) =>
      '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';

  String _formatDate(DateTime dt) =>
      '${dt.day.toString().padLeft(2, '0')}.${dt.month.toString().padLeft(2, '0')}.${dt.year}';

  Duration get _duration =>
      flight.arrivesDatetime.difference(flight.departsDatetime);

  String get _durationLabel {
    final h = _duration.inHours;
    final m = _duration.inMinutes % 60;
    return '${h}h ${m}m';
  }

  Color _statusColor(ColorScheme colors) {
    switch (flight.flightStatus.toLowerCase()) {
      case 'scheduled': return Colors.blue;
      case 'delayed':   return Colors.orange;
      case 'cancelled': return colors.error;
      default:          return colors.onSurfaceVariant;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? colors.primaryContainer.withValues(alpha: 0.25)
              : colors.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? colors.primary : colors.outlineVariant,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? colors.primary
                        : colors.surfaceContainerHigh,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    flight.flightNumber,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: isSelected ? colors.onPrimary : colors.onSurface,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: _statusColor(colors).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    flight.flightStatus,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: _statusColor(colors),
                    ),
                  ),
                ),
                const Spacer(),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isSelected ? colors.primary : Colors.transparent,
                    border: Border.all(
                      color: isSelected ? colors.primary : colors.outline,
                      width: 1.5,
                    ),
                  ),
                  child: isSelected
                      ? Icon(Icons.check, size: 12, color: colors.onPrimary)
                      : null,
                ),
              ],
            ),

            const SizedBox(height: 14),

            Row(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      flight.departsCode,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: isSelected ? colors.primary : colors.onSurface,
                      ),
                    ),
                    Text(_formatTime(flight.departsDatetime),
                        style: TextStyle(
                            fontSize: 12, color: colors.onSurfaceVariant)),
                  ],
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                                child: Container(
                                    height: 1,
                                    color: colors.outlineVariant)),
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 6),
                              child: Icon(Icons.airplanemode_active,
                                  size: 16,
                                  color: isSelected
                                      ? colors.primary
                                      : colors.onSurfaceVariant),
                            ),
                            Expanded(
                                child: Container(
                                    height: 1,
                                    color: colors.outlineVariant)),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(_durationLabel,
                            style: TextStyle(
                                fontSize: 11,
                                color: colors.onSurfaceVariant)),
                      ],
                    ),
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      flight.arrivesCode,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: isSelected ? colors.primary : colors.onSurface,
                      ),
                    ),
                    Text(_formatTime(flight.arrivesDatetime),
                        style: TextStyle(
                            fontSize: 12, color: colors.onSurfaceVariant)),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 10),

            Row(
              children: [
                Icon(Icons.calendar_today_outlined,
                    size: 12, color: colors.onSurfaceVariant),
                const SizedBox(width: 4),
                Text(_formatDate(flight.departsDatetime),
                    style: TextStyle(
                        fontSize: 11, color: colors.onSurfaceVariant)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}