import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../widgets/responsive_layout.dart';
import '../widgets/passenger_form_card.dart';
import '../widgets/booking_progress_header.dart';
import '../widgets/custom_button.dart';
import '../models/passenger_model.dart';

class PassengerDetailsPage extends StatefulWidget {
  final String fromCity;
  final String toCity;
  final DateTime departDate;
  final DateTime? returnDate;
  final Map<String, int> passengers;
  final String flightClass;
  final String airlineName;
  final double totalPrice;
  final bool isRoundTrip;

  const PassengerDetailsPage({
    super.key,
    required this.fromCity,
    required this.toCity,
    required this.departDate,
    this.returnDate,
    required this.passengers,
    required this.flightClass,
    required this.airlineName,
    required this.totalPrice,
    required this.isRoundTrip,
  });

  @override
  State<PassengerDetailsPage> createState() => _PassengerDetailsPageState();
}

class _PassengerDetailsPageState extends State<PassengerDetailsPage> {
  final Map<int, Map<String, dynamic>> _passengerData = {};

  // ← ТУТ MOCK ФУНКЦІЯ
  List<PassengerModel> _getMockSavedPassengers() {
    return [
      PassengerModel(
        id: '1',
        firstName: 'John',
        lastName: 'Doe',
        sex: 'Male',
        dateOfBirth: DateTime(1990, 5, 15),
        citizenship: 'Ukraine',
        documentType: 'Passport',
        documentNumber: 'AB123456',
        documentExpire: DateTime(2028, 12, 31),
      ),
      PassengerModel(
        id: '2',
        firstName: 'Jane',
        lastName: 'Smith',
        sex: 'Female',
        dateOfBirth: DateTime(1995, 8, 22),
        citizenship: 'Poland',
        documentType: 'ID Card',
        documentNumber: 'CD789012',
        documentExpire: DateTime(2027, 6, 30),
      ),
    ];
  }

  int get _totalPassengers => widget.passengers.values.reduce((a, b) => a + b);

  String _getPassengerType(int index) {
    final adultsCount = widget.passengers['adults'] ?? 0;
    final childrenCount = widget.passengers['children'] ?? 0;
    
    if (index < adultsCount) {
      return 'Adult';
    } else if (index < adultsCount + childrenCount) {
      return 'Child';
    } else {
      return 'Infant';
    }
  }

  bool _isFormValid() {
    if (_passengerData.length != _totalPassengers) return false;
    
    for (var data in _passengerData.values) {
      if (data['firstName']?.isEmpty ?? true) return false;
      if (data['lastName']?.isEmpty ?? true) return false;
      if (data['dateOfBirth'] == null) return false;
      if (data['documentNumber']?.isEmpty ?? true) return false;
      if (data['documentExpire'] == null) return false;
    }
    
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final savedPassengers = _getMockSavedPassengers();

    return ResponsiveLayout(
      header: BookingProgressHeader(
        fromCity: widget.fromCity,
        toCity: widget.toCity,
        departDate: widget.departDate,
        returnDate: widget.returnDate,
        totalPassengers: _totalPassengers,
        flightClass: widget.flightClass,
        currentStep: 'passengers',
        airlineName: widget.airlineName,
        onBack: () => context.pop(),
      ),
      body: Column(
        children: [
          const SizedBox(height: 16),

          // TITLE
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'Passenger Details',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          const SizedBox(height: 8),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'Please fill in the details for each passenger',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),

          const SizedBox(height: 24),

          // PASSENGER FORMS
          ...List.generate(_totalPassengers, (index) {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: PassengerFormCard(
                passengerIndex: index,
                passengerType: _getPassengerType(index),
                savedPassengers: savedPassengers,
                initialData: _passengerData[index],
                onDataChanged: (data) {
                  setState(() {
                    _passengerData[index] = data;
                  });
                },
              ),
            );
          }),

          const SizedBox(height: 24),

          // PRICE SUMMARY
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Total Price',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '\$${widget.totalPrice.toStringAsFixed(2)}',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // BUTTONS
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => context.pop(),
                    icon: const Icon(Icons.arrow_back),
                    label: const Text('Back'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: CustomButton(
                    label: 'Continue to Payment',
                    onPressed: _isFormValid()
                        ? () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Proceeding to payment...')),
                            );
                          }
                        : null,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 48),
        ],
      ),
    );
  }
}