import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../pages/bookings_page.dart';
import '../pages/search_results_page.dart';
import '../pages/baggage_selection_page.dart';
import '../pages/payment/payment_page.dart';
import '../pages/admin/admin_users_page.dart';
import '../pages/login_page.dart';
import '../pages/change_password_page.dart';
import '../pages/checkin_page.dart';
import '../services/auth_service.dart';
import '../services/navigation_storage_service.dart';
import '../models/user_model.dart';
import 'package:provider/provider.dart';
import '../pages/flight_operation_page.dart';
import '../pages/planning/planning_overview_page.dart';
import '../pages/planning/planning_flights_page.dart';
import '../pages/planning/create_flight_page.dart';
import '../models/booking_group_draft.dart';

class SearchResultsArguments {
  final int fromCityId;
  final String fromCity;
  final int toCityId;
  final String toCity;
  final DateTime departDate;
  final DateTime? returnDate;
  final Map<String, int> passengers;
  final BookingGroupDraft? bookingGroupDraft;
  final DateTime? leg2Date;

  SearchResultsArguments({
    required this.fromCityId,
    required this.fromCity,
    required this.toCityId,
    required this.toCity,
    required this.departDate,
    this.returnDate,
    required this.passengers,
    this.bookingGroupDraft,
    this.leg2Date,
  });
}

class BaggageSelectionArguments {
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
  final int outboundFlightId;
  final int outboundFlightClassId;
  final BookingGroupDraft? bookingGroupDraft;
  final int segmentIndex;
  final Map<int, Map<String, dynamic>>? initialPassengerData;

  BaggageSelectionArguments({
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
    required this.outboundFlightId,
    required this.outboundFlightClassId,
    this.bookingGroupDraft,
    this.segmentIndex = 0,
    this.initialPassengerData,
  });

  Map<String, dynamic> toMap() => {
        'fromCity': fromCity,
        'toCity': toCity,
        'departDate': departDate.toIso8601String(),
        'returnDate': returnDate?.toIso8601String(),
        'passengers': passengers,
        'passengerClassLabels': passengerClassLabels,
        'airlineName': airlineName,
        'airlineLogoUrl': airlineLogoUrl,
        'fromAirportCode': fromAirportCode,
        'toAirportCode': toAirportCode,
        'departureTime': departureTime,
        'arrivalTime': arrivalTime,
        'duration': duration,
        'basePrice': basePrice,
        'isRoundTrip': isRoundTrip,
        'outboundAssignments': outboundAssignments,
        'returnAssignments': returnAssignments,
        'outboundFlightId': outboundFlightId,
        'outboundFlightClassId': outboundFlightClassId,
        'segmentIndex': segmentIndex,
      };

  static BaggageSelectionArguments? fromMap(Map<String, dynamic>? map) {
    if (map == null) return null;
    try {
      DateTime parseDate(dynamic val) {
        if (val is DateTime) return val;
        return DateTime.parse(val as String);
      }

      List<Map<String, dynamic>> parseAssignments(dynamic raw) {
        if (raw == null) return [];
        return (raw as List)
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList();
      }

      return BaggageSelectionArguments(
        fromCity: map['fromCity'] as String,
        toCity: map['toCity'] as String,
        departDate: parseDate(map['departDate']),
        returnDate:
            map['returnDate'] != null ? parseDate(map['returnDate']) : null,
        passengers: Map<String, int>.from(map['passengers'] as Map),
        passengerClassLabels:
            Map<String, String>.from(map['passengerClassLabels'] as Map),
        airlineName: map['airlineName'] as String,
        airlineLogoUrl: map['airlineLogoUrl'] as String,
        fromAirportCode: map['fromAirportCode'] as String,
        toAirportCode: map['toAirportCode'] as String,
        departureTime: map['departureTime'] as String,
        arrivalTime: map['arrivalTime'] as String,
        duration: map['duration'] as String,
        basePrice: (map['basePrice'] as num).toDouble(),
        isRoundTrip: map['isRoundTrip'] as bool,
        outboundAssignments: parseAssignments(map['outboundAssignments']),
        returnAssignments: parseAssignments(map['returnAssignments']),
        outboundFlightId: (map['outboundFlightId'] as num).toInt(),
        outboundFlightClassId: (map['outboundFlightClassId'] as num).toInt(),
        segmentIndex: (map['segmentIndex'] as num?)?.toInt() ?? 0,
      );
    } catch (e) {
      debugPrint('BaggageSelectionArguments.fromMap error: $e');
      return null;
    }
  }
}

class PaymentArguments {
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
  final Map<int, Map<int, int>> baggageSelections;
  final Map<int, Map<String, dynamic>> passengerData;
  final double totalPrice;
  final bool isMultiSegment;
  final BookingGroupDraft? bookingGroupDraft;

  PaymentArguments({
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
    required this.baggageSelections,
    required this.passengerData,
    required this.totalPrice,
    this.isMultiSegment = false,
    this.bookingGroupDraft,
  });
}

String buildSearchResultsUrl({
  required int fromCityId,
  required String fromCity,
  required int toCityId,
  required String toCity,
  required DateTime departDate,
  DateTime? returnDate,
  required Map<String, int> passengers,
}) {
  return Uri(
    path: '/search-results',
    queryParameters: {
      'fromId': fromCityId.toString(),
      'from': fromCity,
      'toId': toCityId.toString(),
      'to': toCity,
      'date': departDate.toIso8601String().substring(0, 10),
      if (returnDate != null)
        'returnDate': returnDate.toIso8601String().substring(0, 10),
      'adults': (passengers['adults'] ?? 1).toString(),
      'children': (passengers['children'] ?? 0).toString(),
      'infants': (passengers['infants'] ?? 0).toString(),
    },
  ).toString();
}

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
          return _BaggageSelectionLoader();
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
            returnAssignments: ((extra['returnAssignments'] as List<dynamic>?) ?? [])
                .map((e) => Map<String, dynamic>.from(e as Map))
                .toList(),
            removedPassengerIndices: List<int>.from(
                (extra['removedPassengerIndices'] as List?)
                        ?.map((e) => e as int) ??
                    []),
            isMultiSegment: extra['isMultiSegment'] as bool? ?? false,
            bookingGroupDraft:
                extra['bookingGroupDraft'] as BookingGroupDraft?,
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
    );
  }
}

class _BaggageSelectionLoader extends StatefulWidget {
  @override
  State<_BaggageSelectionLoader> createState() =>
      _BaggageSelectionLoaderState();
}

class _BaggageSelectionLoaderState extends State<_BaggageSelectionLoader> {
  BaggageSelectionArguments? _args;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final map = await NavigationStorageService.loadBaggageArgs();
    final args = BaggageSelectionArguments.fromMap(map);
    if (!mounted) return;
    if (args == null) {
      context.go('/sales/bookings');
    } else {
      setState(() => _args = args);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_args == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    return AppRouter._buildBaggagePage(_args!);
  }
}