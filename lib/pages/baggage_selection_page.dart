import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../widgets/responsive_layout.dart';
import '../widgets/booking/baggage_option_card.dart';
import '../widgets/custom/passenger_form_card/passenger_form_card.dart';
import '/widgets/custom/custom_button.dart';
import '../models/baggage_models.dart';
import '../widgets/booking/booking_progress_header.dart';
import '../widgets/booking/price_summary_card.dart';
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
  int? _hoveredPassengerIndex;
  bool _hasVisitedPayment = false;

  late final String _sessionId;

  List<BaggagePricingInFlight> _baggageOptions = [];
  bool _baggageLoading = true;
  String? _baggageError;

  List<BaggagePricingInFlight> _leg2BaggageOptions = [];
  Map<int, Map<int, int>> _passengerLeg2BaggageSelections = {};

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
    debugPrint('leg2FlightClassId: ${widget.leg2FlightClassId}');
    debugPrint('bookingGroupDraft: ${widget.bookingGroupDraft}');

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
        _passengerData[entry.key]?['isSaved'] = true;
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
          service.getBaggageOptions(flightClassId: widget.outboundFlightClassId),
          service.getBaggageOptions(flightClassId: widget.leg2FlightClassId!),
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
  int get _activePassengers => _totalPassengers - _removedPassengerIndices.length;

  void _removePassenger(int index) {
    final isLastAdult = _isLastAdult(index);

    if (isLastAdult) {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          icon: const Icon(Icons.warning_amber_outlined, color: Colors.orange),
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
              style: FilledButton.styleFrom(backgroundColor: Colors.red),
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
        icon: const Icon(Icons.person_remove_outlined, color: Colors.orange),
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
    if (i != excludeIndex && !_removedPassengerIndices.contains(i)) {
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

  int _getTotalBaggageForPassenger(int passengerIndex) =>
      _passengerBaggageSelections[passengerIndex]
          ?.values
          .fold<int>(0, (sum, qty) => sum + qty) ??
      0;

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
          (opt) => opt.id == baggageId,
          orElse: () => _baggageOptions.first,
        );
        total += option.price * quantity;
      });
    });
    return total;
  }

  double get _grandTotal => widget.basePrice + _totalBaggagePrice;

  bool _isFormValid() {
    if (!_hasAdultPassenger()) return false;
    debugPrint('=== _isFormValid ===');
    for (int i = 0; i < _totalPassengers; i++) {
      if (_removedPassengerIndices.contains(i)) continue;
      final data = _passengerData[i];
      debugPrint('Passenger $i: isSaved=${data?['isSaved']}, data=$data');

      if (data == null || data.isEmpty) return false;

      if (data['isSaved'] != true) return false;

      final requiredFields = [
        'firstName',
        'lastName',
        'dateOfBirth',
        'documentNumber',
        'documentExpire',
        'citizenshipId',
        'documentTypeId',
      ];

      for (var field in requiredFields) {
        if (data[field] == null || data[field].toString().trim().isEmpty) {
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
        data['firstName'] == null ||
        data['firstName'].toString().isEmpty) {
      return _getPassengerLabel(index);
    }
    final firstName = data['firstName'].toString();
    bool hasDuplicate = false;
    for (int i = 0; i < _totalPassengers; i++) {
      if (i != index) {
        final otherData = _passengerData[i];
        if (otherData != null &&
            otherData['firstName']?.toString().toLowerCase() ==
                firstName.toLowerCase()) {
          hasDuplicate = true;
          break;
        }
      }
    }
    if (hasDuplicate &&
        data['lastName'] != null &&
        data['lastName'].toString().isNotEmpty) {
      return '$firstName ${data['lastName']}';
    }
    return firstName;
  }

  void _navigateToPayment() {
    setState(() => _hasVisitedPayment = true);

    if (widget.bookingGroupDraft != null && widget.leg2FlightClassId != null) {
      var updatedDraft = widget.bookingGroupDraft!.withBaggageForSegment(
        0, _passengerBaggageSelections,
      );
      updatedDraft = updatedDraft.withBaggageForSegment(
        1, _passengerLeg2BaggageSelections,
      );

      final seg1 = updatedDraft.firstSegment;
      final seg2 = updatedDraft.secondSegment!;

      context.push('/payment', extra: {
        'fromCity': seg1.fromCity,
        'toCity': seg2.toCity,
        'departDate': seg1.departDate.toIso8601String(),
        'passengers': widget.passengers,
        'passengerClassLabels': seg1.passengerClassLabels,
        'airlineName': seg1.airlineName,
        'airlineLogoUrl': seg1.airlineLogoUrl,
        'fromAirportCode': seg1.fromAirportCode,
        'toAirportCode': seg2.toAirportCode,
        'departureTime': seg1.departureTime,
        'arrivalTime': seg2.arrivalTime,
        'duration': seg1.duration,
        'basePrice': updatedDraft.totalPrice,
        'isRoundTrip': false,
        'baggageSelections': _passengerBaggageSelections,
        'passengerData': _passengerData,
        'totalPrice': updatedDraft.totalPrice,
        'sessionId': _sessionId,
        'outboundAssignments': seg1.assignments,
        'returnAssignments': const [],
        'removedPassengerIndices': _removedPassengerIndices.toList(),
        'bookingGroupDraft': updatedDraft,
        'isMultiSegment': true,
        'bookingId': widget.bookingId,
        'bookingNumber': widget.bookingNumber,
        'bookingId2': widget.bookingId2,
        'bookingNumber2': widget.bookingNumber2,
        'expiresAt': widget.expiresAt?.toIso8601String(),
      });
      return;
    }

    context.push('/payment', extra: {
      'fromCity': widget.fromCity,
      'toCity': widget.toCity,
      'departDate': widget.departDate.toIso8601String(),
      'returnDate': widget.returnDate?.toIso8601String(),
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
      'sessionId': _sessionId,
      'outboundAssignments': widget.outboundAssignments,
      'returnAssignments': widget.returnAssignments,
      'removedPassengerIndices': _removedPassengerIndices.toList(),
      'bookingId': widget.bookingId,
      'bookingNumber': widget.bookingNumber,
      'bookingId2': widget.bookingId2,
      'bookingNumber2': widget.bookingNumber2,
      'expiresAt': widget.expiresAt?.toIso8601String(),
    });
  }


  bool _hasAdultPassenger() {
    for (int i = 0; i < _totalPassengers; i++) {
      if (_removedPassengerIndices.contains(i)) continue;
      final data = _passengerData[i];
      if (data == null || data['dateOfBirth'] == null) continue;

      final DateTime birthDate = data['dateOfBirth'];
      final DateTime referenceDate = widget.departDate;

      int age = referenceDate.year - birthDate.year;
      if (referenceDate.month < birthDate.month ||
          (referenceDate.month == birthDate.month && referenceDate.day < birthDate.day)) {
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
      final doc = entry.value['documentNumber']?.toString() ?? '';
      final isSaved = entry.value['isSaved'] == true;
      if (isSaved && doc.isNotEmpty) result.add(doc);
    }
    return result;
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
        baggageCount: _totalBaggageCount > 0 ? _totalBaggageCount : null,
        expiresAt: widget.expiresAt,
        onExpired: () => context.go('/sales/bookings'),
        onBack: () {
          if (context.canPop()) {
            context.pop();
          } else {
            context.go('/sales/bookings'); 
          }
        },
        onForward: (widget.segmentIndex == 0 || _hasVisitedPayment) && _isFormValid()
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
          _buildPassengerSelector(context),
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: PassengerFormCard(
              passengerIndex: _currentPassengerIndex,
              passengerType: _getPassengerType(_currentPassengerIndex),
              initialData: _passengerData[_currentPassengerIndex] ?? {},
              authService: authService,
              sessionId: _sessionId,
              departDate: widget.departDate,
              usedDocumentNumbers: _getSavedDocumentNumbers(_currentPassengerIndex),
              searchDocumentNumber: _searchDocumentNumbers[_currentPassengerIndex] ?? '',
              onSearchDocumentChanged: (val) => setState(() =>
                  _searchDocumentNumbers[_currentPassengerIndex] = val),
              onDataChanged: (data) =>
                  setState(() => _passengerData[_currentPassengerIndex] = data),
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
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          _buildBaggageOptions(context),
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
                      label: widget.bookingGroupDraft != null && widget.segmentIndex == 0
                          ? 'Continue to Next Flight'
                          : 'Proceed to Payment',
                      onPressed: _isFormValid() ? _navigateToPayment : null,
                    ),
                  ),
                  if (!_isFormValid() && _passengerData.values.any((d) => d.isNotEmpty))
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        'Please save all passenger forms before proceeding to payment.',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
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

  Widget _buildBaggageOptions(BuildContext context) {
  if (_baggageLoading) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 32),
      child: Center(child: CircularProgressIndicator()),
    );
  }

  if (_baggageError != null) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          Text(_baggageError!,
              style: TextStyle(color: Theme.of(context).colorScheme.error)),
          const SizedBox(height: 8),
          TextButton(onPressed: _loadBaggageOptions, child: const Text('Try again')),
        ],
      ),
    );
  }

  final isMultiSegment = widget.leg2FlightClassId != null;

  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Leg 1 або звичайний рейс
        if (isMultiSegment) ...[
          _buildSegmentLabel(context, 'LEG 1  ${widget.fromCity} → ${widget.toCity}'),
          const SizedBox(height: 12),
        ],
        if (_baggageOptions.isEmpty)
          Text('No baggage options available.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant))
        else
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: _baggageOptions.map((option) {
              final qty = _passengerBaggageSelections[_currentPassengerIndex]?[option.id] ?? 0;
              return BaggageOptionCard(
                option: option,
                quantity: qty,
                isDisabled: false,
                onCardTap: () {
                  if (qty > 0) return;
                  setState(() {
                    _passengerBaggageSelections[_currentPassengerIndex]?.clear();
                    _passengerBaggageSelections[_currentPassengerIndex] ??= {};
                    _passengerBaggageSelections[_currentPassengerIndex]![option.id] = 1;
                  });
                },
                onIncrement: () {
                  if (qty > 0 && qty < 3) {
                    setState(() => _passengerBaggageSelections[_currentPassengerIndex]![option.id] = qty + 1);
                  }
                },
                onDecrement: () {
                  if (qty > 0) {
                    setState(() {
                      final newQty = qty - 1;
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

        // Leg 2
        if (isMultiSegment) ...[
          const SizedBox(height: 24),
          _buildSegmentLabel(context, 'LEG 2  ${widget.leg2FromCity} → ${widget.leg2ToCity}'),
          const SizedBox(height: 12),
          if (_leg2BaggageOptions.isEmpty)
            Text('No baggage options available.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant))
          else
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: _leg2BaggageOptions.map((option) {
                final qty = _passengerLeg2BaggageSelections[_currentPassengerIndex]?[option.id] ?? 0;
                return BaggageOptionCard(
                  option: option,
                  quantity: qty,
                  isDisabled: false,
                  onCardTap: () {
                    if (qty > 0) return;
                    setState(() {
                      _passengerLeg2BaggageSelections[_currentPassengerIndex]?.clear();
                      _passengerLeg2BaggageSelections[_currentPassengerIndex] ??= {};
                      _passengerLeg2BaggageSelections[_currentPassengerIndex]![option.id] = 1;
                    });
                  },
                  onIncrement: () {
                    if (qty > 0 && qty < 3) {
                      setState(() => _passengerLeg2BaggageSelections[_currentPassengerIndex]![option.id] = qty + 1);
                    }
                  },
                  onDecrement: () {
                    if (qty > 0) {
                      setState(() {
                        final newQty = qty - 1;
                        if (newQty == 0) {
                          _passengerLeg2BaggageSelections[_currentPassengerIndex]?.remove(option.id);
                        } else {
                          _passengerLeg2BaggageSelections[_currentPassengerIndex]![option.id] = newQty;
                        }
                      });
                    }
                  },
                );
              }).toList(),
            ),
        ],
      ],
    ),
  );
}

  Widget _buildSegmentLabel(BuildContext context, String label) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: colors.primaryContainer.withOpacity(0.4),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: colors.primary,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
      ),
    );
  }


    Widget _buildPassengerSelector(BuildContext context) {
      return SizedBox(
        height: 88,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: _totalPassengers,
          itemBuilder: (context, index) {
            if (_removedPassengerIndices.contains(index)) return const SizedBox.shrink();

            final isSelected = index == _currentPassengerIndex;
            final isHovered = _hoveredPassengerIndex == index;
            final baggageCount = _getTotalBaggageForPassenger(index);
            final hasPassengerData = _passengerData[index]?.isNotEmpty ?? false;
            
            final label = _getPassengerLabel(index);
            final type = _getPassengerType(index); 
            final classLabel = widget.passengerClassLabels[label] ?? '';
            
            String passengerName = label;
            if (hasPassengerData &&
                _passengerData[index]!['firstName']?.toString().isNotEmpty == true) {
              passengerName = _passengerData[index]!['firstName'].toString();
            }

            final subtitleText = classLabel.isNotEmpty ? '$type • $classLabel' : type;

            final IconData passengerIcon = hasPassengerData ? Icons.person : Icons.person_outline;

            return Padding(
              padding: const EdgeInsets.only(right: 12),
              child: MouseRegion(
                onEnter: (_) => setState(() => _hoveredPassengerIndex = index),
                onExit: (_) => setState(() => _hoveredPassengerIndex = null),
                child: Stack(
                  clipBehavior: Clip.none,
                  children:[
                    InkWell(
                      onTap: () => setState(() => _currentPassengerIndex = index),
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                        constraints: const BoxConstraints(maxHeight: 84),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? Theme.of(context).colorScheme.primaryContainer
                              : Theme.of(context).colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected
                                ? Theme.of(context).colorScheme.primary
                                : Colors.transparent,
                            width: 2,
                          ),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children:[
                            Icon(
                              passengerIcon,
                              size: 20,
                              color: isSelected
                                  ? Theme.of(context).colorScheme.onPrimaryContainer
                                  : Theme.of(context).colorScheme.onSurface,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              passengerName,
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    fontWeight: isSelected
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                    color: isSelected
                                        ? Theme.of(context).colorScheme.onPrimaryContainer
                                        : Theme.of(context).colorScheme.onSurface,
                                  ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              subtitleText,
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
                            if (baggageCount > 0) ...[
                              const SizedBox(height: 2),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children:[
                                  Icon(Icons.luggage,
                                      size: 10,
                                      color: Theme.of(context).colorScheme.primary),
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
                    if (isHovered)
                      Positioned(
                        top: -6,
                        right: 6,
                        child: GestureDetector(
                          onTap: () => _removePassenger(index),
                          child: Container(
                            width: 18,
                            height: 18,
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.error,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.close,
                              size: 12,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        ),
      );
    }

    Widget _buildPriceSummary(BuildContext context) {
    final List<PassengerPriceItem> passengerPrices = [];
    final isMultiSegment = widget.leg2FlightClassId != null;

    for (int i = 0; i < _totalPassengers; i++) {
      if (_removedPassengerIndices.contains(i)) continue;
      final passengerLabel = _getPassengerDisplayName(i);
      double passengerFlightPrice = widget.basePrice / _totalPassengers;

      double passengerBaggagePrice = 0;

      final baggageMap = _passengerBaggageSelections[i] ?? {};
      baggageMap.forEach((baggageId, quantity) {
        if (_baggageOptions.isNotEmpty) {
          final option = _baggageOptions.firstWhere(
            (opt) => opt.id == baggageId,
            orElse: () => _baggageOptions.first,
          );
          passengerBaggagePrice += option.price * quantity;
        }
      });

      if (isMultiSegment) {
        final leg2BaggageMap = _passengerLeg2BaggageSelections[i] ?? {};
        leg2BaggageMap.forEach((baggageId, quantity) {
          if (_leg2BaggageOptions.isNotEmpty) {
            final option = _leg2BaggageOptions.firstWhere(
              (opt) => opt.id == baggageId,
              orElse: () => _leg2BaggageOptions.first,
            );
            passengerBaggagePrice += option.price * quantity;
          }
        });
      }

      final baggageCount = baggageMap.values.fold<int>(0, (sum, qty) => sum + qty)
          + (isMultiSegment
              ? (_passengerLeg2BaggageSelections[i] ?? {}).values.fold<int>(0, (sum, qty) => sum + qty)
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

}