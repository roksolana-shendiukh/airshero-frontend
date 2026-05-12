import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../models/flight_without_operation_model.dart';
import '../../models/airfleet_model.dart';
import '../../models/gate_model.dart';
import '../../schemas/create_flight_operation_dto.dart';
import '../../services/auth_service.dart';
import '../../services/flight_operation_api_service.dart';
import '../../widgets/responsive_layout.dart';
import '../../widgets/custom/custom_button.dart';
import '../widgets/flight_operation/operation_status_bar.dart';
import '../widgets/custom/custom_select_field.dart';
import '../widgets/flight_operation/airfleet_step.dart';

class FlightOperationCreatePage extends StatefulWidget {
  final FlightWithoutOperationModel flight;

  const FlightOperationCreatePage({super.key, required this.flight});

  @override
  State<FlightOperationCreatePage> createState() =>
      _FlightOperationCreatePageState();
}

class _FlightOperationCreatePageState
    extends State<FlightOperationCreatePage> {
  late final FlightOperationApiService _apiService;

  List<AirfleetModel> _airfleets        = [];
  List<GateModel>     _gates            = [];
  AirfleetModel?      _selectedAirfleet;
  GateModel?          _selectedGate;
  bool                _loadingAirfleets = true;
  bool                _loadingGates     = true;
  bool                _showAircraftList = false;
  String?             _openTerminal;
  bool                _isSubmitting     = false;
  String?             _errorMessage;

  @override
  void initState() {
    super.initState();
    _apiService = FlightOperationApiService(context.read<AuthService>());
    _loadAirfleets();
    _loadGates();
  }

  Future<void> _loadAirfleets() async {
    setState(() => _loadingAirfleets = true);
    final list = await _apiService.getAirfleets(flightId: widget.flight.flightId);
    if (!mounted) return;
    setState(() {
      _airfleets        = list;
      _loadingAirfleets = false;
      if (list.isNotEmpty) _selectedAirfleet = list.first;
    });
  }

  Future<void> _loadGates() async {
    setState(() => _loadingGates = true);
    final list = await _apiService.getGates(flightId: widget.flight.flightId);
    if (!mounted) return;
    setState(() {
      _gates        = list;
      _loadingGates = false;
    });
  }

  Future<void> _createOperation() async {
    if (_selectedAirfleet == null || _selectedGate == null) return;
    setState(() { _isSubmitting = true; _errorMessage = null; });

    final dto = CreateFlightOperationDTO(
      flightId:   widget.flight.flightId,
      airfleetId: _selectedAirfleet!.airfleetId,
      gateId:     _selectedGate!.gateId,
    );

    final result = await _apiService.createFlightOperation(dto);
    if (!mounted) return;

    if (!result.success) {
      setState(() {
        _isSubmitting = false;
        _errorMessage = result.error ?? 'Failed to create operation';
      });
      return;
    }

    await context.read<AuthService>().refreshSession();
    if (mounted) context.go('/flight-operations');
  }

  Map<String, List<GateModel>> get _groupedGates {
    final map = <String, List<GateModel>>{};
    for (final g in _gates) {
      map.putIfAbsent(g.terminalCode ?? '?', () => []).add(g);
    }
    return map;
  }

  @override
  Widget build(BuildContext context) {
    return ResponsiveLayout(
      header: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const OperatorStatusBar(),
          _buildPageHeader(),
        ],
      ),
      body: Column(
        children: [
          Expanded(child: _buildSetupStep()),
          _buildFooter(Theme.of(context).colorScheme),
        ],
      ),
    );
  }

  Widget _buildPageHeader() {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: colors.outlineVariant.withValues(alpha: 0.4)),
        ),
      ),
      child: Row(
        children: [
          IconButton(
            icon:     const Icon(Icons.arrow_back_rounded),
            onPressed: () => context.go('/flight-operations'),
            tooltip:  'Back to board',
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(widget.flight.flightNumber,
                      style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(width: 12),
                  Text(
                    '${widget.flight.departsCode} → ${widget.flight.arrivesCode}',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: colors.onSurfaceVariant),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    _fmtTime(widget.flight.departsDatetime),
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: colors.onSurfaceVariant),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text('Select aircraft and gate',
                  style: TextStyle(fontSize: 12, color: colors.onSurfaceVariant)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSetupStep() {
  final colors = Theme.of(context).colorScheme;

  return Row(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Expanded(
        child: Container(
          decoration: BoxDecoration(
            border: Border(
              right: BorderSide(
                  color: colors.outlineVariant.withValues(alpha: 0.4)),
            ),
          ),
          child: Column(
            children: [
              _buildSectionHeader(
                'Aircraft',
                Icons.airplanemode_active_outlined,
                trailing: _airfleets.length > 1
                    ? TextButton(
                        onPressed: () => setState(
                            () => _showAircraftList = !_showAircraftList),
                        child: Text(
                          _showAircraftList ? 'Show selected' : 'Change',
                          style: const TextStyle(fontSize: 13),
                        ),
                      )
                    : null,
              ),
              Expanded(
                child: _loadingAirfleets
                    ? const Center(child: CircularProgressIndicator())
                    : _showAircraftList
                        ? Padding(
                            padding: const EdgeInsets.all(16),
                            child: AirfleetStep(
                              airfleets:  _airfleets,
                              selected:   _selectedAirfleet,
                              apiService: _apiService,
                              onChanged: (a) => setState(() {
                                _selectedAirfleet = a;
                                _showAircraftList  = false;
                              }),
                            ),
                          )
                        : _selectedAirfleet != null
                            ? SingleChildScrollView(
                                padding: const EdgeInsets.all(20),
                                child: _SelectedAircraftCard(
                                  airfleet:   _selectedAirfleet!,
                                  colors:     colors,
                                  apiService: _apiService,
                                ),
                              )
                            : Center(
                                child: Text('No aircraft available',
                                    style: TextStyle(
                                        color: colors.onSurfaceVariant)),
                              ),
              ),
            ],
          ),
        ),
      ),

      Expanded(
        child: Column(
          children: [
            _buildSectionHeader('Gate', Icons.door_sliding_outlined),
            Expanded(
              child: _loadingGates
                  ? const Center(child: CircularProgressIndicator())
                  : _gates.isEmpty
                      ? Center(
                          child: Text('No gates available',
                              style: TextStyle(
                                  color: colors.onSurfaceVariant)),
                        )
                      : Padding(
                          padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              CustomSelectField(
                                label:      'Terminal',
                                value:      _openTerminal ?? '',
                                icon:       Icons.door_sliding_outlined,
                                items:      ['', ..._groupedGates.keys.toList()],
                                itemLabels: [
                                  'Select terminal',
                                  ..._groupedGates.keys
                                      .map((t) => 'Terminal $t')
                                      .toList(),
                                ],
                                searchable: false,
                                onChanged: (v) => setState(() {
                                  _openTerminal =
                                      (v == null || v.isEmpty) ? null : v;
                                  _selectedGate = null;
                                }),
                              ),
                              const SizedBox(height: 16),
                              if (_openTerminal != null)
                                Expanded(
                                  child: SingleChildScrollView(
                                    child: Wrap(
                                      spacing:    8,
                                      runSpacing: 8,
                                      children:
                                          (_groupedGates[_openTerminal] ?? [])
                                              .map((gate) => GestureDetector(
                                                    onTap: gate.isAvailable
                                                        ? () => setState(() =>
                                                            _selectedGate =
                                                                _selectedGate
                                                                            ?.gateId ==
                                                                        gate.gateId
                                                                    ? null
                                                                    : gate)
                                                        : null,
                                                    child: AnimatedContainer(
                                                      duration: const Duration(
                                                          milliseconds: 150),
                                                      width:  72,
                                                      height: 56,
                                                      decoration: BoxDecoration(
                                                        color: !gate.isAvailable
                                                            ? colors
                                                                .surfaceContainerHighest
                                                                .withValues(
                                                                    alpha: 0.5)
                                                            : _selectedGate
                                                                        ?.gateId ==
                                                                    gate.gateId
                                                                ? colors
                                                                    .primaryContainer
                                                                    .withValues(
                                                                        alpha:
                                                                            0.35)
                                                                : colors
                                                                    .surfaceContainerHighest,
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(8),
                                                        border: Border.all(
                                                          color: !gate.isAvailable
                                                              ? colors
                                                                  .outlineVariant
                                                                  .withValues(
                                                                      alpha: 0.4)
                                                              : _selectedGate
                                                                          ?.gateId ==
                                                                      gate.gateId
                                                                  ? colors
                                                                      .primary
                                                                  : colors
                                                                      .outlineVariant,
                                                          width: _selectedGate
                                                                      ?.gateId ==
                                                                  gate.gateId
                                                              ? 1.5
                                                              : 1,
                                                        ),
                                                      ),
                                                      child: Column(
                                                        mainAxisAlignment:
                                                            MainAxisAlignment
                                                                .center,
                                                        children: [
                                                          if (!gate.isAvailable)
                                                            Icon(
                                                              Icons.lock_outline,
                                                              size:  12,
                                                              color: colors
                                                                  .onSurfaceVariant
                                                                  .withValues(
                                                                      alpha:
                                                                          0.4),
                                                            ),
                                                          Text(
                                                            gate.gateCode,
                                                            style: TextStyle(
                                                              fontSize:   16,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w600,
                                                              color: !gate
                                                                      .isAvailable
                                                                  ? colors
                                                                      .onSurfaceVariant
                                                                      .withValues(
                                                                          alpha:
                                                                              0.4)
                                                                  : _selectedGate
                                                                              ?.gateId ==
                                                                          gate
                                                                              .gateId
                                                                      ? colors
                                                                          .primary
                                                                      : colors
                                                                          .onSurface,
                                                            ),
                                                          ),
                                                          Text(
                                                            gate.isAvailable
                                                                ? 'Gate'
                                                                : 'Busy',
                                                            style: TextStyle(
                                                              fontSize: 10,
                                                              color: !gate
                                                                      .isAvailable
                                                                  ? colors
                                                                      .onSurfaceVariant
                                                                      .withValues(
                                                                          alpha:
                                                                              0.4)
                                                                  : _selectedGate
                                                                              ?.gateId ==
                                                                          gate
                                                                              .gateId
                                                                      ? colors
                                                                          .primary
                                                                          .withValues(
                                                                              alpha: 0.7)
                                                                      : colors
                                                                          .onSurfaceVariant,
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  ))
                                              .toList(),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
            ),
          ],
        ),
      ),
    
    
    ],
  );
}
  
  
  Widget _buildSectionHeader(String title, IconData icon, {Widget? trailing}) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 16, 16),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
              color: colors.outlineVariant.withValues(alpha: 0.4)),
        ),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: colors.primary),
          const SizedBox(width: 8),
          Text(
            title.toUpperCase(),
            style: const TextStyle(
              fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1.0),
          ),
          const Spacer(),
          if (trailing != null) trailing,
        ],
      ),
    );
  }

  Widget _buildFooter(ColorScheme colors) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        border: Border(
            top: BorderSide(
                color: colors.outlineVariant.withValues(alpha: 0.4))),
      ),
      child: Row(
        children: [
          if (_errorMessage != null)
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color:        colors.errorContainer.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error_outline_rounded,
                        color: colors.error, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(_errorMessage!,
                          style: TextStyle(
                              color: colors.onErrorContainer, fontSize: 12)),
                    ),
                  ],
                ),
              ),
            ),
          const Spacer(),
          SizedBox(
            width: 200, height: 44,
            child: CustomButton(
              label: _isSubmitting ? 'Creating...' : 'Create Operation',
              onPressed: (_selectedAirfleet != null &&
                          _selectedGate != null &&
                          !_isSubmitting)
                  ? _createOperation
                  : null,
            ),
          ),
        ],
      ),
    );
  }

  String _fmtTime(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }
}


class _SelectedAircraftCard extends StatefulWidget {
  final AirfleetModel             airfleet;
  final ColorScheme               colors;
  final FlightOperationApiService apiService;

  const _SelectedAircraftCard({
    required this.airfleet,
    required this.colors,
    required this.apiService,
  });

  @override
  State<_SelectedAircraftCard> createState() => _SelectedAircraftCardState();
}

class _SelectedAircraftCardState extends State<_SelectedAircraftCard> {
  List<String> _photos     = [];
  int          _photoIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadPhotos();
  }

  Future<void> _loadPhotos() async {
    final photos =
        await widget.apiService.getAirfleetPhotos(widget.airfleet.airfleetId);
    if (mounted) setState(() => _photos = photos);
  }

  @override
  Widget build(BuildContext context) {
    final colors = widget.colors;
    final a      = widget.airfleet;

    return Container(
      decoration: BoxDecoration(
        color:        colors.primary.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(12),
        border:       Border.all(color: colors.primary.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [

          if (_photos.isNotEmpty)
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(11)),
              child: SizedBox(
                height: 200,
                child: Stack(
                  children: [
                    Image.network(
                      _photos[_photoIndex],
                      width: double.infinity, height: 200,
                      fit:   BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        color: colors.surfaceContainerHigh,
                        child: Icon(Icons.broken_image_outlined,
                            color: colors.onSurfaceVariant),
                      ),
                    ),
                    if (_photos.length > 1) ...[
                      Positioned(
                        left: 6, top: 0, bottom: 0,
                        child: Center(
                          child: _NavBtn(
                            icon:  Icons.chevron_left,
                            onTap: () => setState(() => _photoIndex =
                                (_photoIndex - 1 + _photos.length) %
                                    _photos.length),
                          ),
                        ),
                      ),
                      Positioned(
                        right: 6, top: 0, bottom: 0,
                        child: Center(
                          child: _NavBtn(
                            icon:  Icons.chevron_right,
                            onTap: () => setState(() => _photoIndex =
                                (_photoIndex + 1) % _photos.length),
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 8, left: 0, right: 0,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(
                            _photos.length,
                            (i) => AnimatedContainer(
                              duration: const Duration(milliseconds: 150),
                              margin: const EdgeInsets.symmetric(horizontal: 3),
                              width:  i == _photoIndex ? 16 : 6,
                              height: 6,
                              decoration: BoxDecoration(
                                color: i == _photoIndex
                                    ? Colors.white
                                    : Colors.white.withValues(alpha: 0.5),
                                borderRadius: BorderRadius.circular(3),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                    
                  ],
                ),
              ),
            )
          else
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(11)),
              child: Container(
                height: 80,
                color: colors.surfaceContainerHigh,
                child: Center(
                  child: Icon(Icons.airplanemode_active_outlined,
                      size: 32,
                      color: colors.onSurfaceVariant.withValues(alpha: 0.4)),
                ),
              ),
            ),

          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
            child: Row(
              children: [
                Icon(Icons.airplanemode_active_rounded,
                    color: colors.primary, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(a.aircraftModel,
                          style: const TextStyle(
                              fontWeight: FontWeight.w700, fontSize: 16)),
                      if (a.manufacturerName != null)
                        Text(a.manufacturerName!,
                            style: TextStyle(
                                color: colors.onSurfaceVariant, fontSize: 12)),
                    ],
                  ),
                ),
                ],
            ),
          ),

        Divider(height: 1, color: colors.outlineVariant.withValues(alpha: 0.5)),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                children: [
                  if (a.seatCapacity != null) ...[
                    _buildSpecCell(colors, Icons.airline_seat_recline_normal_outlined, 'Seats', '${a.seatCapacity}', borderRight: true),
                    Divider(height: 1, color: colors.outlineVariant.withValues(alpha: 0.5)),
                  ],
                  if (a.aircraftSpeed != null) ...[
                    _buildSpecCell(colors, Icons.speed_outlined, 'Speed', '${a.aircraftSpeed!.round()} km/h', borderRight: true),
                    Divider(height: 1, color: colors.outlineVariant.withValues(alpha: 0.5)),
                  ],
                  if (a.aircraftFuelConsumption != null)
                    _buildSpecCell(colors, Icons.local_gas_station_outlined, 'Fuel', '${a.aircraftFuelConsumption} L/h', borderRight: true),
                ],
              ),
            ),
            Expanded(
              child: Column(
                children: [
                  if (a.aircraftRangeKm != null) ...[
                    _buildSpecCell(colors, Icons.route_outlined, 'Range', '${a.aircraftRangeKm!.round()} km', borderRight: false),
                    Divider(height: 1, color: colors.outlineVariant.withValues(alpha: 0.5)),
                  ],
                  if (a.baggageCapacity != null)
                    _buildSpecCell(colors, Icons.luggage_outlined, 'Baggage', '${a.baggageCapacity!.round()} kg', borderRight: false),
                ],
              ),
            ),
          ],
        ),
        ],
      ),
    );
  }
  Widget _buildSpecCell(ColorScheme colors, IconData icon, String label, String value, {required bool borderRight}) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
    decoration: borderRight
        ? BoxDecoration(
            border: Border(
              right: BorderSide(color: colors.outlineVariant.withValues(alpha: 0.5)),
            ),
          )
        : null,
    child: Row(
      children: [
        Icon(icon, size: 13, color: colors.onSurfaceVariant),
        const SizedBox(width: 6),
        Text(label, style: TextStyle(fontSize: 12, color: colors.onSurfaceVariant)),
        const Spacer(),
        Text(value, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: colors.onSurface)),
      ],
    ),
  );
}

  
}

class _NavBtn extends StatelessWidget {
  final IconData     icon;
  final VoidCallback onTap;
  const _NavBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 30, height: 30,
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.35),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: Colors.white, size: 20),
      ),
    );
  }
}