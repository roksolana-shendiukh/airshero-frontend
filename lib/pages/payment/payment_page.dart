import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../widgets/responsive_layout.dart';
import '../../widgets/booking/booking_progress_header.dart';
import '../../services/auth_service.dart';
import '../../services/booking_api_service.dart';
import '../../widgets/custom/custom_button.dart';
import '../../models/booking_group_draft.dart';
import '../../widgets/booking/booking_summary_card.dart';
import '../../services/payment_api_service.dart';

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
  final int? bookingId;
  final String? bookingNumber;
  final int? bookingId2;
  final String? bookingNumber2;
  final DateTime? expiresAt;

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
    this.bookingId,
    this.bookingNumber,
    this.bookingId2,
    this.bookingNumber2,
    this.expiresAt,
  });

  @override
  State<PaymentPage> createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage> {
  String? _bookingError;
  bool _isLoading = true;
  bool _isExpired = false;
  bool _isProcessingPayment = false;

  int? _bookingId;
  String? _bookingNumber;
  int? _bookingId1;
  int? _bookingId2;
  String? _bookingNumber1;
  String? _bookingNumber2;

  List<Map<String, dynamic>> _paymentMethods = [];
  int? _singlePaymentMethodId;

  bool _isPartialPayment = false;
  List<Map<String, dynamic>> _partialPayments = [
    {'amount': 0.0, 'methodId': null}
  ];

  int get _totalPassengers =>
      widget.passengers.values.fold(0, (a, b) => a + b);

  @override
  void initState() {
    super.initState();

    _bookingId = widget.bookingId;
    _bookingNumber = widget.bookingNumber;
    _bookingId1 = widget.bookingId;
    _bookingId2 = widget.bookingId2;
    _bookingNumber1 = widget.bookingNumber;
    _bookingNumber2 = widget.bookingNumber2;

    _initPage();
  }

  Future<void> _initPage() async {
      final authService = context.read<AuthService>();
      final bookingApi = BookingApiService(authService);
      final paymentApi = PaymentApiService(authService);

      await Future.wait([
        _loadPaymentMethods(paymentApi),
        _updatePassengers(bookingApi),
      ]);

      if (mounted) setState(() => _isLoading = false);
    }

  Future<void> _loadPaymentMethods(PaymentApiService api) async {
    try {
      final methods = await api.getPaymentMethods();
      if (mounted) setState(() => _paymentMethods = methods);
    } catch (e) {
      debugPrint('Error loading payment methods: $e');
    }
  }

  Future<void> _updatePassengers(BookingApiService api) async {
    try {
      if (widget.isMultiSegment && widget.bookingGroupDraft != null) {
        final draft = widget.bookingGroupDraft!;
        final seg1 = draft.firstSegment;
        final seg2 = draft.secondSegment!;

        final body1 = _buildPassengersBody(
          assignments: seg1.assignments,
          returnAssignments: const [],
          baggageSelections: seg1.baggageSelections,
          totalAmount: seg1.basePrice,
        );
        final body2 = _buildPassengersBody(
          assignments: seg2.assignments,
          returnAssignments: const [],
          baggageSelections: seg2.baggageSelections,
          totalAmount: seg2.basePrice,
        );

        await Future.wait([
          api.updateBookingPassengers(_bookingId1!, body1),
          api.updateBookingPassengers(_bookingId2!, body2),
        ]);
      } else {
        final body = _buildPassengersBody(
          assignments: widget.outboundAssignments,
          returnAssignments: widget.returnAssignments,
          baggageSelections: widget.baggageSelections,
          totalAmount: widget.totalPrice,
        );
        await api.updateBookingPassengers(_bookingId!, body);
      }
    } catch (e) {
      if (mounted) setState(() => _bookingError = e.toString());
    }
  }

  Map<String, dynamic> _buildPassengersBody({
    required List<Map<String, dynamic>> assignments,
    required List<Map<String, dynamic>> returnAssignments,
    required Map<int, Map<int, int>> baggageSelections,
    required double totalAmount,
  }) {
    final passengers = <Map<String, dynamic>>[];

    for (int i = 0; i < _totalPassengers; i++) {
      if (widget.removedPassengerIndices.contains(i)) continue;
      final data = widget.passengerData[i] ?? {};

      final outbound = i < assignments.length ? assignments[i] : null;
      final ret = i < returnAssignments.length ? returnAssignments[i] : null;

      final flightPriceId = outbound?['flightPriceId'] as int? ?? 0;
      final returnFlightPriceId = ret?['flightPriceId'] as int?;

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
        'passenger_id':            data['passenger_id'],
        'document_id':             data['document_id'],
        'first_name':              data['first_name'],
        'last_name':               data['last_name'],
        'sex':                     data['sex'] == 'Male',
        'email':                   data['email'],
        'date_of_birth':           formatDate(data['date_of_birth']),
        'citizenship_id':          data['citizenship_id'],
        'document_type_id':        data['document_type_id'],
        'document_number':         data['document_number'],
        'document_date_of_issue':  formatDate(data['document_issue']),
        'document_date_of_expire': formatDate(data['document_expire']),
        'flight_price_id':         outbound?['flight_price_id'] as int? ?? 0,
        'return_flight_price_id':  ret?['flight_price_id'] as int?,
        'baggage_items': baggageItems,
      });
    }

    return {
      'passengers': passengers,
      'total_amount': totalAmount,
    };
  }

  void _handleAmountChanged(int index, double amount) {
    setState(() {
      _partialPayments[index]['amount'] = amount;
      _partialPayments.removeRange(index + 1, _partialPayments.length);

      final totalPaid = _partialPayments.fold(
          0.0, (sum, item) => sum + (item['amount'] as double));

      if (totalPaid < widget.totalPrice &&
          amount > 0 &&
          (widget.totalPrice - totalPaid) > 0.01) {
        _partialPayments.add({'amount': 0.0, 'methodId': null});
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
      final api = PaymentApiService(authService);

      if (widget.isMultiSegment) {
        final draft = widget.bookingGroupDraft!;
        final seg1Price = draft.firstSegment.basePrice;
        final seg2Price = draft.secondSegment!.basePrice;

        if (_isPartialPayment) {
          for (final payment in _partialPayments) {
            if (payment['methodId'] == null || payment['amount'] <= 0) continue;
            final amount = payment['amount'] as double;
            final ratio = seg1Price / widget.totalPrice;
            final amount1 = amount * ratio;
            final amount2 = amount - amount1;

            await api.confirmPayment(
              bookingId: _bookingId1!,
              data: {
                'payment_method_id': payment['methodId'],
                'status': status,
                'amount': amount1,
              },
            );
            await api.confirmPayment(
              bookingId: _bookingId2!,
              data: {
                'payment_method_id': payment['methodId'],
                'status': status,
                'amount': amount2,
              },
            );
          }
        } else {
          await api.confirmPayment(
            bookingId: _bookingId1!,
            data: {
              'payment_method_id': _singlePaymentMethodId,
              'status': status,
              'amount': seg1Price,
            },
          );
          await api.confirmPayment(
            bookingId: _bookingId2!,
            data: {
              'payment_method_id': _singlePaymentMethodId,
              'status': status,
              'amount': seg2Price,
            },
          );
        }
      } else {
        if (_isPartialPayment) {
          for (final payment in _partialPayments) {
            if (payment['methodId'] == null || payment['amount'] <= 0) continue;
            await api.confirmPayment(
              bookingId: _bookingId!,
              data: {
                'payment_method_id': payment['methodId'],
                'status': status,
                'amount': payment['amount'],
              },
            );
          }
        } else {
          await api.confirmPayment(
            bookingId: _bookingId!,
            data: {
              'payment_method_id': _singlePaymentMethodId,
              'status': status,
              'amount': widget.totalPrice,
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

    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_bookingError != null) {
      return Scaffold(body: Center(child: Text(_bookingError!)));
    }

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
        expiresAt: widget.expiresAt,
        onExpired: () {
          setState(() => _isExpired = true);
          _showTimeoutDialog();
        },
        onBack: () {
          if (context.canPop()) {
            context.pop();
          } else {
            context.go('/sales/bookings');
          }
        },
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        child: Column(
          children: [
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
            _buildPaymentSection(colors),
            const SizedBox(height: 48),
            _buildActionButtons(colors),
            const SizedBox(height: 48),
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
                  onChanged: _isExpired
                      ? null
                      : (v) => setState(() => _isPartialPayment = v),
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
                onSelected: (id) =>
                    setState(() => _singlePaymentMethodId = id),
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
      final hasNoMethod =
          _partialPayments.any((p) => p['methodId'] == null);
      final totalPaid = _partialPayments.fold<double>(
          0, (s, p) => s + (p['amount'] as double));
      final notCovered = (totalPaid - widget.totalPrice).abs() > 0.01 &&
          totalPaid < widget.totalPrice;

      if (hasZeroAmount) {
        disabledReason = 'Enter amount for each payment part';
      } else if (hasNoMethod) {
        disabledReason = 'Select payment method for each part';
      } else if (notCovered) {
        disabledReason =
            'Total amount does not cover \$${widget.totalPrice.toStringAsFixed(2)}';
      }
    } else {
      if (_singlePaymentMethodId == null) {
        disabledReason = 'Select a payment method';
      }
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
        child: CustomButton(
          label: 'Failed',
          onPressed: canConfirm ? () => _processPayment('failed') : null,
          verticalPadding: 16,
          backgroundColor: colors.errorContainer,
          foregroundColor: colors.onErrorContainer,
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
          onPressed: canConfirm ? () => _processPayment('paid') : null,
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
      builder: (context) {
        final colors = Theme.of(context).colorScheme;
        return Dialog(
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20)),
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
                    style: TextStyle(
                        fontSize: 22, fontWeight: FontWeight.bold),
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
      builder: (context) {
        final colors = Theme.of(context).colorScheme;
        return Dialog(
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20)),
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
                    style: TextStyle(
                        fontSize: 22, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center),
                const SizedBox(height: 12),
                Text(
                  'Booking $bookingRef has been confirmed.',
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
      builder: (context) {
        final colors = Theme.of(context).colorScheme;
        return AlertDialog(
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16)),
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
}