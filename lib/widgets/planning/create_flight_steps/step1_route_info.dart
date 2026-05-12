import 'dart:math' as math;
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
    required Duration? flightDuration,
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

  Duration? _flightDuration;
  bool _loadingDuration = false;
  double? _routeDistanceKm;

  @override
  void initState() {
    super.initState();
    _airfleet = widget.selectedAirfleet;
    _departsAirport = widget.selectedDepartsAirport;
    _arrivesAirport = widget.selectedArrivesAirport;
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
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
      if (_departsAirport != null && _arrivesAirport != null) {
        _calcDistance();
      }
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _loading = false; });
    }
  }

  void _calcDistance() {
    if (_departsAirport == null || _arrivesAirport == null) {
      setState(() => _routeDistanceKm = null);
      return;
    }
    final lat1 = math.pi / 180 *
        (_departsAirport!['latitude'] as num).toDouble();
    final lon1 = math.pi / 180 *
        (_departsAirport!['longitude'] as num).toDouble();
    final lat2 = math.pi / 180 *
        (_arrivesAirport!['latitude'] as num).toDouble();
    final lon2 = math.pi / 180 *
        (_arrivesAirport!['longitude'] as num).toDouble();
    final dlat = lat2 - lat1;
    final dlon = lon2 - lon1;
    final a = math.pow(math.sin(dlat / 2), 2) +
        math.cos(lat1) * math.cos(lat2) * math.pow(math.sin(dlon / 2), 2);
    final km = 6371 * 2 * math.asin(math.sqrt(a));
    setState(() => _routeDistanceKm = km);
  }

  List<Map<String, dynamic>> get _eligibleAirfleets {
    if (_routeDistanceKm == null) return _airfleets;
    return _airfleets.where((af) {
      final range = (af['aircraftRangeKm'] as num?)?.toDouble();
      if (range == null) return true;
      return range >= _routeDistanceKm!;
    }).toList();
  }

  Future<void> _notify() async {
    if (_airfleet == null ||
        _departsAirport == null ||
        _arrivesAirport == null ||
        _departsAirport!['airportId'] == _arrivesAirport!['airportId']) {
      setState(() { _flightDuration = null; _loadingDuration = false; });
      widget.onChanged(
        airfleet: _airfleet,
        departsAirport: _departsAirport,
        arrivesAirport: _arrivesAirport,
        flightDuration: null,
      );
      return;
    }

    setState(() => _loadingDuration = true);
    widget.onChanged(
      airfleet: _airfleet,
      departsAirport: _departsAirport,
      arrivesAirport: _arrivesAirport,
      flightDuration: null,
    );

    try {
      final duration = await widget.service.getRouteDuration(
        airfleetId: _airfleet!['airfleetId'] as int,
        departsAirportId: _departsAirport!['airportId'] as int,
        arrivesAirportId: _arrivesAirport!['airportId'] as int,
      );
      if (!mounted) return;
      setState(() { _flightDuration = duration; _loadingDuration = false; });
      widget.onChanged(
        airfleet: _airfleet,
        departsAirport: _departsAirport,
        arrivesAirport: _arrivesAirport,
        flightDuration: duration,
      );
    } catch (e) {
      if (mounted) setState(() => _loadingDuration = false);
    }
  }

  void _onAirportChanged() {
    if (_airfleet != null && _routeDistanceKm != null) {
      final range =
          (_airfleet!['aircraftRangeKm'] as num?)?.toDouble();
      if (range != null && range < _routeDistanceKm!) {
        setState(() => _airfleet = null);
      }
    }
    _notify();
  }

  void _swapAirports() {
    setState(() {
      final tmp = _departsAirport;
      _departsAirport = _arrivesAirport;
      _arrivesAirport = tmp;
      _calcDistance();
    });
    _onAirportChanged();
  }

  Map<String, dynamic>? _airportById(String id) {
    try {
      return _airports.firstWhere((a) => a['airportId'].toString() == id);
    } catch (_) {
      return null;
    }
  }

  String _fmtDuration(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes % 60;
    return '${h}h ${m}min';
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
            context, Icons.connecting_airports_outlined, 'Route'),
        const SizedBox(height: 12),
        _buildRouteRow(colors),

        if (_departsAirport != null &&
            _arrivesAirport != null &&
            _departsAirport!['airportId'] !=
                _arrivesAirport!['airportId']) ...[
          const SizedBox(height: 12),
          _buildRouteInfo(colors),
        ],

        if (_departsAirport != null &&
            _arrivesAirport != null &&
            _departsAirport!['airportId'] !=
                _arrivesAirport!['airportId']) ...[
          const SizedBox(height: 28),
          _buildSectionLabel(
              context, Icons.airplanemode_active_outlined, 'Aircraft'),
          const SizedBox(height: 4),
          if (_eligibleAirfleets.isEmpty)
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: colors.errorContainer.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.warning_outlined,
                      size: 16, color: colors.error),
                  const SizedBox(width: 8),
                  Text(
                    'No aircraft available for this route distance '
                    '(${_routeDistanceKm?.toStringAsFixed(0)} km)',
                    style: TextStyle(fontSize: 13, color: colors.error),
                  ),
                ],
              ),
            )
          else ...[
            Text(
              'Showing ${_eligibleAirfleets.length} aircraft that can cover '
              '${_routeDistanceKm?.toStringAsFixed(0)} km',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 12),
            PlanningAirfleetSelector(
              service: widget.service,
              airfleets: _eligibleAirfleets,
              selected: _airfleet,
              onChanged: (af) {
                setState(() => _airfleet = af);
                _notify();
              },
            ),
          ],

          if (_airfleet != null) ...[
            const SizedBox(height: 12),
            _buildDurationInfo(colors),
          ],
        ],
      ],
    );
  }

  Widget _buildSectionLabel(BuildContext context, IconData icon, String label) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 8),
        Text(label,
            style: Theme.of(context)
                .textTheme
                .titleSmall
                ?.copyWith(fontWeight: FontWeight.w600)),
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
            searchable: true,
            onChanged: (v) {
              if (v == null) return;
              setState(() {
                _departsAirport = _airportById(v);
                _calcDistance();
              });
              _onAirportChanged();
            },
          ),
        ),
        const SizedBox(width: 8),
        IconButton(
          onPressed: (_departsAirport != null || _arrivesAirport != null)
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
            searchable: true,
            onChanged: (v) {
              if (v == null) return;
              setState(() {
                _arrivesAirport = _airportById(v);
                _calcDistance();
              });
              _onAirportChanged();
            },
          ),
        ),
      ],
    );
  }

  Widget _buildRouteInfo(ColorScheme colors) {
    final sameCountry =
        _departsAirport?['countryName'] == _arrivesAirport?['countryName'];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: colors.surfaceContainerHighest.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colors.outline.withValues(alpha: 0.15)),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline,
              size: 16, color: colors.onSurfaceVariant),
          const SizedBox(width: 10),
          Wrap(
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
              if (_routeDistanceKm != null)
                _InfoChip(
                  label: 'Distance',
                  value: '${_routeDistanceKm!.toStringAsFixed(0)} km',
                  colors: colors,
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDurationInfo(ColorScheme colors) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: colors.primaryContainer.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colors.primary.withValues(alpha: 0.15)),
      ),
      child: Row(
        children: [
          Icon(Icons.schedule_outlined,
              size: 16, color: colors.primary),
          const SizedBox(width: 10),
          if (_loadingDuration)
            SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(
                  strokeWidth: 2, color: colors.primary),
            )
          else if (_flightDuration != null)
            _InfoChip(
              label: 'Flight duration',
              value: _fmtDuration(_flightDuration!),
              colors: colors,
            )
          else
            Text(
              'Calculating duration...',
              style:
                  TextStyle(fontSize: 12, color: colors.onSurfaceVariant),
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