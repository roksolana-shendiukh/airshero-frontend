import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../services/planning_service.dart';
import '../../widgets/responsive_layout.dart';
import '../../widgets/planning/route_wizard_header.dart';
import '../../widgets/planning/create_flight_steps/step1_route_info.dart';
import '../../widgets/planning/create_flight_steps/step2_schedule.dart';
import '../../widgets/planning/create_flight_steps/step3_route_confirm.dart';

class CreateRoutePage extends StatefulWidget {
  const CreateRoutePage({super.key});

  @override
  State<CreateRoutePage> createState() => _CreateRoutePageState();
}

class _CreateRoutePageState extends State<CreateRoutePage> {
  late final PlanningService _service;

  String _currentStep = 'routeInfo';

  Map<String, dynamic>? _selectedAirfleet;
  Map<String, dynamic>? _selectedDepartsAirport;
  Map<String, dynamic>? _selectedArrivesAirport;

  List<Map<String, dynamic>> _scheduleGroups = [];
  DateTime? _flightStartDate;
  DateTime? _flightEndDate;

  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _service = PlanningService(context.read<AuthService>());
  }

  bool get _canGoNext {
    switch (_currentStep) {
      case 'routeInfo':
        return _selectedAirfleet != null &&
            _selectedDepartsAirport != null &&
            _selectedArrivesAirport != null &&
            (_selectedDepartsAirport!['airportId'] !=
                _selectedArrivesAirport!['airportId']);
      case 'schedule':
        return _scheduleGroups.isNotEmpty &&
            _flightStartDate != null &&
            _flightEndDate != null &&
            _flightEndDate!.isAfter(_flightStartDate!);
      case 'confirm':
        return true;
      default:
        return false;
    }
  }

  void _next() {
    setState(() {
      switch (_currentStep) {
        case 'routeInfo':
          _currentStep = 'schedule';
        case 'schedule':
          _currentStep = 'confirm';
      }
    });
  }

  void _back() {
    switch (_currentStep) {
      case 'routeInfo':
        context.go('/planning/flights');
      case 'schedule':
        setState(() => _currentStep = 'routeInfo');
      case 'confirm':
        setState(() => _currentStep = 'schedule');
    }
  }

  Future<void> _submit() async {
    setState(() => _isSubmitting = true);
    try {
      final result = await _service.createRoute(
        airfleetId: _selectedAirfleet!['airfleetId'] as int,
        departsAirportId: _selectedDepartsAirport!['airportId'] as int,
        arrivesAirportId: _selectedArrivesAirport!['airportId'] as int,
        flightStartDate: _flightStartDate!.toIso8601String().split('T')[0],
        flightEndDate: _flightEndDate!.toIso8601String().split('T')[0],
        scheduleGroups: _scheduleGroups,
      );

      if (mounted) {
        final flightsGenerated = result['flightsGenerated'] as int? ?? 0;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(children: [
              const Icon(Icons.check_circle_outline,
                  color: Colors.white, size: 16),
              const SizedBox(width: 8),
              Text('Route created · $flightsGenerated flights generated'),
            ]),
            backgroundColor: Colors.green.shade700,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8)),
          ),
        );
        context.go('/planning/flights');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceFirst('Exception: ', '')),
            backgroundColor: Colors.red.shade700,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8)),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ResponsiveLayout(
      scrollable: true,
      header: RouteWizardHeader(
        currentStep: _currentStep,
        onBack: _back,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildStep(),
            const SizedBox(height: 16),
            _buildBottomBar(),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildStep() {
    final colors = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: colors.outline.withValues(alpha: 0.15)),
      ),
      clipBehavior: Clip.antiAlias,
      padding: const EdgeInsets.all(28),
      child: switch (_currentStep) {
        'routeInfo' => Step1RouteInfo(
            service: _service,
            selectedAirfleet: _selectedAirfleet,
            selectedDepartsAirport: _selectedDepartsAirport,
            selectedArrivesAirport: _selectedArrivesAirport,
            onChanged: ({
              required airfleet,
              required departsAirport,
              required arrivesAirport,
            }) {
              setState(() {
                _selectedAirfleet = airfleet;
                _selectedDepartsAirport = departsAirport;
                _selectedArrivesAirport = arrivesAirport;
              });
            },
          ),
        'schedule' => Step2Schedule(
            scheduleGroups: _scheduleGroups,
            flightStartDate: _flightStartDate,
            flightEndDate: _flightEndDate,
            onChanged: ({
              required scheduleGroups,
              required flightStartDate,
              required flightEndDate,
            }) {
              setState(() {
                _scheduleGroups = scheduleGroups;
                _flightStartDate = flightStartDate;
                _flightEndDate = flightEndDate;
              });
            },
          ),
        'confirm' => Step3RouteConfirm(
            airfleet: _selectedAirfleet!,
            departsAirport: _selectedDepartsAirport!,
            arrivesAirport: _selectedArrivesAirport!,
            scheduleGroups: _scheduleGroups,
            flightStartDate: _flightStartDate!,
            flightEndDate: _flightEndDate!,
          ),
        _ => const SizedBox.shrink(),
      },
    );
  }

  Widget _buildBottomBar() {
    final colors = Theme.of(context).colorScheme;
    final isLast = _currentStep == 'confirm';

    return Row(
      children: [
        TextButton.icon(
          onPressed: _back,
          icon: const Icon(Icons.arrow_back, size: 15),
          label: Text(_currentStep == 'routeInfo' ? 'Cancel' : 'Back'),
          style: TextButton.styleFrom(
            foregroundColor: colors.onSurfaceVariant,
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8)),
          ),
        ),
        const Spacer(),
        if (!isLast)
          FilledButton(
            onPressed: _canGoNext ? _next : null,
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(
                  horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(_currentStep == 'routeInfo'
                    ? 'Continue to Schedule'
                    : 'Review & Confirm'),
                const SizedBox(width: 6),
                const Icon(Icons.arrow_forward, size: 15),
              ],
            ),
          )
        else
          _isSubmitting
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : FilledButton.icon(
                  onPressed: _submit,
                  icon: const Icon(Icons.add_road, size: 16),
                  label: const Text('Create route'),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                ),
      ],
    );
  }
}