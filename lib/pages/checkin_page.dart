import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../services/checkin_api_service.dart';
import '../../widgets/responsive_layout.dart';
import '../../widgets/checkin/checkin_search_step.dart';
import '../../widgets/checkin/checkin_progress_header.dart';
import '../../widgets/checkin/checkin_confirm_passenger_step.dart';
import '../../widgets/checkin/checkin_seat_map_step.dart';
import '../../widgets/checkin/checkin_baggage_step.dart';
import '../../widgets/checkin/checkin_boarding_pass_step.dart';
import '../../widgets/checkin/checkin_baggage_tag_step.dart';
import '../../widgets/checkin/flight_operation_error.dart';
import '../pages/payment/checkin_payment_step.dart';
import 'package:go_router/go_router.dart';

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
  // ignore: unused_field
  int? _boardingPassId;

  Map<String, dynamic>?      _bookingData;
  List<Map<String, dynamic>> _baggageUnits = [];
  List<Map<String, dynamic>> _issuedBags = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.preselectedFlight != null) {
        _handleFlightSelected(widget.preselectedFlight!);
      }
    });
  }


  void _handleFlightSelected(Map<String, dynamic> flight) {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }
    setState(() {
      _selectedFlight    = flight;
      _flightNumber      = flight['flight_number'] as String?;
      _flightOperationId = flight['flight_operation_id'] as int?;
      _departDate        = DateTime.tryParse(flight['departs_datetime'] as String? ?? '');
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

  bool get _showBackButton => _currentStep != CheckInStep.boardingPass;

  void _goBack() {
  if (_currentStep == CheckInStep.search) {
    context.go('/checkin');
    return;
  }
  
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
      default:
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
      _passengerName        = '${booking['passenger_name']} ${booking['passenger_surname']}';
      _passengerDateOfBirth = booking['passenger_date_of_birth'] as String?;
      _flightClass          = booking['class_name']          as String?;
      _flightOperationId    = booking['flight_operation_id'] as int?;
      _passengerClassId     = booking['class_id']            as int?;
      _bookingItemId        = booking['booking_item_id']     as int?;
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
      _issuedBags = [];
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
          authService:      widget.authService,
          flightNumber:     _flightNumber!,
          departDate:       _departDate!,
          onSearch:         _handleSearchResult,
          onBackToFlights:  () => context.go('/checkin'),
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
        if (_flightOperationId == null) return const FlightOperationError();
        debugPrint('>>> passengerClassId: $_passengerClassId');
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
              debugPrint('>>> baggageUnits sending: $_baggageUnits');
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
                  _ticketNumber   = result['ticket_number'] as String?;
                  _boardingPassId = result['boarding_pass_id'] as int?;
                  _issuedBags     = List<Map<String, dynamic>>.from(result['bags'] ?? []);
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
          onSuccess: (ticketNumber, boardingPassId, bags) => setState(() {
            _ticketNumber   = ticketNumber;
            _boardingPassId = boardingPassId;
            _issuedBags     = List<Map<String, dynamic>>.from(bags);
            _currentStep    = CheckInStep.boardingPass;
          }),
        );

      case CheckInStep.boardingPass:
      debugPrint('>>> issuedBags: $_issuedBags');
        return Column(
          children: [
            CheckInBoardingPassStep(
              ticketNumber:   _ticketNumber  ?? '—',
              passengerName:  _passengerName ?? '—',
              flightNumber:   _flightNumber  ?? '—',
              flightClass:    _flightClass   ?? '—',
              seat:           _selectedSeat  ?? '—',
              departDate:     _departDate!,
              departsAirport: _selectedFlight?['departs_airport'] as String? ?? '—',
              arrivesAirport: _selectedFlight?['arrives_airport'] as String? ?? '—',
              departsTime:    _selectedFlight?['departs_datetime'] as String? ?? '—',
              arrivesTime:    _selectedFlight?['arrives_datetime'] as String? ?? '—',
              gate:           _selectedFlight?['gate_code']        as String? ?? '—',
              showActions:    false, 
              onNewPassenger: _resetForNextPassenger,
            ),
            CheckInBaggageTagStep(
              bags:          _issuedBags,
              passengerName: _passengerName ?? '—',
              flightNumber:  _flightNumber  ?? '—',
              departDate:    _departDate!,
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _resetForNextPassenger,
                  icon:  const Icon(Icons.person_add_outlined, size: 18),
                  label: const Text('Check In Next Passenger'),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape:   RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
            ),
          ],
        );
          
    }
  }
  
}