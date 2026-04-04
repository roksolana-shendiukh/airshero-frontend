import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../widgets/booking/flight_search_form.dart';
import '../widgets/booking/segment_date_form.dart';
import '../widgets/responsive_layout.dart';
import '../widgets/animation/animated_flight_progress.dart';
import '../widgets/custom/custom_input_field.dart';
import '../widgets/custom/custom_date_range_picker.dart';
import '../widgets/custom/custom_button.dart';
import '../widgets/passenger_selector.dart';
import '../config/routes.dart';
import '../services/recent_searches_service.dart';
import '../services/auth_service.dart';
import '../services/booking_api_service.dart';
import '../models/flight_alternatives_model.dart';
import '../models/booking_group_draft.dart';

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

  _HubSelection? _selectedHub;
  DateTime? _leg1Date;
  DateTime? _leg2Date;
  MainFormData? _mainFormData;

  // Leg2 стан
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
        final fromCityId = last['fromCityId'] as int? ?? 0;
        final fromCity = last['fromCity'] as String? ?? '';
        final toCityId = last['toCityId'] as int? ?? 0;
        final toCity = last['toCity'] as String? ?? '';
        final departDateStr = last['departDate'] as String? ?? '';
        final returnDateStr = last['returnDate'] as String?;
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
            returnDate:
                returnDateStr != null ? DateTime.tryParse(returnDateStr) : null,
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
      if (mounted) {
        setState(() => _isSearching = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Search failed: $error')),
        );
      }
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
      final api = BookingApiService(AuthService());
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
      if (mounted) {
        setState(() => _isLoadingLeg2 = false);
      }
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
      if (mounted) {
        setState(() => _isSearching = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Search failed: $error')),
        );
      }
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

  String _formatPassengers() {
    final total = _passengers.values.reduce((a, b) => a + b);
    return '$total passenger${total > 1 ? 's' : ''}';
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';
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
                      ? _buildAlternativesSection(context)
                      : _buildMultiSegmentSection(context),
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

  Widget _buildAlternativesSection(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      decoration: BoxDecoration(
        color: colors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(4),
        border: Border(
          left: BorderSide(color: colors.primary, width: 3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'No direct flights available',
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'The following routing options are available for this route.',
                  style: textTheme.bodySmall?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),

          if (_alternatives == null ||
              (_alternatives!.nearbyCities.isEmpty &&
                  _alternatives!.connectingHubs.isEmpty))
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: Text(
                'No alternative routes found. Please select different cities.',
                style: textTheme.bodySmall?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
              ),
            )
          else ...[
            if (_alternatives!.connectingHubs.isNotEmpty) ...[
              _buildSectionDivider(context),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
                child: Row(
                  children: [
                    Text(
                      'VIA CONNECTING CITY',
                      style: textTheme.labelSmall?.copyWith(
                        color: colors.onSurfaceVariant,
                        letterSpacing: 1.2,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: colors.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(3),
                      ),
                      child: Text(
                        '2 bookings required',
                        style: textTheme.labelSmall?.copyWith(
                          color: colors.onSurfaceVariant,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _alternatives!.connectingHubs.map((hub) {
                    return _ConnectingHubButton(
                      cityName: hub.cityName,
                      onTap: () {
                        final formState = _formKey.currentState;
                        if (formState != null) {
                          setState(() {
                            _selectedHub = _HubSelection(
                              cityId: hub.cityId,
                              cityName: hub.cityName,
                            );
                            _mainFormData = formState.currentFormData;
                          });
                        }
                      },
                    );
                  }).toList(),
                ),
              ),
            ],

            if (_alternatives!.nearbyCities.isNotEmpty) ...[
              _buildSectionDivider(context),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
                child: Text(
                  'NEARBY AIRPORTS',
                  style: textTheme.labelSmall?.copyWith(
                    color: colors.onSurfaceVariant,
                    letterSpacing: 1.2,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _alternatives!.nearbyCities.map((city) {
                    return _NearbyAirportButton(
                      cityName: city.cityName,
                      distanceKm: city.distanceKm,
                      onTap: () {
                        _formKey.currentState?.applyAlternativeCity(
                            city.cityId, city.cityName);
                      },
                    );
                  }).toList(),
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }

  Widget _buildSectionDivider(BuildContext context) {
    return Divider(
      height: 1,
      thickness: 1,
      color: Theme.of(context).colorScheme.outlineVariant.withOpacity(0.5),
    );
  }

  Widget _buildMultiSegmentSection(BuildContext context) {
    final hub = _selectedHub!;
    final mainData = _mainFormData;
    if (mainData == null) return const SizedBox.shrink();
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: colors.surfaceContainerLow,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(4),
              topRight: Radius.circular(4),
            ),
            border: Border(
              left: BorderSide(color: colors.primary, width: 3),
              top: BorderSide(
                  color: colors.outlineVariant.withOpacity(0.5)),
              right: BorderSide(
                  color: colors.outlineVariant.withOpacity(0.5)),
              bottom: BorderSide(
                  color: colors.outlineVariant.withOpacity(0.5)),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'CONNECTING ROUTE',
                      style: textTheme.labelSmall?.copyWith(
                        color: colors.primary,
                        letterSpacing: 1.2,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${mainData.fromCity}  →  ${hub.cityName}  →  ${mainData.toCity}',
                      style: textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                        letterSpacing: -0.2,
                      ),
                    ),
                  ],
                ),
              ),
              TextButton(
                onPressed: _clearHub,
                style: TextButton.styleFrom(
                  foregroundColor: colors.onSurfaceVariant,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 8),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(
                  'Change route',
                  style: textTheme.labelSmall?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 12),

        SegmentDateForm(
          fromCityId: mainData.fromCityId,
          fromCity: mainData.fromCity,
          toCityId: hub.cityId,
          toCity: hub.cityName,
          finalDestinationCityId: mainData.toCityId,
          isCalendarOpen: _activeSegmentIndex == 0,
          onDateChanged: (date) {
            setState(() {
              _leg1Date = date;
              _leg2Date = null;
              _leg2Dates = [];
              _suggestedLeg1Dates = [];
            });
            if (date != null) {
              _loadLeg2Dates(date);
            }
          },
          onRemove: _clearHub,
          onOpenCalendar: (fieldKey, availableDates, current, onSelected) {
            _openSegmentCalendar(
              fieldKey: fieldKey,
              availableDates: availableDates,
              current: current,
              onSelected: onSelected,
              segmentIndex: 0,
            );
          },
        ),

        const SizedBox(height: 8),

        Row(
          children: [
            const SizedBox(width: 16),
            Container(
              width: 1,
              height: 16,
              color: colors.outlineVariant,
            ),
          ],
        ),

        const SizedBox(height: 8),

        _buildLeg2Result(context, hub, mainData, colors, textTheme),

        const SizedBox(height: 16),

        CustomInputField(
          key: _passengerFieldKey,
          label: 'Passengers',
          value: _formatPassengers(),
          icon: Icons.person_outline,
          readOnly: true,
          isSelected: _isPassengerOpen,
          onTap: () {
            if (_isPassengerOpen) {
              _closePassengerSelector();
            } else {
              _openPassengerSelector();
            }
          },
        ),

        const SizedBox(height: 16),

        SizedBox(
          width: double.infinity,
          child: CustomButton(
            label: 'Search flights',
            onPressed:
                _canSearchMultiSegment ? _handleMultiSegmentSearch : null,
          ),
        ),
      ],
    );
  }

  Widget _buildLeg2Result(
    BuildContext context,
    _HubSelection hub,
    MainFormData mainData,
    ColorScheme colors,
    TextTheme textTheme,
  ) {
    if (_leg1Date == null) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: colors.surfaceContainerLow.withOpacity(0.5),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: colors.outlineVariant.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Icon(Icons.arrow_forward, size: 14, color: colors.onSurfaceVariant),
            const SizedBox(width: 8),
            Text(
              '${hub.cityName}  →  ${mainData.toCity}',
              style: textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: colors.onSurfaceVariant,
              ),
            ),
            const Spacer(),
            Text(
              'Select first leg date to see options',
              style: textTheme.bodySmall?.copyWith(color: colors.onSurfaceVariant),
            ),
          ],
        ),
      );
    }

    if (_isLoadingLeg2) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: colors.surfaceContainerLow,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: colors.outlineVariant.withOpacity(0.6)),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2, color: colors.primary),
            ),
            const SizedBox(width: 12),
            Text(
              'Looking for connecting flights...',
              style: textTheme.bodySmall?.copyWith(color: colors.onSurfaceVariant),
            ),
          ],
        ),
      );
    }

    if (_leg2Date != null) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: colors.surfaceContainerLow,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: colors.primary.withOpacity(0.4)),
        ),
        child: Row(
          children: [
            Icon(Icons.check_circle_outline, size: 16, color: colors.primary),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${hub.cityName}  →  ${mainData.toCity}',
                    style: textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  Text(
                    _formatDate(_leg2Date!),
                    style: textTheme.bodySmall?.copyWith(
                      color: colors.primary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            if (_leg2Dates.length > 1)
              TextButton(
                onPressed: () => setState(() => _leg2Date = null),
                style: TextButton.styleFrom(
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                ),
                child: Text(
                  'Change',
                  style: textTheme.labelSmall?.copyWith(color: colors.onSurfaceVariant),
                ),
              ),
          ],
        ),
      );
    }

    if (_leg2Dates.length > 1) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: colors.surfaceContainerLow,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: colors.outlineVariant.withOpacity(0.6)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${hub.cityName}  →  ${mainData.toCity}',
              style: textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              'Select connecting flight date:',
              style: textTheme.bodySmall?.copyWith(color: colors.onSurfaceVariant),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: _leg2Dates.map((dateStr) {
                final date = DateTime.parse(dateStr);
                return InkWell(
                  onTap: () => setState(() => _leg2Date = date),
                  borderRadius: BorderRadius.circular(4),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: colors.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: colors.outlineVariant),
                    ),
                    child: Text(
                      _formatDate(date),
                      style: textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w500,
                        color: colors.primary,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      );
    }

    return const SizedBox.shrink();
  }

}


class _HubSelection {
  final int cityId;
  final String cityName;
  const _HubSelection({required this.cityId, required this.cityName});
}

class _ConnectingHubButton extends StatefulWidget {
  final String cityName;
  final VoidCallback onTap;

  const _ConnectingHubButton({
    required this.cityName,
    required this.onTap,
  });

  @override
  State<_ConnectingHubButton> createState() => _ConnectingHubButtonState();
}

class _ConnectingHubButtonState extends State<_ConnectingHubButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: _hovered
                ? colors.primary.withOpacity(0.08)
                : colors.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(
              color: _hovered ? colors.primary : colors.outlineVariant,
              width: _hovered ? 1.5 : 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'via',
                style: textTheme.bodySmall?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                widget.cityName,
                style: textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: _hovered ? colors.primary : colors.onSurface,
                  letterSpacing: -0.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NearbyAirportButton extends StatefulWidget {
  final String cityName;
  final int distanceKm;
  final VoidCallback onTap;

  const _NearbyAirportButton({
    required this.cityName,
    required this.distanceKm,
    required this.onTap,
  });

  @override
  State<_NearbyAirportButton> createState() => _NearbyAirportButtonState();
}

class _NearbyAirportButtonState extends State<_NearbyAirportButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: _hovered
                ? colors.primary.withOpacity(0.06)
                : colors.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(
              color: _hovered ? colors.primary : colors.outlineVariant,
              width: _hovered ? 1.5 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                widget.cityName,
                style: textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: _hovered ? colors.primary : colors.onSurface,
                  letterSpacing: -0.2,
                ),
              ),
              Text(
                '${widget.distanceKm} km from destination',
                style: textTheme.labelSmall?.copyWith(
                  color: colors.onSurfaceVariant,
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}