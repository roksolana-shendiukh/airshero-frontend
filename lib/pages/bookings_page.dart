import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../widgets/booking/flight_search_form.dart';
import '../widgets/booking/alternatives_section.dart';
import '../widgets/booking/multi_segment_section.dart';
import '../widgets/responsive_layout.dart';
import '../widgets/animation/animated_flight_progress.dart';
import '../widgets/custom/custom_input_field.dart';
import '../widgets/custom/custom_date_range_picker.dart';
import '../widgets/passenger_selector.dart';
import '../config/routes.dart';
import '../services/recent_searches_service.dart';
import '../services/auth_service.dart';
import '../services/city_api_service.dart';
import '../models/flight_alternatives_model.dart';
import '../models/booking_group_draft.dart';
import '../models/hub_selection_model.dart';

class BookingsPage extends StatefulWidget {
  const BookingsPage({super.key});

  @override
  State<BookingsPage> createState() => _BookingsPageState();
}

class _BookingsPageState extends State<BookingsPage> {
  bool _isSearching = false;
  bool _isRestoringSearch = true;
  final _recentSearchesService = RecentSearchesService();
  void Function(Offset position)? _closeFormOverlays;

  final GlobalKey<FlightSearchFormState> _formKey =
      GlobalKey<FlightSearchFormState>();

  bool _routeExists = true;
  FlightAlternatives? _alternatives;

  HubSelection? _selectedHub;
  DateTime? _leg1Date;
  DateTime? _leg2Date;
  MainFormData? _mainFormData;

  bool _isLoadingLeg2 = false;
  List<String> _leg2Dates = [];
  List<String> _suggestedLeg1Dates = [];

  OverlayEntry? _segmentCalendarOverlay;
  int? _activeSegmentIndex;

  OverlayEntry? _passengerOverlay;
  bool _isPassengerOpen = false;
  final GlobalKey _passengerFieldKey = GlobalKey();
  Map<String, int> _passengers = {
    'adults': 1,
    'children': 0,
    'infants': 0,
  };

  @override
  void initState() {
    super.initState();
    _tryRestoreLastSearch();
  }

  @override
  void dispose() {
    _segmentCalendarOverlay?.remove();
    _passengerOverlay?.remove();
    super.dispose();
  }

  Future<void> _tryRestoreLastSearch() async {
    try {
      final last = await _recentSearchesService.loadLastSearch();
      if (last != null && mounted) {
        final fromCityId = last['from_city_id'] as int? ?? 0;
        final fromCity = last['from_city'] as String? ?? '';
        final toCityId = last['to_city_id'] as int? ?? 0;
        final toCity = last['to_city'] as String? ?? '';
        final departDateStr = last['depart_date'] as String? ?? '';
        final returnDateStr = last['return_date'] as String?;
        final adults = last['adults'] as int? ?? 1;
        final children = last['children'] as int? ?? 0;
        final infants = last['infants'] as int? ?? 0;

        final departDate = DateTime.tryParse(departDateStr);

        if (fromCity.isNotEmpty && toCity.isNotEmpty && departDate != null) {
          final url = buildSearchResultsUrl(
            fromCityId: fromCityId,
            fromCity: fromCity,
            toCityId: toCityId,
            toCity: toCity,
            departDate: departDate,
            returnDate: returnDateStr != null
                ? DateTime.tryParse(returnDateStr)
                : null,
            passengers: {
              'adults': adults,
              'children': children,
              'infants': infants,
            },
          );

          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) context.push(url);
          });
          return;
        }
      }
    } catch (_) {}

    if (mounted) {
      setState(() => _isRestoringSearch = false);
    }
  }

  void _handleSearch({
    required int fromCityId,
    required String fromLocation,
    required int toCityId,
    required String toLocation,
    required DateTime departDate,
    DateTime? returnDate,
    required Map<String, int> passengers,
  }) async {
    setState(() => _isSearching = true);

    await _recentSearchesService.saveLastSearch(
      fromCityId: fromCityId,
      fromCity: fromLocation,
      toCityId: toCityId,
      toCity: toLocation,
      departDate: departDate,
      returnDate: returnDate,
      passengers: passengers,
    );

    try {
      await Future.delayed(const Duration(seconds: 3));

      if (mounted) {
        setState(() => _isSearching = false);
        context.push(
          buildSearchResultsUrl(
            fromCityId: fromCityId,
            fromCity: fromLocation,
            toCityId: toCityId,
            toCity: toLocation,
            departDate: departDate,
            returnDate: returnDate,
            passengers: passengers,
          ),
          extra: SearchResultsArguments(
            fromCityId: fromCityId,
            fromCity: fromLocation,
            toCityId: toCityId,
            toCity: toLocation,
            departDate: departDate,
            returnDate: returnDate,
            passengers: passengers,
          ),
        );
      }
    } catch (error) {
      if (mounted) setState(() => _isSearching = false);
    }
  }

  Future<void> _loadLeg2Dates(DateTime leg1Date) async {
    final hub = _selectedHub;
    final mainData = _mainFormData;
    if (hub == null || mainData == null) return;

    setState(() {
      _isLoadingLeg2 = true;
      _leg2Dates = [];
      _suggestedLeg1Dates = [];
      _leg2Date = null;
    });

    try {
      final api = CityApiService(AuthService());
      final leg1DateStr =
          '${leg1Date.year}-${leg1Date.month.toString().padLeft(2, '0')}-${leg1Date.day.toString().padLeft(2, '0')}';

      final result = await api.getLeg2DatesWithSuggestions(
        fromCityId: mainData.fromCityId,
        hubCityId: hub.cityId,
        toCityId: mainData.toCityId,
        leg1Date: leg1DateStr,
      );

      if (!mounted) return;

      final leg2Dates = List<String>.from(result['leg2_dates'] ?? []);
      final suggestedLeg1Dates =
          List<String>.from(result['suggested_leg1_dates'] ?? []);

      setState(() {
        _isLoadingLeg2 = false;
        _leg2Dates = leg2Dates;
        _suggestedLeg1Dates = suggestedLeg1Dates;
      });

      if (leg2Dates.length == 1) {
        setState(() => _leg2Date = DateTime.parse(leg2Dates.first));
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingLeg2 = false);
    }
  }

  void _handleMultiSegmentSearch() async {
    final hub = _selectedHub;
    final mainData = _mainFormData;
    if (hub == null ||
        mainData == null ||
        _leg1Date == null ||
        _leg2Date == null) return;

    setState(() => _isSearching = true);

    try {
      await Future.delayed(const Duration(seconds: 3));

      if (!mounted) return;
      setState(() => _isSearching = false);

      final draft = BookingGroupDraft(
        segments: [],
        passengers: _passengers,
        finalDestinationCityId: mainData.toCityId,
        finalDestinationCity: mainData.toCity,
      );

      context.push(
        buildSearchResultsUrl(
          fromCityId: mainData.fromCityId,
          fromCity: mainData.fromCity,
          toCityId: hub.cityId,
          toCity: hub.cityName,
          departDate: _leg1Date!,
          passengers: _passengers,
        ),
        extra: SearchResultsArguments(
          fromCityId: mainData.fromCityId,
          fromCity: mainData.fromCity,
          toCityId: hub.cityId,
          toCity: hub.cityName,
          departDate: _leg1Date!,
          passengers: _passengers,
          bookingGroupDraft: draft,
          leg2Date: _leg2Date,
        ),
      );
    } catch (error) {
      if (mounted) setState(() => _isSearching = false);
    }
  }

  bool get _canSearchMultiSegment =>
      _selectedHub != null &&
      _mainFormData != null &&
      _leg1Date != null &&
      _leg2Date != null;

  void _clearHub() {
    _closeSegmentCalendar();
    _closePassengerSelector();
    setState(() {
      _selectedHub = null;
      _leg1Date = null;
      _leg2Date = null;
      _leg2Dates = [];
      _suggestedLeg1Dates = [];
      _passengers = {'adults': 1, 'children': 0, 'infants': 0};
    });
  }

  void _openSegmentCalendar({
    required GlobalKey fieldKey,
    required List<String> availableDates,
    required DateTime? current,
    required void Function(DateTime?) onSelected,
    required int segmentIndex,
  }) {
    if (_activeSegmentIndex == segmentIndex &&
        _segmentCalendarOverlay != null) {
      _closeSegmentCalendar();
      return;
    }

    _closeSegmentCalendar();
    _closePassengerSelector();

    final availableDatesNotifier = ValueNotifier(availableDates);

    _segmentCalendarOverlay = OverlayEntry(
      builder: (_) {
        final box =
            fieldKey.currentContext?.findRenderObject() as RenderBox?;
        final pos =
            box != null ? box.localToGlobal(Offset.zero) : Offset.zero;
        final fieldHeight = box?.size.height ?? 56.0;
        final screenHeight = MediaQuery.of(context).size.height;
        const calendarHeight = 360.0;

        final top =
            (pos.dy + fieldHeight + 8 + calendarHeight > screenHeight)
                ? pos.dy - calendarHeight - 8
                : pos.dy + fieldHeight + 8;

        return Stack(
          children: [
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTap: _closeSegmentCalendar,
              ),
            ),
            Positioned(
              left: pos.dx,
              top: top,
              width: 400,
              child: Material(
                elevation: 8,
                borderRadius: BorderRadius.circular(12),
                child: ValueListenableBuilder<List<String>>(
                  valueListenable: availableDatesNotifier,
                  builder: (context, dates, _) {
                    return CustomDateRangePicker(
                      departDate: current,
                      returnDate: null,
                      availableDates: dates,
                      returnAvailableDates: const [],
                      isSelectingReturn: false,
                      onDatesSelected: (date, _) {
                        onSelected(date);
                        _closeSegmentCalendar();
                      },
                      onClose: _closeSegmentCalendar,
                    );
                  },
                ),
              ),
            ),
          ],
        );
      },
    );

    Overlay.of(context).insert(_segmentCalendarOverlay!);
    setState(() => _activeSegmentIndex = segmentIndex);
  }

  void _closeSegmentCalendar() {
    _segmentCalendarOverlay?.remove();
    _segmentCalendarOverlay = null;
    if (mounted) setState(() => _activeSegmentIndex = null);
  }

  void _openPassengerSelector() {
    if (_passengerOverlay != null) return;
    if (_passengerFieldKey.currentContext == null) return;

    _closeSegmentCalendar();

    _passengerOverlay = OverlayEntry(
      builder: (_) {
        final box = _passengerFieldKey.currentContext?.findRenderObject()
            as RenderBox?;
        final pos =
            box != null ? box.localToGlobal(Offset.zero) : Offset.zero;
        final fieldHeight = box?.size.height ?? 56.0;
        final screenHeight = MediaQuery.of(context).size.height;
        const selectorHeight = 320.0;
        final top =
            (pos.dy + fieldHeight + 8 + selectorHeight > screenHeight)
                ? pos.dy - selectorHeight - 8
                : pos.dy + fieldHeight + 8;

        return Stack(
          children: [
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTap: _closePassengerSelector,
              ),
            ),
            Positioned(
              left: pos.dx,
              top: top,
              child: Material(
                elevation: 8,
                borderRadius: BorderRadius.circular(8),
                child: PassengerSelector(
                  initialPassengers: _passengers,
                  onChanged: (data) {
                    setState(() => _passengers = data);
                    _passengerOverlay?.markNeedsBuild();
                  },
                  onClose: _closePassengerSelector,
                ),
              ),
            ),
          ],
        );
      },
    );

    Overlay.of(context).insert(_passengerOverlay!);
    setState(() => _isPassengerOpen = true);
  }

  void _closePassengerSelector() {
    _passengerOverlay?.remove();
    _passengerOverlay = null;
    if (mounted) setState(() => _isPassengerOpen = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_isRestoringSearch) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return ResponsiveLayout(
      body: Listener(
        behavior: HitTestBehavior.translucent,
        onPointerDown: (event) {
          _closeFormOverlays?.call(event.position);
        },
        child: SingleChildScrollView(
          child: Column(
            children: [
              FlightSearchForm(
                key: _formKey,
                hideDateAndPassengers: _selectedHub != null,
                onOverlayControllerReady: (closeOverlaysIfOutside) {
                  _closeFormOverlays = closeOverlaysIfOutside;
                },
                onRouteStatusChanged: (routeExists, alternatives) {
                  setState(() {
                    _routeExists = routeExists;
                    _alternatives = alternatives;
                    if (routeExists) _clearHub();
                  });
                },
                onSearch: _selectedHub == null
                    ? ({
                        required int fromCityId,
                        required String fromLocation,
                        required int toCityId,
                        required String toLocation,
                        required DateTime departDate,
                        DateTime? returnDate,
                        required Map<String, int> passengers,
                      }) {
                        _handleSearch(
                          fromCityId: fromCityId,
                          fromLocation: fromLocation,
                          toCityId: toCityId,
                          toLocation: toLocation,
                          departDate: departDate,
                          returnDate: returnDate,
                          passengers: passengers,
                        );
                      }
                    : null,
              ),

              const SizedBox(height: 16),

              if (!_routeExists && !_isSearching)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: _selectedHub == null
                      ? AlternativesSection(
                          alternatives: _alternatives,
                          onHubSelected: (hub) {
                            final formState = _formKey.currentState;
                            if (formState != null) {
                              setState(() {
                                _selectedHub = hub;
                                _mainFormData = formState.currentFormData;
                              });
                            }
                          },
                          onNearbyAirportSelected: (cityId, cityName) {
                            _formKey.currentState
                                ?.applyAlternativeCity(cityId, cityName);
                          },
                        )
                      : MultiSegmentSection(
                          hub: _selectedHub!,
                          mainData: _mainFormData!,
                          leg1Date: _leg1Date,
                          leg2Date: _leg2Date,
                          leg2Dates: _leg2Dates,
                          isLoadingLeg2: _isLoadingLeg2,
                          isCalendarOpen: _activeSegmentIndex == 0,
                          isPassengerOpen: _isPassengerOpen,
                          canSearch: _canSearchMultiSegment,
                          passengers: _passengers,
                          passengerFieldKey: _passengerFieldKey,
                          onLeg1DateChanged: (date) {
                            setState(() {
                              _leg1Date = date;
                              _leg2Date = null;
                              _leg2Dates = [];
                              _suggestedLeg1Dates = [];
                            });
                            if (date != null) _loadLeg2Dates(date);
                          },
                          onLeg2DateSelected: (date) =>
                              setState(() => _leg2Date = date),
                          onClearHub: _clearHub,
                          onSearch: _handleMultiSegmentSearch,
                          onOpenPassenger: _openPassengerSelector,
                          onClosePassenger: _closePassengerSelector,
                          onPassengersChanged: (data) =>
                              setState(() => _passengers = data),
                          onOpenCalendar: (fieldKey, availableDates, current,
                              onSelected) {
                            _openSegmentCalendar(
                              fieldKey: fieldKey,
                              availableDates: availableDates,
                              current: current,
                              onSelected: onSelected,
                              segmentIndex: 0,
                            );
                          },
                        ),
                ),

              if (_isSearching)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: AnimatedFlightProgress(
                    isSearching: _isSearching,
                    onComplete: () {},
                  ),
                ),

              const SizedBox(height: 48),

              if (!_isSearching && _routeExists)
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Icon(
                        Icons.flight,
                        size: 120,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'Welcome to AirShero',
                        style: Theme.of(context).textTheme.displayMedium,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Your journey starts here',
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}