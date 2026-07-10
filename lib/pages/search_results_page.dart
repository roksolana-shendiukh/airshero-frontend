import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../widgets/responsive_layout.dart';
import '../widgets/booking/flight_route_card.dart';
import '../widgets/booking/flight_filter_form.dart';
import '../widgets/booking/booking_progress_header.dart';
import '../widgets/booking/multi_segment_pair_card.dart'; 
import '../models/grouped_flight.dart';
import '../models/flight_combo.dart';
import '../models/flight_filter_state.dart';
import '../utils/flight_combo_builder.dart';
import '../models/class.dart';
import '../services/booking_api_service.dart';
import '../services/auth_service.dart';
import '../services/recent_searches_service.dart';
import '../models/args/baggage_selection_args.dart';
import '../services/navigation_storage_service.dart';
import '../models/booking_group_draft.dart';
import '../services/flight_api_service.dart';

class _LegPair {
  final FlightCombo leg1;
  final FlightCombo leg2;

  const _LegPair({required this.leg1, required this.leg2});

  double get totalPrice => leg1.totalPrice + leg2.totalPrice;
}

class SearchResultsPage extends StatefulWidget {
  final int fromCityId;
  final String fromCity;
  final int toCityId;
  final String toCity;
  final DateTime departDate;
  final DateTime? returnDate;
  final Map<String, int> passengers;
  final BookingGroupDraft? bookingGroupDraft;
  final DateTime? leg2Date;

  const SearchResultsPage({
    super.key,
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

  @override
  State<SearchResultsPage> createState() => _SearchResultsPageState();
}

class _SearchResultsPageState extends State<SearchResultsPage> {
  List<FlightCombo> _allCombos = [];
  List<FlightCombo> _filteredCombos = [];
  List<int> _outboundFlightIds = [];
  List<GroupedFlight> _outboundGrouped = [];
  List<GroupedFlight> _returnGrouped = [];
  List<int> _returnFlightIds = [];

  List<FlightCombo> _leg2AllCombos = [];
  List<int> _leg2FlightIds = [];
  List<GroupedFlight> _leg2Grouped = [];

  List<_LegPair> _legPairs = [];
  List<_LegPair> _filteredLegPairs = [];
  int? _selectedPairIndex;

  bool _isLoading = true;
  bool _isBooking = false;
  bool _isFiltering = false;
  String? _error;

  late Map<int, Class> _passengerClasses;
  late Map<int, Class> _returnPassengerClasses;
  FlightFilterState? _filterState;
  bool _filtersExpanded = false;

  final _recentSearchesService = RecentSearchesService();

  bool get _isRoundTrip => widget.returnDate != null;
  bool get _isMultiSegment =>
      widget.bookingGroupDraft != null && widget.leg2Date != null;

  @override
  void initState() {
    super.initState();
    _initPassengerClasses();
    _loadFlights();
  }

  void _initPassengerClasses() {
    final total = widget.passengers.values.reduce((a, b) => a + b);
    _passengerClasses = {for (int i = 0; i < total; i++) i: Class.any};
    _returnPassengerClasses = Map.from(_passengerClasses);
  }

  List<_LegPair> _buildPairs(
    List<FlightCombo> leg1Combos,
    List<FlightCombo> leg2Combos,
  ) {
    final pairs = <_LegPair>[];
    for (final l1 in leg1Combos) {
      for (final l2 in leg2Combos) {
        pairs.add(_LegPair(leg1: l1, leg2: l2));
      }
    }
    return pairs;
  }

  Future<void> _loadFlights() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });    

    try {
      final authService = context.read<AuthService>();
      final flightService = FlightApiService(authService);
      
      if (_isMultiSegment) {
        final results = await Future.wait([
          flightService .searchFlights(
            fromCityId: widget.fromCityId,
            toCityId: widget.toCityId,
            departDate: widget.departDate,
          ),
          flightService .searchFlights(
            fromCityId: widget.toCityId,
            toCityId: widget.bookingGroupDraft!.finalDestinationCityId,
            departDate: widget.leg2Date!,
          ),
        ]);

        _outboundFlightIds =
            results[0].map((f) => f.flightId).toSet().toList();
        _leg2FlightIds = results[1].map((f) => f.flightId).toSet().toList();

        _outboundGrouped = GroupedFlight.fromFlightList(results[0]);
        _leg2Grouped = GroupedFlight.fromFlightList(results[1]);

        final leg1Combos = FlightComboBuilder.build(
          outboundFlights: _outboundGrouped,
          returnFlights: [],
          passengerClasses: _passengerClasses,
          returnPassengerClasses: _returnPassengerClasses,
          passengers: widget.passengers,
        );

        final leg2Combos = FlightComboBuilder.build(
          outboundFlights: _leg2Grouped,
          returnFlights: [],
          passengerClasses: _passengerClasses,
          returnPassengerClasses: _returnPassengerClasses,
          passengers: widget.passengers,
        );

        setState(() {
          _allCombos = leg1Combos;
          _leg2AllCombos = leg2Combos;
          _legPairs = _buildPairs(leg1Combos, leg2Combos);
          _filteredLegPairs = _legPairs; 
          _selectedPairIndex = null;
          _filterState = FlightFilterState.fromCombos(
            combos: leg1Combos,
            passengerClasses: _passengerClasses,
            leg2Combos: leg2Combos,
          );
          _isLoading = false;
        });
        _filterByAvailability();

      } else {
        final futures = [
          flightService .searchFlights(
            fromCityId: widget.fromCityId,
            toCityId: widget.toCityId,
            departDate: widget.departDate,
          ),
          if (_isRoundTrip)
            flightService .searchFlights(
              fromCityId: widget.toCityId,
              toCityId: widget.fromCityId,
              departDate: widget.returnDate!,
            ),
        ];

        final results = await Future.wait(futures);

        _outboundFlightIds =
            results[0].map((f) => f.flightId).toSet().toList();
        if (_isRoundTrip && results.length > 1) {
          _returnFlightIds =
              results[1].map((f) => f.flightId).toSet().toList();
        }

        _outboundGrouped = GroupedFlight.fromFlightList(results[0]);
        _returnGrouped = _isRoundTrip && results.length > 1
            ? GroupedFlight.fromFlightList(results[1])
            : [];

        _rebuildCombos(_outboundGrouped, _returnGrouped);
      }

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
      returnPassengerClasses: _returnPassengerClasses,
      passengers: widget.passengers,
    );

    setState(() {
      _allCombos = combos;
      _filteredCombos = combos;
      _filterState = FlightFilterState.fromCombos(
        combos: combos,
        passengerClasses: _passengerClasses,
      );
      _isLoading = false;
      _filterByAvailability();
    });
  }

  Future<void> _filterByAvailability() async {
    if (_outboundFlightIds.isEmpty) return;
    
    try {
      final authService = context.read<AuthService>();
      final flightService = FlightApiService(authService);
      
      final allFlightIds = [
        ..._outboundFlightIds,
        ..._returnFlightIds,
        ..._leg2FlightIds,
      ].toSet().toList();
      
      final availability = await flightService .getFlightsAvailability(allFlightIds);

      bool isAvailable(List<PassengerClassAssignment> assignments, int flightId) {
        final flightAvail = availability[flightId] ?? [];
        if (flightAvail.isEmpty) return true;
        for (final a in assignments) {
          final classAvail = flightAvail.firstWhere(
            (fa) => (fa['className'] as String).toLowerCase() == a.assignedClass.toLowerCase(),
            orElse: () => {},
          );
          if (classAvail.isNotEmpty && (classAvail['availableSeats'] as int) <= 0) {
            return false;
          }
        }
        return true;
      }

      if (mounted) {
        setState(() {
          _filteredCombos = _allCombos.where((combo) =>
            isAvailable(combo.outboundAssignments, combo.outbound.flightId) &&
            (combo.returnFlight == null ||
            isAvailable(combo.returnAssignments, combo.returnFlight!.flightId))
          ).toList();

          _filteredLegPairs = _legPairs.where((pair) =>
            isAvailable(pair.leg1.outboundAssignments, pair.leg1.outbound.flightId) &&
            isAvailable(pair.leg2.outboundAssignments, pair.leg2.outbound.flightId)
          ).toList();

          final filteredLeg2Combos = _leg2AllCombos.where((combo) =>
            isAvailable(combo.outboundAssignments, combo.outbound.flightId)
          ).toList();

          _filterState = FlightFilterState.fromCombos(
            combos: _filteredCombos,
            passengerClasses: _passengerClasses,
            leg2Combos: filteredLeg2Combos,
          );
        });
      }
    } catch (e) {
      debugPrint('Availability filter error: $e');
    }
  }

  Map<String, String> _buildClassLabels(FlightCombo combo) {
    final Map<String, String> result = {};
    for (final a in combo.outboundAssignments) {
      result[a.passengerLabel] = a.assignedClass;
    }
    return result;
  }

  String get _classLabel {
    final classes = _passengerClasses.values.toSet();
    if (classes.every((c) => c == Class.any)) return 'Any class';
    if (classes.length == 1) return classes.first.label;
    return 'Mixed class';
  }

  List<Map<String, dynamic>> _serializeAssignments(
      List<PassengerClassAssignment> assignments) {
    return assignments
        .map((a) => {
              'passengerLabel': a.passengerLabel,
              'assignedClass': a.assignedClass,
              'price': a.price,
              'flightPriceId': a.flightPriceId,
              'flightClassId': a.flightClassId,
            })
        .toList();
  }

  Future<void> _onMultiSegmentFilterChanged(FlightFilterState newState) async {
    setState(() {
      _filterState = newState;
      _isFiltering = true;
    });

    try {
      final authService = context.read<AuthService>();
      final flightService = FlightApiService(authService);

      final leg1ClassNames = newState.passengerClasses.values.any((c) => c == Class.any)
          ? null
          : newState.passengerClasses.values.map((c) => c.label).toSet().toList();

      final leg2ClassNames = newState.returnPassengerClasses.values.any((c) => c == Class.any)
          ? null
          : newState.returnPassengerClasses.values.map((c) => c.label).toSet().toList();

      final airlineNames = newState.selectedAirlines.isNotEmpty
          ? newState.selectedAirlines.toList()
          : null;
      final departureSlots = newState.departureSlots.isNotEmpty
          ? newState.departureSlots.map((s) => s.name).toList()
          : null;

      final results = await Future.wait([
        flightService .filterFlights(
          flightIds: _outboundFlightIds,
          classNames: leg1ClassNames,
          minPrice: newState.selectedMinPrice != newState.minPrice
              ? newState.selectedMinPrice : null,
          maxPrice: newState.selectedMaxPrice != newState.maxPrice
              ? newState.selectedMaxPrice : null,
          airlineNames: airlineNames,
          sortBy: newState.sortOrder == SortOrder.priceAsc ? 'price_asc' : 'price_desc',
          departureSlots: departureSlots,
        ),
        flightService .filterFlights(
          flightIds: _leg2FlightIds,
          classNames: leg2ClassNames,
          minPrice: newState.selectedMinPrice != newState.minPrice
              ? newState.selectedMinPrice : null,
          maxPrice: newState.selectedMaxPrice != newState.maxPrice
              ? newState.selectedMaxPrice : null,
          airlineNames: airlineNames,
          sortBy: newState.sortOrder == SortOrder.priceAsc ? 'price_asc' : 'price_desc',
          departureSlots: null,
        ),
      ]);

      final leg1Combos = FlightComboBuilder.build(
        outboundFlights: GroupedFlight.fromFlightList(results[0]),
        returnFlights: [],
        passengerClasses: newState.passengerClasses,       
        returnPassengerClasses: newState.returnPassengerClasses,
        passengers: widget.passengers,
      );

      final leg2Combos = FlightComboBuilder.build(
        outboundFlights: GroupedFlight.fromFlightList(results[1]),
        returnFlights: [],
        passengerClasses: newState.returnPassengerClasses, 
        returnPassengerClasses: newState.returnPassengerClasses,
        passengers: widget.passengers,
      );

      var pairs = _buildPairs(leg1Combos, leg2Combos);
      pairs.sort((a, b) => newState.sortOrder == SortOrder.priceAsc
          ? a.totalPrice.compareTo(b.totalPrice)
          : b.totalPrice.compareTo(a.totalPrice));

      debugPrint('leg1ClassNames: $leg1ClassNames');
debugPrint('leg2ClassNames: $leg2ClassNames');
debugPrint('pairs after filter: ${pairs.length}');
      if (mounted) {
        setState(() {
          _filteredLegPairs = pairs;
          _isFiltering = false;
          _selectedPairIndex = null;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isFiltering = false);
    }
  }

  Future<void> _handleBook(FlightCombo resolvedCombo) async {
    final outboundFlightClassId = resolvedCombo.outboundAssignments.isNotEmpty
        ? resolvedCombo.outboundAssignments.first.flightClassId
        : 0;

    setState(() => _isBooking  = true);

    try {
      final authService = context.read<AuthService>();
      final bookingService = BookingApiService(authService);

      final totalPassengers =
          widget.passengers.values.reduce((a, b) => a + b);
      final passengersList = List.generate(totalPassengers, (i) {
        final outbound = i < resolvedCombo.outboundAssignments.length
            ? resolvedCombo.outboundAssignments[i]
            : resolvedCombo.outboundAssignments.last;
        final ret = i < resolvedCombo.returnAssignments.length
            ? resolvedCombo.returnAssignments[i]
            : null;
        return {
          'flight_price_id': outbound.flightPriceId,
          if (ret != null) 'return_flight_price_id': ret.flightPriceId,
        };
      });

      final result = await bookingService.reserveBooking({
        'passengers': passengersList,
        'total_amount': resolvedCombo.totalPrice,
      });

      final bookingId = result['bookingId'] as int;
      final bookingNumber = result['bookingNumber'] as String;
      final expiresAt = DateTime.parse(result['expiresAt'] as String).toLocal();

      final args = BaggageSelectionArguments(
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
        outboundAssignments:
            _serializeAssignments(resolvedCombo.outboundAssignments),
        returnAssignments:
            _serializeAssignments(resolvedCombo.returnAssignments),
        outboundFlightId: resolvedCombo.outbound.flightId,
        outboundFlightClassId: outboundFlightClassId,
        bookingId: bookingId,
        bookingNumber: bookingNumber,
        expiresAt: expiresAt,
      );

      await NavigationStorageService.saveBaggageArgs(args.toMap());
      if (!mounted) return;
      context.go('/baggage-selection', extra: args);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isBooking  = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceAll('Exception: ', '')),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  Future<void> _handleBookPair(int pairIndex) async {
    final pair = _filteredLegPairs[pairIndex];
    final leg1 = pair.leg1;
    final leg2 = pair.leg2;

    setState(() => _isBooking = true);

    try {
      final authService = context.read<AuthService>();
      final bookingService = BookingApiService(authService);

      final totalPassengers =
          widget.passengers.values.reduce((a, b) => a + b);

      final passengers1 = List.generate(totalPassengers, (i) {
        final a = i < leg1.outboundAssignments.length
            ? leg1.outboundAssignments[i]
            : leg1.outboundAssignments.last;
        return {'flight_price_id': a.flightPriceId};
      });

      final passengers2 = List.generate(totalPassengers, (i) {
        final a = i < leg2.outboundAssignments.length
            ? leg2.outboundAssignments[i]
            : leg2.outboundAssignments.last;
        return {'flight_price_id': a.flightPriceId};
      });

      final result = await bookingService.reserveGroupBooking({
        'booking1': {
          'passengers': passengers1,
          'total_amount': leg1.totalPrice,
        },
        'booking2': {
          'passengers': passengers2,
          'total_amount': leg2.totalPrice,
        },
      });

      final bookingId1 = result['booking1']['bookingId'] as int;
      final bookingNumber1 = result['booking1']['bookingNumber'] as String;
      final bookingId2 = result['booking2']['bookingId'] as int;
      final bookingNumber2 = result['booking2']['bookingNumber'] as String;
      final expiresAt = DateTime.parse(result['expiresAt'] as String).toLocal(); 

      final leg1ClassId = leg1.outboundAssignments.isNotEmpty
          ? leg1.outboundAssignments.first.flightClassId
          : 0;
      final leg2ClassId = leg2.outboundAssignments.isNotEmpty
          ? leg2.outboundAssignments.first.flightClassId
          : 0;

      final seg1 = BookingSegmentDraft(
        flightId: leg1.outbound.flightId,
        flightClassId: leg1ClassId,
        fromCity: widget.fromCity,
        toCity: widget.toCity,
        fromCityId: widget.fromCityId,
        toCityId: widget.toCityId,
        fromAirportCode: leg1.outbound.departsCode,
        toAirportCode: leg1.outbound.arrivesCode,
        departureTime: leg1.outbound.departureTime,
        arrivalTime: leg1.outbound.arrivalTime,
        duration: leg1.outbound.formattedDuration,
        airlineName: leg1.outbound.airlineName,
        airlineLogoUrl: leg1.outbound.airlineLogoUrl ?? '',
        departDate: widget.departDate,
        passengerClassLabels: _buildClassLabels(leg1),
        basePrice: leg1.totalPrice,
        assignments: _serializeAssignments(leg1.outboundAssignments),
      );

      final seg2 = BookingSegmentDraft(
        flightId: leg2.outbound.flightId,
        flightClassId: leg2ClassId,
        fromCity: widget.toCity,
        toCity: widget.bookingGroupDraft!.finalDestinationCity,
        fromCityId: widget.toCityId,
        toCityId: widget.bookingGroupDraft!.finalDestinationCityId,
        fromAirportCode: leg2.outbound.departsCode,
        toAirportCode: leg2.outbound.arrivesCode,
        departureTime: leg2.outbound.departureTime,
        arrivalTime: leg2.outbound.arrivalTime,
        duration: leg2.outbound.formattedDuration,
        airlineName: leg2.outbound.airlineName,
        airlineLogoUrl: leg2.outbound.airlineLogoUrl ?? '',
        departDate: widget.leg2Date!,
        passengerClassLabels: _buildClassLabels(leg2),
        basePrice: leg2.totalPrice,
        assignments: _serializeAssignments(leg2.outboundAssignments),
      );

      final draft = BookingGroupDraft(
        segments: [seg1],
        passengers: widget.passengers,
        finalDestinationCityId:
            widget.bookingGroupDraft!.finalDestinationCityId,
        finalDestinationCity: widget.bookingGroupDraft!.finalDestinationCity,
      ).withSecondSegment(seg2);

      final baggageArgs = BaggageSelectionArguments(
        fromCity: seg1.fromCity,
        toCity: seg1.toCity,
        departDate: seg1.departDate,
        passengers: widget.passengers,
        passengerClassLabels: seg1.passengerClassLabels,
        airlineName: seg1.airlineName,
        airlineLogoUrl: seg1.airlineLogoUrl,
        fromAirportCode: seg1.fromAirportCode,
        toAirportCode: seg1.toAirportCode,
        departureTime: seg1.departureTime,
        arrivalTime: seg1.arrivalTime,
        duration: seg1.duration,
        basePrice: seg1.basePrice,
        isRoundTrip: false,
        outboundAssignments: seg1.assignments,
        outboundFlightId: seg1.flightId,
        outboundFlightClassId: seg1.flightClassId,
        bookingGroupDraft: draft,
        segmentIndex: 0,
        bookingId: bookingId1,
        bookingNumber: bookingNumber1,
        bookingId2: bookingId2,
        bookingNumber2: bookingNumber2,
        expiresAt: expiresAt,
        leg2FlightClassId: seg2.flightClassId,
        leg2FromCity: seg2.fromCity,
        leg2ToCity: seg2.toCity,
      );

      await NavigationStorageService.saveBaggageArgs(baggageArgs.toMap());
      if (!mounted) return;
      context.go('/baggage-selection', extra: baggageArgs);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isBooking = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceAll('Exception: ', '')),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  void _handleBack() async {
    await _recentSearchesService.clearLastSearch();
    if (mounted) context.go('/sales/bookings');
  }

  Future<void> _onFilterChanged(FlightFilterState newState) async {
    setState(() {
      _filterState = newState;
      _passengerClasses = newState.passengerClasses;
      _returnPassengerClasses = newState.returnPassengerClasses;
      _isFiltering = true;
    });

    try {
      final authService = context.read<AuthService>();
      final flightService = FlightApiService(authService);
      
      final hasAnyClass =
          newState.passengerClasses.values.any((c) => c == Class.any);
      final classNames = hasAnyClass
          ? null
          : newState.passengerClasses.values
              .map((c) => c.label)
              .toSet()
              .toList();
      final airlineNames = newState.selectedAirlines.isNotEmpty
          ? newState.selectedAirlines.toList()
          : null;
      final departureSlots = newState.departureSlots.isNotEmpty
          ? newState.departureSlots.map((s) => s.name).toList()
          : null;

      final outboundFiltered = await flightService .filterFlights(
        flightIds: _outboundFlightIds,
        classNames: classNames,
        minPrice: newState.selectedMinPrice != newState.minPrice
            ? newState.selectedMinPrice
            : null,
        maxPrice: newState.selectedMaxPrice != newState.maxPrice
            ? newState.selectedMaxPrice
            : null,
        airlineNames: airlineNames,
        sortBy: newState.sortOrder == SortOrder.priceAsc
            ? 'price_asc'
            : 'price_desc',
        departureSlots: departureSlots,
      );

      final outboundGrouped = GroupedFlight.fromFlightList(outboundFiltered);

      List<GroupedFlight> returnGrouped = [];
      if (_isRoundTrip && _returnFlightIds.isNotEmpty) {
        final hasAnyReturnClass = newState.returnPassengerClasses.values
            .any((c) => c == Class.any);
        final returnClassNames = hasAnyReturnClass
            ? null
            : newState.returnPassengerClasses.values
                .map((c) => c.label)
                .toSet()
                .toList();
        final returnSlots = newState.returnSlots.isNotEmpty
            ? newState.returnSlots.map((s) => s.name).toList()
            : null;

        final returnFiltered = await flightService .filterFlights(
          flightIds: _returnFlightIds,
          classNames: returnClassNames,
          minPrice: newState.selectedMinPrice != newState.minPrice
              ? newState.selectedMinPrice
              : null,
          maxPrice: newState.selectedMaxPrice != newState.maxPrice
              ? newState.selectedMaxPrice
              : null,
          airlineNames: airlineNames,
          sortBy: newState.sortOrder == SortOrder.priceAsc
              ? 'price_asc'
              : 'price_desc',
          departureSlots: returnSlots,
        );
        returnGrouped = GroupedFlight.fromFlightList(returnFiltered);
      }

      final combos = FlightComboBuilder.build(
        outboundFlights: outboundGrouped,
        returnFlights: returnGrouped,
        passengerClasses: newState.passengerClasses,
        returnPassengerClasses: newState.returnPassengerClasses,
        passengers: widget.passengers,
      );

      if (mounted) {
        setState(() {
          _filteredCombos = combos;
          _isFiltering = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isFiltering = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final totalPassengers = widget.passengers.values.reduce((a, b) => a + b);
    final isLargeScreen = MediaQuery.of(context).size.width >= 1024;
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

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
            Text(_error!, style: textTheme.titleMedium),
            const SizedBox(height: 8),
            TextButton(onPressed: _loadFlights, child: const Text('Try again')),
          ],
        ),
      );
    } else if (_isMultiSegment) {
      body = _buildMultiSegmentBody(colors, textTheme);
    } else {
      body = _buildNormalBody(colors, isLargeScreen);
    }

    return ResponsiveLayout(
      header: BookingProgressHeader(
        fromCity: widget.fromCity,
        toCity: _isMultiSegment
            ? widget.bookingGroupDraft!.finalDestinationCity
            : widget.toCity,
        departDate: widget.departDate,
        returnDate: widget.returnDate,
        totalPassengers: totalPassengers,
        flightClass: _classLabel,
        currentStep: 'search',
        onBack: _handleBack,
      ),
      body: Stack(
        children: [
          body,
          if (_isBooking)
            Container(
              color: Colors.black.withValues(alpha: 0.3),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircularProgressIndicator(),
                    const SizedBox(height: 16),
                    Text(
                      'Reserving seats...',
                      style: textTheme.bodyMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
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

  Widget _buildMultiSegmentBody(ColorScheme colors, TextTheme textTheme) {
    final isLargeScreen = MediaQuery.of(context).size.width >= 1024;

    final listView = _filteredLegPairs.isEmpty
        ? Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  _legPairs.isEmpty ? Icons.airplane_ticket : Icons.filter_alt_off,
                  size: 48,
                  color: colors.onSurfaceVariant,
                ),
                const SizedBox(height: 16),
                Text(
                  _legPairs.isEmpty
                      ? 'No connecting flights found'
                      : 'No flights match the filters',
                  style: textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                if (_legPairs.isNotEmpty && _filterState != null)
                  TextButton(
                    onPressed: () => _onMultiSegmentFilterChanged(
                      FlightFilterState.fromCombos(
                        combos: _allCombos,
                        passengerClasses: {
                          for (final e in _passengerClasses.entries)
                            e.key: Class.any
                        },
                        leg2Combos: _leg2AllCombos,
                      ),
                    ),
                    child: const Text('Reset filters'),
                  )
                else
                  Text(
                    '${widget.fromCity} → ${widget.toCity} → ${widget.bookingGroupDraft?.finalDestinationCity ?? ''}',
                    style: textTheme.bodyMedium,
                  ),
              ],
            ),
          )
        : ListView.builder(
            padding: const EdgeInsets.only(top: 8, bottom: 48),
            itemCount: _filteredLegPairs.length,
            itemBuilder: (context, index) {
              final pair = _filteredLegPairs[index];
              return MultiSegmentPairCard(
                leg1: pair.leg1,
                leg2: pair.leg2,
                totalPrice: pair.totalPrice,
                isSelected: _selectedPairIndex == index,
                fromCity: widget.fromCity,
                hubCity: widget.toCity,
                destinationCity: widget.bookingGroupDraft!.finalDestinationCity,
                leg1Date: widget.departDate,
                leg2Date: widget.leg2Date!,
                onTap: () => setState(() =>
                    _selectedPairIndex =
                        _selectedPairIndex == index ? null : index),
                onBook: () => _handleBookPair(index),
                apiService: FlightApiService(context.read<AuthService>()),
              );
            },
          );

    final filterWidget = _filterState == null
        ? const SizedBox.shrink()
        : FlightFilterForm(
            filterState: _filterState!,
            passengers: widget.passengers,
            isRoundTrip: false,
            isMultiSegment: true,
            onChanged: _onMultiSegmentFilterChanged,
          );

    if (isLargeScreen) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: Column(
              children: [
                if (_isFiltering) const LinearProgressIndicator(),
                Expanded(child: listView),
              ],
            ),
          ),
          Container(
            width: 300,
            decoration: BoxDecoration(
              border: Border(
                left: BorderSide(color: colors.outlineVariant),
              ),
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: filterWidget,
            ),
          ),
        ],
      );
    }

    final hasActiveFilters = _filterState?.isDefault == false;

    return Column(
      children: [
        if (_isFiltering) const LinearProgressIndicator(),
        Container(
          decoration: BoxDecoration(
            color: colors.surfaceContainerHigh,
            border: Border(bottom: BorderSide(color: colors.outlineVariant)),
          ),
          child: InkWell(
            onTap: () => setState(() => _filtersExpanded = !_filtersExpanded),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  const Icon(Icons.tune, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Filters',
                    style: Theme.of(context)
                        .textTheme
                        .titleSmall
                        ?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  if (hasActiveFilters) ...[
                    const SizedBox(width: 6),
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: colors.primary,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ],
                  const Spacer(),
                  Icon(
                    _filtersExpanded
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
        ),
        AnimatedCrossFade(
          firstChild: const SizedBox.shrink(),
          secondChild: Container(
            width: double.infinity,
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.5,
            ),
            decoration: BoxDecoration(
              color: colors.surfaceContainerLow,
              border: Border(bottom: BorderSide(color: colors.outlineVariant)),
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: filterWidget,
            ),
          ),
          crossFadeState: _filtersExpanded
              ? CrossFadeState.showSecond
              : CrossFadeState.showFirst,
          duration: const Duration(milliseconds: 250),
        ),
        Expanded(child: listView),
      ],
    );
  }

  Widget _buildNormalBody(ColorScheme colors, bool isLargeScreen) {
    Widget flightsList;

    if (_filteredCombos.isEmpty) {
      flightsList = Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _allCombos.isEmpty
                  ? Icons.airplane_ticket
                  : Icons.filter_alt_off,
              size: 48,
              color: Colors.grey,
            ),
            const SizedBox(height: 16),
            Text(
              _allCombos.isEmpty
                  ? 'No flights found for this route'
                  : 'No flights match the filters',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            if (_allCombos.isNotEmpty && _filterState != null)
              TextButton(
                onPressed: () => _onFilterChanged(
                  FlightFilterState.fromCombos(
                    combos: _allCombos,
                    passengerClasses: {
                      for (final e in _passengerClasses.entries)
                        e.key: Class.any
                    },
                  ),
                ),
                child: const Text('Reset filters'),
              )
            else
              Text(
                '${widget.fromCity} → ${widget.toCity}',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
          ],
        ),
      );
    } else {
      flightsList = ListView.builder(
        physics: const BouncingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics(),
        ),
        padding: const EdgeInsets.only(top: 16, bottom: 48),
        itemCount: _filteredCombos.length,
        itemBuilder: (context, index) {
          return FlightRouteCard(
            combo: _filteredCombos[index],
            onBook: _handleBook,
            apiService: FlightApiService(context.read<AuthService>()),
          );
        },
      );
    }

    final Widget filterWidget = _filterState == null
        ? const SizedBox.shrink()
        : FlightFilterForm(
            filterState: _filterState!,
            passengers: widget.passengers,
            isRoundTrip: _isRoundTrip,
            onChanged: _onFilterChanged,
          );

    if (isLargeScreen) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: Column(
              children: [
                if (_isFiltering) const LinearProgressIndicator(),
                Expanded(child: flightsList),
              ],
            ),
          ),
          Container(
            width: 300,
            decoration: BoxDecoration(
              border: Border(
                left: BorderSide(color: colors.outlineVariant),
              ),
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: filterWidget,
            ),
          ),
        ],
      );
    }

    final hasActiveFilters = _filterState?.isDefault == false;

    return Column(
      children: [
        if (_isFiltering) const LinearProgressIndicator(),
        Container(
          decoration: BoxDecoration(
            color: colors.surfaceContainerHigh,
            border: Border(
              bottom: BorderSide(color: colors.outlineVariant),
            ),
          ),
          child: InkWell(
            onTap: () => setState(() => _filtersExpanded = !_filtersExpanded),
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  const Icon(Icons.tune, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Filters',
                    style: Theme.of(context)
                        .textTheme
                        .titleSmall
                        ?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  if (hasActiveFilters) ...[
                    const SizedBox(width: 6),
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: colors.primary,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ],
                  const Spacer(),
                  Icon(
                    _filtersExpanded
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
        ),
        AnimatedCrossFade(
          firstChild: const SizedBox.shrink(),
          secondChild: Container(
            width: double.infinity,
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.5,
            ),
            decoration: BoxDecoration(
              color: colors.surfaceContainerLow,
              border: Border(
                bottom: BorderSide(color: colors.outlineVariant),
              ),
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: filterWidget,
            ),
          ),
          crossFadeState: _filtersExpanded
              ? CrossFadeState.showSecond
              : CrossFadeState.showFirst,
          duration: const Duration(milliseconds: 250),
        ),
        Expanded(child: flightsList),
      ],
    );
  }


}