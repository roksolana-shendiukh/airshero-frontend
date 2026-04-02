import 'dart:async';
import 'package:flutter/material.dart';
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
import '../../models/booking_group_draft.dart';
import '../../widgets/booking/booking_summary_card.dart';

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
  final bool isMultiSegment;
  final BookingGroupDraft? bookingGroupDraft;

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
    this.isMultiSegment = false,
    this.bookingGroupDraft,
  });

  @override
  State<PaymentPage> createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage> {
  bool _isCreatingBooking = true;
  String? _bookingError;

  int? _bookingId;
  String? _bookingNumber;

  int? _bookingId1;
  int? _bookingId2;
  String? _bookingNumber1;
  String? _bookingNumber2;

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

  Future<void> _initPage() async {
    final authService = context.read<AuthService>();
    final api = BookingApiService(authService);
    await Future.wait([_loadPaymentMethods(api), _createBooking(api)]);
  }

  Future<void> _loadPaymentMethods(BookingApiService api) async {
    try {
      final methods = await api.getPaymentMethods();
      if (mounted) {
        setState(() {
          _paymentMethods = methods;
          _isLoadingMethods = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingMethods = false);
    }
  }

  Future<void> _createBooking(BookingApiService api) async {
    try {
      Map<String, dynamic> result;

      if (widget.isMultiSegment && widget.bookingGroupDraft != null) {
        final body = _buildGroupBookingBody();
        result = await api.createGroupBooking(body);

        if (!mounted) return;
        setState(() {
          _bookingId1 = result['booking1']['bookingId'] as int;
          _bookingId2 = result['booking2']['bookingId'] as int;
          _bookingNumber1 = result['booking1']['bookingNumber'] as String;
          _bookingNumber2 = result['booking2']['bookingNumber'] as String;
          _expiresAt = DateTime.parse(result['expiresAt']).toLocal();
          _isCreatingBooking = false;
        });

        final adults = await api.getAdultPassengers(_bookingId1!);
        if (mounted) _applyAdultPassengers(adults);
      } else {
        final body = _buildBookingBody();
        result = await api.createBooking(body);

        if (!mounted) return;
        setState(() {
          _bookingId = result['bookingId'] as int;
          _bookingNumber = result['bookingNumber'] as String;
          _expiresAt = DateTime.parse(result['expiresAt']).toLocal();
          _isCreatingBooking = false;
        });

        final adults = await api.getAdultPassengers(_bookingId!);
        if (mounted) _applyAdultPassengers(adults);
      }

      _startTimer();
    } catch (e) {
      if (mounted) {
        setState(() {
          _bookingError = e.toString();
          _isCreatingBooking = false;
        });
      }
    }
  }

  void _applyAdultPassengers(List<Map<String, dynamic>> adults) {
    setState(() {
      _adultPassengers = adults;
      if (adults.isNotEmpty) {
        _selectedAdultIndex = adults.first['passengerId'] as int?;
        _selectedAdultName =
            "${adults.first['firstName'] ?? ''} ${adults.first['lastName'] ?? ''}"
                .trim();
        _emailValue = adults.first['email'] ?? '';
      }
    });
  }

  Map<String, dynamic> _buildBookingBody() {
    final passengers = _buildPassengerList(
      assignments: widget.outboundAssignments,
      returnAssignments: widget.returnAssignments,
      baggageSelections: widget.baggageSelections,
    );

    final body = {
      'passengers': passengers,
      'total_amount': widget.totalPrice,
    };

    debugPrint('=== BOOKING BODY ===');
    debugPrint(jsonEncode(body));
    return body;
  }

  Map<String, dynamic> _buildGroupBookingBody() {
    final draft = widget.bookingGroupDraft!;
    final seg1 = draft.firstSegment;
    final seg2 = draft.secondSegment!;

    final passengers1 = _buildPassengerList(
      assignments: seg1.assignments,
      returnAssignments: const [],
      baggageSelections: seg1.baggageSelections,
    );

    final passengers2 = _buildPassengerList(
      assignments: seg2.assignments,
      returnAssignments: const [],
      baggageSelections: seg2.baggageSelections,
    );

    final body = {
      'booking1': {
        'passengers': passengers1,
        'total_amount': seg1.basePrice,
      },
      'booking2': {
        'passengers': passengers2,
        'total_amount': seg2.basePrice,
      },
    };

    debugPrint('=== GROUP BOOKING BODY ===');
    debugPrint(jsonEncode(body));
    return body;
  }

  List<Map<String, dynamic>> _buildPassengerList({
    required List<Map<String, dynamic>> assignments,
    required List<Map<String, dynamic>> returnAssignments,
    required Map<int, Map<int, int>> baggageSelections,
  }) {
    final List<Map<String, dynamic>> passengers = [];

    for (int i = 0; i < _totalPassengers; i++) {
      if (widget.removedPassengerIndices.contains(i)) continue;
      final data = widget.passengerData[i] ?? {};

      final outboundAssignment =
          i < assignments.length ? assignments[i] : null;
      final returnAssignment =
          i < returnAssignments.length ? returnAssignments[i] : null;

      final flightPriceId = outboundAssignment?['flightPriceId'] as int? ?? 0;
      final returnFlightPriceId = returnAssignment?['flightPriceId'] as int?;

      final baggageMap = baggageSelections[i] ?? {};
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
        'passenger_id': data['foundPassengerId'],
        'document_id': data['documentId'],
        'first_name': data['firstName'],
        'last_name': data['lastName'],
        'sex': data['sex'] == 'Male',
        'date_of_birth': formatDate(data['dateOfBirth']),
        'citizenship_id': data['citizenshipId'],
        'document_type_id': data['documentTypeId'],
        'document_number': data['documentNumber'],
        'document_date_of_issue': formatDate(data['documentIssue']),
        'document_date_of_expire': formatDate(data['documentExpire']),
        'flight_price_id': flightPriceId,
        'return_flight_price_id': returnFlightPriceId,
        'baggage_items': baggageItems,
      });
    }

    return passengers;
  }

  void _handleAmountChanged(int index, double amount) {
    setState(() {
      _partialPayments[index]['amount'] = amount;
      _partialPayments.removeRange(index + 1, _partialPayments.length);

      final totalPaid =
          _partialPayments.fold(0.0, (sum, item) => sum + (item['amount'] as double));

      if (totalPaid < widget.totalPrice &&
          amount > 0 &&
          (widget.totalPrice - totalPaid) > 0.01) {
        _partialPayments.add({'amount': 0.0, 'methodId': null});
      }
    });
  }

  void _startTimer() {
    _timeLeft = const Duration(minutes: 10);
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        if (_timeLeft.inSeconds <= 0) {
          timer.cancel();
          _isExpired = true;
        } else {
          _timeLeft = _timeLeft - const Duration(seconds: 1);
        }
      });
      if (_timeLeft.inSeconds <= 0 && mounted) {
        _showTimeoutDialog();
      }
    });
  }

  void _showTimeoutDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Session Expired'),
        content: const Text(
            'The time for payment has run out. You will be redirected to the bookings page.'),
        actions: [
          TextButton(
            onPressed: () => context.go('/sales/bookings'),
            child: const Text('OK'),
          ),
        ],
      ),
    );

    Future.delayed(const Duration(seconds: 5), () {
      if (mounted &&
          GoRouterState.of(context).uri.toString().contains('payment')) {
        context.go('/sales/bookings');
      }
    });
  }

  Future<void> _processPayment(String status) async {
    setState(() => _isProcessingPayment = true);

    try {
      final authService = context.read<AuthService>();
      final api = BookingApiService(authService);

      if (widget.isMultiSegment) {
        // Для multi-segment — платимо за обидва бронювання
        // Сума розподіляється пропорційно між двома бронюваннями
        final draft = widget.bookingGroupDraft!;
        final seg1Price = draft.firstSegment.basePrice;
        final seg2Price = draft.secondSegment!.basePrice;

        if (_isPartialPayment) {
          for (var payment in _partialPayments) {
            if (payment['methodId'] == null || payment['amount'] <= 0) continue;
            final amount = payment['amount'] as double;
            final ratio = seg1Price / widget.totalPrice;
            final amount1 = amount * ratio;
            final amount2 = amount - amount1;

            await api.confirmPayment(
              bookingId: _bookingId1!,
              data: {
                'paymentMethodId': payment['methodId'],
                'status': status,
                'amount': amount1,
                'email': _emailValue,
                'passengerId': _selectedAdultIndex,
              },
            );
            await api.confirmPayment(
              bookingId: _bookingId2!,
              data: {
                'paymentMethodId': payment['methodId'],
                'status': status,
                'amount': amount2,
                'email': _emailValue,
                'passengerId': _selectedAdultIndex,
              },
            );
          }
        } else {
          await api.confirmPayment(
            bookingId: _bookingId1!,
            data: {
              'paymentMethodId': _singlePaymentMethodId,
              'status': status,
              'amount': seg1Price,
              'email': _emailValue,
              'passengerId': _selectedAdultIndex,
            },
          );
          await api.confirmPayment(
            bookingId: _bookingId2!,
            data: {
              'paymentMethodId': _singlePaymentMethodId,
              'status': status,
              'amount': seg2Price,
              'email': _emailValue,
              'passengerId': _selectedAdultIndex,
            },
          );
        }
      } else {
        // Звичайний флоу
        if (_isPartialPayment) {
          for (var payment in _partialPayments) {
            if (payment['methodId'] == null || payment['amount'] <= 0) continue;
            await api.confirmPayment(
              bookingId: _bookingId!,
              data: {
                'paymentMethodId': payment['methodId'],
                'status': status,
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
              'status': status,
              'amount': widget.totalPrice,
              'email': _emailValue,
              'passengerId': _selectedAdultIndex,
            },
          );
        }
      }

      if (!mounted) return;
      setState(() => _isProcessingPayment = false);

      if (status == 'failed') {
        _showFailedStatusDialog();
      } else {
        _showSuccessDialog();
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isProcessingPayment = false);
      _showErrorDialog(e.toString().replaceAll('Exception: ', ''));
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    if (_isCreatingBooking) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
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
        onBack: null,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        child: Column(
          children: [
            _buildTimer(colors),
            const SizedBox(height: 24),
            BookingSummaryCard(
                totalPrice: widget.totalPrice,
                bookingNumber: _bookingNumber,
                bookingNumber1: _bookingNumber1,
                bookingNumber2: _bookingNumber2,
                fromCity: widget.fromCity,
                toCity: widget.toCity,
                departDate: widget.departDate,
                returnDate: widget.returnDate,
                fromAirportCode: widget.fromAirportCode,
                toAirportCode: widget.toAirportCode,
                departureTime: widget.departureTime,
                arrivalTime: widget.arrivalTime,
                isRoundTrip: widget.isRoundTrip,
                basePrice: widget.basePrice,
                passengers: widget.passengers,
                passengerClassLabels: widget.passengerClassLabels,
                baggageSelections: widget.baggageSelections,
                isMultiSegment: widget.isMultiSegment,
                bookingGroupDraft: widget.bookingGroupDraft,
              ),
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

  Widget _buildTimer(ColorScheme colors) {
    final isUrgent = _timeLeft.inSeconds > 0 && _timeLeft.inSeconds < 120;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _isExpired
            ? colors.errorContainer
            : isUrgent
                ? colors.errorContainer.withOpacity(0.5)
                : colors.primaryContainer.withOpacity(0.4),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: _isExpired
                ? colors.error
                : isUrgent
                    ? colors.error.withOpacity(0.5)
                    : colors.primary.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(
            _isExpired ? Icons.timer_off_outlined : Icons.timer_outlined,
            color: _isExpired || isUrgent ? colors.error : colors.primary,
            size: 28,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _isExpired ? 'Booking Expired' : 'Time to complete payment',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: _isExpired || isUrgent
                        ? colors.error
                        : colors.onSurface,
                  ),
                ),
                Text(
                  _isExpired
                      ? 'This booking has been cancelled'
                      : 'Booking will be cancelled if not paid',
                  style: TextStyle(fontSize: 12, color: colors.onSurfaceVariant),
                ),
              ],
            ),
          ),
          if (!_isExpired)
            Text(
              '${_timeLeft.inMinutes}:${(_timeLeft.inSeconds % 60).toString().padLeft(2, '0')}',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                fontFeatures: const [FontFeature.tabularFigures()],
                color: isUrgent ? colors.error : colors.primary,
              ),
            ),
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
            const Text('Ticket Delivery',
                style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            CustomSelectField(
              label: 'Select Adult Passenger',
              value: _selectedAdultName ?? '',
              icon: Icons.person_outline,
              items: _adultPassengers
                  .map((e) =>
                      "${e['firstName'] ?? ''} ${e['lastName'] ?? ''}".trim())
                  .toList(),
              onChanged: (val) {
                if (val == null) return;
                final selected = _adultPassengers.firstWhere(
                  (e) =>
                      "${e['firstName'] ?? ''} ${e['lastName'] ?? ''}".trim() ==
                      val,
                  orElse: () => {},
                );
                if (selected.isEmpty) return;
                setState(() {
                  _selectedAdultName = val;
                  _selectedAdultIndex = selected['passengerId'] as int?;
                  _emailValue = selected['email'] ?? '';
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
            Text(
              widget.isMultiSegment
                  ? 'Tickets for both flights will be sent to this email'
                  : 'Tickets will be sent to this email',
              style: TextStyle(color: colors.onSurfaceVariant, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentSection(ColorScheme colors) {
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
              children: [
                Switch(
                  value: _isPartialPayment,
                  onChanged:
                      _isExpired ? null : (v) => setState(() => _isPartialPayment = v),
                ),
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
                onMethodSelected: (idx, id) =>
                    setState(() => _partialPayments[idx]['methodId'] = id),
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

  Widget _buildActionButtons(ColorScheme colors) {
    if (_isExpired) {
      return SizedBox(
        width: double.infinity,
        child: CustomButton(
          label: 'Session Expired - Back to Bookings',
          isIconAfterLabel: false,
          onPressed: () => context.go('/sales/bookings'),
          borderRadius: 12,
        ),
      );
    }

    String? disabledReason;
    if (_isPartialPayment) {
      final hasZeroAmount =
          _partialPayments.any((p) => (p['amount'] as double) <= 0);
      final hasNoMethod = _partialPayments.any((p) => p['methodId'] == null);
      final totalPaid = _partialPayments.fold<double>(
          0, (s, p) => s + (p['amount'] as double));
      final notCovered = (totalPaid - widget.totalPrice).abs() > 0.01 &&
          totalPaid < widget.totalPrice;

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
        Row(
          children: [
            Expanded(
              child: Tooltip(
                message: disabledReason ?? '',
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: colors.errorContainer,
                    foregroundColor: colors.onErrorContainer,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: const Icon(Icons.cancel_outlined),
                  label: const Text('Failed'),
                  onPressed:
                      canConfirm ? () => _processPayment('failed') : null,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Tooltip(
                message: disabledReason ?? '',
                child: CustomButton(
                  label: _isPartialPayment ? 'Confirm Partial' : 'Confirm Payment',
                  isIconAfterLabel: true,
                  onPressed:
                      canConfirm ? () => _processPayment('paid') : null,
                  borderRadius: 12,
                  verticalPadding: 16,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _showFailedStatusDialog() {
    final bookingRef = widget.isMultiSegment
        ? '#${_bookingNumber1 ?? ''} + #${_bookingNumber2 ?? ''}'
        : '#${_bookingNumber ?? 'N/A'}';

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        final colors = Theme.of(context).colorScheme;
        return Dialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: colors.error.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.cancel, color: colors.error, size: 80),
                ),
                const SizedBox(height: 24),
                const Text('Payment Failed',
                    style:
                        TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center),
                const SizedBox(height: 12),
                Text(
                  'The payment for booking $bookingRef was marked as failed.',
                  style: TextStyle(color: colors.onSurfaceVariant),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  child: CustomButton(
                    label: 'Go to My Bookings',
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

  void _showSuccessDialog() {
    final bookingRef = widget.isMultiSegment
        ? '#${_bookingNumber1 ?? ''} + #${_bookingNumber2 ?? ''}'
        : '#${_bookingNumber ?? 'N/A'}';

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        final colors = Theme.of(context).colorScheme;
        return Dialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
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
                  child: const Icon(Icons.check_circle,
                      color: Colors.green, size: 80),
                ),
                const SizedBox(height: 24),
                const Text('Payment Successful!',
                    style:
                        TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center),
                const SizedBox(height: 12),
                Text(
                  'Your booking $bookingRef has been confirmed. '
                  'Tickets will be sent to $_emailValue shortly.',
                  style: TextStyle(color: colors.onSurfaceVariant),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  child: CustomButton(
                    label: 'Go to My Bookings',
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
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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

  Widget _buildErrorState(ColorScheme colors) {
    return Scaffold(
        body: Center(child: Text(_bookingError ?? 'Unknown Error')));
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}