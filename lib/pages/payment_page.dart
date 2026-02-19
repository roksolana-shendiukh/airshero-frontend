import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../widgets/responsive_layout.dart';
import '../widgets/booking_progress_header.dart';
import '../widgets/payment_status_selector.dart';
import '../widgets/paid_payment_form.dart';
import '../widgets/partially_paid_payment_form.dart';
import '../widgets/custom_button.dart';

class PaymentPage extends StatefulWidget {
  final String fromCity;
  final String toCity;
  final DateTime departDate;
  final DateTime? returnDate;
  final Map<String, int> passengers;
  final String flightClass;
  
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

  const PaymentPage({
    super.key,
    required this.fromCity,
    required this.toCity,
    required this.departDate,
    this.returnDate,
    required this.passengers,
    required this.flightClass,
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
  });

  @override
  State<PaymentPage> createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage> {
  String _selectedPaymentStatus = 'paid';
  int? _selectedPaymentMethod;
  double _depositAmount = 0;

  int get _totalPassengers => widget.passengers.values.reduce((a, b) => a + b);

  int get _totalBaggageCount {
    int total = 0;
    widget.baggageSelections.forEach((_, baggageMap) {
      baggageMap.forEach((_, qty) => total += qty);
    });
    return total;
  }

  final List<Map<String, dynamic>> _paymentMethods = [
    {'id': 1, 'name': 'Cash', 'icon': Icons.money},
    {'id': 2, 'name': 'Credit Card', 'icon': Icons.credit_card},
    {'id': 3, 'name': 'Debit Card', 'icon': Icons.credit_card},
    {'id': 4, 'name': 'Bank Transfer', 'icon': Icons.account_balance},
  ];

  bool _isFormValid() {
    if (_selectedPaymentMethod == null) return false;
    
    if (_selectedPaymentStatus == 'partially_paid') {
      if (_depositAmount <= 0) return false;
      if (_depositAmount >= widget.totalPrice) return false;
    }
    
    return true;
  }

  void _completeBooking() {
    if (!_isFormValid()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill in all required fields'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }


    context.go('/');
  }

  @override
  Widget build(BuildContext context) {
    return ResponsiveLayout(
      header: BookingProgressHeader(
        fromCity: widget.fromCity,
        toCity: widget.toCity,
        departDate: widget.departDate,
        returnDate: widget.returnDate,
        totalPassengers: _totalPassengers,
        flightClass: widget.flightClass,
        currentStep: 'payment',
        airlineName: widget.airlineName,
        baggageCount: _totalBaggageCount > 0 ? _totalBaggageCount : null,
        onBack: () => context.pop(),
        onForward: null,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 16),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: PaymentStatusSelector(
                selectedStatus: _selectedPaymentStatus,
                onStatusChanged: (status) {
                  setState(() {
                    _selectedPaymentStatus = status;
                  });
                },
                totalAmount: widget.totalPrice,
              ),
            ),

            const SizedBox(height: 24),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _selectedPaymentStatus == 'paid'
                  ? PaidPaymentForm(
                      totalAmount: widget.totalPrice,
                      selectedPaymentMethod: _selectedPaymentMethod,
                      paymentMethods: _paymentMethods,
                      onPaymentMethodChanged: (method) {
                        setState(() {
                          _selectedPaymentMethod = method;
                        });
                      },
                    )
                  : PartiallyPaidPaymentForm(
                      totalAmount: widget.totalPrice,
                      depositAmount: _depositAmount,
                      onDepositChanged: (amount) {
                        setState(() {
                          _depositAmount = amount;
                        });
                      },
                      selectedPaymentMethod: _selectedPaymentMethod,
                      paymentMethods: _paymentMethods,
                      onPaymentMethodChanged: (method) {
                        setState(() {
                          _selectedPaymentMethod = method;
                        });
                      },
                    ),
            ),

            const SizedBox(height: 24),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Align(
                alignment: Alignment.centerRight,
                child: SizedBox(
                  width: 220,
                  child: CustomButton(
                    label: 'Complete Booking',
                    onPressed: _isFormValid() ? _completeBooking : null,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 48),
          ],
        ),
      ),
    );
  }
}