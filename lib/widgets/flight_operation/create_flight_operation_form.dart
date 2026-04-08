import 'package:flutter/material.dart';
import '../../models/flight_without_operation_model.dart';
import '../../models/airfleet_model.dart';
import '../../models/gate_model.dart';
import '../../schemas/create_flight_operation_dto.dart';
import '../../services/flight_operation_api_service.dart';
import '../custom/custom_button.dart';
import 'airfleet_step.dart';
import 'flight_step.dart';

class CreateFlightOperationForm extends StatefulWidget {
  final FlightOperationApiService apiService;
  final VoidCallback onSuccess;
  final VoidCallback onCancel;

  const CreateFlightOperationForm({
    super.key,
    required this.apiService,
    required this.onSuccess,
    required this.onCancel,
  });

  @override
  State<CreateFlightOperationForm> createState() =>
      _CreateFlightOperationFormState();
}

class _CreateFlightOperationFormState extends State<CreateFlightOperationForm> {
  bool _isLoadingFlights = true;
  bool _isLoadingAirfleets = false;
  bool _isLoadingGates = false;
  bool _isSubmitting = false;
  bool _showAircraftList = false;
  String? _errorMessage;
  String? _openTerminal;

  List<FlightWithoutOperationModel> _flights = [];
  List<AirfleetModel> _airfleets = [];
  List<GateModel> _gates = [];

  FlightWithoutOperationModel? _selectedFlight;
  AirfleetModel? _selectedAirfleet;
  GateModel? _selectedGate;

  @override
  void initState() {
    super.initState();
    _loadFlights();
  }

  Future<void> _loadFlights() async {
    setState(() => _isLoadingFlights = true);
    try {
      final flights = await widget.apiService.getFlightsWithoutOperation();
      if (mounted) {
        setState(() {
          _flights = flights;
          _isLoadingFlights = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to load flights';
          _isLoadingFlights = false;
        });
      }
    }
  }

  Future<void> _loadAirfleets(int flightId) async {
    setState(() => _isLoadingAirfleets = true);
    final airfleets = await widget.apiService.getAirfleets(flightId: flightId);
    if (!mounted) return;
    setState(() {
      _airfleets = airfleets;
      _isLoadingAirfleets = false;
      if (_selectedAirfleet == null && airfleets.isNotEmpty) {
        _selectedAirfleet = airfleets.first;
      }
    });
  }

  Future<void> _loadGates(int flightId) async {
    setState(() => _isLoadingGates = true);
    final gates = await widget.apiService.getGates(flightId: flightId);
    if (!mounted) return;
    setState(() {
      _gates = gates;
      _isLoadingGates = false;
    });
  }

  void _onFlightSelected(FlightWithoutOperationModel? flight) {
    if (flight?.flightId == _selectedFlight?.flightId) return;
    setState(() {
      _selectedFlight = flight;
      _selectedAirfleet = null;
      _selectedGate = null;
      _airfleets = [];
      _gates = [];
      _showAircraftList = false;
      _openTerminal = null;
    });
    if (flight != null) {
      _loadAirfleets(flight.flightId);
      _loadGates(flight.flightId);
    }
  }

  Future<void> _handleSubmit() async {
    if (_selectedFlight == null || _selectedAirfleet == null || _selectedGate == null) return;

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    final dto = CreateFlightOperationDTO(
      flightId: _selectedFlight!.flightId,
      airfleetId: _selectedAirfleet!.airfleetId,
      gateId: _selectedGate!.gateId,
    );

    final result = await widget.apiService.createFlightOperation(dto);
    if (!mounted) return;
    setState(() => _isSubmitting = false);

    if (result.success) {
      widget.onSuccess();
    } else {
      setState(() => _errorMessage = result.error ?? 'Failed to create flight operation');
    }
  }

  Map<String, List<GateModel>> get _groupedGates {
    final map = <String, List<GateModel>>{};
    for (final g in _gates) {
      final key = g.terminalCode ?? '?';
      map.putIfAbsent(key, () => []).add(g);
    }
    return map;
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        constraints: const BoxConstraints(
          maxWidth: 1200,
          maxHeight: 1050, 
        ),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 30,
              offset: const Offset(0, 12),
            )
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Column(
            children: [
              _buildHeader(colors),
              Expanded(
                child: _buildBody(colors),
              ),
              if (_errorMessage != null) _buildError(colors),
              _buildFooter(colors),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(ColorScheme colors) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border(bottom: BorderSide(color: colors.outlineVariant.withOpacity(0.4))),
      ),
      child: Row(
        children: [
          Icon(Icons.flight_takeoff_rounded, color: colors.primary, size: 22),
          const SizedBox(width: 12),
          const Text(
            'Create Flight Operation',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
          ),
          const Spacer(),
          IconButton(
            onPressed: widget.onCancel,
            icon: const Icon(Icons.close_rounded, size: 22),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(ColorScheme colors) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          flex: 46,
          child: Container(
            color: colors.surfaceContainerLowest.withOpacity(0.3),
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: _isLoadingFlights
                ? const Center(child: CircularProgressIndicator())
                : FlightStep(
                    flights: _flights,
                    selected: _selectedFlight,
                    onChanged: _onFlightSelected,
                  ),
          ),
        ),
        VerticalDivider(width: 1, thickness: 1, color: colors.outlineVariant.withOpacity(0.4)),
        Expanded(
          flex: 54,
          child: _selectedFlight == null
              ? _buildPlaceholder(colors)
              : AnimatedSwitcher(
                  duration: const Duration(milliseconds: 250),
                  child: _showAircraftList
                      ? _buildAircraftListMode(colors)
                      : _buildDetailsMode(colors),
                ),
        ),
      ],
    );
  }

  Widget _buildAircraftListMode(ColorScheme colors) {
    return Column(
      key: const ValueKey('ListMode'),
      children: [
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: AirfleetStep(
              airfleets: _airfleets,
              selected: _selectedAirfleet,
              apiService: widget.apiService,
              onChanged: (a) => setState(() {
                _selectedAirfleet = a;
                _showAircraftList = false;
              }),
            ),
          ),
        ),
        _buildModeFooter('Back to details', Icons.arrow_back_rounded, () {
          setState(() => _showAircraftList = false);
        }, colors),
      ],
    );
  }

  Widget _buildDetailsMode(ColorScheme colors) {
    return ListView(
      key: const ValueKey('DetailsMode'),
      padding: const EdgeInsets.all(28),
      children: [
        _buildAircraftSection(colors),
        const SizedBox(height: 28),
        _buildGateSection(colors),
      ],
    );
  }

  Widget _buildAircraftSection(ColorScheme colors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('AIRCRAFT', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 1.1)),
            if (_airfleets.length > 1)
              TextButton(
                onPressed: () => setState(() => _showAircraftList = true),
                child: const Text('Change', style: TextStyle(fontSize: 13)),
              ),
          ],
        ),
        const SizedBox(height: 10),
        if (_isLoadingAirfleets)
          const LinearProgressIndicator()
        else if (_selectedAirfleet != null)
          _SelectedAircraftCard(
            airfleet: _selectedAirfleet!,
            colors: colors,
          ),
      ],
    );
  }

  Widget _buildGateSection(ColorScheme colors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('GATE SELECTION', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 1.1)),
        const SizedBox(height: 14),
        if (_isLoadingGates)
          const Center(child: Padding(padding: EdgeInsets.all(25), child: CircularProgressIndicator()))
        else if (_gates.isEmpty)
          const Text('No gates available', style: TextStyle(fontSize: 14))
        else
          ..._groupedGates.entries.map((e) => _buildTerminalGroup(e.key, e.value, colors)),
      ],
    );
  }

  Widget _buildTerminalGroup(String terminal, List<GateModel> gates, ColorScheme colors) {
    final isExpanded = _openTerminal == terminal;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: colors.outlineVariant.withOpacity(0.6)),
      ),
      child: Column(
        children: [
          ListTile(
            dense: true,
            title: Text('Terminal $terminal', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            trailing: Icon(isExpanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded, size: 20),
            onTap: () => setState(() => _openTerminal = isExpanded ? null : terminal),
          ),
          if (isExpanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: gates.map((gate) => ChoiceChip(
                  label: Text(gate.gateCode, style: const TextStyle(fontSize: 12)),
                  selected: _selectedGate?.gateId == gate.gateId,
                  onSelected: gate.isAvailable ? (val) => setState(() => _selectedGate = val ? gate : null) : null,
                  showCheckmark: false,
                  selectedColor: colors.primaryContainer,
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                )).toList(),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPlaceholder(ColorScheme colors) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.airplane_ticket_outlined, size: 56, color: colors.outline.withOpacity(0.15)),
          const SizedBox(height: 12),
          Text('Select a flight to continue', style: TextStyle(color: colors.onSurfaceVariant, fontSize: 14)),
        ],
      ),
    );
  }

  Widget _buildFooter(ColorScheme colors) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border(top: BorderSide(color: colors.outlineVariant.withOpacity(0.4))),
      ),
      child: Row(
        children: [
          const Spacer(),
          TextButton(
            onPressed: widget.onCancel,
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            ),
            child: const Text('Cancel', style: TextStyle(fontSize: 14)),
          ),
          const SizedBox(width: 14),
          SizedBox(
            width: 210,
            height: 44, 
            child: CustomButton(
              label: _isSubmitting ? 'Processing...' : 'Create Operation',
              onPressed: (_selectedFlight != null && _selectedAirfleet != null && _selectedGate != null && !_isSubmitting)
                  ? _handleSubmit : null,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModeFooter(String label, IconData icon, VoidCallback onTap, ColorScheme colors) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextButton.icon(
        onPressed: onTap, 
        icon: Icon(icon, size: 16), 
        label: Text(label, style: const TextStyle(fontSize: 13))
      ),
    );
  }

  Widget _buildError(ColorScheme colors) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 6),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.errorContainer.withOpacity(0.3),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: colors.error.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline_rounded, color: colors.error, size: 18),
          const SizedBox(width: 10),
          Expanded(child: Text(_errorMessage!, style: TextStyle(color: colors.onErrorContainer, fontSize: 12))),
        ],
      ),
    );
  }
}

class _SelectedAircraftCard extends StatelessWidget {
  final AirfleetModel airfleet;
  final ColorScheme colors;

  const _SelectedAircraftCard({required this.airfleet, required this.colors});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.primary.withOpacity(0.04),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: colors.primary.withOpacity(0.2), width: 1),
      ),
      child: Row(
        children: [
          Icon(Icons.airplanemode_active_rounded, color: colors.primary, size: 20),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(airfleet.aircraftModel, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                if (airfleet.manufacturerName != null)
                  Text(airfleet.manufacturerName!, style: TextStyle(color: colors.onSurfaceVariant, fontSize: 12)),
              ],
            ),
          ),
          Icon(Icons.check_circle_rounded, color: colors.primary, size: 22),
        ],
      ),
    );
  }
}