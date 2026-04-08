import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../pages/bookings_page.dart';
import '../pages/search_results_page.dart';
import '../pages/baggage_selection_page.dart';
import '../pages/payment/payment_page.dart';
import '../pages/admin/admin_users_page.dart';
import '../pages/login_page.dart';
import '../pages/change_password_page.dart';
import '../pages/checkin_page.dart';
import '../pages/flight_operation_page.dart';
import '../pages/planning/planning_overview_page.dart';
import '../pages/planning/planning_flights_page.dart';
import '../pages/planning/create_flight_page.dart';
import '../pages/planning/create_route_page.dart';

import '../models/args/search_results_args.dart';
import '../models/args/baggage_selection_args.dart';
import '../models/booking_group_draft.dart';

import '../services/auth_service.dart';
import '../models/user_model.dart';
import '../widgets/baggage_selection_loader.dart';

export '../models/args/search_results_args.dart';
export '../models/args/baggage_selection_args.dart';
export '../models/args/payment_args.dart';
export '../utils/url_helpers.dart';

class AppRouter {
  static final GoRouter router = GoRouter(
    initialLocation: '/login',

    redirect: (context, state) {
      final authService = context.read<AuthService>();
      final isLoggedIn = authService.isAuthenticated;
      final location = state.matchedLocation;

      if (!isLoggedIn && location != '/login') return '/login';

      if (isLoggedIn) {
        final status = authService.currentUser?.status;
        final role = authService.currentUser?.role;
        final homeRoute = role?.menuItems.first.route ?? '/login';

        if (status == UserStatus.pendingPasswordChange &&
            location != '/change-password') {
          return '/change-password';
        }

        if (status != UserStatus.pendingPasswordChange &&
            location == '/change-password') {
          return homeRoute;
        }

        if (location == '/login') {
          return homeRoute;
        }
      }

      return null;
    },

    routes: [
      GoRoute(
        path: '/sales/bookings',
        builder: (context, state) => const BookingsPage(),
      ),

      GoRoute(
        path: '/search-results',
        name: 'search-results',
        builder: (context, state) {
          final args = state.extra as SearchResultsArguments?;
          if (args != null) {
            return SearchResultsPage(
              fromCityId: args.fromCityId,
              fromCity: args.fromCity,
              toCityId: args.toCityId,
              toCity: args.toCity,
              departDate: args.departDate,
              returnDate: args.returnDate,
              passengers: args.passengers,
              bookingGroupDraft: args.bookingGroupDraft,
              leg2Date: args.leg2Date,
            );
          }

          final q = state.uri.queryParameters;
          final fromCity = q['from'] ?? '';
          final toCity = q['to'] ?? '';
          final departDateStr = q['date'] ?? '';
          final returnDateStr = q['returnDate'];

          if (fromCity.isEmpty || toCity.isEmpty || departDateStr.isEmpty) {
            WidgetsBinding.instance
                .addPostFrameCallback((_) => context.go('/sales/bookings'));
            return const SizedBox.shrink();
          }

          final departDate = DateTime.tryParse(departDateStr);
          if (departDate == null) {
            WidgetsBinding.instance
                .addPostFrameCallback((_) => context.go('/sales/bookings'));
            return const SizedBox.shrink();
          }

          return SearchResultsPage(
            fromCityId: int.tryParse(q['fromId'] ?? '0') ?? 0,
            fromCity: fromCity,
            toCityId: int.tryParse(q['toId'] ?? '0') ?? 0,
            toCity: toCity,
            departDate: departDate,
            returnDate:
                returnDateStr != null ? DateTime.tryParse(returnDateStr) : null,
            passengers: {
              'adults': int.tryParse(q['adults'] ?? '1') ?? 1,
              'children': int.tryParse(q['children'] ?? '0') ?? 0,
              'infants': int.tryParse(q['infants'] ?? '0') ?? 0,
            },
          );
        },
      ),

      GoRoute(
        path: '/search-results/leg-2',
        name: 'search-results-leg-2',
        builder: (context, state) {
          final args = state.extra as SearchResultsArguments?;
          if (args == null || args.bookingGroupDraft == null) {
            WidgetsBinding.instance
                .addPostFrameCallback((_) => context.go('/sales/bookings'));
            return const SizedBox.shrink();
          }
          return SearchResultsPage(
            fromCityId: args.fromCityId,
            fromCity: args.fromCity,
            toCityId: args.toCityId,
            toCity: args.toCity,
            departDate: args.departDate,
            passengers: args.passengers,
            bookingGroupDraft: args.bookingGroupDraft,
          );
        },
      ),

      GoRoute(
        path: '/baggage-selection',
        name: 'baggage-selection',
        builder: (context, state) {
          if (state.extra is BaggageSelectionArguments) {
            return _buildBaggagePage(state.extra as BaggageSelectionArguments);
          }
          return const BaggageSelectionLoader();
        },
      ),

      GoRoute(
        path: '/baggage-selection/leg-2',
        name: 'baggage-selection-leg-2',
        builder: (context, state) {
          final args = state.extra as BaggageSelectionArguments?;
          if (args == null || args.bookingGroupDraft == null) {
            WidgetsBinding.instance
                .addPostFrameCallback((_) => context.go('/sales/bookings'));
            return const SizedBox.shrink();
          }
          return _buildBaggagePage(args);
        },
      ),

      GoRoute(
        path: '/payment',
        name: 'payment',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          if (extra == null) {
            WidgetsBinding.instance
                .addPostFrameCallback((_) => context.go('/sales/bookings'));
            return const SizedBox.shrink();
          }
          return PaymentPage(
            fromCity: extra['fromCity'] as String,
            toCity: extra['toCity'] as String,
            departDate: DateTime.parse(extra['departDate'] as String),
            returnDate: extra['returnDate'] != null
                ? DateTime.parse(extra['returnDate'] as String)
                : null,
            passengers: extra['passengers'] as Map<String, int>,
            passengerClassLabels:
                extra['passengerClassLabels'] as Map<String, String>,
            airlineName: extra['airlineName'] as String,
            airlineLogoUrl: extra['airlineLogoUrl'] as String,
            fromAirportCode: extra['fromAirportCode'] as String,
            toAirportCode: extra['toAirportCode'] as String,
            departureTime: extra['departureTime'] as String,
            arrivalTime: extra['arrivalTime'] as String,
            duration: extra['duration'] as String,
            basePrice: extra['basePrice'] as double,
            isRoundTrip: extra['isRoundTrip'] as bool,
            baggageSelections:
                extra['baggageSelections'] as Map<int, Map<int, int>>,
            passengerData:
                extra['passengerData'] as Map<int, Map<String, dynamic>>,
            totalPrice: extra['totalPrice'] as double,
            sessionId: extra['sessionId'] as String,
            outboundAssignments: (extra['outboundAssignments'] as List<dynamic>)
                .map((e) => Map<String, dynamic>.from(e as Map))
                .toList(),
            returnAssignments:
                ((extra['returnAssignments'] as List<dynamic>?) ?? [])
                    .map((e) => Map<String, dynamic>.from(e as Map))
                    .toList(),
            removedPassengerIndices: List<int>.from(
                (extra['removedPassengerIndices'] as List?)
                        ?.map((e) => e as int) ??
                    []),
            isMultiSegment: extra['isMultiSegment'] as bool? ?? false,
            bookingGroupDraft:
                extra['bookingGroupDraft'] as BookingGroupDraft?,
            bookingId: extra['bookingId'] as int?,
            bookingNumber: extra['bookingNumber'] as String?,
            bookingId2: extra['bookingId2'] as int?,
            bookingNumber2: extra['bookingNumber2'] as String?,
            expiresAt: extra['expiresAt'] != null
                ? DateTime.parse(extra['expiresAt'] as String)
                : null,
          );
        },
      ),

      GoRoute(
        path: '/admin/users',
        builder: (context, state) => const AdminUsersPage(),
      ),

      GoRoute(
        path: '/change-password',
        builder: (context, state) => const ChangePasswordPage(),
      ),

      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginPage(),
      ),

      GoRoute(
        path: '/checkin',
        builder: (context, state) => CheckInPage(
          authService: context.read<AuthService>(),
        ),
      ),

      GoRoute(
        path: '/flight-operations',
        builder: (context, state) => const FlightOperationPage(),
      ),

      GoRoute(
        path: '/planning/overview',
        builder: (context, state) => const PlanningOverviewPage(),
      ),

      GoRoute(
        path: '/planning/flights',
        builder: (context, state) => const PlanningFlightsPage(),
      ),

      GoRoute(
        path: '/planning/create-flight',
        builder: (context, state) => const CreateFlightPage(),
      ),

      GoRoute(
        path: '/planning/create-route',
        builder: (context, state) => const CreateRoutePage(),
      ),
    ],
  );

  static Widget _buildBaggagePage(BaggageSelectionArguments args) {
    return BaggageSelectionPage(
      fromCity: args.fromCity,
      toCity: args.toCity,
      departDate: args.departDate,
      returnDate: args.returnDate,
      passengers: args.passengers,
      passengerClassLabels: args.passengerClassLabels,
      airlineName: args.airlineName,
      airlineLogoUrl: args.airlineLogoUrl,
      fromAirportCode: args.fromAirportCode,
      toAirportCode: args.toAirportCode,
      departureTime: args.departureTime,
      arrivalTime: args.arrivalTime,
      duration: args.duration,
      basePrice: args.basePrice,
      isRoundTrip: args.isRoundTrip,
      outboundAssignments: args.outboundAssignments,
      returnAssignments: args.returnAssignments,
      outboundFlightClassId: args.outboundFlightClassId,
      bookingGroupDraft: args.bookingGroupDraft,
      segmentIndex: args.segmentIndex,
      initialPassengerData: args.initialPassengerData,
      bookingId: args.bookingId,
      bookingNumber: args.bookingNumber,
      bookingId2: args.bookingId2,
      bookingNumber2: args.bookingNumber2,
      expiresAt: args.expiresAt,
      leg2FlightClassId: args.leg2FlightClassId,
      leg2FromCity: args.leg2FromCity,
      leg2ToCity: args.leg2ToCity,
    );
  }
}