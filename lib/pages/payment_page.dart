import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../widgets/responsive_layout.dart';
import '../widgets/booking_progress_header.dart';
import '../services/auth_service.dart';
import '../services/booking_api_service.dart';
import '../widgets/custom/custom_input_field.dart';
import '../widgets/custom/custom_select_field.dart';

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

  bool _isPartialPayment = false;
  final TextEditingController _partialAmountController = TextEditingController();
  String? _partialAmountError;

  final TextEditingController _emailController = TextEditingController();
  String? _emailError;

  int get _totalPassengers => widget.passengers.values.reduce((a, b) => a + b);

  int? _selectedAdultIndex;
  String? _selectedAdultName;

  String get _classLabel {
    final classes = widget.passengerClassLabels.values.toSet();
    if (classes.isEmpty) return '';
    if (classes.length == 1) return classes.first;
    return 'Mixed class';
  }

  String _emailValue = '';

  List<String> get _adultEmails {
    final adultsCount = widget.passengers['adults'] ?? 0;
    final emails = <String>[];
    for (int i = 0; i < adultsCount; i++) {
      final email = widget.passengerData[i]?['email'] as String?;
      if (email != null && email.trim().isNotEmpty) emails.add(email.trim());
    }
    return emails;
  }

  double get _paymentAmount {
    if (_isPartialPayment) {
      return double.tryParse(_partialAmountController.text) ?? widget.totalPrice;
    }
    return widget.totalPrice;
  }

  @override
  void initState() {
    super.initState();
    print('PassengerData on init: ${widget.passengerData}');
    final emails = _adultEmails;
    if (emails.isNotEmpty) {
      _emailValue = emails.first;
      _emailController.text = emails.first;
    }

    _initPage();
  }

  Future<void> _initPage() async {
    final authService = context.read<AuthService>();
    final api = BookingApiService(authService);

    await Future.wait([
      _loadPaymentMethods(api),
      _createBooking(api),
    ]);

    final adultsCount = widget.passengers['adults'] ?? 0;
    for (int i = 0; i < adultsCount; i++) {
      final data = widget.passengerData[i] ?? {};
      final passengerId = data['foundPassengerId'];
      if (passengerId != null) {
        try {
          final email = await api.getPassengerEmail(passengerId);
          if (mounted && email != null && email.isNotEmpty) {
            setState(() {
              widget.passengerData[i]!['email'] = email;
              if (_emailController.text.isEmpty) {
                _emailValue = email;
                _emailController.text = email;
              }
            });
          }
        } catch (e) {
          debugPrint('Failed to load email for passenger $passengerId: $e');
        }
      }
    }

    debugPrint('PassengerData after fetching emails: ${widget.passengerData}');
  }

  Future<void> _loadPaymentMethods(BookingApiService api) async {
    try {
      final methods = await api.getPaymentMethods();
      if (mounted) setState(() { _paymentMethods = methods; _isLoadingMethods = false; });
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
        _bookingId     = result['bookingId'] as int;
        _bookingNumber = result['bookingNumber'] as String;
        _expiresAt     = DateTime.parse(result['expiresAt'] as String);
        _isCreatingBooking = false;
      });
      _startTimer();
    } catch (e) {
      if (mounted) setState(() { _bookingError = e.toString(); _isCreatingBooking = false; });
    }
  }

  Map<String, dynamic> _buildBookingBody() {
    final List<Map<String, dynamic>> passengers = [];

    for (int i = 0; i < _totalPassengers; i++) {
      final data = widget.passengerData[i] ?? {};

      final outbound = i < widget.outboundAssignments.length ? widget.outboundAssignments[i] : null;
      final flightPriceId = outbound?['flightPriceId'] as int? ?? 0;

      final returnAssign = i < widget.returnAssignments.length ? widget.returnAssignments[i] : null;
      final returnFlightPriceId = returnAssign?['flightPriceId'] as int?;

      final baggageMap = widget.baggageSelections[i] ?? {};
      final baggageItems = baggageMap.entries
          .map((e) => {'baggage_pricing_in_flight_id': e.key, 'quantity': e.value})
          .toList();

      String? formatDate(dynamic date) {
        if (date is DateTime) return date.toIso8601String().split('T')[0];
        return date?.toString();
      }

      passengers.add({
        'passenger_id':           data['foundPassengerId'],
        'document_id':            data['documentId'],
        'first_name':             data['firstName'],
        'last_name':              data['lastName'],
        'sex':                    data['sexId'] != null ? data['sexId'].toString() == '1' : null,
        'date_of_birth':          formatDate(data['dateOfBirth']),
        'citizenship_id':         data['citizenshipId'],
        'document_type_id':       data['documentTypeId'],
        'document_number':        data['documentNumber'],
        'document_date_of_issue': formatDate(data['documentIssue']),
        'document_date_of_expire':formatDate(data['documentExpire']),
        'flight_price_id':        flightPriceId,
        if (returnFlightPriceId != null) 'return_flight_price_id': returnFlightPriceId,
        'baggage_items':          baggageItems,
      });
    }

    return {'passengers': passengers, 'total_amount': widget.totalPrice};
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
    final diff = _expiresAt!.toUtc().difference(DateTime.now().toUtc());
    if (diff.isNegative && !_isExpired) {
      setState(() { _timeLeft = Duration.zero; _isExpired = true; });
      _timer?.cancel();
      _showExpiredDialog();
    } else if (!diff.isNegative) {
      setState(() => _timeLeft = diff);
    }
  }

  bool _validateEmail() {
    if (_selectedAdultIndex == null) {
      setState(() => _emailError = 'Select adult passenger');
      return false;
    }

    final email = _emailValue.trim();

    if (email.isEmpty) {
      setState(() => _emailError = 'Email is required');
      return false;
    }

    final emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    if (!emailRegex.hasMatch(email)) {
      setState(() => _emailError = 'Invalid email format');
      return false;
    }

    setState(() => _emailError = null);
    return true;
  }

  List<Map<String, dynamic>> get _adultPassengers {
    final adultsCount = widget.passengers['adults'] ?? 0;
    final now = DateTime.now();

    return List.generate(adultsCount, (i) {
      final data = widget.passengerData[i] ?? {};
      final dob = data['dateOfBirth'] as DateTime?;

      bool is18Plus = false;

      if (dob != null) {
        final age = now.year - dob.year -
            ((now.month < dob.month ||
                    (now.month == dob.month && now.day < dob.day))
                ? 1
                : 0);
        is18Plus = age >= 18;
      }

      if (!is18Plus) return null;

      final email = data['email'] ?? '';

      return {
        'index': i,
        'firstName': data['firstName'] ?? '',
        'lastName': data['lastName'] ?? '',
        'email': email,
        'passengerId': data['foundPassengerId'],
      };
    }).whereType<Map<String, dynamic>>().toList();
  }

  bool _validatePartialAmount() {
    if (!_isPartialPayment) return true;
    final value = double.tryParse(_partialAmountController.text);
    if (value == null || value <= 0) {
      setState(() => _partialAmountError = 'Enter a valid amount');
      return false;
    }
    if (value > widget.totalPrice) {
      setState(() => _partialAmountError = 'Cannot exceed total \$${widget.totalPrice.toStringAsFixed(2)}');
      return false;
    }
    setState(() => _partialAmountError = null);
    return true;
  }

  Future<void> _processPayment(String status) async {
    if (_bookingId == null || _selectedPaymentMethodId == null) return;

    if (status == 'paid') {
      if (!_validateEmail() || !_validatePartialAmount()) return;
    }

    setState(() => _isProcessingPayment = true);

    try {
      final authService = context.read<AuthService>();
      final api = BookingApiService(authService);

      await api.processPayment(
        bookingId: _bookingId!,
        paymentMethodId: _selectedPaymentMethodId!,
        status: status,
        amount: _paymentAmount,
        email: _emailValue.trim().isEmpty ? null : _emailValue.trim(),
      );

      if (!mounted) return;

      if (status == 'paid') {
        _showSuccessDialog();
      } else {
        _showFailedDialog();
      }

    } catch (e) {
      if (!mounted) return;
      setState(() => _isProcessingPayment = false);
      _showErrorDialog(e.toString());
    }
  }
  
  void _showExpiredDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: const Text('Session Expired'),
        content: const Text('The 10-minute booking window has closed. Please start over.'),
        actions: [
          TextButton(onPressed: () => context.go('/sales/search'), child: const Text('OK')),
        ],
      ),
    );
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        icon: const Icon(Icons.check_circle_outline, color: Colors.green, size: 48),
        title: const Text('Payment Confirmed'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Booking $_bookingNumber confirmed.'),
            const SizedBox(height: 8),
            Text(
              'PDF ticket will be sent to ${_emailValue.trim()}',
              style: const TextStyle(fontSize: 13),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () { Navigator.of(context).pop(); context.go('/sales/bookings'); },
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
            onPressed: () { Navigator.of(context).pop(); context.go('/sales/bookings'); },
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
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('OK')),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _partialAmountController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  String _formatDuration(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '${d.inMinutes >= 60 ? '${d.inHours}:' : ''}$m:$s';
  }

  String _fmt(DateTime d) => DateFormat('dd MMM yyyy').format(d);

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
                      _buildBookingSummary(colors),
                      const SizedBox(height: 24),
                      _buildEmailField(colors),
                      const SizedBox(height: 24),
                      _buildPaymentSection(colors),
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
            Text('Failed to create booking',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: colors.error)),
            const SizedBox(height: 8),
            Text(_bookingError ?? '', textAlign: TextAlign.center),
            const SizedBox(height: 24),
            TextButton(onPressed: () => context.pop(), child: const Text('Go Back')),
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
          color: _isExpired ? colors.error : isUrgent ? colors.error.withValues(alpha: 0.5) : colors.primary.withValues(alpha: 0.3),
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
                  _isExpired ? 'Booking Expired' : 'Time to complete payment',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: _isExpired || isUrgent ? colors.error : colors.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _isExpired
                      ? 'This booking has been automatically cancelled'
                      : 'Booking will be cancelled if not paid',
                  style: TextStyle(fontSize: 12, color: _isExpired ? colors.error : colors.onSurfaceVariant),
                ),
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

  Widget _buildBookingSummary(ColorScheme colors) {
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
              Text('Booking Summary',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
              if (_bookingNumber != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: colors.primaryContainer,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(_bookingNumber!,
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: colors.onPrimaryContainer)),
                ),
            ],
          ),
          const SizedBox(height: 16),

          _buildFlightRow(
            colors: colors,
            icon: Icons.flight_takeoff,
            label: 'Outbound',
            from: '${widget.fromCity} (${widget.fromAirportCode})',
            to: '${widget.toCity} (${widget.toAirportCode})',
            date: _fmt(widget.departDate),
            departTime: widget.departureTime,
            arrivalTime: widget.arrivalTime,
            duration: widget.duration,
          ),

          if (widget.isRoundTrip && widget.returnDate != null) ...[
            const SizedBox(height: 12),
            _buildFlightRow(
              colors: colors,
              icon: Icons.flight_land,
              label: 'Return',
              from: '${widget.toCity} (${widget.toAirportCode})',
              to: '${widget.fromCity} (${widget.fromAirportCode})',
              date: _fmt(widget.returnDate!),
              departTime: '',
              arrivalTime: '',
              duration: '',
            ),
          ],

          const Divider(height: 24),

          Text('Passengers', style: Theme.of(context).textTheme.labelMedium?.copyWith(color: colors.onSurfaceVariant)),
          const SizedBox(height: 8),
          ...List.generate(_totalPassengers, (i) => _buildPassengerRow(colors, i)),

          const Divider(height: 24),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Total Amount',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
              Text(
                '\$${widget.totalPrice.toStringAsFixed(2)}',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold, color: colors.primary),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFlightRow({
    required ColorScheme colors,
    required IconData icon,
    required String label,
    required String from,
    required String to,
    required String date,
    required String departTime,
    required String arrivalTime,
    required String duration,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: colors.primary),
              const SizedBox(width: 6),
              Text(label,
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: colors.primary)),
              const SizedBox(width: 8),
              Text(date, style: TextStyle(fontSize: 12, color: colors.onSurfaceVariant)),
            ],
          ),
          const SizedBox(height: 6),
          Text('$from → $to', style: const TextStyle(fontWeight: FontWeight.w500)),
          if (departTime.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text('$departTime → $arrivalTime  ·  $duration',
                style: TextStyle(fontSize: 12, color: colors.onSurfaceVariant)),
          ],
        ],
      ),
    );
  }

  Widget _buildPassengerRow(ColorScheme colors, int i) {
    final data = widget.passengerData[i] ?? {};
    final firstName = data['firstName'] as String? ?? '';
    final lastName  = data['lastName']  as String? ?? '';
    final name = '$firstName $lastName'.trim().isEmpty ? 'Passenger ${i + 1}' : '$firstName $lastName';

    final adultsCount    = widget.passengers['adults']   ?? 0;
    final childrenCount  = widget.passengers['children'] ?? 0;
    final String type    = i < adultsCount ? 'Adult'
        : i < adultsCount + childrenCount  ? 'Child'
        : 'Infant';

    final classLabel = widget.passengerClassLabels['${type} ${i + 1}'] ?? _classLabel;

    final baggageMap = widget.baggageSelections[i] ?? {};
    final totalBaggage = baggageMap.values.fold<int>(0, (s, v) => s + v);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(Icons.person_outline, size: 16, color: colors.onSurfaceVariant),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(fontWeight: FontWeight.w500)),
                Text('$type · $classLabel',
                    style: TextStyle(fontSize: 12, color: colors.onSurfaceVariant)),
              ],
            ),
          ),
          if (totalBaggage > 0)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.luggage, size: 14, color: colors.primary),
                const SizedBox(width: 4),
                Text('$totalBaggage bag${totalBaggage > 1 ? 's' : ''}',
                    style: TextStyle(fontSize: 12, color: colors.primary)),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildEmailField(ColorScheme colors) {
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

          Text('Ticket Delivery Email',
              style: Theme.of(context)
                  .textTheme
                  .titleSmall
                  ?.copyWith(fontWeight: FontWeight.bold)),

          const SizedBox(height: 16),

          CustomSelectField(
            label: 'Select adult passenger *',
            value: _selectedAdultName ?? '',
            icon: Icons.person_outline,
            items: _adultPassengers
                .map((p) => '${p['firstName']} ${p['lastName']}'.trim())
                .toList(),
            onChanged: (value) {
              final passenger = _adultPassengers.firstWhere(
                  (p) =>
                      '${p['firstName']} ${p['lastName']}'.trim() == value);

              setState(() {
                _selectedAdultIndex = passenger['index'];
                _selectedAdultName = value;

                _emailValue = passenger['email'] ?? '';
                _emailController.text = _emailValue;

                _emailError = null;

                debugPrint('Selected passenger: $value');
                debugPrint('Passenger email: ${_emailValue}');
              });
            },
          ),

          const SizedBox(height: 16),

          CustomInputField(
            label: 'Email address *',
            value: _emailValue,         
            icon: Icons.email_outlined,
            keyboardType: TextInputType.emailAddress,
            errorText: _emailError,
            onChanged: (value) {
              setState(() {
                _emailValue = value;
                _emailError = null;
              });
            },
          )
        ],
      ),
    );
  }
    
  Widget _buildPaymentSection(ColorScheme colors) {
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
          Text('Payment', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),

          Text('Payment Method', style: Theme.of(context).textTheme.labelMedium?.copyWith(color: colors.onSurfaceVariant)),
          const SizedBox(height: 8),
          _buildPaymentMethods(colors),
          const SizedBox(height: 20),

          Row(
            children: [
              Switch(
                value: _isPartialPayment,
                onChanged: _isExpired ? null : (v) {
                  setState(() {
                    _isPartialPayment = v;
                    if (!v) {
                      _partialAmountController.clear();
                      _partialAmountError = null;
                    }
                  });
                },
              ),
              const SizedBox(width: 8),
              Text('Partial payment', style: Theme.of(context).textTheme.bodyMedium),
            ],
          ),

          if (_isPartialPayment) ...[
            const SizedBox(height: 12),
            TextField(
              controller: _partialAmountController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}'))],
              decoration: InputDecoration(
                labelText: 'Amount to pay (max \$${widget.totalPrice.toStringAsFixed(2)}) *',
                prefixIcon: Icon(Icons.attach_money, color: colors.primary),
                errorText: _partialAmountError,
                filled: true,
                fillColor: colors.primaryContainer.withValues(alpha: 0.1),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (_) => setState(() => _partialAmountError = null),
            ),
          ],

          const SizedBox(height: 24),
          _buildActionButtons(colors),
        ],
      ),
    );
  }

  Widget _buildPaymentMethods(ColorScheme colors) {
    if (_isLoadingMethods) return const Center(child: CircularProgressIndicator());
    if (_paymentMethods.isEmpty) {
      return Text('No payment methods available', style: TextStyle(color: colors.onSurfaceVariant));
    }

    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: _paymentMethods.map((method) {
        final id   = method['paymentMethodId'] as int;
        final name = method['paymentMethodName'] as String;
        final isSelected = _selectedPaymentMethodId == id;

        IconData icon;
        switch (name.toLowerCase()) {
          case 'cash':          icon = Icons.payments_outlined; break;
          case 'credit card':   icon = Icons.credit_card; break;
          case 'debit card':    icon = Icons.credit_card_outlined; break;
          case 'bank transfer': icon = Icons.account_balance_outlined; break;
          default:              icon = Icons.payment;
        }

        return InkWell(
          onTap: _isExpired ? null : () => setState(() => _selectedPaymentMethodId = id),
          borderRadius: BorderRadius.circular(10),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isSelected ? colors.primaryContainer : colors.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isSelected ? colors.primary : Colors.transparent,
                width: 2,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 20, color: isSelected ? colors.onPrimaryContainer : colors.onSurfaceVariant),
                const SizedBox(width: 8),
                Text(name,
                    style: TextStyle(
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      color: isSelected ? colors.onPrimaryContainer : colors.onSurface,
                    )),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildActionButtons(ColorScheme colors) {
    final canAct = !_isExpired && _selectedPaymentMethodId != null && !_isProcessingPayment;

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
                ? const SizedBox(width: 18, height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.check_circle_outline),
            label: Text(_isPartialPayment
                ? 'Confirm Partial Payment'
                : 'Confirm Payment'),
            style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
          ),
        ),
      ],
    );
  }
}