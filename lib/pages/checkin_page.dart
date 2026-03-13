import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../widgets/responsive_layout.dart';
import '../../widgets/checkin/checkin_search_step.dart';
import '../../widgets/checkin/checkin_progress_header.dart';

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

  Map<String, dynamic>?       _bookingData;
  List<Map<String, dynamic>>  _baggageUnits = [];

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
          _currentStep = CheckInStep.search;
        case CheckInStep.selectSeat:
          _currentStep = CheckInStep.confirmPassenger;
        case CheckInStep.baggage:
          _currentStep = CheckInStep.selectSeat;
        case CheckInStep.payment:
          _currentStep = CheckInStep.baggage;
        case CheckInStep.boardingPass:
          break;
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
      _flightClass          = null;
      _selectedSeat         = null;
      _baggageCount         = null;
      _extraPaymentAmount   = 0;
      _bookingData          = null;
      _baggageUnits         = [];
    });
  }

  void _handleSearchResult({
    required String documentNumber,
    required String flightNumber,
    required DateTime departDate,
  }) {
    setState(() {
      _documentNumber = documentNumber;
      _flightNumber   = flightNumber;
      _departDate     = departDate;
      _bookingData    = {
        'documentNumber': documentNumber,
        'flightNumber':   flightNumber,
        'departDate':     departDate,
      };
      _currentStep = CheckInStep.confirmPassenger;
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
          onSearch: _handleSearchResult,
        );
      case CheckInStep.confirmPassenger:
        return _buildPlaceholder('Confirm Passenger', Icons.person_outline);
      case CheckInStep.selectSeat:
        return _buildPlaceholder('Select Seat', Icons.airline_seat_recline_normal_outlined);
      case CheckInStep.baggage:
        return _buildPlaceholder('Baggage', Icons.luggage_outlined);
      case CheckInStep.payment:
        return _buildPlaceholder('Payment', Icons.payment_outlined);
      case CheckInStep.boardingPass:
        return _buildPlaceholder('Boarding Pass', Icons.confirmation_number_outlined);
    }
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