import 'package:flutter/material.dart';
import '../../models/flight_without_operation_model.dart';
import '../../models/gate_model.dart';
import '../../models/airfleet_model.dart';
import '../../models/flight_operation_status_model.dart';
import '../../schemas/create_flight_operation_dto.dart';
import '../../services/flight_operation_api_service.dart';
import '../custom/custom_select_field.dart';
import '../custom/custom_button.dart';
import 'airfleet_step.dart';

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

class _CreateFlightOperationFormState
    extends State<CreateFlightOperationForm> {
  int _currentStep = 0;
  static const int _totalSteps = 3;

  bool _isLoadingData  = true;
  bool _isLoadingGates = false;
  bool _isSubmitting   = false;
  String? _errorMessage;

  List<FlightWithoutOperationModel> _flights  = [];
  List<AirfleetModel>              _airfleets = [];
  List<GateModel>                  _gates     = [];
  List<FlightOperationStatusModel> _statuses  = [];

  FlightWithoutOperationModel? _selectedFlight;
  FlightOperationStatusModel?  _selectedStatus;
  AirfleetModel?               _selectedAirfleet;
  GateModel?                   _selectedGate;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoadingData = true);
    try {
      final results = await Future.wait([
        widget.apiService.getFlightsWithoutOperation(),
        widget.apiService.getAirfleets(flightId: _selectedFlight?.flightId),
        widget.apiService.getOperationStatuses(),
      ]);
      if (mounted) {
        setState(() {
          _flights   = results[0] as List<FlightWithoutOperationModel>;
          _airfleets = results[1] as List<AirfleetModel>;
          _statuses  = results[2] as List<FlightOperationStatusModel>;
          _isLoadingData = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage  = 'Failed to load data';
          _isLoadingData = false;
        });
      }
    }
  }

  Future<void> _loadGates({int? minCapacity}) async {
    if (_selectedFlight == null) return;
    setState(() => _isLoadingGates = true);
    final gates = await widget.apiService.getGates(
      airportId:   _selectedFlight!.departsAirportId,
      minCapacity: minCapacity,
    );
    if (mounted) {
      setState(() {
        _gates          = gates;
        _isLoadingGates = false;
      });
    }
  }

  bool get _canGoNext {
    switch (_currentStep) {
      case 0: return _selectedFlight != null;
      case 1: return _selectedAirfleet != null;
      case 2: return true;
      default: return false;
    }
  }

  void _goNext() {
    if (!_canGoNext) return;
    if (_currentStep == 0) {
      _loadAirfleets(); 
    }
    if (_currentStep == 1) {
      _loadGates(minCapacity: _selectedAirfleet?.seatCapacity);
    }
    setState(() => _currentStep++);
  }

  Future<void> _loadAirfleets() async {
    final airfleets = await widget.apiService
        .getAirfleets(flightId: _selectedFlight?.flightId);
    if (mounted) setState(() => _airfleets = airfleets);
  }

  void _goBack() {
    if (_currentStep > 0) setState(() => _currentStep--);
  }

  Future<void> _handleSubmit() async {
    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    final dto = CreateFlightOperationDTO(
      flightId:   _selectedFlight!.flightId,
      airfleetId: _selectedAirfleet?.airfleetId,
      gateId:     _selectedGate?.gateId,
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

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: colors.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 12, 0),
            child: Row(
              children: [
                Icon(Icons.flight_takeoff_outlined,
                    color: colors.primary, size: 22),
                const SizedBox(width: 10),
                Text(
                  'New Flight Operation',
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.w600),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: widget.onCancel,
                  tooltip: 'Cancel',
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: _StepIndicator(
              currentStep: _currentStep,
              totalSteps: _totalSteps,
              labels: const ['Flight', 'Aircraft', 'Gate'],
            ),
          ),

          const Divider(height: 28),

          if (_isLoadingData)
            const Padding(
              padding: EdgeInsets.all(48),
              child: Center(child: CircularProgressIndicator()),
            )
          else
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                transitionBuilder: (child, animation) => FadeTransition(
                  opacity: animation,
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0.04, 0),
                      end: Offset.zero,
                    ).animate(animation),
                    child: child,
                  ),
                ),
                child: KeyedSubtree(
                  key: ValueKey(_currentStep),
                  child: _buildStep(context, colors),
                ),
              ),
            ),

          if (_errorMessage != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: colors.errorContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error_outline,
                        color: colors.onErrorContainer, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: TextStyle(
                            color: colors.onErrorContainer, fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // Actions
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
            child: Row(
              children: [
                if (_currentStep > 0)
                  TextButton.icon(
                    onPressed: _goBack,
                    icon: const Icon(Icons.arrow_back, size: 16),
                    label: const Text('Back'),
                  ),
                const Spacer(),
                if (_currentStep < _totalSteps - 1)
                  SizedBox(
                    width: 120,
                    child: CustomButton(
                      label: 'Next',
                      onPressed: _canGoNext ? _goNext : null,
                    ),
                  )
                else
                  SizedBox(
                    width: 160,
                    child: CustomButton(
                      label: _isSubmitting ? 'Creating...' : 'Create',
                      onPressed: _isSubmitting ? null : _handleSubmit,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStep(BuildContext context, ColorScheme colors) {
    switch (_currentStep) {
      case 0:
        return _StepContent(
          title: 'Select Flight',
          subtitle: 'Choose a flight without an assigned operation',
          child: CustomSelectField(
            label: 'Flight',
            icon: Icons.flight_outlined,
            value: _selectedFlight?.flightId.toString() ?? '',
            items: _flights.map((f) => f.flightId.toString()).toList(),
            itemLabels: _flights.map((f) => f.label).toList(),
            searchable: true,
            onChanged: (v) => setState(() {
              _selectedFlight = v == null
                  ? null
                  : _flights.firstWhere((f) => f.flightId.toString() == v);
              _selectedGate = null;
              _gates = [];
            }),
          ),
        );

      case 1:
        return _StepContent(
          title: 'Assign Aircraft',
          subtitle: 'Select the aircraft for this route',
          child: AirfleetStep(
            airfleets:  _airfleets,
            selected:   _selectedAirfleet,
            apiService: widget.apiService,
            onChanged: (a) => setState(() {
              _selectedAirfleet = a;
              _selectedGate     = null;
            }),
          ),
        );

      case 2:
        return _StepContent(
          title: 'Assign Gate',
          subtitle: _selectedAirfleet?.seatCapacity != null
              ? 'Gates filtered: terminal capacity ≥ ${_selectedAirfleet!.seatCapacity} seats'
              : 'Select departure gate (optional)',
          child: _isLoadingGates
              ? const Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: Center(child: CircularProgressIndicator()),
                )
              : CustomSelectField(
                  label: 'Gate',
                  icon: Icons.door_sliding_outlined,
                  value: _selectedGate?.gateId.toString() ?? '',
                  items: _gates.map((g) => g.gateId.toString()).toList(),
                  itemLabels: _gates.map((g) => g.label).toList(),
                  searchable: true,
                  onChanged: (v) => setState(() {
                    _selectedGate = v == null
                        ? null
                        : _gates.firstWhere((g) => g.gateId.toString() == v);
                  }),
                ),
        );

      default:
        return const SizedBox.shrink();
    }
  }
}

// ── Step Indicator ─────────────────────────────────────────────────────────────

class _StepIndicator extends StatelessWidget {
  final int currentStep;
  final int totalSteps;
  final List<String> labels;

  const _StepIndicator({
    required this.currentStep,
    required this.totalSteps,
    required this.labels,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Row(
      children: List.generate(totalSteps, (i) {
        final isDone   = i < currentStep;
        final isActive = i == currentStep;
        return Expanded(
          child: Column(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                height: 3,
                decoration: BoxDecoration(
                  color: isDone || isActive
                      ? colors.primary
                      : colors.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isDone
                          ? colors.primary
                          : isActive
                              ? colors.primaryContainer
                              : colors.surfaceContainerHighest,
                      border: Border.all(
                        color: isDone || isActive
                            ? colors.primary
                            : colors.outline,
                        width: 1.5,
                      ),
                    ),
                    child: Center(
                      child: isDone
                          ? Icon(Icons.check, size: 12, color: colors.onPrimary)
                          : Text(
                              '${i + 1}',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: isActive
                                    ? colors.primary
                                    : colors.onSurfaceVariant,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    labels[i],
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: isDone || isActive
                              ? colors.primary
                              : colors.onSurfaceVariant,
                          fontWeight: isActive
                              ? FontWeight.w600
                              : FontWeight.normal,
                        ),
                  ),
                ],
              ),
            ],
          ),
        );
      }),
    );
  }
}

// ── Step Content ───────────────────────────────────────────────────────────────

class _StepContent extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget child;

  const _StepContent({
    required this.title,
    required this.subtitle,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context)
                .textTheme
                .titleSmall
                ?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}