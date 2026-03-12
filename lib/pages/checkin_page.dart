import 'package:flutter/material.dart';
import '../../widgets/responsive_layout.dart';
import '../../widgets/checkin/checkin_search_step.dart';

enum CheckInStep {
  search,
  confirmPassenger,
  selectSeat,
  baggage,
  payment,
  boardingPass,
}

class CheckInPage extends StatefulWidget {
  const CheckInPage({super.key});

  @override
  State<CheckInPage> createState() => _CheckInPageState();
}

class _CheckInPageState extends State<CheckInPage> {
  CheckInStep _currentStep = CheckInStep.search;

  // Data passed between steps
  Map<String, dynamic>? _bookingData;
  String? _selectedSeat;
  List<Map<String, dynamic>> _baggageUnits = [];
  double _extraPaymentAmount = 0;

  final List<({String label, CheckInStep step})> _steps = const [
    (label: 'Search',        step: CheckInStep.search),
    (label: 'Passenger',     step: CheckInStep.confirmPassenger),
    (label: 'Seat',          step: CheckInStep.selectSeat),
    (label: 'Baggage',       step: CheckInStep.baggage),
    (label: 'Payment',       step: CheckInStep.payment),
    (label: 'Boarding Pass', step: CheckInStep.boardingPass),
  ];

  int get _currentStepIndex =>
      _steps.indexWhere((s) => s.step == _currentStep);

  void _goToStep(CheckInStep step) => setState(() => _currentStep = step);

  void _resetWizard() {
    setState(() {
      _currentStep        = CheckInStep.search;
      _bookingData        = null;
      _selectedSeat       = null;
      _baggageUnits       = [];
      _extraPaymentAmount = 0;
    });
  }

  void _handleSearchResult({
    required String documentNumber,
    required String flightNumber,
    required DateTime departDate,
  }) {
    // TODO: call CheckInApiService.searchBooking(...)
    // For now simulate found booking and move to next step
    setState(() {
      _bookingData = {
        'documentNumber': documentNumber,
        'flightNumber':   flightNumber,
        'departDate':     departDate,
        // API will populate: passengerName, class, bookingNumber, baggage, etc.
      };
      _currentStep = CheckInStep.confirmPassenger;
    });
  }

  @override
  Widget build(BuildContext context) {
    return ResponsiveLayout(
      body: Column(
        children: [
          _buildStepIndicator(),
          Expanded(
            child: SingleChildScrollView(
              child: _buildCurrentStep(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepIndicator() {
    final colors = Theme.of(context).colorScheme;
    final currentIndex = _currentStepIndex;

    // Hide payment step in indicator if no extra payment needed
    final visibleSteps = _steps.where((s) {
      if (s.step == CheckInStep.payment && _extraPaymentAmount == 0 &&
          _currentStep != CheckInStep.payment) {
        return false;
      }
      return true;
    }).toList();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: colors.surfaceContainerHigh,
        border: Border(
          bottom: BorderSide(color: colors.outline.withValues(alpha: 0.2)),
        ),
      ),
      child: Row(
        children: visibleSteps.asMap().entries.map((entry) {
          final index      = entry.key;
          final stepItem   = entry.value;
          final stepIndex  = _steps.indexOf(stepItem);
          final isActive   = stepItem.step == _currentStep;
          final isComplete = stepIndex < currentIndex;
          final isLast     = index == visibleSteps.length - 1;

          return Expanded(
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      // Circle indicator
                      Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isComplete
                              ? colors.primary
                              : isActive
                                  ? colors.primaryContainer
                                  : colors.surfaceContainerHighest,
                          border: Border.all(
                            color: isActive ? colors.primary : Colors.transparent,
                            width: 2,
                          ),
                        ),
                        child: Center(
                          child: isComplete
                              ? Icon(Icons.check, size: 14, color: colors.onPrimary)
                              : Text(
                                  '${index + 1}',
                                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                        color: isActive
                                            ? colors.primary
                                            : colors.onSurfaceVariant,
                                        fontWeight: FontWeight.bold,
                                      ),
                                ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      // Label
                      Text(
                        stepItem.label,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: isActive
                                  ? colors.primary
                                  : isComplete
                                      ? colors.onSurface
                                      : colors.onSurfaceVariant,
                              fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                            ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                // Connector line
                if (!isLast)
                  Expanded(
                    child: Container(
                      height: 2,
                      margin: const EdgeInsets.only(bottom: 20),
                      color: stepIndex < currentIndex
                          ? colors.primary
                          : colors.outline.withValues(alpha: 0.3),
                    ),
                  ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildCurrentStep() {
    switch (_currentStep) {
      case CheckInStep.search:
        return CheckInSearchStep(onSearch: _handleSearchResult);

      case CheckInStep.confirmPassenger:
        // TODO: build CheckInConfirmPassengerStep
        return _buildPlaceholder('Confirm Passenger', 'Step 2 coming soon');

      case CheckInStep.selectSeat:
        // TODO: build CheckInSeatSelectionStep
        return _buildPlaceholder('Select Seat', 'Step 3 coming soon');

      case CheckInStep.baggage:
        // TODO: build CheckInBaggageStep
        return _buildPlaceholder('Baggage', 'Step 4 coming soon');

      case CheckInStep.payment:
        // TODO: build CheckInPaymentStep
        return _buildPlaceholder('Payment', 'Step 5 coming soon');

      case CheckInStep.boardingPass:
        // TODO: build CheckInBoardingPassStep
        return _buildPlaceholder('Boarding Pass', 'Step 6 coming soon');
    }
  }

  Widget _buildPlaceholder(String title, String subtitle) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      margin:  const EdgeInsets.all(16),
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color:        colors.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Icon(Icons.construction_outlined,
              size: 48, color: colors.onSurfaceVariant),
          const SizedBox(height: 16),
          Text(title,
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(subtitle,
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: colors.onSurfaceVariant)),
          const SizedBox(height: 24),
          TextButton.icon(
            onPressed: _resetWizard,
            icon: const Icon(Icons.arrow_back_outlined, size: 16),
            label: const Text('Back to Search'),
          ),
        ],
      ),
    );
  }
}