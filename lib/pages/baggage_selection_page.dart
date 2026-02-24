import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../widgets/responsive_layout.dart';
import '../widgets/baggage_option_card.dart';
import '/widgets/passenger_form_card.dart';
import '/widgets/custom/custom_button.dart';
import '../models/baggage_models.dart';
import '../models/passenger_model.dart';
import '../widgets/booking_progress_header.dart';
import '../widgets/price_summary_card.dart';

class BaggageSelectionPage extends StatefulWidget {
  final String fromCity;
  final String toCity;
  final DateTime departDate;
  final DateTime? returnDate;
  final Map<String, int> passengers;
  /// passengerLabel → assignedClass, e.g. {'Adult 1': 'Business', 'Child 1': 'Economy'}
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

  const BaggageSelectionPage({
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
  });

  @override
  State<BaggageSelectionPage> createState() => _BaggageSelectionPageState();
}

class _BaggageSelectionPageState extends State<BaggageSelectionPage> {
  final Map<int, Map<int, int>> _passengerBaggageSelections = {};
  final Map<int, Map<String, dynamic>> _passengerData = {};

  int _currentPassengerIndex = 0;
  bool _hasVisitedPayment = false;

  /// Форматуємо клас для хедера
  String get _classLabel {
    final classes = widget.passengerClassLabels.values.toSet();
    if (classes.isEmpty) return '';
    if (classes.length == 1) return classes.first;
    return 'Mixed class';
  }

  @override
  void initState() {
    super.initState();
    final totalPassengers = widget.passengers.values.reduce((a, b) => a + b);
    for (int i = 0; i < totalPassengers; i++) {
      _passengerBaggageSelections[i] = {};
      _passengerData[i] = {};
    }
  }

  List<BaggagePricingInFlight> _getMockBaggageOptions() {
    return [
      BaggagePricingInFlight(
        id: 1, baggagePricingRuleId: 3, flightId: 1, flightClassId: 1,
        price: widget.isRoundTrip ? 100.00 : 50.00,
        rule: const BaggagePricingRule(id: 3, baggageTypeId: 1, dimension: '158x75x70', maxWeight: 23.00, overweightFeePerKg: 250.00),
        type: const BaggageType(id: 1, name: 'Checked baggage'),
      ),
      BaggagePricingInFlight(
        id: 2, baggagePricingRuleId: 5, flightId: 1, flightClassId: 1,
        price: widget.isRoundTrip ? 300.00 : 150.00,
        rule: const BaggagePricingRule(id: 5, baggageTypeId: 2, dimension: '200x80x60', maxWeight: 50.00, overweightFeePerKg: 400.00),
        type: const BaggageType(id: 2, name: 'Oversized baggage'),
      ),
      BaggagePricingInFlight(
        id: 3, baggagePricingRuleId: 7, flightId: 1, flightClassId: 1,
        price: widget.isRoundTrip ? 160.00 : 80.00,
        rule: const BaggagePricingRule(id: 7, baggageTypeId: 3, dimension: '70x50x40', maxWeight: 25.00, overweightFeePerKg: 300.00),
        type: const BaggageType(id: 3, name: 'Fragile baggage'),
      ),
      BaggagePricingInFlight(
        id: 4, baggagePricingRuleId: 9, flightId: 1, flightClassId: 1,
        price: widget.isRoundTrip ? 150.00 : 75.00,
        rule: const BaggagePricingRule(id: 9, baggageTypeId: 4, dimension: '120x80x40', maxWeight: 25.00, overweightFeePerKg: 300.00),
        type: const BaggageType(id: 4, name: 'Sports equipment'),
      ),
      BaggagePricingInFlight(
        id: 5, baggagePricingRuleId: 14, flightId: 1, flightClassId: 1,
        price: widget.isRoundTrip ? 200.00 : 100.00,
        rule: const BaggagePricingRule(id: 14, baggageTypeId: 5, dimension: '100x70x50', maxWeight: 30.00, overweightFeePerKg: 350.00),
        type: const BaggageType(id: 5, name: 'Special baggage'),
      ),
    ];
  }

  List<PassengerModel> _getMockSavedPassengers() {
    return [
      PassengerModel(id: '1', firstName: 'John', lastName: 'Doe', sex: 'Male', dateOfBirth: DateTime(1990, 5, 15), citizenship: 'Ukraine', documentType: 'Passport', documentNumber: 'AB123456', documentExpire: DateTime(2028, 12, 31)),
      PassengerModel(id: '2', firstName: 'Jane', lastName: 'Smith', sex: 'Female', dateOfBirth: DateTime(1995, 8, 22), citizenship: 'Poland', documentType: 'ID Card', documentNumber: 'CD789012', documentExpire: DateTime(2027, 6, 30)),
    ];
  }

  String _getPassengerLabel(int index) {
    final adultsCount = widget.passengers['adults'] ?? 0;
    final childrenCount = widget.passengers['children'] ?? 0;
    if (index < adultsCount) return 'Adult ${index + 1}';
    if (index < adultsCount + childrenCount) return 'Child ${index - adultsCount + 1}';
    return 'Infant ${index - adultsCount - childrenCount + 1}';
  }

  String _getPassengerType(int index) {
    final adultsCount = widget.passengers['adults'] ?? 0;
    final childrenCount = widget.passengers['children'] ?? 0;
    if (index < adultsCount) return 'Adult';
    if (index < adultsCount + childrenCount) return 'Child';
    return 'Infant';
  }

  int get _totalPassengers => widget.passengers.values.reduce((a, b) => a + b);

  int _getTotalBaggageForPassenger(int passengerIndex) =>
      _passengerBaggageSelections[passengerIndex]?.values.fold<int>(0, (sum, qty) => sum + qty) ?? 0;

  int get _totalBaggageCount {
    int total = 0;
    _passengerBaggageSelections.forEach((_, baggageMap) {
      baggageMap.forEach((_, qty) => total += qty);
    });
    return total;
  }

  double get _totalBaggagePrice {
    double total = 0;
    final options = _getMockBaggageOptions();
    _passengerBaggageSelections.forEach((_, baggageMap) {
      baggageMap.forEach((baggageId, quantity) {
        final option = options.firstWhere((opt) => opt.id == baggageId);
        total += option.price * quantity;
      });
    });
    return total;
  }

  double get _grandTotal => widget.basePrice + _totalBaggagePrice;

  bool _isFormValid() {
    for (int i = 0; i < _totalPassengers; i++) {
      final data = _passengerData[i];
      if (data == null || data.isEmpty) return false;
      if (data['firstName'] == null || data['firstName'].toString().isEmpty) return false;
      if (data['lastName'] == null || data['lastName'].toString().isEmpty) return false;
      if (data['dateOfBirth'] == null) return false;
      if (data['documentNumber'] == null || data['documentNumber'].toString().isEmpty) return false;
      if (data['documentExpire'] == null) return false;
    }
    return true;
  }

  String _getPassengerDisplayName(int index) {
    final data = _passengerData[index];
    if (data == null || data.isEmpty || data['firstName'] == null || data['firstName'].toString().isEmpty) {
      return _getPassengerLabel(index);
    }
    final firstName = data['firstName'].toString();
    bool hasDuplicate = false;
    for (int i = 0; i < _totalPassengers; i++) {
      if (i != index) {
        final otherData = _passengerData[i];
        if (otherData != null && otherData['firstName']?.toString().toLowerCase() == firstName.toLowerCase()) {
          hasDuplicate = true;
          break;
        }
      }
    }
    if (hasDuplicate && data['lastName'] != null && data['lastName'].toString().isNotEmpty) {
      return '$firstName ${data['lastName']}';
    }
    return firstName;
  }

  void _navigateToPayment() {
    setState(() => _hasVisitedPayment = true);

    context.push('/payment', extra: {
      'fromCity': widget.fromCity,
      'toCity': widget.toCity,
      'departDate': widget.departDate,
      'returnDate': widget.returnDate,
      'passengers': widget.passengers,
      'passengerClassLabels': widget.passengerClassLabels,
      'airlineName': widget.airlineName,
      'airlineLogoUrl': widget.airlineLogoUrl,
      'fromAirportCode': widget.fromAirportCode,
      'toAirportCode': widget.toAirportCode,
      'departureTime': widget.departureTime,
      'arrivalTime': widget.arrivalTime,
      'duration': widget.duration,
      'basePrice': widget.basePrice,
      'isRoundTrip': widget.isRoundTrip,
      'baggageSelections': _passengerBaggageSelections,
      'passengerData': _passengerData,
      'totalPrice': _grandTotal,
    });
  }

  @override
  Widget build(BuildContext context) {
    final baggageOptions = _getMockBaggageOptions();
    final savedPassengers = _getMockSavedPassengers();

    return ResponsiveLayout(
      header: BookingProgressHeader(
        fromCity: widget.fromCity,
        toCity: widget.toCity,
        departDate: widget.departDate,
        returnDate: widget.returnDate,
        totalPassengers: _totalPassengers,
        flightClass: _classLabel,
        currentStep: 'baggage',
        airlineName: widget.airlineName,
        baggageCount: _totalBaggageCount > 0 ? _totalBaggageCount : null,
        onBack: () => context.pop(),
        onForward: _hasVisitedPayment && _isFormValid() ? _navigateToPayment : null,
      ),
      body: Column(
        children: [
          const SizedBox(height: 16),
          _buildPassengerSelector(context),
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: PassengerFormCard(
              passengerIndex: _currentPassengerIndex,
              passengerType: _getPassengerType(_currentPassengerIndex),
              savedPassengers: savedPassengers,
              initialData: _passengerData[_currentPassengerIndex],
              onDataChanged: (data) => setState(() => _passengerData[_currentPassengerIndex] = data),
            ),
          ),
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Select baggage for ${_getPassengerLabel(_currentPassengerIndex)}',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Select one baggage type (up to 3 items)',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Wrap(
              spacing: 12,
              runSpacing: 12,
              children: baggageOptions.map((option) {
                final currentQuantity = _passengerBaggageSelections[_currentPassengerIndex]?[option.id] ?? 0;
                return BaggageOptionCard(
                  option: option,
                  quantity: currentQuantity,
                  isDisabled: false,
                  onCardTap: () {
                    if (currentQuantity > 0) return;
                    setState(() {
                      _passengerBaggageSelections[_currentPassengerIndex]?.clear();
                      _passengerBaggageSelections[_currentPassengerIndex] ??= {};
                      _passengerBaggageSelections[_currentPassengerIndex]![option.id] = 1;
                    });
                  },
                  onIncrement: () {
                    if (currentQuantity > 0 && currentQuantity < 3) {
                      setState(() => _passengerBaggageSelections[_currentPassengerIndex]![option.id] = currentQuantity + 1);
                    }
                  },
                  onDecrement: () {
                    if (currentQuantity > 0) {
                      setState(() {
                        final newQty = currentQuantity - 1;
                        if (newQty == 0) {
                          _passengerBaggageSelections[_currentPassengerIndex]?.remove(option.id);
                        } else {
                          _passengerBaggageSelections[_currentPassengerIndex]![option.id] = newQty;
                        }
                      });
                    }
                  },
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _buildPriceSummary(context),
          ),
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Align(
              alignment: Alignment.centerRight,
              child: SizedBox(
                width: 220,
                child: CustomButton(
                  label: 'Proceed to Payment',
                  onPressed: _navigateToPayment,
                ),
              ),
            ),
          ),
          const SizedBox(height: 48),
        ],
      ),
    );
  }

  Widget _buildPassengerSelector(BuildContext context) {
    return SizedBox(
      height: 80,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _totalPassengers,
        itemBuilder: (context, index) {
          final isSelected = index == _currentPassengerIndex;
          final baggageCount = _getTotalBaggageForPassenger(index);
          final hasPassengerData = _passengerData[index]?.isNotEmpty ?? false;
          final label = _getPassengerLabel(index);
          final classLabel = widget.passengerClassLabels[label] ?? '';
          String passengerName = label;
          if (hasPassengerData && _passengerData[index]!['firstName']?.toString().isNotEmpty == true) {
            passengerName = _passengerData[index]!['firstName'].toString();
          }

          return Padding(
            padding: const EdgeInsets.only(right: 12),
            child: InkWell(
              onTap: () => setState(() => _currentPassengerIndex = index),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                constraints: const BoxConstraints(maxHeight: 76),
                decoration: BoxDecoration(
                  color: isSelected
                      ? Theme.of(context).colorScheme.primaryContainer
                      : Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected ? Theme.of(context).colorScheme.primary : Colors.transparent,
                    width: 2,
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      hasPassengerData ? Icons.person : Icons.person_outline,
                      size: 20,
                      color: isSelected
                          ? Theme.of(context).colorScheme.onPrimaryContainer
                          : Theme.of(context).colorScheme.onSurface,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      passengerName,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        color: isSelected
                            ? Theme.of(context).colorScheme.onPrimaryContainer
                            : Theme.of(context).colorScheme.onSurface,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (classLabel.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        classLabel,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontSize: 10,
                          color: isSelected
                              ? Theme.of(context).colorScheme.onPrimaryContainer
                              : Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    if (baggageCount > 0) ...[
                      const SizedBox(height: 2),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.luggage, size: 10, color: Theme.of(context).colorScheme.primary),
                          const SizedBox(width: 2),
                          Text(
                            '$baggageCount',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              fontSize: 10,
                              color: Theme.of(context).colorScheme.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildPriceSummary(BuildContext context) {
    final baggageOptions = _getMockBaggageOptions();
    List<PassengerPriceItem> passengerPrices = [];

    for (int i = 0; i < _totalPassengers; i++) {
      final passengerType = _getPassengerType(i);
      final passengerLabel = _getPassengerDisplayName(i);
      double passengerFlightPrice = widget.basePrice / _totalPassengers;
      if (passengerType == 'Child') passengerFlightPrice *= 0.75;
      if (passengerType == 'Infant') passengerFlightPrice *= 0.1;

      double passengerBaggagePrice = 0;
      final baggageMap = _passengerBaggageSelections[i] ?? {};
      baggageMap.forEach((baggageId, quantity) {
        final option = baggageOptions.firstWhere((opt) => opt.id == baggageId);
        passengerBaggagePrice += option.price * quantity;
      });
      final baggageCount = baggageMap.values.fold<int>(0, (sum, qty) => sum + qty);

      passengerPrices.add(PassengerPriceItem(
        passengerType: passengerLabel,
        count: 1,
        totalPrice: passengerFlightPrice + passengerBaggagePrice,
        flightPrice: passengerFlightPrice,
        baggagePrice: passengerBaggagePrice,
        baggageCount: baggageCount,
      ));
    }

    return PriceSummaryCard(
      passengerPrices: passengerPrices,
      totalPrice: _grandTotal,
      showDetailedBaggage: true,
    );
  }
}