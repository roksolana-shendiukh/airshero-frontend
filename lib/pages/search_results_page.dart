import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../widgets/responsive_layout.dart';
import '../widgets/flight_route_card.dart';
import '../widgets/search_results_header.dart';

class SearchResultsPage extends StatefulWidget {
  final String fromCity;
  final String toCity;
  final DateTime departDate;
  final DateTime? returnDate;
  final Map<String, int> passengers;
  final String flightClass;

  const SearchResultsPage({
    super.key,
    required this.fromCity,
    required this.toCity,
    required this.departDate,
    this.returnDate,
    required this.passengers,
    required this.flightClass,
  });

  @override
  State<SearchResultsPage> createState() => _SearchResultsPageState();
}

class _SearchResultsPageState extends State<SearchResultsPage> {
  @override
  Widget build(BuildContext context) {
    final isRoundTrip = widget.returnDate != null;
    final totalPassengers = widget.passengers.values.reduce((a, b) => a + b);
    final adultsCount = widget.passengers['adults'] ?? 1;
    final childrenCount = widget.passengers['children'] ?? 0;
    final infantsCount = widget.passengers['infants'] ?? 0;

    final flights = _getMockFlights();

    return ResponsiveLayout(
      body: Column(
        children: [
          SearchResultsHeader(
            fromCity: widget.fromCity,
            toCity: widget.toCity,
            departDate: widget.departDate,
            returnDate: widget.returnDate,
            totalPassengers: totalPassengers,
            flightClass: widget.flightClass,
            flightsCount: flights.length,
            onBack: () => context.go('/'),
          ),

          const SizedBox(height: 16),

          ...flights.map((flight) {
            return FlightRouteCard(
              airlineName: flight['airline'] as String,
              airlineLogoUrl: flight['logo'] as String,
              flightClass: widget.flightClass,
              fromCity: widget.fromCity,
              toCity: widget.toCity,
              fromAirportCode: 'KBP', // ← ДОДАНО
              toAirportCode: 'LHR',
              departureTime: flight['departTime'] as String,
              arrivalTime: flight['arriveTime'] as String,
              duration: flight['duration'] as String,
              hasBaggage: flight['baggage'] as bool,
              isRoundTrip: isRoundTrip,
              pricePerAdult: flight['priceAdult'] as double,
              adultsCount: adultsCount,
              pricePerChild: childrenCount > 0 ? flight['priceChild'] as double : null,
              childrenCount: childrenCount > 0 ? childrenCount : null,
              pricePerInfant: infantsCount > 0 ? flight['priceInfant'] as double : null,
              infantsCount: infantsCount > 0 ? infantsCount : null,
              onBook: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Booking ${flight['airline']}...'),
                    action: SnackBarAction(
                      label: 'VIEW',
                      onPressed: () {},
                    ),
                  ),
                );
              },
            );
          }),

          const SizedBox(height: 48),
        ],
      ),
    );
  }

  List<Map<String, dynamic>> _getMockFlights() {
  return [
    {
      'airline': 'Ukraine International Airlines',
      'logo': 'https://upload.wikimedia.org/wikipedia/commons/thumb/a/a3/Ukraine_International_Airlines_logo.svg/200px-Ukraine_International_Airlines_logo.svg.png',
      'departTime': '10:30',
      'arriveTime': '14:45',
      'duration': '4h 15m',
      'baggage': true,
      'priceAdult': 350.0,
      'priceChild': 280.0,
      'priceInfant': 50.0,
    },
    {
      'airline': 'Wizz Air',
      'logo': 'https://upload.wikimedia.org/wikipedia/commons/thumb/e/e6/Wizz_Air_logo.svg/200px-Wizz_Air_logo.svg.png',
      'departTime': '06:15',
      'arriveTime': '10:30',
      'duration': '4h 15m',
      'baggage': false,
      'priceAdult': 180.0,
      'priceChild': 150.0,
      'priceInfant': 0.0,
    },
    {
      'airline': 'Lufthansa',
      'logo': 'https://upload.wikimedia.org/wikipedia/commons/thumb/b/b8/Lufthansa_Logo_2018.svg/200px-Lufthansa_Logo_2018.svg.png',
      'departTime': '18:00',
      'arriveTime': '22:15',
      'duration': '4h 15m',
      'baggage': true,
      'priceAdult': 420.0,
      'priceChild': 340.0,
      'priceInfant': 60.0,
    },
    {
      'airline': 'Turkish Airlines',
      'logo': 'https://upload.wikimedia.org/wikipedia/commons/thumb/0/00/Turkish_Airlines_logo_2019_compact.svg/200px-Turkish_Airlines_logo_2019_compact.svg.png',
      'departTime': '13:20',
      'arriveTime': '17:35',
      'duration': '4h 15m',
      'baggage': true,
      'priceAdult': 390.0,
      'priceChild': 310.0,
      'priceInfant': 55.0,
    },
    {
      'airline': 'Ryanair',
      'logo': 'https://upload.wikimedia.org/wikipedia/commons/thumb/6/60/Ryanair_logo.svg/200px-Ryanair_logo.svg.png',
      'departTime': '21:45',
      'arriveTime': '02:00',
      'duration': '4h 15m',
      'baggage': false,
      'priceAdult': 120.0,
      'priceChild': 100.0,
      'priceInfant': 0.0,
    },
  ];
}


}