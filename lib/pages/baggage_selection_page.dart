import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../widgets/responsive_layout.dart';
import '../widgets/passenger_form_card/passenger_form_card.dart';
import '/widgets/custom/custom_button.dart';
import '../models/baggage_model.dart';
import '../widgets/booking/booking_progress_header.dart';
import '../widgets/booking/price_summary_card.dart';
import '../widgets/booking/passenger_selector_bar.dart';
import '../widgets/booking/baggage_options_section.dart';
import '../services/auth_service.dart';
import '../services/baggage_api_service.dart';
import '../models/booking_group_draft.dart';

class BaggageSelectionPage extends StatefulWidget {
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
  final List<Map<String, dynamic>> outboundAssignments;
  final List<Map<String, dynamic>> returnAssignments;
  final int outboundFlightClassId;
  final BookingGroupDraft? bookingGroupDraft;
  final int segmentIndex;
  final Map<int, Map<String, dynamic>>? initialPassengerData;
  final int? bookingId;
  final String? bookingNumber;
  final int? bookingId2;
  final String? bookingNumber2;
  final DateTime? expiresAt;
  final int? leg2FlightClassId;
  final String? leg2FromCity;
  final String? leg2ToCity;

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
    required this.outboundAssignments,
    this.returnAssignments = const [],
    required this.outboundFlightClassId,
    this.bookingGroupDraft,
    this.segmentIndex = 0,
    this.initialPassengerData,
    this.bookingId,
    this.bookingNumber,
    this.bookingId2,
    this.bookingNumber2,
    this.expiresAt,
    this.leg2FlightClassId,
    this.leg2FromCity,
    this.leg2ToCity,
  });

  @override
  State<BaggageSelectionPage> createState() => _BaggageSelectionPageState();
}

class _BaggageSelectionPageState extends State<BaggageSelectionPage> {
  final Map<int, Map<int, int>> _passengerBaggageSelections = {};
  final Map<int, Map<String, dynamic>> _passengerData = {};
  final Set<int> _removedPassengerIndices = {};
  int _currentPassengerIndex = 0;
  bool _hasVisitedPayment = false;

  late final String _sessionId;

  List<BaggagePricingInFlight> _baggageOptions = [];
  bool _baggageLoading = true;
  String? _baggageError;

  List<BaggagePricingInFlight> _leg2BaggageOptions = [];
  final Map<int, Map<int, int>> _passengerLeg2BaggageSelections = {};

  final Map<int, String> _searchDocumentNumbers = {};

  String get _classLabel {
    final classes = widget.passengerClassLabels.values.toSet();
    if (classes.isEmpty) return '';
    if (classes.length == 1) return classes.first;
    return 'Mixed class';
  }

  @override
  void initState() {
    super.initState();
    _sessionId = 'booking_${widget.fromAirportCode}_${widget.toAirportCode}'
        '_${widget.departDate.millisecondsSinceEpoch}';

    final totalPassengers = widget.passengers.values.reduce((a, b) => a + b);
    for (int i = 0; i < totalPassengers; i++) {
      _passengerBaggageSelections[i] = {};
      _passengerLeg2BaggageSelections[i] = {};
      _passengerData[i] = {};
    }

    if (widget.initialPassengerData != null) {
      for (final entry in widget.initialPassengerData!.entries) {
        _passengerData[entry.key] = Map<String, dynamic>.from(entry.value);
        _passengerData[entry.key]?['is_saved'] = true;
      }
    }

    _loadBaggageOptions();
  }

  Future<void> _loadBaggageOptions() async {
    setState(() {
      _baggageLoading = true;
      _baggageError = null;
    });

    try {
      final authService = context.read<AuthService>();
      final service = BaggageApiService(authService);
      final isMultiSegment = widget.leg2FlightClassId != null;

      if (isMultiSegment) {
        final results = await Future.wait([
          service.getBaggageOptions(
              flightClassId: widget.outboundFlightClassId),
          service.getBaggageOptions(
              flightClassId: widget.leg2FlightClassId!),
        ]);
        if (!mounted) return;
        setState(() {
          _baggageOptions = results[0];
          _leg2BaggageOptions = results[1];
          _baggageLoading = false;
        });
      } else {
        final options = await service.getBaggageOptions(
          flightClassId: widget.outboundFlightClassId,
        );
        if (!mounted) return;
        setState(() {
          _baggageOptions = options;
          _baggageLoading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _baggageError = 'Could not load baggage options';
        _baggageLoading = false;
      });
    }
  }

  String _getPassengerLabel(int index) {
    final adultsCount   = widget.passengers['adults']   ?? 0;
    final childrenCount = widget.passengers['children'] ?? 0;
    if (index < adultsCount) {
      return 'Adult ${index + 1}';
    }
    if (index < adultsCount + childrenCount) {
      return 'Child ${index - adultsCount + 1}';
    }
    return 'Infant ${index - adultsCount - childrenCount + 1}';
  }

  String _getPassengerType(int index) {
    final adultsCount = widget.passengers['adults'] ?? 0;
    final childrenCount = widget.passengers['children'] ?? 0;
    if (index < adultsCount) return 'Adult';
    if (index < adultsCount + childrenCount) return 'Child';
    return 'Infant';
  }

  int get _totalPassengers =>
      widget.passengers.values.reduce((a, b) => a + b);

  void _removePassenger(int index) {
    final isLastAdult = _isLastAdult(index);

    if (isLastAdult) {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          icon: const Icon(Icons.warning_amber_outlined,
              color: Colors.orange),
          title: const Text('Cancel Booking?'),
          content: const Text(
            'This is the only adult passenger in the booking. '
            'Removing them will cancel the entire booking process.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Keep'),
            ),
            FilledButton(
              style:
                  FilledButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () {
                Navigator.of(context).pop();
                context.go('/sales/bookings');
              },
              child: const Text('Cancel Booking'),
            ),
          ],
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        icon: const Icon(Icons.person_remove_outlined,
            color: Colors.orange),
        title: const Text('Remove Passenger?'),
        content: Text(
          'Are you sure you want to remove ${_getPassengerDisplayName(index)} '
          'from this booking?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              Navigator.of(context).pop();
              setState(() {
                _removedPassengerIndices.add(index);
                _passengerData.remove(index);
                _passengerBaggageSelections.remove(index);
                _searchDocumentNumbers.remove(index);
                if (_currentPassengerIndex == index) {
                  _currentPassengerIndex = _getFirstActiveIndex();
                }
              });
            },
            child: const Text('Remove'),
          ),
        ],
      ),
    );
  }

  bool _isLastAdult(int excludeIndex) {
    final adultsCount = widget.passengers['adults'] ?? 0;
    int activeAdults = 0;
    for (int i = 0; i < adultsCount; i++) {
      if (i != excludeIndex &&
          !_removedPassengerIndices.contains(i)) {
        activeAdults++;
      }
    }
    return activeAdults == 0;
  }

  int _getFirstActiveIndex() {
    for (int i = 0; i < _totalPassengers; i++) {
      if (!_removedPassengerIndices.contains(i)) return i;
    }
    return 0;
  }

  int get _totalBaggageCount {
    int total = 0;
    _passengerBaggageSelections.forEach((_, baggageMap) {
      baggageMap.forEach((_, qty) => total += qty);
    });
    return total;
  }

  double get _totalBaggagePrice {
    double total = 0;
    _passengerBaggageSelections.forEach((_, baggageMap) {
      baggageMap.forEach((baggageId, quantity) {
        final option = _baggageOptions.firstWhere(
          (opt) => opt.baggagePricingInFlightId == baggageId,
          orElse: () => _baggageOptions.first,
        );
        total += (option.baggagePrice ?? 0) * quantity;
      });
    });
    return total;
  }

  double get _grandTotal => widget.basePrice + _totalBaggagePrice;

  bool _isFormValid() {
    if (!_hasAdultPassenger()) return false;
    for (int i = 0; i < _totalPassengers; i++) {
      if (_removedPassengerIndices.contains(i)) continue;
      final data = _passengerData[i];
      if (data == null || data.isEmpty) return false;
      if (data['is_saved'] != true) return false;

      final requiredFields = [
        'first_name',
        'last_name',
        'date_of_birth',
        'document_number',
        'document_expire',
        'citizenship_id',
        'document_type_id',
      ];

      for (var field in requiredFields) {
        if (data[field] == null ||
            data[field].toString().trim().isEmpty) {
          return false;
        }
      }
    }
    return true;
  }

  String _getPassengerDisplayName(int index) {
    final data = _passengerData[index];
    if (data == null ||
        data.isEmpty ||
        data['first_name'] == null ||
        data['first_name'].toString().isEmpty) {
      return _getPassengerLabel(index);
    }
    final firstName = data['first_name'].toString();
    bool hasDuplicate = false;
    for (int i = 0; i < _totalPassengers; i++) {
      if (i != index) {
        final otherData = _passengerData[i];
        if (otherData != null &&
            otherData['first_name']?.toString().toLowerCase() ==
                firstName.toLowerCase()) {
          hasDuplicate = true;
          break;
        }
      }
    }
    if (hasDuplicate &&
        data['last_name'] != null &&
        data['last_name'].toString().isNotEmpty) {
      return '$firstName ${data['last_name']}';
    }
    return firstName;
  }

  void _handleBaggageQuantityChanged(
      int optionId, int qty, bool isLeg2) {
    setState(() {
      if (isLeg2) {
        if (qty == 0) {
          _passengerLeg2BaggageSelections[_currentPassengerIndex]
              ?.remove(optionId);
        } else {
          _passengerLeg2BaggageSelections[_currentPassengerIndex] ??= {};
          if (qty == 1) {
            _passengerLeg2BaggageSelections[_currentPassengerIndex]!
                .clear();
          }
          _passengerLeg2BaggageSelections[_currentPassengerIndex]![
              optionId] = qty;
        }
      } else {
        if (qty == 0) {
          _passengerBaggageSelections[_currentPassengerIndex]
              ?.remove(optionId);
        } else {
          _passengerBaggageSelections[_currentPassengerIndex] ??= {};
          if (qty == 1) {
            _passengerBaggageSelections[_currentPassengerIndex]!.clear();
          }
          _passengerBaggageSelections[_currentPassengerIndex]![optionId] =
              qty;
        }
      }
    });
  }

  void _navigateToPayment() {
    setState(() => _hasVisitedPayment = true);

    if (widget.bookingGroupDraft != null &&
        widget.leg2FlightClassId != null) {
      var updatedDraft = widget.bookingGroupDraft!.withBaggageForSegment(
        0,
        _passengerBaggageSelections,
      );
      updatedDraft = updatedDraft.withBaggageForSegment(
        1,
        _passengerLeg2BaggageSelections,
      );

      final seg1 = updatedDraft.firstSegment;
      final seg2 = updatedDraft.secondSegment!;

      context.push('/payment', extra: {
        'from_city': seg1.fromCity,
        'to_city': seg2.toCity,
        'depart_date': seg1.departDate.toIso8601String(),
        'passengers': widget.passengers,
        'passenger_class_labels': seg1.passengerClassLabels,
        'airline_name': seg1.airlineName,
        'airline_logo_url': seg1.airlineLogoUrl,
        'from_airport_code': seg1.fromAirportCode,
        'to_airport_code': seg2.toAirportCode,
        'departure_time': seg1.departureTime,
        'arrival_time': seg2.arrivalTime,
        'duration': seg1.duration,
        'base_price': updatedDraft.totalPrice,
        'is_round_trip': false,
        'baggage_selections': _passengerBaggageSelections,
        'passenger_data': _passengerData,
        'total_price': updatedDraft.totalPrice,
        'session_id': _sessionId,
        'outbound_assignments': seg1.assignments,
        'return_assignments': const [],
        'removed_passenger_indices': _removedPassengerIndices.toList(),
        'booking_group_draft': updatedDraft,
        'is_multi_segment': true,
        'booking_id': widget.bookingId,
        'booking_number': widget.bookingNumber,
        'booking_id2': widget.bookingId2,
        'booking_number2': widget.bookingNumber2,
        'expires_at': widget.expiresAt?.toIso8601String(),
      });
      return;
    }

    context.push('/payment', extra: {
      'from_city': widget.fromCity,
      'to_city': widget.toCity,
      'depart_date': widget.departDate.toIso8601String(),
      'return_date': widget.returnDate?.toIso8601String(),
      'passengers': widget.passengers,
      'passenger_class_labels': widget.passengerClassLabels,
      'airline_name': widget.airlineName,
      'airline_logo_url': widget.airlineLogoUrl,
      'from_airport_code': widget.fromAirportCode,
      'to_airport_code': widget.toAirportCode,
      'departure_time': widget.departureTime,
      'arrival_time': widget.arrivalTime,
      'duration': widget.duration,
      'base_price': widget.basePrice,
      'is_round_trip': widget.isRoundTrip,
      'baggage_selections': _passengerBaggageSelections,
      'passenger_data': _passengerData,
      'total_price': _grandTotal,
      'session_id': _sessionId,
      'outbound_assignments': widget.outboundAssignments,
      'return_assignments': widget.returnAssignments,
      'removed_passenger_indices': _removedPassengerIndices.toList(),
      'booking_id': widget.bookingId,
      'booking_number': widget.bookingNumber,
      'booking_id2': widget.bookingId2,
      'booking_number2': widget.bookingNumber2,
      'expires_at': widget.expiresAt?.toIso8601String(),
    });
  }

  bool _hasAdultPassenger() {
    for (int i = 0; i < _totalPassengers; i++) {
      if (_removedPassengerIndices.contains(i)) continue;
      final data = _passengerData[i];
      if (data == null || data['date_of_birth'] == null) continue;

      final DateTime birthDate = data['date_of_birth'];
      final DateTime referenceDate = widget.departDate;

      int age = referenceDate.year - birthDate.year;
      if (referenceDate.month < birthDate.month ||
          (referenceDate.month == birthDate.month &&
              referenceDate.day < birthDate.day)) {
        age--;
      }

      if (age >= 18) return true;
    }
    return false;
  }

  Set<String> _getSavedDocumentNumbers(int excludeIndex) {
    final result = <String>{};
    for (final entry in _passengerData.entries) {
      if (entry.key == excludeIndex) continue;
      final doc =
          entry.value['document_number']?.toString() ?? '';
      final isSaved = entry.value['is_saved'] == true;
      if (isSaved && doc.isNotEmpty) result.add(doc);
    }
    return result;
  }

  Widget _buildPriceSummary(BuildContext context) {
    final List<PassengerPriceItem> passengerPrices = [];
    final isMultiSegment = widget.leg2FlightClassId != null;

    for (int i = 0; i < _totalPassengers; i++) {
      if (_removedPassengerIndices.contains(i)) continue;
      final passengerLabel = _getPassengerDisplayName(i);
      double passengerFlightPrice =
          widget.basePrice / _totalPassengers;
      double passengerBaggagePrice = 0;

      final baggageMap = _passengerBaggageSelections[i] ?? {};
      baggageMap.forEach((baggageId, quantity) {
        if (_baggageOptions.isNotEmpty) {
          final option = _baggageOptions.firstWhere(
            (opt) => opt.baggagePricingInFlightId == baggageId,
            orElse: () => _baggageOptions.first,
          );
          passengerBaggagePrice +=
              (option.baggagePrice ?? 0) * quantity;
        }
      });

      if (isMultiSegment) {
        final leg2BaggageMap =
            _passengerLeg2BaggageSelections[i] ?? {};
        leg2BaggageMap.forEach((baggageId, quantity) {
          if (_leg2BaggageOptions.isNotEmpty) {
            final option = _leg2BaggageOptions.firstWhere(
              (opt) => opt.baggagePricingInFlightId == baggageId,
              orElse: () => _leg2BaggageOptions.first,
            );
            passengerBaggagePrice +=
                (option.baggagePrice ?? 0) * quantity;
          }
        });
      }

      final baggageCount = baggageMap.values
              .fold<int>(0, (sum, qty) => sum + qty) +
          (isMultiSegment
              ? (_passengerLeg2BaggageSelections[i] ?? {})
                  .values
                  .fold<int>(0, (sum, qty) => sum + qty)
              : 0);

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

  @override
  Widget build(BuildContext context) {
    final authService = context.read<AuthService>();

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
        baggageCount:
            _totalBaggageCount > 0 ? _totalBaggageCount : null,
        expiresAt: widget.expiresAt,
        onExpired: () => context.go('/sales/bookings'),
        onBack: () {
          if (context.canPop()) {
            context.pop();
          } else {
            context.go('/sales/bookings');
          }
        },
        onForward:
            (widget.segmentIndex == 0 || _hasVisitedPayment) &&
                    _isFormValid()
                ? _navigateToPayment
                : null,
      ),
      body: ListView(
        physics: const BouncingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics(),
        ),
        padding: const EdgeInsets.only(bottom: 48),
        children: [
          const SizedBox(height: 16),
          PassengerSelectorBar(
            totalPassengers: _totalPassengers,
            currentPassengerIndex: _currentPassengerIndex,
            removedPassengerIndices: _removedPassengerIndices,
            passengerData: _passengerData,
            passengerBaggageSelections: _passengerBaggageSelections,
            passengerClassLabels: widget.passengerClassLabels,
            passengers: widget.passengers,
            onPassengerSelected: (index) =>
                setState(() => _currentPassengerIndex = index),
            onPassengerRemoved: _removePassenger,
          ),
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: PassengerFormCard(
              passengerIndex: _currentPassengerIndex,
              passengerType:
                  _getPassengerType(_currentPassengerIndex),
              initialData:
                  _passengerData[_currentPassengerIndex] ?? {},
              authService: authService,
              sessionId: _sessionId,
              departDate: widget.departDate,
              usedDocumentNumbers:
                  _getSavedDocumentNumbers(_currentPassengerIndex),
              searchDocumentNumber:
                  _searchDocumentNumbers[_currentPassengerIndex] ?? '',
              onSearchDocumentChanged: (val) => setState(() =>
                  _searchDocumentNumbers[_currentPassengerIndex] = val),
              onDataChanged: (data) => setState(
                  () => _passengerData[_currentPassengerIndex] = data),
            ),
          ),
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Select baggage for ${_getPassengerLabel(_currentPassengerIndex)}',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold),
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
                      color: Theme.of(context)
                          .colorScheme
                          .onSurfaceVariant,
                    ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          BaggageOptionsSection(
            baggageOptions: _baggageOptions,
            leg2BaggageOptions: _leg2BaggageOptions,
            isLoading: _baggageLoading,
            error: _baggageError,
            isMultiSegment: widget.leg2FlightClassId != null,
            currentPassengerIndex: _currentPassengerIndex,
            passengerBaggageSelections: _passengerBaggageSelections,
            passengerLeg2BaggageSelections:
                _passengerLeg2BaggageSelections,
            fromCity: widget.fromCity,
            toCity: widget.toCity,
            leg2FromCity: widget.leg2FromCity,
            leg2ToCity: widget.leg2ToCity,
            onRetry: _loadBaggageOptions,
            onQuantityChanged: _handleBaggageQuantityChanged,
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  SizedBox(
                    width: 220,
                    child: CustomButton(
                      label: widget.bookingGroupDraft != null &&
                              widget.segmentIndex == 0
                          ? 'Continue to Next Flight'
                          : 'Proceed to Payment',
                      onPressed:
                          _isFormValid() ? _navigateToPayment : null,
                    ),
                  ),
                  if (!_isFormValid() &&
                      _passengerData.values
                          .any((d) => d.isNotEmpty))
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        'Please save all passenger forms before proceeding to payment.',
                        style: TextStyle(
                          color:
                              Theme.of(context).colorScheme.error,
                          fontSize: 12,
                        ),
                        textAlign: TextAlign.right,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}