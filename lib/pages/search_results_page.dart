import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../widgets/responsive_layout.dart';
import '../widgets/flight_route_card.dart';
import '../widgets/booking_progress_header.dart';
import '../models/class.dart';
import '../models/flight_model.dart';
import '../services/booking_api_service.dart';
import '../services/auth_service.dart';
import '../config/routes.dart';

class SearchResultsPage extends StatefulWidget {
  final String fromCity;
  final String toCity;
  final DateTime departDate;
  final DateTime? returnDate;
  final Map<String, int> passengers;
  final Map<int, Class> passengerClasses;

  const SearchResultsPage({
    super.key,
    required this.fromCity,
    required this.toCity,
    required this.departDate,
    this.returnDate,
    required this.passengers,
    required this.passengerClasses,
  });

  @override
  State<SearchResultsPage> createState() => _SearchResultsPageState();
}

class _SearchResultsPageState extends State<SearchResultsPage> {
  List<FlightModel> _flights = [];
  bool _isLoading = true;
  String? _error;

  String get _classLabel {
    final classes = widget.passengerClasses.values.toSet();
    return classes.length == 1 ? classes.first.label : 'Mixed class';
  }

  bool get _isAnyClass =>
      widget.passengerClasses.values.any((c) => c == Class.any);

  Set<String> get _selectedClassNames => widget.passengerClasses.values
      .where((c) => c != Class.any)
      .map((c) => c.label)
      .toSet();

  @override
  void initState() {
    super.initState();
    _loadFlights();
  }

  Future<void> _loadFlights() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final authService = context.read<AuthService>();
      final service = BookingApiService(authService);
      final flights = await service.searchFlights(
        fromCity: widget.fromCity,
        toCity: widget.toCity,
        departDate: widget.departDate,
      );

      final filtered = _isAnyClass
          ? flights
          : flights
              .where((f) => _selectedClassNames.contains(f.className))
              .toList();

      setState(() {
        _flights = filtered;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Map<int, List<FlightModel>> get _groupedFlights {
    final Map<int, List<FlightModel>> grouped = {};
    for (final f in _flights) {
      grouped.putIfAbsent(f.flightId, () => []).add(f);
    }
    return grouped;
  }

  @override
  Widget build(BuildContext context) {
    final isRoundTrip = widget.returnDate != null;
    final totalPassengers = widget.passengers.values.reduce((a, b) => a + b);
    final adultsCount = widget.passengers['adults'] ?? 1;
    final childrenCount = widget.passengers['children'] ?? 0;
    final infantsCount = widget.passengers['infants'] ?? 0;

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
            Text('Failed to load flights',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            TextButton(
                onPressed: _loadFlights, child: const Text('Try again')),
          ],
        ),
      );
    } else if (_flights.isEmpty) {
      body = Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.airplane_ticket, size: 48),
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
      final grouped = _groupedFlights;
      body = ListView(
        children: [
          const SizedBox(height: 16),
          for (final entry in grouped.entries)
            for (final flight in entry.value)
              FlightRouteCard(
                airlineName: flight.airlineName,
                airlineLogoUrl: flight.airlineLogoUrl ?? '',
                flightClass: flight.className,
                fromAirportCode: flight.departsCode,
                toAirportCode: flight.arrivesCode,
                departureTime: flight.departureTime,
                arrivalTime: flight.arrivalTime,
                duration: flight.flightDuration,
                isRoundTrip: isRoundTrip,
                pricePerAdult: flight.ticketPrice,
                adultsCount: adultsCount,
                pricePerChild:
                    childrenCount > 0 ? flight.ticketPrice * 0.75 : null,
                childrenCount: childrenCount > 0 ? childrenCount : null,
                pricePerInfant:
                    infantsCount > 0 ? flight.ticketPrice * 0.1 : null,
                infantsCount: infantsCount > 0 ? infantsCount : null,
                onBook: () {
                  context.push(
                    '/baggage-selection',
                    extra: BaggageSelectionArguments(
                      fromCity: widget.fromCity,
                      toCity: widget.toCity,
                      departDate: widget.departDate,
                      returnDate: widget.returnDate,
                      passengers: widget.passengers,
                      passengerClasses: widget.passengerClasses,
                      airlineName: flight.airlineName,
                      airlineLogoUrl: flight.airlineLogoUrl ?? '',
                      fromAirportCode: flight.departsCode,
                      toAirportCode: flight.arrivesCode,
                      departureTime: flight.departureTime,
                      arrivalTime: flight.arrivalTime,
                      duration: flight.flightDuration,
                      basePrice: flight.ticketPrice * adultsCount +
                          (childrenCount > 0
                              ? flight.ticketPrice * 0.75 * childrenCount
                              : 0) +
                          (infantsCount > 0
                              ? flight.ticketPrice * 0.1 * infantsCount
                              : 0),
                      isRoundTrip: isRoundTrip,
                    ),
                  );
                },
              ),
          const SizedBox(height: 48),
        ],
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
        onBack: () => context.go('/'),
      ),
      body: body,
    );
  }
}