import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../pages/home_page.dart';
import '../pages/search_results_page.dart';
import '../pages/baggage_selection_page.dart';
import '../pages/payment_page.dart';

class SearchResultsArguments {
  final String fromCity;
  final String toCity;
  final DateTime departDate;
  final DateTime? returnDate;
  final Map<String, int> passengers;
  final String flightClass;

  SearchResultsArguments({
    required this.fromCity,
    required this.toCity,
    required this.departDate,
    this.returnDate,
    required this.passengers,
    required this.flightClass,
  });
}

class BaggageSelectionArguments {
  final String fromCity;
  final String toCity;
  final DateTime departDate;
  final DateTime? returnDate;
  final Map<String, int> passengers;
  final String flightClass;
  
  // Flight details
  final String airlineName;
  final String airlineLogoUrl;
  final String fromAirportCode;
  final String toAirportCode;
  final String departureTime;
  final String arrivalTime;
  final String duration;
  final double basePrice;
  final bool isRoundTrip;

  BaggageSelectionArguments({
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
  });
}

class PaymentArguments {
  final String fromCity;
  final String toCity;
  final DateTime departDate;
  final DateTime? returnDate;
  final Map<String, int> passengers;
  final String flightClass;
  
  // Flight details
  final String airlineName;
  final String airlineLogoUrl;
  final String fromAirportCode;
  final String toAirportCode;
  final String departureTime;
  final String arrivalTime;
  final String duration;
  final double basePrice;
  final bool isRoundTrip;
  
  // Baggage and passenger data
  final Map<int, Map<int, int>> baggageSelections;
  final Map<int, Map<String, dynamic>> passengerData;
  final double totalPrice;

  PaymentArguments({
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
}

class AppRouter {
  static final GoRouter router = GoRouter(
    initialLocation: '/',
    
    routes: [
      GoRoute(
        path: '/',
        name: 'home',
        builder: (context, state) => const HomePage(),
      ),

      GoRoute(
        path: '/search-results',
        name: 'search-results',
        builder: (context, state) {
          final args = state.extra as SearchResultsArguments?;
          
          if (args == null) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              context.go('/');
            });
            return const SizedBox.shrink();
          }

          return SearchResultsPage(
            fromCity: args.fromCity,
            toCity: args.toCity,
            departDate: args.departDate,
            returnDate: args.returnDate,
            passengers: args.passengers,
            flightClass: args.flightClass,
          );
        },
      ),

      GoRoute(
        path: '/baggage-selection',
        name: 'baggage-selection',
        builder: (context, state) {
          final args = state.extra as BaggageSelectionArguments?;
          
          if (args == null) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              context.go('/');
            });
            return const SizedBox.shrink();
          }

          return BaggageSelectionPage(
            fromCity: args.fromCity,
            toCity: args.toCity,
            departDate: args.departDate,
            returnDate: args.returnDate,
            passengers: args.passengers,
            flightClass: args.flightClass,
            airlineName: args.airlineName,
            airlineLogoUrl: args.airlineLogoUrl,
            fromAirportCode: args.fromAirportCode,
            toAirportCode: args.toAirportCode,
            departureTime: args.departureTime,
            arrivalTime: args.arrivalTime,
            duration: args.duration,
            basePrice: args.basePrice,
            isRoundTrip: args.isRoundTrip,
          );
        },
      ),

      GoRoute(
        path: '/payment',
        name: 'payment',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          
          if (extra == null) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              context.go('/');
            });
            return const SizedBox.shrink();
          }

          return PaymentPage(
            fromCity: extra['fromCity'] as String,
            toCity: extra['toCity'] as String,
            departDate: extra['departDate'] as DateTime,
            returnDate: extra['returnDate'] as DateTime?,
            passengers: extra['passengers'] as Map<String, int>,
            flightClass: extra['flightClass'] as String,
            airlineName: extra['airlineName'] as String,
            airlineLogoUrl: extra['airlineLogoUrl'] as String,
            fromAirportCode: extra['fromAirportCode'] as String,
            toAirportCode: extra['toAirportCode'] as String,
            departureTime: extra['departureTime'] as String,
            arrivalTime: extra['arrivalTime'] as String,
            duration: extra['duration'] as String,
            basePrice: extra['basePrice'] as double,
            isRoundTrip: extra['isRoundTrip'] as bool,
            baggageSelections: extra['baggageSelections'] as Map<int, Map<int, int>>,
            passengerData: extra['passengerData'] as Map<int, Map<String, dynamic>>,
            totalPrice: extra['totalPrice'] as double,
          );
        },
      ),
    ],
  );
}