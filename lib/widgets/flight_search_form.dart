import 'package:flutter/material.dart';
import 'custom/custom_input_field.dart';
import 'custom/custom_date_range_picker.dart';
import 'custom/custom_button.dart';
import 'passenger_selector.dart';
import '../services/recent_searches_service.dart';
import '../models/city_model.dart';
import '../services/booking_api_service.dart';
import '../services/auth_service.dart';

typedef SearchCallback = void Function({
  required int fromCityId,
  required String fromLocation,
  required int toCityId,
  required String toLocation,
  required DateTime departDate,
  DateTime? returnDate,
  required Map<String, int> passengers,
});

class FlightSearchForm extends StatefulWidget {
  final SearchCallback? onSearch;
  final void Function(void Function(Offset position) closeOverlaysIfOutside)? onOverlayControllerReady;

  const FlightSearchForm({
    super.key,
    this.onSearch,
    this.onOverlayControllerReady,
  });

  @override
  State<FlightSearchForm> createState() => FlightSearchFormState();
}

class FlightSearchFormState extends State<FlightSearchForm> {
  String fromLocation = '';
  String toLocation = '';
  CityModel? _selectedFromCity;
  CityModel? _selectedToCity;
  List<CityModel> _alternatives = [];
  bool _routeExists = true;
  late final BookingApiService _apiService;

  DateTime? departDate;
  DateTime? returnDate;
  Map<String, int> passengers = {'adults': 1, 'children': 0, 'infants': 0};

  List<String> _availableDates = [];
  List<String> _returnAvailableDates = [];

  List<Map<String, String>> _recentSearches = [];
  List<String> _recentCities = [];
  final _recentSearchesService = RecentSearchesService();

  // Calendar state owned here — no parent props
  bool _isCalendarOpen = false;
  final ValueNotifier<bool> _isSelectingReturnNotifier =
      ValueNotifier<bool>(false);
  bool get _isSelectingReturn => _isSelectingReturnNotifier.value;
  set _isSelectingReturn(bool v) => _isSelectingReturnNotifier.value = v;

  bool _isPassengerSelectorOpen = false;
  bool _showCitiesRequired = false;

  final GlobalKey _passengerFieldKey = GlobalKey();
  final GlobalKey _departFieldKey = GlobalKey();
  final GlobalKey _returnFieldKey = GlobalKey();

  OverlayEntry? _passengerOverlay;
  OverlayEntry? _calendarOverlay;
  Size? _lastConstraints;

  @override
  void initState() {
    super.initState();
    _apiService = BookingApiService(AuthService());
    _loadRecentSearches();
    // Give parent a function that closes overlays only if the tap
    // is outside the overlay-owning fields (Depart, Return, Passengers).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.onOverlayControllerReady?.call(_closeOverlaysIfOutsideFields);
    });
  }

  @override
  void dispose() {
    _isSelectingReturnNotifier.dispose();
    _calendarOverlay?.remove();
    _passengerOverlay?.remove();
    super.dispose();
  }

  // ─── Data ──────────────────────────────────────────────────────────────────

  Future<void> _loadRecentSearches() async {
    final routes = await _recentSearchesService.loadRoutes();
    final cities = await _recentSearchesService.loadCities();
    if (mounted) {
      setState(() {
        _recentSearches = routes;
        _recentCities = cities;
      });
    }
  }

  void _fetchAvailableDates() async {
    if (_selectedFromCity == null || _selectedToCity == null) return;

    setState(() {
      _availableDates = [];
      _returnAvailableDates = [];
    });
    _calendarOverlay?.markNeedsBuild();

    try {
      final results = await Future.wait([
        _apiService.getAvailableDates(
          _selectedFromCity!.cityId,
          _selectedToCity!.cityId,
        ),
        _apiService.getAvailableDates(
          _selectedToCity!.cityId,
          _selectedFromCity!.cityId,
        ),
      ]);

      if (!mounted) return;
      setState(() {
        _availableDates = results[0];
        _returnAvailableDates = results[1];

        if (_availableDates.isEmpty) {
          _routeExists = false;
          _loadAlternatives();
        } else {
          _routeExists = true;
          _alternatives = [];
          if (departDate != null) {
            final formatted =
                '${departDate!.year}-${departDate!.month.toString().padLeft(2, '0')}-${departDate!.day.toString().padLeft(2, '0')}';
            if (!_availableDates.contains(formatted)) {
              departDate = DateTime.parse(_availableDates.first);
              returnDate = null;
            }
          }
        }
      });
      _calendarOverlay?.markNeedsBuild();
    } catch (e) {
      debugPrint('Fetch dates error: $e');
      if (mounted) setState(() => _routeExists = false);
      _loadAlternatives();
    }
  }

  void _loadAlternatives() async {
    try {
      final list =
          await _apiService.getAlternatives(_selectedFromCity!.cityId);
      if (mounted) setState(() => _alternatives = list);
    } catch (e) {
      debugPrint('Alternatives error: $e');
    }
  }

  // ─── Format ────────────────────────────────────────────────────────────────

  String _formatDate(DateTime? date) {
    if (date == null) return 'Select date';
    return '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';
  }

  String _formatPassengers() {
    final total = passengers.values.reduce((a, b) => a + b);
    return '$total passenger${total > 1 ? 's' : ''}';
  }

  // ─── Overlays ──────────────────────────────────────────────────────────────

  void _openCalendar() {
    if (_calendarOverlay != null) return;
    if (_departFieldKey.currentContext == null) return;

    _calendarOverlay = OverlayEntry(
      builder: (_) => _CalendarOverlay(
        departFieldKey: _departFieldKey,
        returnFieldKey: _returnFieldKey,
        departDate: departDate,
        returnDate: returnDate,
        availableDates: _availableDates,
        returnAvailableDates: _returnAvailableDates,
        isSelectingReturnNotifier: _isSelectingReturnNotifier,
        onDatesSelected: (depart, ret) {
          setState(() {
            departDate = depart;
            returnDate = ret;
          });
          _calendarOverlay?.markNeedsBuild();
        },
        onClose: _closeCalendar,
      ),
    );

    Overlay.of(context).insert(_calendarOverlay!);
    setState(() => _isCalendarOpen = true);
  }

  void _closeCalendar() {
    _calendarOverlay?.remove();
    _calendarOverlay = null;
    if (mounted) setState(() => _isCalendarOpen = false);
  }

  void _openPassengerSelector() {
    if (_passengerOverlay != null) return;
    if (_passengerFieldKey.currentContext == null) return;

    _passengerOverlay = OverlayEntry(
      builder: (_) => _PassengerSelectorOverlay(
        fieldKey: _passengerFieldKey,
        passengers: passengers,
        onChanged: (data) => setState(() => passengers = data),
        onClose: _closePassengerSelector,
      ),
    );

    Overlay.of(context).insert(_passengerOverlay!);
    setState(() => _isPassengerSelectorOpen = true);
  }

  void _closePassengerSelector() {
    _passengerOverlay?.remove();
    _passengerOverlay = null;
    if (mounted) setState(() => _isPassengerSelectorOpen = false);
  }

  void _closeAllOverlays() {
    _closeCalendar();
    _closePassengerSelector();
  }

  /// Called by parent Listener. Closes overlays only when the tap
  /// position is outside all overlay-owning fields.
  void _closeOverlaysIfOutsideFields(Offset position) {
    if (!_isCalendarOpen && !_isPassengerSelectorOpen) return;
    for (final key in [_departFieldKey, _returnFieldKey, _passengerFieldKey]) {
      final box = key.currentContext?.findRenderObject() as RenderBox?;
      if (box != null && box.hasSize) {
        final rect = box.localToGlobal(Offset.zero) & box.size;
        if (rect.contains(position)) return; // tap is on a field — don't close
      }
    }
    _closeAllOverlays();
  }

  // ─── Search ────────────────────────────────────────────────────────────────

  void _handleSearch() {
    if (_selectedFromCity == null || _selectedToCity == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content:
                Text('Please select both departure and destination cities')),
      );
      return;
    }

    if (fromLocation.isNotEmpty && toLocation.isNotEmpty) {
      _recentSearchesService.add(fromLocation, toLocation);
      _loadRecentSearches();
    }

    widget.onSearch?.call(
      fromCityId: _selectedFromCity!.cityId,
      fromLocation: fromLocation,
      toCityId: _selectedToCity!.cityId,
      toLocation: toLocation,
      departDate: departDate ?? DateTime.now(),
      returnDate: returnDate,
      passengers: passengers,
    );
  }

  // ─── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final currentSize = Size(constraints.maxWidth, constraints.maxHeight);
        if (_lastConstraints != currentSize) {
          _lastConstraints = currentSize;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              _passengerOverlay?.markNeedsBuild();
              _calendarOverlay?.markNeedsBuild();
            }
          });
        }

        return Listener(
          behavior: HitTestBehavior.translucent,
          onPointerDown: (event) {
            if (!_isCalendarOpen && !_isPassengerSelectorOpen) return;
            // Only close when clicking outside the ENTIRE form widget.
            // Clicks on fields (Depart/Return/Passengers) are handled by their onTap.
            // Clicks on the overlay panels (calendar/passenger) are above the form in z-order.
            final formBox = context.findRenderObject() as RenderBox?;
            if (formBox != null && formBox.hasSize) {
              final formRect = formBox.localToGlobal(Offset.zero) & formBox.size;
              if (formRect.contains(event.position)) return; // inside form — let fields handle
            }
            _closeCalendar();
            _closePassengerSelector();
          },
          child: Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            children: [
              // ── From / To ──────────────────────────────────────────────
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: CustomInputField(
                      label: 'From',
                      value: fromLocation,
                      icon: Icons.location_on,
                      searchAirports: true,
                      isFromField: true,
                      previousSearches: _recentSearches,
                      recentCities: _recentCities,
                      onChanged: (v) => setState(() => fromLocation = v),
                      onCitySelected: (city) {
                        setState(() {
                          _selectedFromCity = city;
                          fromLocation = city.cityName;
                        });
                        _fetchAvailableDates();
                      },
                      // onTap not needed — TapRegion in overlays handles outside-close
                      onPairSelect: (from, to) => setState(() {
                        fromLocation = from;
                        toLocation = to;
                      }),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 8),
                    child: IconButton(
                      onPressed: () {
                        setState(() {
                          final tl = fromLocation;
                          fromLocation = toLocation;
                          toLocation = tl;
                          final tc = _selectedFromCity;
                          _selectedFromCity = _selectedToCity;
                          _selectedToCity = tc;
                          final td = _availableDates;
                          _availableDates = _returnAvailableDates;
                          _returnAvailableDates = td;
                        });
                      },
                      icon: Icon(Icons.swap_horiz,
                          color: Theme.of(context).colorScheme.primary),
                      tooltip: 'Swap locations',
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CustomInputField(
                          label: 'To',
                          value: toLocation,
                          icon: Icons.location_on,
                          searchAirports: true,
                          isFromField: false,
                          previousSearches: _recentSearches,
                          recentCities: _recentCities,
                          onChanged: (v) => setState(() => toLocation = v),
                          onCitySelected: (city) {
                            setState(() {
                              _selectedToCity = city;
                              toLocation = city.cityName;
                            });
                            _fetchAvailableDates();
                          },
                          // onTap not needed — TapRegion in overlays handles outside-close
                          onPairSelect: (from, to) => setState(() {
                            fromLocation = from;
                            toLocation = to;
                          }),
                        ),
                        if (!_routeExists)
                          Padding(
                            padding: const EdgeInsets.only(top: 4, left: 4),
                            child: Text(
                              'Route does not exist',
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.error,
                                fontSize: 12,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // ── Depart / Return ────────────────────────────────────────
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      // DEPART
                      Expanded(
                        child: CustomInputField(
                          key: _departFieldKey,
                          label: 'Depart',
                          value: _formatDate(departDate),
                          icon: Icons.calendar_today,
                          readOnly: true,
                          isSelected:
                              _isCalendarOpen && !_isSelectingReturn,
                          onTap: () {
                            if (_selectedFromCity == null ||
                                _selectedToCity == null) {
                              setState(() => _showCitiesRequired = true);
                              return;
                            }
                            setState(() => _showCitiesRequired = false);
                            _closePassengerSelector();

                            if (!_isCalendarOpen) {
                              _isSelectingReturn = false;
                              _openCalendar();
                            } else if (_isSelectingReturn) {
                              // Switch mode, keep overlay open
                              _isSelectingReturn = false;
                            } else {
                              _closeCalendar();
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      // RETURN
                      Expanded(
                        child: CustomInputField(
                          key: _returnFieldKey,
                          label: 'Return',
                          value: _formatDate(returnDate),
                          icon: Icons.calendar_today,
                          readOnly: true,
                          isSelected:
                              _isCalendarOpen && _isSelectingReturn,
                          onTap: () {
                            if (_selectedFromCity == null ||
                                _selectedToCity == null) {
                              setState(() => _showCitiesRequired = true);
                              return;
                            }
                            setState(() => _showCitiesRequired = false);
                            _closePassengerSelector();

                            if (!_isCalendarOpen) {
                              _isSelectingReturn = true;
                              _openCalendar();
                            } else if (!_isSelectingReturn) {
                              // Switch mode, keep overlay open
                              _isSelectingReturn = true;
                            } else {
                              _closeCalendar();
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                  if (_showCitiesRequired)
                    Padding(
                      padding: const EdgeInsets.only(top: 4, left: 4),
                      child: Text(
                        'Please select departure and destination cities first',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                          fontSize: 12,
                        ),
                      ),
                    ),
                ],
              ),

              const SizedBox(height: 12),

              // ── Passengers / Search ────────────────────────────────────
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 2,
                    child: CustomInputField(
                      key: _passengerFieldKey,
                      label: 'Passengers',
                      value: _formatPassengers(),
                      icon: Icons.person,
                      readOnly: true,
                      isSelected: _isPassengerSelectorOpen,
                      onTap: () {
                        if (_isPassengerSelectorOpen) {
                          _closePassengerSelector();
                        } else {
                          _closeCalendar();
                          _openPassengerSelector();
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: CustomButton(
                      label: 'Search',
                      onPressed: _routeExists ? _handleSearch : null,
                    ),
                  ),
                ],
              ),

              // ── Alternatives ───────────────────────────────────────────
              if (!_routeExists && _alternatives.isNotEmpty) ...[
                const SizedBox(height: 16),
                const Divider(),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    'Available destinations from this city:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _alternatives
                      .map(
                        (city) => ActionChip(
                          label: Text(city.cityName),
                          onPressed: () {
                            setState(() {
                              _selectedToCity = city;
                              toLocation = city.cityName;
                              _routeExists = true;
                              _alternatives = [];
                            });
                            _fetchAvailableDates();
                          },
                        ),
                      )
                      .toList(),
                ),
              ],
            ],
          ),
          ),
        );
      },
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// Calendar Overlay
// ═══════════════════════════════════════════════════════════════════════════════

class _CalendarOverlay extends StatelessWidget {
  final GlobalKey departFieldKey;
  final GlobalKey returnFieldKey;
  final DateTime? departDate;
  final DateTime? returnDate;
  final List<String> availableDates;
  final List<String> returnAvailableDates;
  final ValueNotifier<bool> isSelectingReturnNotifier;
  final Function(DateTime?, DateTime?) onDatesSelected;
  final VoidCallback onClose;

  const _CalendarOverlay({
    required this.departFieldKey,
    required this.returnFieldKey,
    required this.departDate,
    required this.returnDate,
    required this.availableDates,
    required this.returnAvailableDates,
    required this.isSelectingReturnNotifier,
    required this.onDatesSelected,
    required this.onClose,
  });

  Offset _pos(GlobalKey key) {
    final b = key.currentContext?.findRenderObject() as RenderBox?;
    return (b != null && b.hasSize) ? b.localToGlobal(Offset.zero) : Offset.zero;
  }

  double _h(GlobalKey key) {
    final b = key.currentContext?.findRenderObject() as RenderBox?;
    return (b != null && b.hasSize) ? b.size.height : 56.0;
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: isSelectingReturnNotifier,
      builder: (context, isSelectingReturn, _) {
        final key = isSelectingReturn ? returnFieldKey : departFieldKey;
        final pos = _pos(key);
        final top = pos.dy + _h(key) + 8;

        return Stack(
          children: [
            Positioned(
              left: pos.dx,
              top: top,
              width: 400,
              child: Material(
                elevation: 8,
                borderRadius: BorderRadius.circular(12),
                child: CustomDateRangePicker(
                  key: ValueKey(
                      '$isSelectingReturn-${availableDates.length}-${returnAvailableDates.length}'),
                  departDate: departDate,
                  returnDate: returnDate,
                  availableDates: availableDates,
                  returnAvailableDates: returnAvailableDates,
                  isSelectingReturn: isSelectingReturn,
                  onDatesSelected: onDatesSelected,
                  onClose: onClose,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// Passenger Selector Overlay
// ═══════════════════════════════════════════════════════════════════════════════

class _PassengerSelectorOverlay extends StatelessWidget {
  final GlobalKey fieldKey;
  final Map<String, int> passengers;
  final ValueChanged<Map<String, int>> onChanged;
  final VoidCallback onClose;

  const _PassengerSelectorOverlay({
    required this.fieldKey,
    required this.passengers,
    required this.onChanged,
    required this.onClose,
  });

  Offset _pos() {
    final b = fieldKey.currentContext?.findRenderObject() as RenderBox?;
    return (b != null && b.hasSize) ? b.localToGlobal(Offset.zero) : Offset.zero;
  }

  double _h() {
    final b = fieldKey.currentContext?.findRenderObject() as RenderBox?;
    return (b != null && b.hasSize) ? b.size.height : 56.0;
  }

  @override
  Widget build(BuildContext context) {
    final pos = _pos();
    final top = pos.dy + _h() + 8;

    return Stack(
      children: [
        Positioned(
          left: pos.dx,
          top: top,
          child: Material(
            elevation: 8,
            borderRadius: BorderRadius.circular(8),
            child: PassengerSelector(
              initialPassengers: passengers,
              onChanged: onChanged,
              onClose: onClose,
            ),
          ),
        ),
      ],
    );
  }
}