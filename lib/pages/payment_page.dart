import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../widgets/responsive_layout.dart';
import '../widgets/booking_progress_header.dart';
import '../services/auth_service.dart';
import '../services/booking_api_service.dart';

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
  Duration _timeLeft = Duration.zero;
  bool _isExpired = false;

  List<Map<String, dynamic>> _paymentMethods = [];
  int? _selectedPaymentMethodId;
  bool _isLoadingMethods = true;

  bool _isProcessingPayment = false;

  int get _totalPassengers => widget.passengers.values.reduce((a, b) => a + b);

  String get _classLabel {
    final classes = widget.passengerClassLabels.values.toSet();
    if (classes.isEmpty) return '';
    if (classes.length == 1) return classes.first;
    return 'Mixed class';
  }

  @override
  void initState() {
    super.initState();
    _initPage();
  }

  Future<void> _initPage() async {
    final authService = context.read<AuthService>();
    final api = BookingApiService(authService);

    await Future.wait([
      _loadPaymentMethods(api),
      _createBooking(api),
    ]);
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
      final body = _buildBookingBody();
      final result = await api.createBooking(body);

      if (!mounted) return;
      setState(() {
        _bookingId = result['bookingId'] as int;
        _bookingNumber = result['bookingNumber'] as String;
        _expiresAt = DateTime.parse(result['expiresAt'] as String);
        _isCreatingBooking = false;
      });

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

  Map<String, dynamic> _buildBookingBody() {
    final List<Map<String, dynamic>> passengers = [];

    for (int i = 0; i < _totalPassengers; i++) {
      final data = widget.passengerData[i] ?? {};
      final assignment = i < widget.outboundAssignments.length
          ? widget.outboundAssignments[i]
          : null;

      final flightPriceId = assignment?['flightPriceId'] as int? ?? 0;

      final baggageMap = widget.baggageSelections[i] ?? {};
      final baggageItems = baggageMap.entries
          .map((e) => {
                'baggagePricingInFlightId': e.key,
                'quantity': e.value,
              })
          .toList();

      final foundPassengerId = data['foundPassengerId'] as int?;
      final documentChanged = data['documentChanged'] as bool? ?? false;

      Map<String, dynamic> passengerDTO;

      if (foundPassengerId != null && !documentChanged) {
        passengerDTO = {
          'passengerId': foundPassengerId,
          'documentId': data['documentId'],
          'flightPriceId': flightPriceId,
          'baggageItems': baggageItems,
        };
      } else {
        final dob = data['dateOfBirth'];
        final docIssue = data['documentIssue'];
        final docExpire = data['documentExpire'];

        passengerDTO = {
          'passengerId': foundPassengerId,
          'firstName': data['firstName'],
          'lastName': data['lastName'],
          'sex': data['sex'] == 'Male' ? true : false,
          'dateOfBirth': dob is DateTime
              ? dob.toIso8601String().split('T')[0]
              : dob?.toString(),
          'citizenshipId': data['citizenshipId'],
          'documentTypeId': data['documentTypeId'],
          'documentNumber': data['documentNumber'],
          'documentDateOfIssue': docIssue is DateTime
              ? docIssue.toIso8601String().split('T')[0]
              : docIssue?.toString(),
          'documentDateOfExpire': docExpire is DateTime
              ? docExpire.toIso8601String().split('T')[0]
              : docExpire?.toString(),
          'flightPriceId': flightPriceId,
          'baggageItems': baggageItems,
        };
      }

      passengers.add(passengerDTO);
    }

    return {
      'passengers': passengers,
      'totalAmount': widget.totalPrice,
    };
  }

  void _startTimer() {
    if (_expiresAt == null) return;
    _updateTimeLeft();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      _updateTimeLeft();
    });
  }

  void _updateTimeLeft() {
    final now = DateTime.now().toUtc();
    final expires = _expiresAt!.toUtc();
    final diff = expires.difference(now);
    setState(() {
      if (diff.isNegative) {
        _timeLeft = Duration.zero;
        _isExpired = true;
        _timer?.cancel();
      } else {
        _timeLeft = diff;
      }
    });
  }

  Future<void> _processPayment(String status) async {
    if (_bookingId == null || _selectedPaymentMethodId == null) return;

    setState(() => _isProcessingPayment = true);

    try {
      final authService = context.read<AuthService>();
      final api = BookingApiService(authService);

      await api.processPayment(
        bookingId: _bookingId!,
        paymentMethodId: _selectedPaymentMethodId!,
        status: status,
        amount: widget.totalPrice,
      );

      if (!mounted) return;

      if (status == 'paid') {
        _showSuccessAndNavigate();
      } else {
        _showFailedDialog();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isProcessingPayment = false);
        _showErrorDialog(e.toString());
      }
    }
  }

  void _showSuccessAndNavigate() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        icon: const Icon(Icons.check_circle_outline, color: Colors.green, size: 48),
        title: const Text('Payment Confirmed'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Booking $_bookingNumber has been confirmed.'),
            const SizedBox(height: 8),
            const Text(
              'PDF tickets will be sent to passengers\' emails.',
              style: TextStyle(fontSize: 13),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              context.go('/sales/bookings');
            },
            child: const Text('Go to Bookings'),
          ),
        ],
      ),
    );
  }

  void _showFailedDialog() {
    setState(() => _isProcessingPayment = false);
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        icon: const Icon(Icons.cancel_outlined, color: Colors.red, size: 48),
        title: const Text('Payment Failed'),
        content: Text('Booking $_bookingNumber marked as failed.'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              context.go('/sales/bookings');
            },
            child: const Text('Go to Bookings'),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        icon: const Icon(Icons.error_outline, color: Colors.red),
        title: const Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '${d.inMinutes >= 60 ? '${d.inHours}:' : ''}$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return ResponsiveLayout(
      header: BookingProgressHeader(
        fromCity: widget.fromCity,
        toCity: widget.toCity,
        departDate: widget.departDate,
        returnDate: widget.returnDate,
        totalPassengers: _totalPassengers,
        flightClass: _classLabel,
        currentStep: 'payment',
        airlineName: widget.airlineName,
        onBack: () => context.pop(),
        onForward: null,
      ),
      body: _isCreatingBooking
          ? const Center(child: CircularProgressIndicator())
          : _bookingError != null
              ? _buildError(colors)
              : SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildTimer(colors),
                      const SizedBox(height: 24),
                      _buildBookingInfo(colors),
                      const SizedBox(height: 24),
                      _buildPaymentMethods(colors),
                      const SizedBox(height: 32),
                      _buildActionButtons(colors),
                      const SizedBox(height: 48),
                    ],
                  ),
                ),
    );
  }

  Widget _buildError(ColorScheme colors) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: colors.error),
            const SizedBox(height: 16),
            Text(
              'Failed to create booking',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: colors.error),
            ),
            const SizedBox(height: 8),
            Text(_bookingError ?? '', textAlign: TextAlign.center),
            const SizedBox(height: 24),
            TextButton(
              onPressed: () => context.pop(),
              child: const Text('Go Back'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimer(ColorScheme colors) {
    final isUrgent = _timeLeft.inSeconds < 120;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _isExpired
            ? colors.errorContainer
            : isUrgent
                ? colors.errorContainer.withValues(alpha: 0.5)
                : colors.primaryContainer.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _isExpired
              ? colors.error
              : isUrgent
                  ? colors.error.withValues(alpha: 0.5)
                  : colors.primary.withValues(alpha: 0.3),
        ),
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
                  _isExpired
                      ? 'Booking Expired'
                      : 'Time to complete payment',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: _isExpired || isUrgent ? colors.error : colors.onSurface,
                  ),
                ),
                if (!_isExpired) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Booking will be cancelled if not paid',
                    style: TextStyle(
                      fontSize: 12,
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                ] else ...[
                  const SizedBox(height: 4),
                  Text(
                    'This booking has been automatically cancelled',
                    style: TextStyle(fontSize: 12, color: colors.error),
                  ),
                ],
              ],
            ),
          ),
          if (!_isExpired)
            Text(
              _formatDuration(_timeLeft),
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

  Widget _buildBookingInfo(ColorScheme colors) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.outline.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Booking Summary',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              if (_bookingNumber != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: colors.primaryContainer,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _bookingNumber!,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: colors.onPrimaryContainer,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Icon(Icons.flight_takeoff, size: 18, color: colors.primary),
              const SizedBox(width: 8),
              Text(
                '${widget.fromCity} → ${widget.toCity}',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              if (widget.isRoundTrip) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: colors.secondaryContainer,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    'Round trip',
                    style: TextStyle(fontSize: 11, color: colors.onSecondaryContainer),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.people_outline, size: 18, color: colors.onSurfaceVariant),
              const SizedBox(width: 8),
              Text(
                '$_totalPassengers passenger${_totalPassengers > 1 ? 's' : ''} · $_classLabel',
                style: TextStyle(color: colors.onSurfaceVariant),
              ),
            ],
          ),
          const Divider(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total Amount',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              Text(
                '\$${widget.totalPrice.toStringAsFixed(2)}',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colors.primary,
                    ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentMethods(ColorScheme colors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Payment Method',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 12),
        if (_isLoadingMethods)
          const Center(child: CircularProgressIndicator())
        else if (_paymentMethods.isEmpty)
          Text('No payment methods available',
              style: TextStyle(color: colors.onSurfaceVariant))
        else
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: _paymentMethods.map((method) {
              final id = method['paymentMethodId'] as int;
              final name = method['paymentMethodName'] as String;
              final isSelected = _selectedPaymentMethodId == id;

              IconData icon;
              switch (name.toLowerCase()) {
                case 'cash':
                  icon = Icons.payments_outlined;
                  break;
                case 'credit card':
                  icon = Icons.credit_card;
                  break;
                case 'debit card':
                  icon = Icons.credit_card_outlined;
                  break;
                case 'bank transfer':
                  icon = Icons.account_balance_outlined;
                  break;
                default:
                  icon = Icons.payment;
              }

              return InkWell(
                onTap: _isExpired
                    ? null
                    : () => setState(() => _selectedPaymentMethodId = id),
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? colors.primaryContainer
                        : colors.surfaceContainerHigh,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isSelected ? colors.primary : Colors.transparent,
                      width: 2,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        icon,
                        size: 20,
                        color: isSelected
                            ? colors.onPrimaryContainer
                            : colors.onSurfaceVariant,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        name,
                        style: TextStyle(
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          color: isSelected
                              ? colors.onPrimaryContainer
                              : colors.onSurface,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
      ],
    );
  }

  Widget _buildActionButtons(ColorScheme colors) {
    final canAct = !_isExpired &&
        _selectedPaymentMethodId != null &&
        !_isProcessingPayment;

    if (_isExpired) {
      return SizedBox(
        width: double.infinity,
        child: OutlinedButton.icon(
          onPressed: () => context.go('/sales/bookings'),
          icon: const Icon(Icons.arrow_back),
          label: const Text('Back to Bookings'),
        ),
      );
    }

    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: canAct ? () => _processPayment('failed') : null,
            icon: const Icon(Icons.cancel_outlined),
            label: const Text('Payment Failed'),
            style: OutlinedButton.styleFrom(
              foregroundColor: colors.error,
              side: BorderSide(color: colors.error.withValues(alpha: 0.5)),
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          flex: 2,
          child: FilledButton.icon(
            onPressed: canAct ? () => _processPayment('paid') : null,
            icon: _isProcessingPayment
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.check_circle_outline),
            label: const Text('Confirm Payment'),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
        ),
      ],
    );
  }
}