import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../services/checkin_api_service.dart';
import '../../widgets/responsive_layout.dart';
import '../../widgets/checkin/checkin_search_step.dart';
import '../../widgets/checkin/checkin_progress_header.dart';
import '../../widgets/checkin/checkin_confirm_passenger_step.dart';
import '../../widgets/checkin/checkin_seat_map_step.dart';
import '../../widgets/checkin/checkin_flight_select_modal.dart';
import '../../widgets/checkin/checkin_baggage_step.dart';
import '../../widgets/checkin/checkin_boarding_pass_step.dart';
import '../pages/payment/checkin_payment_step.dart';

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
  final Map<String, dynamic>? preselectedFlight;

  const CheckInPage({
    super.key, 
    required this.authService,
    this.preselectedFlight,});

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
  String?   _ticketNumber;
  int?      _boardingPassId;

  Map<String, dynamic>?      _bookingData;
  List<Map<String, dynamic>> _baggageUnits = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.preselectedFlight != null) {
        _handleFlightSelected(widget.preselectedFlight!);
      } else {
        _showFlightModal();
      }
    });
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
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }
    setState(() {
      _selectedFlight    = flight;
      _flightNumber      = flight['flightNumber'] as String?;
      _flightOperationId = flight['flightOperationId'] as int?;
      _departDate        = DateTime.tryParse(flight['departsDatetime'] as String? ?? '');
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

  bool get _showBackButton =>
      _currentStep != CheckInStep.search &&
      _currentStep != CheckInStep.boardingPass;

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
      _flightClass          = booking['className']         as String?;
      _flightOperationId    = booking['flightOperationId'] as int?;
      _passengerClassId     = booking['classId']           as int?;
      _bookingItemId        = booking['bookingItemId']     as int?;
      _currentStep          = CheckInStep.confirmPassenger;
    });
  }

  void _resetForNextPassenger() {
    setState(() {
      _currentStep          = CheckInStep.search;
      _documentNumber       = null;
      _passengerName        = null;
      _flightClass          = null;
      _selectedSeat         = null;
      _baggageCount         = null;
      _extraPaymentAmount   = 0;
      _passengerClassId     = null;
      _selectedSeatLayoutId = null;
      _passengerDateOfBirth = null;
      _bookingItemId        = null;
      _bookingData          = null;
      _baggageUnits         = [];
      _ticketNumber         = null;
      _boardingPassId       = null;
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
              bookingData:       _bookingData!,
              authService:       widget.authService,
              flightOperationId: _flightOperationId!,
              onConfirm:         () => setState(() => _currentStep = CheckInStep.selectSeat),
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
          authService:      widget.authService,
          bookingItemId:    _bookingItemId!,
          passengerClassId: _passengerClassId!,
          flightOperationId: _flightOperationId!,
          onCompleted: (units, surcharge) async {
            setState(() {
              _baggageUnits       = units.map((u) => u.toJson()).toList();
              _baggageCount       = units.length;
              _extraPaymentAmount = surcharge;
            });

            if (surcharge > 0) {
              setState(() => _currentStep = CheckInStep.payment);
            } else {
              try {
                final api    = CheckInApiService(widget.authService);
                final result = await api.issueWithBaggage(
                  bookingItemId:     _bookingItemId!,
                  seatLayoutId:      _selectedSeatLayoutId!,
                  flightOperationId: _flightOperationId!,
                  bags:              _baggageUnits,
                  paymentMethodId:   null,
                  totalSurcharge:    0,
                  status:            'Paid',
                );
                setState(() {
                  _ticketNumber   = result['ticketNumber'] as String?;
                  _boardingPassId = result['boardingPassId'] as int?;
                  _currentStep    = CheckInStep.boardingPass;
                });
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))),
                  );
                }
              }
            }
          },
        );

      case CheckInStep.payment:
        return CheckInPaymentStep(
          authService:       widget.authService,
          bookingItemId:     _bookingItemId!,
          seatLayoutId:      _selectedSeatLayoutId!,
          flightOperationId: _flightOperationId!,
          bags:              _baggageUnits,
          totalSurcharge:    _extraPaymentAmount,
          passengerName:     _passengerName ?? '',
          flightNumber:      _flightNumber  ?? '',
          flightClass:       _flightClass   ?? '',
          seat:              _selectedSeat  ?? '',
          bagCount:          _baggageCount  ?? 0,
          onSuccess: (ticketNumber, boardingPassId) => setState(() {
            _ticketNumber   = ticketNumber;
            _boardingPassId = boardingPassId;
            _currentStep    = CheckInStep.boardingPass;
          }),
        );

      case CheckInStep.boardingPass:
        return CheckInBoardingPassStep(
          ticketNumber:  _ticketNumber  ?? '—',
          passengerName: _passengerName ?? '—',
          flightNumber:  _flightNumber  ?? '—',
          flightClass:   _flightClass   ?? '—',
          seat:          _selectedSeat  ?? '—',
          departDate:    _departDate!,
          bagCount:      _baggageCount  ?? 0,
          onNewPassenger: _resetForNextPassenger,
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
                  'This flight has no scheduled operation yet. Please contact a supervisor.',
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
}