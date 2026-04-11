import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../models/flight_without_operation_model.dart';
import '../../models/flight_operation_model.dart';
import '../../models/airfleet_model.dart';
import '../../models/gate_model.dart';
import '../../models/flight_crew_model.dart';
import '../../schemas/create_flight_operation_dto.dart';
import '../../services/auth_service.dart';
import '../../services/flight_operation_api_service.dart';
import '../../widgets/responsive_layout.dart';
import '../../widgets/custom/custom_button.dart';
import '../../widgets/flight_operation/operation_status_bar.dart';
import '../../widgets/flight_operation/airfleet_step.dart';

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

  
  FlightOperationModel?   _createdOperation;
  List<FlightCrewModel>   _crew             = [];
  List<FlightCrewModel>   _available        = [];
  CrewValidationModel?    _validation;
  bool                    _loadingCrew      = false;
  bool                    _loadingAvailable = false;
  bool                    _isAddingCrew     = false;
  final Set<int>          _assignedIds      = {};
  String                  _crewSearch       = '';

  bool    _isSubmitting = false;
  String? _errorMessage;

  bool get _operationCreated => _createdOperation != null;

  @override
  void initState() {
    super.initState();
    _apiService = FlightOperationApiService(context.read<AuthService>());
    _loadAirfleets();
    _loadGates();
  }

  Future<void> _loadAirfleets() async {
    setState(() => _loadingAirfleets = true);
    final list = await _apiService.getAirfleets(
        flightId: widget.flight.flightId);
    if (!mounted) return;
    setState(() {
      _airfleets        = list;
      _loadingAirfleets = false;
      if (list.isNotEmpty) _selectedAirfleet = list.first;
    });
  }

  Future<void> _loadGates() async {
    setState(() => _loadingGates = true);
    final list =
        await _apiService.getGates(flightId: widget.flight.flightId);
    if (!mounted) return;
    setState(() {
      _gates        = list;
      _loadingGates = false;
    });
  }

  Future<void> _loadCrew() async {
    if (_createdOperation == null) return;
    setState(() => _loadingCrew = true);
    final results = await Future.wait([
      _apiService.getCrew(_createdOperation!.flightOperationId),
      _apiService.validateCrew(_createdOperation!.flightOperationId),
    ]);
    if (!mounted) return;
    setState(() {
      _crew       = results[0] as List<FlightCrewModel>;
      _validation = results[1] as CrewValidationModel?;
      _loadingCrew = false;
    });
  }

  Future<void> _loadAvailable() async {
    if (_createdOperation == null) return;
    setState(() => _loadingAvailable = true);
    final list = await _apiService.getAvailableCrew(
      _createdOperation!.flightOperationId,
      search: _crewSearch.isNotEmpty ? _crewSearch : null,
    );
    if (!mounted) return;
    setState(() {
      _available        = list;
      _loadingAvailable = false;
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
    final opId = context.read<AuthService>().currentUser?.operationId;
    if (opId != null) {
      final op = await _apiService.getFlightOperation(opId);
      if (mounted) {
        setState(() {
          _createdOperation = op;
          _isSubmitting     = false;
        });
        await _loadCrew();
      }
    } else {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _assignCrew(int crewId) async {
    if (_createdOperation == null) return;
    final result = await _apiService.assignCrew(
        _createdOperation!.flightOperationId, crewId);
    if (!mounted || !result.success) return;
    setState(() => _assignedIds.add(crewId));
    await _loadCrew();
    await _loadAvailable();
  }

  Future<void> _removeCrew(int crewId) async {
    if (_createdOperation == null) return;
    await _apiService.removeCrew(
        _createdOperation!.flightOperationId, crewId);
    if (!mounted) return;
    await _loadCrew();
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
          Expanded(
            child: _operationCreated ? _buildCrewStep() : _buildSetupStep(),
          ),
          if (!_operationCreated) _buildFooter(Theme.of(context).colorScheme),
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
          bottom: BorderSide(
              color: colors.outlineVariant.withValues(alpha: 0.4)),
        ),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: () => context.go('/flight-operations'),
            tooltip: 'Back to board',
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    widget.flight.flightNumber,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    '${widget.flight.departsCode} → ${widget.flight.arrivesCode}',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: colors.onSurfaceVariant,
                        ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    _fmtTime(widget.flight.departsDatetime),
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: colors.onSurfaceVariant,
                        ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              _buildStepIndicator(colors),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStepIndicator(ColorScheme colors) {
    return Row(
      children: [
        _StepDot(
          number: 1,
          label: 'Aircraft & Gate',
          isActive: !_operationCreated,
          isDone: _operationCreated,
          colors: colors,
        ),
        Container(
          width: 32,
          height: 1,
          color: colors.outlineVariant,
          margin: const EdgeInsets.symmetric(horizontal: 6),
        ),
        _StepDot(
          number: 2,
          label: 'Crew',
          isActive: _operationCreated,
          isDone: false,
          colors: colors,
        ),
      ],
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
                              ? Padding(
                                  padding: const EdgeInsets.all(20),
                                  child: _SelectedAircraftCard(
                                    airfleet: _selectedAirfleet!,
                                    colors:   colors,
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

        // Gate
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
                        : ListView(
                            padding: const EdgeInsets.all(20),
                            children: _groupedGates.entries
                                .map((e) => _buildTerminalGroup(
                                    e.key, e.value, colors))
                                .toList(),
                          ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title, IconData icon,
      {Widget? trailing}) {
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
              fontSize:      11,
              fontWeight:    FontWeight.w700,
              letterSpacing: 1.0,
            ),
          ),
          const Spacer(),
          if (trailing != null) trailing,
          if (_errorMessage != null) ...[
            const SizedBox(height: 8),
          ],
        ],
      ),
    );
  }

  Widget _buildTerminalGroup(
      String terminal, List<GateModel> gates, ColorScheme colors) {
    final isExpanded = _openTerminal == terminal;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
            color: colors.outlineVariant.withValues(alpha: 0.6)),
      ),
      child: Column(
        children: [
          ListTile(
            dense: true,
            title: Text('Terminal $terminal',
                style: const TextStyle(
                    fontWeight: FontWeight.w600, fontSize: 13)),
            trailing: Icon(
              isExpanded
                  ? Icons.keyboard_arrow_up_rounded
                  : Icons.keyboard_arrow_down_rounded,
              size: 20,
            ),
            onTap: () => setState(
                () => _openTerminal = isExpanded ? null : terminal),
          ),
          if (isExpanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: gates
                    .map((gate) => GestureDetector(
                          onTap: gate.isAvailable
                              ? () => setState(() => _selectedGate =
                                  _selectedGate?.gateId == gate.gateId
                                      ? null
                                      : gate)
                              : null,
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            width: 72,
                            height: 56,
                            decoration: BoxDecoration(
                              color: !gate.isAvailable
                                  ? colors.surfaceContainerHighest
                                      .withValues(alpha: 0.5)
                                  : _selectedGate?.gateId == gate.gateId
                                      ? colors.primaryContainer
                                          .withValues(alpha: 0.35)
                                      : colors.surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: !gate.isAvailable
                                    ? colors.outlineVariant
                                        .withValues(alpha: 0.4)
                                    : _selectedGate?.gateId == gate.gateId
                                        ? colors.primary
                                        : colors.outlineVariant,
                                width: _selectedGate?.gateId == gate.gateId
                                    ? 1.5
                                    : 1,
                              ),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                if (!gate.isAvailable)
                                  Icon(Icons.lock_outline,
                                      size: 12,
                                      color: colors.onSurfaceVariant
                                          .withValues(alpha: 0.4)),
                                Text(
                                  gate.gateCode,
                                  style: TextStyle(
                                    fontSize:   16,
                                    fontWeight: FontWeight.w600,
                                    color: !gate.isAvailable
                                        ? colors.onSurfaceVariant
                                            .withValues(alpha: 0.4)
                                        : _selectedGate?.gateId == gate.gateId
                                            ? colors.primary
                                            : colors.onSurface,
                                  ),
                                ),
                                Text(
                                  gate.isAvailable ? 'Gate' : 'Busy',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: !gate.isAvailable
                                        ? colors.onSurfaceVariant
                                            .withValues(alpha: 0.4)
                                        : _selectedGate?.gateId == gate.gateId
                                            ? colors.primary
                                                .withValues(alpha: 0.7)
                                            : colors.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ))
                    .toList(),
              ),
            ),
        ],
      ),
    );
  }


  Widget _buildCrewStep() {
    final colors = Theme.of(context).colorScheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          width: 300,
          child: Container(
            decoration: BoxDecoration(
              border: Border(
                right: BorderSide(
                    color: colors.outlineVariant.withValues(alpha: 0.4)),
              ),
            ),
            child: _buildOperationSummary(colors),
          ),
        ),

        // Crew
        Expanded(
          child: Column(
            children: [
              _buildSectionHeader(
                'Crew',
                Icons.people_outline,
                trailing: TextButton.icon(
                  onPressed: () {
                    setState(() {
                      _isAddingCrew = !_isAddingCrew;
                      _assignedIds.clear();
                    });
                    if (_isAddingCrew) _loadAvailable();
                  },
                  icon: Icon(
                    _isAddingCrew
                        ? Icons.close_rounded
                        : Icons.person_add_outlined,
                    size: 14,
                  ),
                  label: Text(
                    _isAddingCrew ? 'Done' : 'Add member',
                    style: const TextStyle(fontSize: 13),
                  ),
                ),
              ),
              Expanded(
                child: _isAddingCrew
                    ? _buildAddCrewMode(colors)
                    : _buildCrewList(colors),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildOperationSummary(ColorScheme colors) {
    final op = _createdOperation!;
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text('Operation created',
            style: TextStyle(
              fontSize:   11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.0,
              color:      Colors.green,
            )),
        const SizedBox(height: 16),
        _SummaryRow(
          icon:  Icons.airplanemode_active_outlined,
          label: 'Aircraft',
          value: op.aircraftModel ?? '—',
        ),
        const SizedBox(height: 12),
        _SummaryRow(
          icon:  Icons.door_sliding_outlined,
          label: 'Gate',
          value: op.gateCode != null ? 'Gate ${op.gateCode}' : '—',
        ),
        const SizedBox(height: 12),
        _SummaryRow(
          icon:  Icons.flight_takeoff_outlined,
          label: 'Flight',
          value: '${op.flightNumber ?? '—'} · '
              '${op.departsCode ?? '—'} → ${op.arrivesCode ?? '—'}',
        ),
        const SizedBox(height: 28),
        if (_validation != null) _buildValidationStatus(colors),
        const SizedBox(height: 20),
        CustomButton(
          label:     'Go to Active Operation',
          icon:      Icons.arrow_forward_rounded,
          onPressed: () => context.go('/flight-operations/active'),
        ),
      ],
    );
  }

  Widget _buildValidationStatus(ColorScheme colors) {
    final v = _validation!;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: v.valid
            ? Colors.green.withValues(alpha: 0.08)
            : colors.errorContainer.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: v.valid
              ? Colors.green.withValues(alpha: 0.3)
              : colors.error.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                v.valid ? Icons.check_circle_outline : Icons.warning_amber_outlined,
                size:  14,
                color: v.valid ? Colors.green : colors.error,
              ),
              const SizedBox(width: 6),
              Text(
                v.valid ? 'Crew complete' : 'Crew incomplete',
                style: TextStyle(
                  fontSize:   12,
                  fontWeight: FontWeight.w600,
                  color:      v.valid ? Colors.green : colors.error,
                ),
              ),
            ],
          ),
          if (!v.valid && v.missing.isNotEmpty) ...[
            const SizedBox(height: 6),
            ...v.missing.entries.map((e) => Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(
                    '· ${e.value}x ${e.key} missing',
                    style: TextStyle(
                        fontSize: 11, color: colors.onSurfaceVariant),
                  ),
                )),
          ],
        ],
      ),
    );
  }

  Widget _buildCrewList(ColorScheme colors) {
    if (_loadingCrew) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_crew.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.people_outline,
                size: 48,
                color: colors.outline.withValues(alpha: 0.3)),
            const SizedBox(height: 12),
            Text('No crew assigned yet',
                style: TextStyle(color: colors.onSurfaceVariant)),
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: () {
                setState(() { _isAddingCrew = true; _assignedIds.clear(); });
                _loadAvailable();
              },
              icon:  const Icon(Icons.person_add_outlined, size: 16),
              label: const Text('Add crew member'),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(20),
      itemCount: _crew.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (_, i) => _CrewTile(
        member:        _crew[i],
        onRemove:      () => _removeCrew(_crew[i].flightCrewId),
        colors:        colors,
      ),
    );
  }

  Widget _buildAddCrewMode(ColorScheme colors) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
          child: TextField(
            decoration: InputDecoration(
              hintText:      'Search by name',
              prefixIcon:    const Icon(Icons.search, size: 18),
              border:        OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8)),
              contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 10),
              isDense: true,
            ),
            onChanged: (v) {
              _crewSearch = v;
              _loadAvailable();
            },
          ),
        ),
        Expanded(
          child: _loadingAvailable
              ? const Center(child: CircularProgressIndicator())
              : _available.isEmpty
                  ? Center(
                      child: Text('No available crew',
                          style:
                              TextStyle(color: colors.onSurfaceVariant)),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                      itemCount: _available.length,
                      separatorBuilder: (_, __) =>
                          const SizedBox(height: 6),
                      itemBuilder: (_, i) {
                        final c         = _available[i];
                        final assigned  = _assignedIds.contains(c.flightCrewId);
                        return _AvailableCrewTile(
                          member:     c,
                          isAssigned: assigned,
                          onAssign:   assigned
                              ? null
                              : () => _assignCrew(c.flightCrewId),
                          colors:     colors,
                        );
                      },
                    ),
        ),
      ],
    );
  }

  Widget _buildFooter(ColorScheme colors) {
    if (_operationCreated) return const SizedBox.shrink();

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
                  color: colors.errorContainer.withValues(alpha: 0.3),
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
                              color: colors.onErrorContainer,
                              fontSize: 12)),
                    ),
                  ],
                ),
              ),
            ),
          const Spacer(),
          SizedBox(
            width: 200,
            height: 44,
            child: CustomButton(
              label:     _isSubmitting ? 'Creating...' : 'Create Operation',
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


class _StepDot extends StatelessWidget {
  final int         number;
  final String      label;
  final bool        isActive;
  final bool        isDone;
  final ColorScheme colors;

  const _StepDot({
    required this.number,
    required this.label,
    required this.isActive,
    required this.isDone,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    final color = isDone
        ? Colors.green
        : isActive
            ? colors.primary
            : colors.onSurfaceVariant.withValues(alpha: 0.4);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 20, height: 20,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isDone || isActive
                ? color.withValues(alpha: 0.12)
                : Colors.transparent,
            border: Border.all(color: color, width: 1.5),
          ),
          child: Center(
            child: isDone
                ? Icon(Icons.check, size: 11, color: color)
                : Text('$number',
                    style: TextStyle(
                        fontSize:   10,
                        fontWeight: FontWeight.w700,
                        color:      color)),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            fontSize:   12,
            fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
            color:      isActive ? colors.onSurface : colors.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final IconData icon;
  final String   label;
  final String   value;

  const _SummaryRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Row(
      children: [
        Icon(icon, size: 14, color: colors.onSurfaceVariant),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: TextStyle(
                    fontSize: 10, color: colors.onSurfaceVariant)),
            Text(value,
                style: const TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w600)),
          ],
        ),
      ],
    );
  }
}

class _SelectedAircraftCard extends StatelessWidget {
  final AirfleetModel airfleet;
  final ColorScheme   colors;

  const _SelectedAircraftCard(
      {required this.airfleet, required this.colors});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color:        colors.primary.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(8),
        border:       Border.all(color: colors.primary.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Icon(Icons.airplanemode_active_rounded,
              color: colors.primary, size: 22),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(airfleet.aircraftModel,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 15)),
                if (airfleet.manufacturerName != null)
                  Text(airfleet.manufacturerName!,
                      style: TextStyle(
                          color: colors.onSurfaceVariant, fontSize: 12)),
              ],
            ),
          ),
          Icon(Icons.check_circle_rounded,
              color: colors.primary, size: 22),
        ],
      ),
    );
  }
}

class _CrewTile extends StatelessWidget {
  final FlightCrewModel member;
  final VoidCallback    onRemove;
  final ColorScheme     colors;

  const _CrewTile({
    required this.member,
    required this.onRemove,
    required this.colors,
  });

  Color _positionColor() {
    switch (member.position) {
      case 'Pilot':            return colors.primary;
      case 'Co-Pilot':         return Colors.blue;
      case 'Flight Attendant': return Colors.teal;
      case 'Engineer':         return Colors.orange;
      default:                 return colors.onSurfaceVariant;
    }
  }

  @override
  Widget build(BuildContext context) {
    final pColor = _positionColor();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color:        colors.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: pColor.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: pColor.withValues(alpha: 0.15),
            child: Text(
              member.firstName?.isNotEmpty == true
                  ? member.firstName![0]
                  : '?',
              style: TextStyle(
                  color:      pColor,
                  fontWeight: FontWeight.w700,
                  fontSize:   13),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(member.fullName,
                    style: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w600)),
                Text(member.position ?? '—',
                    style: TextStyle(
                        fontSize: 11,
                        color:    pColor,
                        fontWeight: FontWeight.w500)),
              ],
            ),
          ),
          IconButton(
            icon: Icon(Icons.remove_circle_outline,
                size: 16, color: colors.error),
            onPressed: onRemove,
            visualDensity: VisualDensity.compact,
          ),
        ],
      ),
    );
  }
}

class _AvailableCrewTile extends StatelessWidget {
  final FlightCrewModel member;
  final bool            isAssigned;
  final VoidCallback?   onAssign;
  final ColorScheme     colors;

  const _AvailableCrewTile({
    required this.member,
    required this.isAssigned,
    required this.onAssign,
    required this.colors,
  });

  Color _positionColor() {
    switch (member.position) {
      case 'Pilot':            return colors.primary;
      case 'Co-Pilot':         return Colors.blue;
      case 'Flight Attendant': return Colors.teal;
      case 'Engineer':         return Colors.orange;
      default:                 return colors.onSurfaceVariant;
    }
  }

  @override
  Widget build(BuildContext context) {
    final pColor = _positionColor();
    return ListTile(
      dense: true,
      shape:     RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      tileColor: isAssigned
          ? Colors.green.withValues(alpha: 0.08)
          : colors.surfaceContainerHighest,
      leading: CircleAvatar(
        radius: 16,
        backgroundColor: pColor.withValues(alpha: 0.15),
        child: Text(
          member.firstName?.isNotEmpty == true ? member.firstName![0] : '?',
          style: TextStyle(
              color: pColor, fontWeight: FontWeight.w700, fontSize: 13),
        ),
      ),
      title: Text(member.fullName,
          style:
              const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
      subtitle: Text(
        '${member.position ?? '—'}'
        '${member.experienceYears != null ? ' · ${member.experienceYears} yrs' : ''}',
        style: TextStyle(fontSize: 11, color: pColor),
      ),
      trailing: isAssigned
          ? const Icon(Icons.check_circle, color: Colors.green, size: 20)
          : IconButton(
              icon:      Icon(Icons.add_circle_outline,
                  color: colors.primary, size: 20),
              onPressed: onAssign,
              visualDensity: VisualDensity.compact,
            ),
    );
  }
}