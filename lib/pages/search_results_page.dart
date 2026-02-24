import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../widgets/responsive_layout.dart';
import '../widgets/flight_route_card.dart';
import '../widgets/booking_progress_header.dart';
import '../models/grouped_flight.dart';
import '../models/flight_combo.dart';
import '../utils/flight_combo_builder.dart';
import '../models/class.dart';
import '../services/booking_api_service.dart';
import '../services/auth_service.dart';
import '../config/routes.dart';

class SearchResultsPage extends StatefulWidget {
  final int fromCityId;
  final String fromCity;
  final int toCityId;
  final String toCity;
  final DateTime departDate;
  final DateTime? returnDate;
  final Map<String, int> passengers;

  const SearchResultsPage({
    super.key,
    required this.fromCityId,
    required this.fromCity,
    required this.toCityId,
    required this.toCity,
    required this.departDate,
    this.returnDate,
    required this.passengers,
  });

  @override
  State<SearchResultsPage> createState() => _SearchResultsPageState();
}

class _SearchResultsPageState extends State<SearchResultsPage> {
  List<FlightCombo> _combos = [];
  bool _isLoading = true;
  String? _error;

  // Фільтри — клас для кожного пасажира (всі Any за замовчуванням)
  late Map<int, Class> _passengerClasses;

  bool get _isRoundTrip => widget.returnDate != null;

  @override
  void initState() {
    super.initState();
    _initPassengerClasses();
    _loadFlights();
  }

  void _initPassengerClasses() {
    final total = widget.passengers.values.reduce((a, b) => a + b);
    _passengerClasses = {
      for (int i = 0; i < total; i++) i: Class.any,
    };
  }

  Future<void> _loadFlights() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final authService = context.read<AuthService>();
      final service = BookingApiService(authService);

      final futures = [
        service.searchFlights(
          fromCityId: widget.fromCityId,
          toCityId: widget.toCityId,
          departDate: widget.departDate,
        ),
        if (_isRoundTrip)
          service.searchFlights(
            fromCityId: widget.toCityId,
            toCityId: widget.fromCityId,
            departDate: widget.returnDate!,
          ),
      ];

      final results = await Future.wait(futures);

      final outboundGrouped = GroupedFlight.fromFlightList(results[0]);
      final returnGrouped = _isRoundTrip
          ? GroupedFlight.fromFlightList(results[1])
          : <GroupedFlight>[];

      _rebuildCombos(outboundGrouped, returnGrouped);
    } catch (e) {
      setState(() {
        _error = 'Could not fetch flights. Please try again later.';
        _isLoading = false;
      });
    }
  }

  void _rebuildCombos(
    List<GroupedFlight> outbound,
    List<GroupedFlight> returnFlights,
  ) {
    final combos = FlightComboBuilder.build(
      outboundFlights: outbound,
      returnFlights: returnFlights,
      passengerClasses: _passengerClasses,
      passengers: widget.passengers,
    );
    setState(() {
      _combos = combos;
      _isLoading = false;
    });
  }

  /// Будує Map<String, String> passengerLabel → assignedClass з FlightCombo
  Map<String, String> _buildClassLabels(FlightCombo combo) {
    final Map<String, String> result = {};
    for (final a in combo.outboundAssignments) {
      result[a.passengerLabel] = a.assignedClass;
    }
    return result;
  }

  /// Форматує клас для хедера
  String get _classLabel {
    final classes = _passengerClasses.values.toSet();
    if (classes.every((c) => c == Class.any)) return 'Any class';
    if (classes.length == 1) return classes.first.label;
    return 'Mixed class';
  }

  void _handleBook(FlightCombo resolvedCombo) {
    context.push(
      '/baggage-selection',
      extra: BaggageSelectionArguments(
        fromCity: widget.fromCity,
        toCity: widget.toCity,
        departDate: widget.departDate,
        returnDate: widget.returnDate,
        passengers: widget.passengers,
        passengerClassLabels: _buildClassLabels(resolvedCombo),
        airlineName: resolvedCombo.outbound.airlineName,
        airlineLogoUrl: resolvedCombo.outbound.airlineLogoUrl ?? '',
        fromAirportCode: resolvedCombo.outbound.departsCode,
        toAirportCode: resolvedCombo.outbound.arrivesCode,
        departureTime: resolvedCombo.outbound.departureTime,
        arrivalTime: resolvedCombo.outbound.arrivalTime,
        duration: resolvedCombo.outbound.formattedDuration,
        basePrice: resolvedCombo.totalPrice,
        isRoundTrip: _isRoundTrip,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final totalPassengers = widget.passengers.values.reduce((a, b) => a + b);

    Widget body;

    if (_isLoading) {
      body = const Center(child: CircularProgressIndicator());
    } else if (_error != null) {
      body = Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text(_error!, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            TextButton(onPressed: _loadFlights, child: const Text('Try again')),
          ],
        ),
      );
    } else if (_combos.isEmpty) {
      body = Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.airplane_ticket, size: 48, color: Colors.grey),
            const SizedBox(height: 16),
            Text('No flights found for this route',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text('${widget.fromCity} → ${widget.toCity}',
                style: Theme.of(context).textTheme.bodyMedium),
          ],
        ),
      );
    } else {
      body = ListView.builder(
        padding: const EdgeInsets.only(top: 16, bottom: 48),
        itemCount: _combos.length,
        itemBuilder: (context, index) {
          return FlightRouteCard(
            combo: _combos[index],
            onBook: _handleBook,
          );
        },
      );
    }

    return ResponsiveLayout(
      header: BookingProgressHeader(
        fromCity: widget.fromCity,
        toCity: widget.toCity,
        departDate: widget.departDate,
        returnDate: widget.returnDate,
        totalPassengers: totalPassengers,
        flightClass: _classLabel,
        currentStep: 'search',
        onBack: () => context.go('/sales/bookings'),
      ),
      body: body,
    );
  }
}