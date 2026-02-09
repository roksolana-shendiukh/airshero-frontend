import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../pages/home_page.dart';
import '../pages/search_results_page.dart';

// Клас для передачі аргументів
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

// GoRouter конфігурація
class AppRouter {
  static final GoRouter router = GoRouter(
    initialLocation: '/',
    
    routes: [
      // HOME PAGE
      GoRoute(
        path: '/',
        name: 'home',
        builder: (context, state) => const HomePage(),
      ),

      // SEARCH RESULTS PAGE
      GoRoute(
        path: '/search-results',
        name: 'search-results',
        builder: (context, state) {
          final args = state.extra as SearchResultsArguments?;
          
          // Якщо немає аргументів - повертаємо на home
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
    ],
  );
}