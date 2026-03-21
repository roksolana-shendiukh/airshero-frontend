import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'dart:convert';

import '../../widgets/responsive_layout.dart';
import '../../widgets/booking_progress_header.dart';
import '../../services/auth_service.dart';
import '../../services/booking_api_service.dart';
import '../../widgets/custom/custom_input_field.dart';
import '../../widgets/custom/custom_select_field.dart';
import '../../widgets/custom/custom_button.dart';

import 'payment_method_selector.dart';
import 'partial_payment_manager.dart';

class PaymentPage extends StatefulWidget {
  final String fromCity;
  final String toCity;
  final DateTime departDate;
  final DateTime? returnDate;
  final Map<String, int> passengers;
  final Map<String, String> passengerClassLabels;
  final String airlineName;
  final String airlineLogoUrl;
  final String fromAirportCode;
  final String toAirportCode;
  final String departureTime;
  final String arrivalTime;
  final String duration;
  final double basePrice;
  final bool isRoundTrip;
  final Map<int, Map<int, int>> baggageSelections;
  final Map<int, Map<String, dynamic>> passengerData;
  final double totalPrice;
  final String sessionId;
  final List<Map<String, dynamic>> outboundAssignments;
  final List<Map<String, dynamic>> returnAssignments;
  final List<int> removedPassengerIndices;

  const PaymentPage({
    super.key,
    required this.fromCity,
    required this.toCity,
    required this.departDate,
    this.returnDate,
    required this.passengers,
    required this.passengerClassLabels,
    required this.airlineName,
    required this.airlineLogoUrl,
    required this.fromAirportCode,
    required this.toAirportCode,
    required this.departureTime,
    required this.arrivalTime,
    required this.duration,
    required this.basePrice,
    required this.isRoundTrip,
    required this.baggageSelections,
    required this.passengerData,
    required this.totalPrice,
    required this.sessionId,
    required this.outboundAssignments,
    this.returnAssignments = const [],
    this.removedPassengerIndices = const [],
  });

  @override
  State<PaymentPage> createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage> {
  bool _isCreatingBooking = true;
  String? _bookingError;
  int? _bookingId;
  String? _bookingNumber;
  DateTime? _expiresAt;

  Timer? _timer;
  Duration _timeLeft = const Duration(minutes: 10);
  bool _isExpired = false;

  List<Map<String, dynamic>> _paymentMethods = [];
  int? _singlePaymentMethodId;
  bool _isLoadingMethods = true;
  bool _isProcessingPayment = false;

  bool _isPartialPayment = false;
  List<Map<String, dynamic>> _partialPayments = [
    {'amount': 0.0, 'methodId': null}
  ];
  

  List<Map<String, dynamic>> _adultPassengers = [];

  String _emailValue = '';
  String? _emailError;
  int? _selectedAdultIndex;
  String? _selectedAdultName;

  int get _totalPassengers => widget.passengers.values.fold(0, (a, b) => a + b);

  @override
  void initState() {
    super.initState();
    _initPage();
  }

  bool _isAdult(dynamic dobValue) {
    if (dobValue == null) return false;
    
    DateTime? dob;
    
    if (dobValue is DateTime) {
      dob = dobValue;
    } else if (dobValue is String) {
      dob = DateTime.tryParse(dobValue);
    }
    
    if (dob == null) return false;

    final today = DateTime.now();
    int age = today.year - dob.year;
    if (today.month < dob.month || (today.month == dob.month && today.day < dob.day)) {
      age--;
    }
    return age >= 18;
  }

  Future<void> _initPage() async {
    final authService = context.read<AuthService>();
    final api = BookingApiService(authService);
    await Future.wait([_loadPaymentMethods(api), _createBooking(api)]);
  }

  Future<void> _loadPaymentMethods(BookingApiService api) async {
    try {
      final methods = await api.getPaymentMethods();
      print('PAYMENT METHODS: $methods');
      if (mounted) setState(() { _paymentMethods = methods; _isLoadingMethods = false; });
    } catch (e) {
      print('PAYMENT METHODS ERROR: $e'); 
      if (mounted) setState(() => _isLoadingMethods = false);
    }
  }

  Future<void> _createBooking(BookingApiService api) async {
    try {
      final body = _buildBookingBody();
      final result = await api.createBooking(body);
      if (!mounted) return;

      setState(() {
        _bookingId     = result['bookingId'];
        _bookingNumber = result['bookingNumber'];
        _expiresAt     = DateTime.parse(result['expiresAt']);
        _isCreatingBooking = false;
      });

      final adults = await api.getAdultPassengers(_bookingId!);
      if (mounted) {
        setState(() {
          _adultPassengers = adults;
          if (adults.isNotEmpty) {
            _selectedAdultIndex = adults.first['passengerId'] as int?;
            _selectedAdultName  = "${adults.first['firstName'] ?? ''} ${adults.first['lastName'] ?? ''}".trim();
            _emailValue         = adults.first['email'] ?? '';
          }
        });
      }

      _startTimer();
    } catch (e) {
      if (mounted) setState(() { _bookingError = e.toString(); _isCreatingBooking = false; });
    }
  }

  void _handleAmountChanged(int index, double amount) {
    setState(() {
      _partialPayments[index]['amount'] = amount;
      _partialPayments.removeRange(index + 1, _partialPayments.length);
      
      double totalPaid = _partialPayments.fold(0, (sum, item) => sum + (item['amount'] as double));
      
      if (totalPaid < widget.totalPrice && amount > 0 && (widget.totalPrice - totalPaid) > 0.01) {
        _partialPayments.add({'amount': 0.0, 'methodId': null});
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    if (_isCreatingBooking) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    if (_bookingError != null) return _buildErrorState(colors);

    return ResponsiveLayout(
      header: BookingProgressHeader(
        fromCity: widget.fromCity,
        toCity: widget.toCity,
        departDate: widget.departDate,
        returnDate: widget.returnDate,
        totalPassengers: _totalPassengers,
        flightClass: widget.passengerClassLabels.values.first,
        currentStep: 'payment',
        airlineName: widget.airlineName,
        onBack: () => context.pop(),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        child: Column(
          children: [
            _buildTimer(colors),
            const SizedBox(height: 24),
            _buildBookingSummary(colors),
            const SizedBox(height: 24),
            _buildEmailSection(colors),
            const SizedBox(height: 24),
            _buildPaymentSection(colors),
            const SizedBox(height: 48),
            _buildActionButtons(colors),
            const SizedBox(height: 48),
          ],
        ),
      ),
    );
  }

  void _startTimer() {
    if (_expiresAt == null) return;
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      final diff = _expiresAt!.toUtc().difference(DateTime.now().toUtc());
      
      if (diff.isNegative) {
        _timer?.cancel();
        setState(() {
          _timeLeft = Duration.zero;
          _isExpired = true;
        });
        
        _showTimeoutDialog();
      } else {
        setState(() => _timeLeft = diff);
      }
    });
  }

  void _showTimeoutDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Session Expired'),
        content: const Text('The time for payment has run out. You will be redirected to the bookings page.'),
        actions: [
          TextButton(
            onPressed: () => context.go('/sales/bookings'),
            child: const Text('OK'),
          ),
        ],
      ),
    );
    
    Future.delayed(const Duration(seconds: 5), () {
      if (mounted && GoRouterState.of(context).uri.toString().contains('payment')) {
        context.go('/sales/bookings');
      }
    });
  }

  Widget _buildTimer(ColorScheme colors) {
    final isUrgent = _timeLeft.inSeconds > 0 && _timeLeft.inSeconds < 120;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _isExpired ? colors.errorContainer : isUrgent ? colors.errorContainer.withOpacity(0.5) : colors.primaryContainer.withOpacity(0.4),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _isExpired ? colors.error : isUrgent ? colors.error.withOpacity(0.5) : colors.primary.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(_isExpired ? Icons.timer_off_outlined : Icons.timer_outlined, color: _isExpired || isUrgent ? colors.error : colors.primary, size: 28),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_isExpired ? 'Booking Expired' : 'Time to complete payment', style: TextStyle(fontWeight: FontWeight.w600, color: _isExpired || isUrgent ? colors.error : colors.onSurface)),
                Text(_isExpired ? 'This booking has been cancelled' : 'Booking will be cancelled if not paid', style: TextStyle(fontSize: 12, color: colors.onSurfaceVariant)),
              ],
            ),
          ),
          if (!_isExpired)
            Text(
              '${_timeLeft.inMinutes}:${(_timeLeft.inSeconds % 60).toString().padLeft(2, '0')}',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, fontFeatures: const [FontFeature.tabularFigures()], color: isUrgent ? colors.error : colors.primary),
            ),
        ],
      ),
    );
  }

  Widget _buildBookingSummary(ColorScheme colors) {
  return Card(
    elevation: 0,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
      side: BorderSide(color: colors.outlineVariant),
    ),
    child: Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Booking Summary', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              if (_bookingNumber != null)
                Chip(label: Text(_bookingNumber!, style: const TextStyle(fontSize: 12)), backgroundColor: colors.primaryContainer),
            ],
          ),
          const Divider(height: 32),
          
          _buildFlightRoute(
            title: 'Outbound Flight',
            from: widget.fromAirportCode,
            to: widget.toAirportCode,
            departure: widget.departureTime,
            arrival: widget.arrivalTime,
            date: widget.departDate,
            colors: colors,
            isReturn: false,
          ),
          
          if (widget.isRoundTrip && widget.returnDate != null) ...[
            const SizedBox(height: 16),
            _buildFlightRoute(
              title: 'Return Flight',
              from: widget.toAirportCode,
              to: widget.fromAirportCode,
              departure: widget.departureTime,
              arrival: widget.arrivalTime,     
              date: widget.returnDate!,
              colors: colors,
              isReturn: true,
            ),
          ],

          const Divider(height: 32),
          const Text('Price Details', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          
          ...widget.passengers.entries.where((e) => e.value > 0).map((e) {
            final label = widget.passengerClassLabels[e.key] ?? e.key;
            return _buildPriceRow(
              '$label x${e.value}', 
              '\$${(widget.basePrice * e.value).toStringAsFixed(2)}', 
              colors
            );
          }),

          ..._buildBaggageRows(colors),

          const Divider(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Total Amount', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              Text(
                '\$${widget.totalPrice.toStringAsFixed(2)}',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: colors.primary),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}

  Widget _buildFlightRoute({
    required String title,
    required String from,
    required String to,
    required String departure,
    required String arrival,
    required DateTime date,
    required ColorScheme colors,
    bool isReturn = false, 
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title, 
          style: TextStyle(
            fontSize: 12, 
            fontWeight: FontWeight.bold, 
            color: colors.primary 
          )
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(departure, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  Text(from, style: TextStyle(color: colors.onSurfaceVariant)),
                ],
              ),
            ),
            
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  Transform.rotate(
                    angle: isReturn ? 4.71239 : 1.5708, 
                    child: Icon(
                      Icons.flight, 
                      color: colors.primary.withValues(alpha: 0.5),
                      size: 22,
                    ),
                  ),
                  Container(
                    width: 40,
                    height: 1,
                    color: colors.outlineVariant,
                  ),
                ],
              ),
            ),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(arrival, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  Text(to, style: TextStyle(color: colors.onSurfaceVariant)),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          DateFormat('EEE, d MMM yyyy').format(date), 
          style: TextStyle(fontSize: 12, color: colors.onSurfaceVariant)
        ),
      ],
    );
  }

  List<Widget> _buildBaggageRows(ColorScheme colors) {
    List<Widget> rows = [];
    widget.baggageSelections.forEach((passengerIdx, selections) {
      selections.forEach((baggageId, count) {
        if (count > 0) {
          rows.add(_buildPriceRow(
            'Extra Baggage (Pass. ${passengerIdx + 1})', 
            'x$count', 
            colors,
            isSecondary: true
          ));
        }
      });
    });
    return rows;
  }

  Widget _buildPriceRow(String label, String value, ColorScheme colors, {bool isSecondary = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: isSecondary ? colors.onSurfaceVariant : colors.onSurface, fontSize: isSecondary ? 13 : 14)),
          Text(value, style: TextStyle(fontWeight: isSecondary ? FontWeight.normal : FontWeight.w500)),
        ],
      ),
    );
  }
  
  Widget _buildEmailSection(ColorScheme colors) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: colors.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Ticket Delivery', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            CustomSelectField(
              label: 'Select Adult Passenger',
              value: _selectedAdultName ?? '',
              icon: Icons.person_outline,
              items: _adultPassengers.map((e) =>
                "${e['firstName'] ?? ''} ${e['lastName'] ?? ''}".trim()
              ).toList(),
              onChanged: (val) {
                if (val == null) return;
                final selected = _adultPassengers.firstWhere(
                  (e) => "${e['firstName'] ?? ''} ${e['lastName'] ?? ''}".trim() == val,
                  orElse: () => {},
                );
                if (selected.isEmpty) return;
                setState(() {
                  _selectedAdultName  = val;
                  _selectedAdultIndex = selected['passengerId'] as int?;
                  _emailValue         = selected['email'] ?? '';
                });
              },
            ),
            const SizedBox(height: 16),
            CustomInputField(
              label: 'Email address',
              value: _emailValue,
              icon: Icons.email_outlined,
              errorText: _emailError,
              keyboardType: TextInputType.emailAddress,
              onChanged: (val) => setState(() => _emailValue = val),
            ),
            const SizedBox(height: 8),
            Text('Tickets will be sent to this email',
                style: TextStyle(color: colors.onSurfaceVariant, fontSize: 12)),
          ],
        ),
      ),
    );
  }
  
  Widget _buildPaymentSection(ColorScheme colors) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: colors.outlineVariant)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Switch(value: _isPartialPayment, onChanged: _isExpired ? null : (v) => setState(() => _isPartialPayment = v)),
                const SizedBox(width: 8),
                const Text('Partial Payment'),
              ],
            ),
            const SizedBox(height: 16),
            if (_isPartialPayment)
              PartialPaymentManager(
                totalPrice: widget.totalPrice,
                payments: _partialPayments,
                paymentMethods: _paymentMethods,
                onAmountChanged: _handleAmountChanged,
                onMethodSelected: (idx, id) => setState(() => _partialPayments[idx]['methodId'] = id),
              )
            else
              PaymentMethodSelector(
                methods: _paymentMethods,
                selectedId: _singlePaymentMethodId,
                onSelected: (id) => setState(() => _singlePaymentMethodId = id),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _processPayment(String status) async {
    setState(() => _isProcessingPayment = true);
    
    try {
      final authService = context.read<AuthService>();
      final api = BookingApiService(authService);

      if (_isPartialPayment) {
        for (var payment in _partialPayments) {
          if (payment['methodId'] == null || payment['amount'] <= 0) continue;
          
          await api.confirmPayment(
            bookingId: _bookingId!,
            data: {
              'paymentMethodId': payment['methodId'],
              'status': 'paid',
              'amount': payment['amount'],
              'email': _emailValue,
              'passengerId': _selectedAdultIndex, 
            },
          );
        }
      } else {
        await api.confirmPayment(
          bookingId: _bookingId!,
          data: {
            'paymentMethodId': _singlePaymentMethodId,
            'status': 'paid',
            'amount': widget.totalPrice,
            'email': _emailValue,
            'passengerId': _selectedAdultIndex, 
          },
        );
      }

      if (!mounted) return;
      setState(() => _isProcessingPayment = false);
      
      _showSuccessDialog();
      
    } catch (e) {
      if (!mounted) return;
      setState(() => _isProcessingPayment = false);
      _showErrorDialog(e.toString().replaceAll('Exception: ', ''));
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        final colors = Theme.of(context).colorScheme;
        
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_circle,
                    color: Colors.green,
                    size: 80,
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Payment Successful!',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  'Your booking #${_bookingNumber ?? 'N/A'} has been confirmed. '
                  'Tickets will be sent to $_emailValue shortly.',
                  style: TextStyle(color: colors.onSurfaceVariant),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  child: CustomButton(
                    label: 'Go to My Bookings',
                    icon: Icons. airplane_ticket_outlined,
                    onPressed: () {
                      Navigator.of(context).pop(); 
                      context.go('/sales/bookings');
                    },
                    borderRadius: 12,
                    verticalPadding: 16,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
  
  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        final colors = Theme.of(context).colorScheme;
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Icon(Icons.error_outline, color: colors.error, size: 28),
              const SizedBox(width: 12),
              const Text('Payment Failed'),
            ],
          ),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildActionButtons(ColorScheme colors) {
    if (_isExpired) {
      return SizedBox(
        width: double.infinity,
        child: CustomButton(
          label: 'Session Expired - Back to Bookings',
          icon: Icons.history,
          isIconAfterLabel: false,
          onPressed: () => context.go('/sales/bookings'),
          borderRadius: 12,
        ),
      );
    }

    String? disabledReason;
    if (_isPartialPayment) {
      final hasZeroAmount = _partialPayments.any((p) => (p['amount'] as double) <= 0);
      final hasNoMethod = _partialPayments.any((p) => p['methodId'] == null);
      final totalPaid = _partialPayments.fold<double>(0, (s, p) => s + (p['amount'] as double));
      final notCovered = (totalPaid - widget.totalPrice).abs() > 0.01 && totalPaid < widget.totalPrice;

      if (hasZeroAmount) disabledReason = 'Enter amount for each payment part';
      else if (hasNoMethod) disabledReason = 'Select payment method for each part';
      else if (notCovered) disabledReason = 'Total amount does not cover \$${widget.totalPrice.toStringAsFixed(2)}';
    } else {
      if (_singlePaymentMethodId == null) disabledReason = 'Select a payment method';
    }

    final canConfirm = !_isProcessingPayment && disabledReason == null;

    return Column(
      children: [
        if (_isProcessingPayment)
          const Padding(
            padding: EdgeInsets.only(bottom: 16),
            child: CircularProgressIndicator(),
          ),
        Tooltip(
          message: disabledReason ?? '',
          child: SizedBox(
            width: double.infinity,
            child: CustomButton(
              label: _isPartialPayment ? 'Confirm Partial Payment' : 'Confirm Payment',
              icon: Icons.check_circle_outline,
              isIconAfterLabel: true,
              onPressed: canConfirm ? () => _processPayment('paid') : null,
              borderRadius: 12,
              verticalPadding: 16,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildErrorState(ColorScheme colors) {
    return Scaffold(body: Center(child: Text(_bookingError ?? 'Unknown Error')));
  }

  Map<String, dynamic> _buildBookingBody() {
    final List<Map<String, dynamic>> passengers = [];

    for (int i = 0; i < _totalPassengers; i++) {
      if (widget.removedPassengerIndices.contains(i)) continue;
      final data = widget.passengerData[i] ?? {};

      final outboundAssignment = i < widget.outboundAssignments.length
          ? widget.outboundAssignments[i] : null;
      final returnAssignment = i < widget.returnAssignments.length
          ? widget.returnAssignments[i] : null;

      final flightPriceId       = outboundAssignment?['flightPriceId'] as int? ?? 0;
      final returnFlightPriceId = returnAssignment?['flightPriceId'] as int?;

      final baggageMap   = widget.baggageSelections[i] ?? {};
      final baggageItems = baggageMap.entries
          .map((e) => {
                'baggage_pricing_in_flight_id': e.key,
                'quantity': e.value,
              })
          .toList();

      String? formatDate(dynamic date) {
        if (date is DateTime) return date.toIso8601String().split('T')[0];
        return date?.toString();
      }

      passengers.add({
        'passenger_id':            data['foundPassengerId'],
        'document_id':             data['documentId'],
        'first_name':              data['firstName'],
        'last_name':               data['lastName'],
        'sex':                     data['sex'] == 'Male',
        'date_of_birth':           formatDate(data['dateOfBirth']),
        'citizenship_id':          data['citizenshipId'],
        'document_type_id':        data['documentTypeId'],
        'document_number':         data['documentNumber'],
        'document_date_of_issue':  formatDate(data['documentIssue']),
        'document_date_of_expire': formatDate(data['documentExpire']),
        'flight_price_id':         flightPriceId,
        'return_flight_price_id':  returnFlightPriceId,
        'baggage_items':           baggageItems,
      });
    }

   final body = {
      'passengers':   passengers,
      'total_amount': widget.totalPrice,
    };
    
    print('=== BOOKING BODY ===');
    print(jsonEncode(body));
    
    return body;
  }
 
  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}