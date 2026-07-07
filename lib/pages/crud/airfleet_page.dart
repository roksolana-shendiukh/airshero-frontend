import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../services/airfleet_api_service.dart';
import '../../services/airfleet_manufacturer_api_service.dart';
import '../../services/seat_layout_api_service.dart';
import '../../services/flight_operation_api_service.dart';
import '../../services/planning_service.dart';
import '../../widgets/responsive_layout.dart';
import '../../widgets/custom/custom_button.dart';
import '../../widgets/airfleet/airfleet_list_panel.dart';
import '../../widgets/airfleet/seat_layout_panel.dart';
import '../../widgets/airfleet/airfleet_form_dialog.dart';

class AirfleetPage extends StatefulWidget {
  const AirfleetPage({super.key});

  @override
  State<AirfleetPage> createState() => _AirfleetPageState();
}

class _AirfleetPageState extends State<AirfleetPage> {
  late final AirfleetApiService _api;
  late final AirfleetManufacturerApiService _manufacturerApi;
  late final SeatLayoutApiService _seatLayoutApi;
  late final FlightOperationApiService _flightApi;
  late final PlanningService _planningService;

  List<Map<String, dynamic>> _airfleets = [];
  List<Map<String, dynamic>> _manufacturers = [];
  Map<String, dynamic>? _selected;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    final auth = context.read<AuthService>();
    _api = AirfleetCrudApiService(auth);
    _api             = AirfleetApiService(auth);
    _manufacturerApi = AirfleetManufacturerApiService(auth);
    _seatLayoutApi   = SeatLayoutApiService(auth);
    _planningService = PlanningService(auth);
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() { _loading = true; _error = null; });
    try {
      final results = await Future.wait([
        _api.getAirfleets(),
        _api.getManufacturers(),
      ]);
      if (!mounted) return;
      setState(() {
        _airfleets = results[0] as List<Map<String, dynamic>>;
        _manufacturers = results[1] as List<Map<String, dynamic>>;
        if (_selected != null) {
          _selected = _airfleets.firstWhere(
            (a) => a['airfleetId'] == _selected!['airfleetId'],
            orElse: () => {},
          );
          if (_selected!.isEmpty) _selected = null;
        }
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() { _error = e.toString(); _loading = false; });
    }
  }

  void _showAirfleetForm([Map<String, dynamic>? airfleet]) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (_) => AirfleetFormDialog(
        api: _api,
        airfleet: airfleet,
        manufacturers: _manufacturers,
      ),
    );
    if (result == true) _loadData();
  }

  Future<void> _confirmDelete(Map<String, dynamic> a) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Aircraft?'),
        content: Text('Permanently remove ${a['aircraftModel']}?'),
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
      await _api.deleteAirfleet(a['airfleetId'] as int);
      if (_selected?['airfleetId'] == a['airfleetId']) {
        setState(() => _selected = null);
      }
      _loadData();
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return ResponsiveLayout(
      header: Padding(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
        child: Row(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Aircraft Fleet',
                    style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 2),
                Text('${_airfleets.length} aircraft',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: colors.onSurfaceVariant)),
              ],
            ),
            const Spacer(),
            CustomButton(
              label: 'Add Aircraft',
              icon: Icons.add,
              isIconAfterLabel: false,
              onPressed: () => _showAirfleetForm(),
            ),
          ],
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!))
              : _airfleets.isEmpty
                  ? _buildEmptyState(colors)
                  : Row(
                      children: [
                        SizedBox(
                          width: 400,
                          child: AirfleetListPanel(
                            airfleets: _airfleets,
                            selected: _selected,
                            flightApi: _flightApi,
                            onSelect: (a) =>
                                setState(() => _selected = a),
                            onAdd: () => _showAirfleetForm(),
                            onEdit: (a) => _showAirfleetForm(a),
                            onDelete: (a) => _confirmDelete(a),
                          ),
                        ),
                        VerticalDivider(
                            width: 1,
                            color: colors.outlineVariant),
                        // ── Права панель ──────────────────
                        Expanded(
                          child: _selected == null
                              ? Center(
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.airline_seat_recline_normal_outlined,
                                        size: 48,
                                        color: colors.outline
                                            .withValues(alpha: 0.25),
                                      ),
                                      const SizedBox(height: 12),
                                      Text(
                                        'Select an aircraft to view seat layout',
                                        style: TextStyle(
                                            color: colors.onSurfaceVariant,
                                            fontSize: 14),
                                      ),
                                    ],
                                  ),
                                )
                              : SeatLayoutPanel(
                                  key: ValueKey(_selected!['airfleetId']),
                                  airfleet: _selected!,
                                  api: _api,
                                ),
                        ),
                      ],
                    ),
    );
  }

  Widget _buildEmptyState(ColorScheme colors) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.flight_outlined,
              size: 56, color: colors.outline.withValues(alpha: 0.3)),
          const SizedBox(height: 12),
          const Text('No aircraft registered'),
          const SizedBox(height: 16),
          CustomButton(
              label: 'Add First Aircraft',
              onPressed: () => _showAirfleetForm()),
        ],
      ),
    );
  }
}