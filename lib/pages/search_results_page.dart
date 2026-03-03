import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../widgets/responsive_layout.dart';
import '../widgets/flight_route_card.dart';
import '../widgets/flight_filter_form.dart';
import '../widgets/booking_progress_header.dart';
import '../models/grouped_flight.dart';
import '../models/flight_combo.dart';
import '../models/flight_filter_state.dart';
import '../utils/flight_combo_builder.dart';
import '../models/class.dart';
import '../services/booking_api_service.dart';
import '../services/auth_service.dart';
import '../services/recent_searches_service.dart';
import '../config/routes.dart';
import '../services/navigation_storage_service.dart';

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
  List<FlightCombo> _allCombos = [];
  List<FlightCombo> _filteredCombos = [];
  bool _isLoading = true;
  String? _error;

  late Map<int, Class> _passengerClasses;
  late Map<int, Class> _returnPassengerClasses;
  FlightFilterState? _filterState;
  bool _filtersExpanded = false;

  final _recentSearchesService = RecentSearchesService();

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
    _returnPassengerClasses = Map.from(_passengerClasses);
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
      returnPassengerClasses: _returnPassengerClasses,
      passengers: widget.passengers,
    );

    final newFilterState = FlightFilterState.fromCombos(
      combos: combos,
      passengerClasses: _passengerClasses,
    );

    setState(() {
      _allCombos = combos;
      _filteredCombos = combos;
      _filterState = newFilterState;
      _isLoading = false;
    });
  }

  void _onFilterChanged(FlightFilterState newState) {
    setState(() {
      _filterState = newState;
      _passengerClasses = newState.passengerClasses;
      _returnPassengerClasses = newState.returnPassengerClasses;
      _filteredCombos = newState.apply(_allCombos);
    });
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

  void _handleBook(FlightCombo resolvedCombo) async {
    List<Map<String, dynamic>> serializeAssignments(
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

    // Беремо flightClassId першого пасажира outbound (всі летять одним рейсом)
    final outboundFlightClassId = resolvedCombo.outboundAssignments.isNotEmpty
        ? resolvedCombo.outboundAssignments.first.flightClassId
        : 0;

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
      outboundAssignments: serializeAssignments(resolvedCombo.outboundAssignments),
      returnAssignments: serializeAssignments(resolvedCombo.returnAssignments),
      outboundFlightId: resolvedCombo.outbound.flightId,
      outboundFlightClassId: outboundFlightClassId,
    );

    debugPrint('Saving baggage args...');
    await NavigationStorageService.saveBaggageArgs(args.toMap());
    debugPrint('Saved. Navigating...');

    if (!mounted) return;
    context.go('/baggage-selection', extra: args);
  }

  void _handleBack() async {
    await _recentSearchesService.clearLastSearch();
    if (mounted) context.go('/sales/bookings');
  }

  @override
  Widget build(BuildContext context) {
    final totalPassengers =
        widget.passengers.values.reduce((a, b) => a + b);
    final isLargeScreen = MediaQuery.of(context).size.width >= 1024;

    Widget flightsList;

    if (_isLoading) {
      flightsList = const Center(child: CircularProgressIndicator());
    } else if (_error != null) {
      flightsList = Center(
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
    } else if (_filteredCombos.isEmpty) {
      flightsList = Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _allCombos.isEmpty ? Icons.airplane_ticket : Icons.filter_alt_off,
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
                      for (final e in _passengerClasses.entries) e.key: Class.any
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

    Widget body;

    if (isLargeScreen) {
      body = Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(child: flightsList),
          Container(
            width: 300,
            decoration: BoxDecoration(
              border: Border(
                left: BorderSide(
                  color: Theme.of(context).colorScheme.outlineVariant,
                ),
              ),
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: filterWidget,
            ),
          ),
        ],
      );
    } else {
      final hasActiveFilters = _filterState?.isDefault == false;

      body = Column(
        children: [
          Container(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHigh,
              border: Border(
                bottom: BorderSide(
                  color: Theme.of(context).colorScheme.outlineVariant,
                ),
              ),
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
                          color: Theme.of(context).colorScheme.primary,
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
                color: Theme.of(context).colorScheme.surfaceContainerLow,
                border: Border(
                  bottom: BorderSide(
                    color: Theme.of(context).colorScheme.outlineVariant,
                  ),
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

    return ResponsiveLayout(
      header: BookingProgressHeader(
        fromCity: widget.fromCity,
        toCity: widget.toCity,
        departDate: widget.departDate,
        returnDate: widget.returnDate,
        totalPassengers: totalPassengers,
        flightClass: _classLabel,
        currentStep: 'search',
        onBack: _handleBack,
      ),
      body: body,
    );
  }
}