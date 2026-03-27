import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../widgets/responsive_layout.dart';
import '../../widgets/checkin/checkin_search_step.dart';
import '../../widgets/checkin/checkin_progress_header.dart';
import '../../widgets/checkin/checkin_confirm_passenger_step.dart';
import '../../widgets/checkin/checkin_seat_map_step.dart';

enum CheckInStep {
  search,
  confirmPassenger,
  selectSeat,
  baggage,
  payment,
  boardingPass,
}

class CheckInPage extends StatefulWidget {
  final AuthService authService;

  const CheckInPage({super.key, required this.authService});

  @override
  State<CheckInPage> createState() => _CheckInPageState();
}

class _CheckInPageState extends State<CheckInPage> {
  CheckInStep _currentStep = CheckInStep.search;

  String?   _documentNumber;
  String?   _flightNumber;
  DateTime? _departDate;
  String?   _passengerName;
  String?   _flightClass;
  String?   _selectedSeat;
  int?      _baggageCount;
  double    _extraPaymentAmount = 0;
  int?      _flightOperationId;
  int?      _passengerClassId;
  int?      _selectedSeatLayoutId;
  String? _passengerDateOfBirth;

  Map<String, dynamic>?      _bookingData;
  List<Map<String, dynamic>> _baggageUnits = [];

  String get _currentStepKey {
    switch (_currentStep) {
      case CheckInStep.search:           return 'search';
      case CheckInStep.confirmPassenger: return 'confirmPassenger';
      case CheckInStep.selectSeat:       return 'selectSeat';
      case CheckInStep.baggage:          return 'baggage';
      case CheckInStep.payment:          return 'payment';
      case CheckInStep.boardingPass:     return 'boardingPass';
    }
  }

  bool get _showBackButton => _currentStep != CheckInStep.search;

  void _goBack() {
    setState(() {
      switch (_currentStep) {
        case CheckInStep.confirmPassenger:
          _currentStep   = CheckInStep.search;
          _bookingData   = null;
          _passengerName = null;
          _flightClass   = null;
        case CheckInStep.selectSeat:
          _currentStep = CheckInStep.confirmPassenger;
        case CheckInStep.baggage:
          _currentStep = CheckInStep.selectSeat;
        case CheckInStep.payment:
          _currentStep = CheckInStep.baggage;
        case CheckInStep.boardingPass:
        case CheckInStep.search:
          break;
      }
    });
  }

  void _resetWizard() {
    setState(() {
      _currentStep          = CheckInStep.search;
      _documentNumber       = null;
      _flightNumber         = null;
      _departDate           = null;
      _passengerName        = null;
      _passengerDateOfBirth = null;
      _flightClass          = null;
      _selectedSeat         = null;
      _baggageCount         = null;
      _extraPaymentAmount   = 0;
      _flightOperationId    = null;
      _passengerClassId     = null;
      _selectedSeatLayoutId = null;
      _bookingData          = null;
      _baggageUnits         = [];
    });
  }

  void _handleSearchResult({
    required String documentNumber,
    required String flightNumber,
    required DateTime departDate,
    required Map<String, dynamic> booking,
  }) {
    setState(() {
      _documentNumber    = documentNumber;
      _flightNumber      = flightNumber;
      _departDate        = departDate;
      _bookingData       = booking;
      _passengerName     = '${booking['passengerName']} ${booking['passengerSurname']}';
      _passengerDateOfBirth = booking['passengerDateOfBirth'] as String?;
      _flightClass       = booking['className']        as String?;
      _flightOperationId = booking['flightOperationId'] as int?;
      _passengerClassId  = booking['classId']          as int?;
      _currentStep       = CheckInStep.confirmPassenger;
    });
  }

  @override
  Widget build(BuildContext context) {
    return ResponsiveLayout(
      body: Column(
        children: [
          CheckInProgressHeader(
            currentStep:     _currentStepKey,
            onBack:          _showBackButton ? _goBack : null,
            documentNumber:  _documentNumber,
            flightNumber:    _flightNumber,
            departDate:      _departDate,
            passengerName:   _passengerName,
            flightClass:     _flightClass,
            selectedSeat:    _selectedSeat,
            baggageCount:    _baggageCount,
            hasExtraPayment: _extraPaymentAmount > 0,
          ),
          Expanded(
            child: SingleChildScrollView(
              child: _buildCurrentStep(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentStep() {
    switch (_currentStep) {

      case CheckInStep.search:
        return CheckInSearchStep(
          authService: widget.authService,
          onSearch:    _handleSearchResult,
        );

      case CheckInStep.confirmPassenger:
        return Column(
          children: [
            CheckInSearchStep(
              authService: widget.authService,
              onSearch:    _handleSearchResult,
            ),
            CheckInConfirmPassengerStep(
              bookingData: _bookingData!,
              onConfirm:   () => setState(
                () => _currentStep = CheckInStep.selectSeat,
              ),
            ),
          ],
        );

      case CheckInStep.selectSeat:
        if (_flightOperationId == null) {
          return _buildFlightOperationError();
        }
        return CheckInSeatMapStep(
          authService:          widget.authService,
          flightOperationId:    _flightOperationId!,
          passengerClassId:     _passengerClassId!,
          passengerDateOfBirth: _passengerDateOfBirth,
          onSeatSelected: (seatPosition, seatLayoutId) {
            setState(() {
              _selectedSeat         = seatPosition;
              _selectedSeatLayoutId = seatLayoutId;
              _currentStep          = CheckInStep.baggage;
            });
          },
        );

      case CheckInStep.baggage:
        return _buildPlaceholder('Baggage', Icons.luggage_outlined);

      case CheckInStep.payment:
        return _buildPlaceholder('Payment', Icons.payment_outlined);

      case CheckInStep.boardingPass:
        return _buildPlaceholder(
          'Boarding Pass',
          Icons.confirmation_number_outlined,
        );
    }
  }

  Widget _buildFlightOperationError() {
    final colors = Theme.of(context).colorScheme;
    return Container(
      margin:  const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color:        colors.errorContainer.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: colors.error.withValues(alpha: 0.3),
          width: 0.5,
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: colors.error, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Flight operation not found',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: colors.error,
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  'This flight has no scheduled operation yet. '
                  'Please contact a supervisor.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colors.onErrorContainer,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceholder(String title, IconData icon) {
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
          Icon(icon, size: 48, color: colors.onSurfaceVariant),
          const SizedBox(height: 16),
          Text(
            title,
            style: Theme.of(context)
                .textTheme
                .titleLarge
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Coming soon',
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(color: colors.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}