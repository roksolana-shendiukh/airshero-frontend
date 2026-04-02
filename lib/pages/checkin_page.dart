import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../widgets/responsive_layout.dart';
import '../../widgets/checkin/checkin_search_step.dart';
import '../../widgets/checkin/checkin_progress_header.dart';
import '../../widgets/checkin/checkin_confirm_passenger_step.dart';
import '../../widgets/checkin/checkin_seat_map_step.dart';
import '../../widgets/checkin/checkin_flight_select_modal.dart';
import '../../widgets/checkin/checkin_baggage_step.dart';

enum CheckInStep {
  selectFlight,
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
  CheckInStep _currentStep = CheckInStep.selectFlight;

  Map<String, dynamic>? _selectedFlight;
  String?               _flightNumber;
  DateTime?             _departDate;

  String?   _documentNumber;
  String?   _passengerName;
  String?   _flightClass;
  String?   _selectedSeat;
  int?      _baggageCount;
  double    _extraPaymentAmount = 0;
  int?      _flightOperationId;
  int?      _passengerClassId;
  int?      _selectedSeatLayoutId;
  String?   _passengerDateOfBirth;
  int?      _bookingItemId;

  Map<String, dynamic>?      _bookingData;
  List<Map<String, dynamic>> _baggageUnits = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _showFlightModal());
  }

  void _showFlightModal() {
    showDialog(
      context:            context,
      barrierDismissible: false,
      builder: (_) => CheckInFlightSelectModal(
        authService:      widget.authService,
        onFlightSelected: _handleFlightSelected,
      ),
    );
  }

  void _handleFlightSelected(Map<String, dynamic> flight) {
    Navigator.of(context).pop();
    setState(() {
      _selectedFlight    = flight;
      _flightNumber      = flight['flightNumber'] as String?;
      _flightOperationId = flight['flightOperationId'] as int?;
      _departDate        = DateTime.tryParse(
          flight['departsDatetime'] as String? ?? '');
      _currentStep       = CheckInStep.search;
    });
  }

  String get _currentStepKey {
    switch (_currentStep) {
      case CheckInStep.selectFlight:     return 'search';
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
          _bookingItemId = null;
        case CheckInStep.selectSeat:
          _currentStep = CheckInStep.confirmPassenger;
        case CheckInStep.baggage:
          _currentStep = CheckInStep.selectSeat;
        case CheckInStep.payment:
          _currentStep = CheckInStep.baggage;
        case CheckInStep.boardingPass:
        case CheckInStep.search:
        case CheckInStep.selectFlight:
          break;
      }
    });
  }

  void _handleSearchResult({
    required String documentNumber,
    required String flightNumber,
    required DateTime departDate,
    required Map<String, dynamic> booking,
  }) {
    setState(() {
      _documentNumber       = documentNumber;
      _bookingData          = booking;
      _passengerName        = '${booking['passengerName']} ${booking['passengerSurname']}';
      _passengerDateOfBirth = booking['passengerDateOfBirth'] as String?;
      _flightClass          = booking['className']            as String?;
      _flightOperationId    = booking['flightOperationId']    as int?;
      _passengerClassId     = booking['classId']              as int?;
      _bookingItemId        = booking['bookingItemId']        as int?;
      _currentStep          = CheckInStep.confirmPassenger;
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

          if (_selectedFlight != null &&
              _currentStep != CheckInStep.selectFlight)
            _buildFlightBanner(),

          Expanded(
            child: SingleChildScrollView(
              child: _buildCurrentStep(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFlightBanner() {
    final colors = Theme.of(context).colorScheme;
    final flight = _selectedFlight!;
    final gate   = flight['gateCode'] as String? ?? '—';
    final status = flight['status']   as String? ?? '—';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color:   colors.primaryContainer.withValues(alpha: 0.3),
      child: Row(
        children: [
          Icon(Icons.flight_takeoff, size: 14, color: colors.primary),
          const SizedBox(width: 8),
          Text(
            _flightNumber ?? '—',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color:      colors.primary,
                ),
          ),
          const SizedBox(width: 8),
          Text(
            '· Gate $gate · $status',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
          ),
          const Spacer(),
          TextButton(
            onPressed: _showFlightModal,
            style: TextButton.styleFrom(
              padding:       const EdgeInsets.symmetric(horizontal: 8),
              visualDensity: VisualDensity.compact,
            ),
            child: Text(
              'Change flight',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colors.primary,
                  ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentStep() {
    switch (_currentStep) {

      case CheckInStep.selectFlight:
        return const SizedBox.shrink();

      case CheckInStep.search:
        return CheckInSearchStep(
          authService:  widget.authService,
          flightNumber: _flightNumber!,
          departDate:   _departDate!,
          onSearch:     _handleSearchResult,
        );

      case CheckInStep.confirmPassenger:
        return Column(
          children: [
            CheckInSearchStep(
              authService:  widget.authService,
              flightNumber: _flightNumber!,
              departDate:   _departDate!,
              onSearch:     _handleSearchResult,
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
        if (_flightOperationId == null) return _buildFlightOperationError();
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
        return CheckInBaggageStep(
          authService:    widget.authService,
          bookingItemId:  _bookingItemId!,
          passengerClassId: _passengerClassId!,
          onCompleted: (units, surcharge) {
            setState(() {
              _baggageUnits         = units.map((u) => u.toJson()).toList();
              _baggageCount         = units.length;
              _extraPaymentAmount   = surcharge;
              _currentStep          = surcharge > 0
                  ? CheckInStep.payment
                  : CheckInStep.boardingPass;
            });
          },
        );

      case CheckInStep.payment:
        return _buildPlaceholder('Payment', Icons.payment_outlined);

      case CheckInStep.boardingPass:
        return _buildPlaceholder(
            'Boarding Pass', Icons.confirmation_number_outlined);
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
        border:       Border.all(color: colors.error.withValues(alpha: 0.3)),
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
                        color: colors.error, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                Text(
                  'This flight has no scheduled operation yet. '
                  'Please contact a supervisor.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colors.onErrorContainer),
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