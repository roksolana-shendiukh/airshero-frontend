import 'package:flutter/material.dart';
import '../../models/flight_without_operation_model.dart';
import '../custom/custom_input_field.dart';


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
  String _search = '';
  String? _filterDate;
  String? _filterDeparts;
  String? _filterArrives;

  List<FlightWithoutOperationModel> get _filtered {
    return widget.flights.where((f) {
      if (_search.isNotEmpty &&
          !f.flightNumber.toLowerCase().contains(_search.toLowerCase())) {
        return false;
      }
      if (_filterDeparts != null && f.departsCode != _filterDeparts) {
        return false;
      }
      if (_filterArrives != null && f.arrivesCode != _filterArrives) {
        return false;
      }
      if (_filterDate != null) {
        final d = f.departsDatetime;
        final label =
            '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
        if (label != _filterDate) return false;
      }
      return true;
    }).toList();
  }

  List<String> get _uniqueDepartures =>
      widget.flights.map((f) => f.departsCode).toSet().toList()..sort();

  List<String> get _uniqueArrivals =>
      widget.flights.map((f) => f.arrivesCode).toSet().toList()..sort();

  List<String> get _uniqueDates {
    return widget.flights.map((f) {
      final d = f.departsDatetime;
      return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
    }).toSet().toList()
      ..sort();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
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
        const SizedBox(height: 16),
        
       
        const SizedBox(height: 20),

        if (filtered.isEmpty)
          const Expanded(
            child: Center(
              child: Text('No flights match filters'),
            ),
          )
        else
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.only(bottom: 20),
              itemCount: filtered.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (_, i) => _FlightCard(
                flight: filtered[i],
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

  String get _durationLabel {
    final diff = flight.arrivesDatetime.difference(flight.departsDatetime);
    return '${diff.inHours}h ${diff.inMinutes % 60}m';
  }

  Color _statusColor(ColorScheme colors) {
    switch (flight.flightStatus.toLowerCase()) {
      case 'scheduled': return Colors.blue;
      case 'delayed': return Colors.orange;
      case 'cancelled': return colors.error;
      default: return colors.onSurfaceVariant;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? colors.primaryContainer.withValues(alpha: 0.15)
              : colors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? colors.primary : colors.outlineVariant.withValues(alpha: 0.5),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isSelected ? colors.primary : colors.surfaceContainerHigh,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    flight.flightNumber,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? colors.onPrimary : colors.onSurface,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  flight.flightStatus,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: _statusColor(colors),
                  ),
                ),
                const Spacer(),
                Icon(
                  isSelected ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                  size: 20,
                  color: isSelected ? colors.primary : colors.outlineVariant,
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildRoutePoint(flight.departsCode, _formatTime(flight.departsDatetime), CrossAxisAlignment.start, colors),
                Expanded(
                  child: Column(
                    children: [
                      Row(
                        children: [
                          const Expanded(child: Divider()),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            child: Icon(Icons.airplanemode_active_rounded, size: 14, color: isSelected ? colors.primary : colors.outline),
                          ),
                          const Expanded(child: Divider()),
                        ],
                      ),
                      Text(_durationLabel, style: TextStyle(fontSize: 10, color: colors.onSurfaceVariant)),
                    ],
                  ),
                ),
                _buildRoutePoint(flight.arrivesCode, _formatTime(flight.arrivesDatetime), CrossAxisAlignment.end, colors),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.calendar_today_outlined, size: 12, color: colors.onSurfaceVariant),
                const SizedBox(width: 4),
                Text(_formatDate(flight.departsDatetime), style: TextStyle(fontSize: 11, color: colors.onSurfaceVariant)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRoutePoint(String code, String time, CrossAxisAlignment align, ColorScheme colors) {
    return Column(
      crossAxisAlignment: align,
      children: [
        Text(code, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        Text(time, style: TextStyle(fontSize: 12, color: colors.onSurfaceVariant)),
      ],
    );
  }
}