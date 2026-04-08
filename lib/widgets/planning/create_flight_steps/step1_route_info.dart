import 'package:flutter/material.dart';
import '../../../services/planning_service.dart';
import '../../custom/custom_select_field.dart';
import 'planning_airfleet_selector.dart';

class Step1RouteInfo extends StatefulWidget {
  final PlanningService service;
  final Map<String, dynamic>? selectedAirfleet;
  final Map<String, dynamic>? selectedDepartsAirport;
  final Map<String, dynamic>? selectedArrivesAirport;
  final void Function({
    required Map<String, dynamic>? airfleet,
    required Map<String, dynamic>? departsAirport,
    required Map<String, dynamic>? arrivesAirport,
  }) onChanged;

  const Step1RouteInfo({
    super.key,
    required this.service,
    required this.selectedAirfleet,
    required this.selectedDepartsAirport,
    required this.selectedArrivesAirport,
    required this.onChanged,
  });

  @override
  State<Step1RouteInfo> createState() => _Step1RouteInfoState();
}

class _Step1RouteInfoState extends State<Step1RouteInfo> {
  List<Map<String, dynamic>> _airfleets = [];
  List<Map<String, dynamic>> _airports = [];
  bool _loading = true;
  String? _error;

  late Map<String, dynamic>? _airfleet;
  late Map<String, dynamic>? _departsAirport;
  late Map<String, dynamic>? _arrivesAirport;

  @override
  void initState() {
    super.initState();
    _airfleet = widget.selectedAirfleet;
    _departsAirport = widget.selectedDepartsAirport;
    _arrivesAirport = widget.selectedArrivesAirport;
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final results = await Future.wait([
        widget.service.getAirfleets(),
        widget.service.getAirports(),
      ]);
      if (!mounted) return;
      setState(() {
        _airfleets = results[0];
        _airports = results[1];
        _loading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _loading = false;
        });
      }
    }
  }

  void _notify() {
    widget.onChanged(
      airfleet: _airfleet,
      departsAirport: _departsAirport,
      arrivesAirport: _arrivesAirport,
    );
  }

  void _swapAirports() {
    setState(() {
      final tmp = _departsAirport;
      _departsAirport = _arrivesAirport;
      _arrivesAirport = tmp;
    });
    _notify();
  }

  Map<String, dynamic>? _airportById(String id) {
    try {
      return _airports
          .firstWhere((a) => a['airportId'].toString() == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline,
                color: Theme.of(context).colorScheme.error, size: 48),
            const SizedBox(height: 12),
            Text(_error!),
            const SizedBox(height: 12),
            FilledButton(onPressed: _load, child: const Text('Retry')),
          ],
        ),
      );
    }

    final colors = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionLabel(
            context, Icons.airplanemode_active_outlined, 'Aircraft'),
        const SizedBox(height: 12),
        PlanningAirfleetSelector(
          service: widget.service,
          airfleets: _airfleets,
          selected: _airfleet,
          onChanged: (af) {
            setState(() => _airfleet = af);
            _notify();
          },
        ),

        const SizedBox(height: 28),
        _buildSectionLabel(
            context, Icons.connecting_airports_outlined, 'Route'),
        const SizedBox(height: 12),
        _buildRouteRow(colors),

        if (_airfleet != null &&
            _departsAirport != null &&
            _arrivesAirport != null &&
            _departsAirport!['airportId'] !=
                _arrivesAirport!['airportId']) ...[
          const SizedBox(height: 20),
          _buildRangeInfo(colors),
        ],
      ],
    );
  }

  Widget _buildSectionLabel(
      BuildContext context, IconData icon, String label) {
    return Row(
      children: [
        Icon(icon,
            size: 18,
            color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 8),
        Text(
          label,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
      ],
    );
  }

  Widget _buildRouteRow(ColorScheme colors) {
    final departsItems = _airports
        .where((a) => a['airportId'] != _arrivesAirport?['airportId'])
        .map((a) => a['airportId'].toString())
        .toList();
    final departsLabels = _airports
        .where((a) => a['airportId'] != _arrivesAirport?['airportId'])
        .map((a) => '${a['airportCode']}  ·  ${a['cityName']}')
        .toList();

    final arrivesItems = _airports
        .where((a) => a['airportId'] != _departsAirport?['airportId'])
        .map((a) => a['airportId'].toString())
        .toList();
    final arrivesLabels = _airports
        .where((a) => a['airportId'] != _departsAirport?['airportId'])
        .map((a) => '${a['airportCode']}  ·  ${a['cityName']}')
        .toList();

    return Row(
      children: [
        Expanded(
          child: CustomSelectField(
            label: 'Departure airport',
            icon: Icons.flight_takeoff_outlined,
            value: _departsAirport?['airportId']?.toString() ?? '',
            items: departsItems,
            itemLabels: departsLabels,
            onChanged: (v) {
              if (v == null) return;
              setState(() => _departsAirport = _airportById(v));
              _notify();
            },
          ),
        ),
        const SizedBox(width: 8),
        IconButton(
          onPressed:
              (_departsAirport != null || _arrivesAirport != null)
                  ? _swapAirports
                  : null,
          icon: const Icon(Icons.swap_horiz_rounded),
          tooltip: 'Swap airports',
          style: IconButton.styleFrom(
            foregroundColor: colors.primary,
            backgroundColor:
                colors.primaryContainer.withValues(alpha: 0.3),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: CustomSelectField(
            label: 'Arrival airport',
            icon: Icons.flight_land_outlined,
            value: _arrivesAirport?['airportId']?.toString() ?? '',
            items: arrivesItems,
            itemLabels: arrivesLabels,
            onChanged: (v) {
              if (v == null) return;
              setState(() => _arrivesAirport = _airportById(v));
              _notify();
            },
          ),
        ),
      ],
    );
  }

  Widget _buildRangeInfo(ColorScheme colors) {
    final rangeKm = _airfleet?['aircraftRangeKm'] as num?;
    final sameCountry = _departsAirport?['countryName'] ==
        _arrivesAirport?['countryName'];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: colors.surfaceContainerHighest.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(8),
        border:
            Border.all(color: colors.outline.withValues(alpha: 0.15)),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline,
              size: 16, color: colors.onSurfaceVariant),
          const SizedBox(width: 10),
          Expanded(
            child: Wrap(
              spacing: 16,
              runSpacing: 4,
              children: [
                _InfoChip(
                  label: 'Route',
                  value:
                      '${_departsAirport!['airportCode']} → ${_arrivesAirport!['airportCode']}',
                  colors: colors,
                ),
                _InfoChip(
                  label: 'Type',
                  value: sameCountry ? 'Domestic' : 'International',
                  colors: colors,
                ),
                if (rangeKm != null)
                  _InfoChip(
                    label: 'Max range',
                    value: '${rangeKm.toStringAsFixed(0)} km',
                    colors: colors,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final String label;
  final String value;
  final ColorScheme colors;

  const _InfoChip({
    required this.label,
    required this.value,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('$label: ',
            style:
                TextStyle(fontSize: 12, color: colors.onSurfaceVariant)),
        Text(value,
            style: const TextStyle(
                fontSize: 12, fontWeight: FontWeight.w600)),
      ],
    );
  }
}