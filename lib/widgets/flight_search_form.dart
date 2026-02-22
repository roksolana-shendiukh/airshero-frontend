import 'package:flutter/material.dart';
import 'custom/custom_input_field.dart';
import 'custom/custom_date_range_picker.dart';
import 'custom/custom_button.dart';
import 'passenger_selector.dart';
import '../models/class.dart';
import '../services/recent_searches_service.dart';
import '../models/city_model.dart';
import '../services/booking_api_service.dart'; 
import '../services/auth_service.dart';        

typedef SearchCallback = void Function({
  required String fromLocation,
  required String toLocation,
  required DateTime departDate,
  DateTime? returnDate,
  required Map<String, int> passengers,
  required Map<int, Class> passengerClasses,
});

class FlightSearchForm extends StatefulWidget {
  final bool isCalendarOpen;
  final ValueChanged<bool> onCalendarToggle;
  final SearchCallback? onSearch;

  const FlightSearchForm({
    super.key,
    required this.isCalendarOpen,
    required this.onCalendarToggle,
    this.onSearch,
  });

  @override
  State<FlightSearchForm> createState() => _FlightSearchFormState();
}

class _FlightSearchFormState extends State<FlightSearchForm> {
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
  Map<int, Class> passengerClasses = {0: Class.economy};

  List<String> _availableDates = [];
  bool _isLoadingDates = false;

  List<Map<String, String>> _recentSearches = [];
  List<String> _recentCities = [];
  final _recentSearchesService = RecentSearchesService();

  final ValueNotifier<bool> _isSelectingReturnNotifier =
      ValueNotifier<bool>(false);
  bool _isPassengerSelectorOpen = false;
  final GlobalKey _passengerFieldKey = GlobalKey();
  final GlobalKey _departFieldKey = GlobalKey();
  final GlobalKey _returnFieldKey = GlobalKey();
  OverlayEntry? _passengerOverlay;
  OverlayEntry? _calendarOverlay;
  Size? _lastConstraints;

  bool get _isSelectingReturn => _isSelectingReturnNotifier.value;
  set _isSelectingReturn(bool value) => _isSelectingReturnNotifier.value = value;

  @override
  void initState() {
    super.initState();
    _apiService = BookingApiService(AuthService()); 
    _loadRecentSearches();
  }

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

    debugPrint("DEBUG API CALL: From ${_selectedFromCity!.cityName} (ID: ${_selectedFromCity!.cityId}) To ${_selectedToCity!.cityName} (ID: ${_selectedToCity!.cityId})");

    setState(() {
      _isLoadingDates = true;
      _availableDates = []; 
    });

    try {
      final datesStr = await _apiService.getAvailableDates(
        _selectedFromCity!.cityId,
        _selectedToCity!.cityId,
      );

      setState(() {
        _availableDates = datesStr; 
        
        if (_availableDates.isEmpty) {
          _routeExists = false;
          _loadAlternatives(); 
        } else {
          _routeExists = true;
          _alternatives = [];
          
          if (departDate != null) {
            final formattedDepart = "${departDate!.year}-${departDate!.month.toString().padLeft(2, '0')}-${departDate!.day.toString().padLeft(2, '0')}";
            
            if (!_availableDates.contains(formattedDepart)) {
              departDate = DateTime.parse(_availableDates.first);
              returnDate = null; 
            }
          }
        }
      });
    } catch (e) {
      debugPrint("Fetch dates error: $e");
      setState(() => _routeExists = false);
      _loadAlternatives(); 
    } finally {
      setState(() {
        _isLoadingDates = false;
      });
    }
  }


  void _loadAlternatives() async {
    try {
      final list = await _apiService.getAlternatives(_selectedFromCity!.cityId);
      setState(() => _alternatives = list);
    } catch (e) {
      debugPrint("Alternative does not have: $e");
    }
  }
  
  String _formatDate(DateTime? date) {
    if (date == null) return 'Select date';
    return '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';
  }

  String _formatPassengers() {
    final total = passengers.values.reduce((a, b) => a + b);
    final classes = passengerClasses.values.toSet();
    final classLabel =
        classes.length == 1 ? classes.first.label : 'Mixed class';
    return '$total passenger${total > 1 ? 's' : ''}, $classLabel';
  }

  void _showPassengerSelector() {
    if (_passengerFieldKey.currentContext == null) return;
    final RenderBox? box =
        _passengerFieldKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return;

    _passengerOverlay?.remove();

    _passengerOverlay = OverlayEntry(
      builder: (context) => _PassengerSelectorOverlay(
        fieldKey: _passengerFieldKey,
        passengers: passengers,
        passengerClasses: passengerClasses,
        onChanged: (data) {
          setState(() {
            passengers = {
              'adults': data['adults'],
              'children': data['children'],
              'infants': data['infants'],
            };
            final rawClasses = data['passengerClasses'] as Map<int, String>;
            passengerClasses = rawClasses.map(
              (index, label) => MapEntry(index, Class.fromLabel(label)),
            );
          });
        },
        onClose: () {
          _hidePassengerSelector();
          setState(() => _isPassengerSelectorOpen = false);
        },
      ),
    );

    Overlay.of(context).insert(_passengerOverlay!);
  }

  void _showCalendar() {
    if (_calendarOverlay != null) return;
    if (_departFieldKey.currentContext == null) return;
    final RenderBox? box =
        _departFieldKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return;

    if (_isLoadingDates) {
        debugPrint("Дати ще вантажаться...");
    }

    _calendarOverlay = OverlayEntry(
      builder: (context) => _CalendarOverlay(
        departFieldKey: _departFieldKey,
        returnFieldKey: _returnFieldKey,
        departDate: departDate,
        returnDate: returnDate,
        availableDates: _availableDates, 
        isSelectingReturnNotifier: _isSelectingReturnNotifier,
        onDatesSelected: (depart, returnD) {
          setState(() {
            departDate = depart;
            returnDate = returnD;
          });
        },
        onClose: () {
          _hideCalendar();
          widget.onCalendarToggle(false);
        },
      ),
    );

    Overlay.of(context).insert(_calendarOverlay!);
  }

  void _hidePassengerSelector() {
    _passengerOverlay?.remove();
    _passengerOverlay = null;
  }

  void _hideCalendar() {
    _calendarOverlay?.remove();
    _calendarOverlay = null;
  }

  void _closeAllOverlays() {
    if (widget.isCalendarOpen) {
      widget.onCalendarToggle(false);
      _hideCalendar();
    }
    if (_isPassengerSelectorOpen) {
      _hidePassengerSelector();
      setState(() => _isPassengerSelectorOpen = false);
    }
  }

  @override
  void dispose() {
    _isSelectingReturnNotifier.dispose();
    _hidePassengerSelector();
    _hideCalendar();
    super.dispose();
  }

  @override
  void didUpdateWidget(FlightSearchForm oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.isCalendarOpen && !oldWidget.isCalendarOpen) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (widget.isCalendarOpen && mounted) _showCalendar();
      });
    }

    if (!widget.isCalendarOpen && oldWidget.isCalendarOpen) {
      _hideCalendar();
    }
  }

  void _handleSearch() {
    if (fromLocation.isNotEmpty && toLocation.isNotEmpty) {
      _recentSearchesService.add(fromLocation, toLocation);
      _loadRecentSearches();
    }
    widget.onSearch?.call(
      fromLocation: fromLocation,
      toLocation: toLocation,
      departDate: departDate ?? DateTime.now(),
      returnDate: returnDate,
      passengers: passengers,
      passengerClasses: passengerClasses,
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final currentSize = Size(constraints.maxWidth, constraints.maxHeight);

        if (_lastConstraints != currentSize) {
          _lastConstraints = currentSize;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              if (_isPassengerSelectorOpen) _passengerOverlay?.markNeedsBuild();
              if (widget.isCalendarOpen) _calendarOverlay?.markNeedsBuild();
            }
          });
        }

        return Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            children: [
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
                      onChanged: (value) => setState(() => fromLocation = value),
                      onCitySelected: (city) {
                        setState(() {
                          _selectedFromCity = city;
                          fromLocation = city.cityName;
                        });
                        _fetchAvailableDates(); 
                      },
                      onTap: _closeAllOverlays,
                      onPairSelect: (from, to) => setState(() {
                        fromLocation = from;
                        toLocation = to;
                      }),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                    child: IconButton(
                      onPressed: () {
                        setState(() {
                          final tempLoc = fromLocation;
                          fromLocation = toLocation;
                          toLocation = tempLoc;

                          final tempCity = _selectedFromCity;
                          _selectedFromCity = _selectedToCity;
                          _selectedToCity = tempCity;
                        });
                        _fetchAvailableDates(); 
                      },
                      icon: Icon(
                        Icons.swap_horiz,
                        color: Theme.of(context).colorScheme.primary,
                      ),
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
                          onChanged: (value) => setState(() => toLocation = value),
                          onCitySelected: (city) {
                            setState(() {
                              _selectedToCity = city;
                              toLocation = city.cityName;
                            });
                            _fetchAvailableDates(); 
                          },
                          onTap: _closeAllOverlays,
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

              Row(
                children: [
                  Expanded(
                    child: CustomInputField(
                      key: _departFieldKey,
                      label: 'Depart',
                      value: _formatDate(departDate),
                      icon: Icons.calendar_today,
                      readOnly: true,
                      isSelected: widget.isCalendarOpen && !_isSelectingReturn,
                      onTap: () {
                        _hidePassengerSelector();
                        setState(() => _isPassengerSelectorOpen = false);
                        if (!widget.isCalendarOpen) {
                          _isSelectingReturn = false;
                          widget.onCalendarToggle(true);
                        } else if (_isSelectingReturn) {
                          _isSelectingReturn = false;
                        } else {
                          widget.onCalendarToggle(false);
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: CustomInputField(
                      key: _returnFieldKey,
                      label: 'Return',
                      value: _formatDate(returnDate),
                      icon: Icons.calendar_today,
                      readOnly: true,
                      isSelected: widget.isCalendarOpen && _isSelectingReturn,
                      onTap: () {
                        _hidePassengerSelector();
                        setState(() => _isPassengerSelectorOpen = false);
                        if (!widget.isCalendarOpen) {
                          _isSelectingReturn = true;
                          widget.onCalendarToggle(true);
                        } else if (!_isSelectingReturn) {
                          _isSelectingReturn = true;
                        } else {
                          widget.onCalendarToggle(false);
                        }
                      },
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 2,
                    child: CustomInputField(
                      key: _passengerFieldKey,
                      label: 'Passengers, class',
                      value: _formatPassengers(),
                      icon: Icons.person,
                      readOnly: true,
                      isSelected: _isPassengerSelectorOpen,
                      onTap: () {
                        if (_isPassengerSelectorOpen) {
                          _hidePassengerSelector();
                          setState(() => _isPassengerSelectorOpen = false);
                        } else {
                          setState(() => _isPassengerSelectorOpen = true);
                          widget.onCalendarToggle(false);
                          _hideCalendar();
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            if (_isPassengerSelectorOpen)
                              _showPassengerSelector();
                          });
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

              if (!_routeExists && _alternatives.isNotEmpty) ...[
                const SizedBox(height: 16),
                const Divider(),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    "Available destinations from this city:",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _alternatives.map((city) => ActionChip(
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
                  )).toList(),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}


class _CalendarOverlay extends StatefulWidget {
  final GlobalKey departFieldKey;
  final GlobalKey returnFieldKey;
  final DateTime? departDate;
  final DateTime? returnDate;
  final List<String> availableDates; 
  final ValueNotifier<bool> isSelectingReturnNotifier;
  final Function(DateTime?, DateTime?) onDatesSelected;
  final VoidCallback onClose;

  const _CalendarOverlay({
    required this.departFieldKey,
    required this.returnFieldKey,
    required this.departDate,
    required this.returnDate,
    required this.availableDates, 
    required this.isSelectingReturnNotifier,
    required this.onDatesSelected,
    required this.onClose,
  });

  @override
  State<_CalendarOverlay> createState() => _CalendarOverlayState();
}
class _CalendarOverlayState extends State<_CalendarOverlay> {
  Offset _getPosition() {
    final RenderBox? box =
        widget.departFieldKey.currentContext?.findRenderObject() as RenderBox?;
    if (box != null && box.hasSize) return box.localToGlobal(Offset.zero);
    return Offset.zero;
  }

  double _getHeight() {
    final RenderBox? box =
        widget.departFieldKey.currentContext?.findRenderObject() as RenderBox?;
    if (box != null && box.hasSize) return box.size.height;
    return 56.0;
  }

  double _getWidth() {
    final RenderBox? box =
        widget.departFieldKey.currentContext?.findRenderObject() as RenderBox?;
    if (box != null && box.hasSize) return box.size.width;
    return 300.0;
  }

  @override
  Widget build(BuildContext context) {
    final position = _getPosition();
    final fieldHeight = _getHeight();
    final fieldWidth = _getWidth();
    final calendarTop = position.dy + fieldHeight + 8;

    return Stack(
      children: [
        Positioned(
          top: calendarTop,
          left: 0,
          right: 0,
          bottom: 0,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: widget.onClose,
            child: Container(color: Colors.transparent),
          ),
        ),
        Positioned(
          left: position.dx,
          top: calendarTop,
          width: fieldWidth * 2 + 12,
          child: GestureDetector(
            onTap: () {},
            child: Material(
              elevation: 8,
              borderRadius: BorderRadius.circular(12),
              child: ValueListenableBuilder<bool>(
                valueListenable: widget.isSelectingReturnNotifier,
                builder: (context, isSelectingReturn, _) {
                  return CustomDateRangePicker(
                    departDate: widget.departDate,
                    returnDate: widget.returnDate,
                    availableDates: widget.availableDates, 
                    isSelectingReturn: isSelectingReturn,
                    onDatesSelected: widget.onDatesSelected,
                    onClose: widget.onClose,
                  );
                },
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _PassengerSelectorOverlay extends StatefulWidget {
  final GlobalKey fieldKey;
  final Map<String, int> passengers;
  final Map<int, Class> passengerClasses;
  final ValueChanged<Map<String, dynamic>> onChanged;
  final VoidCallback onClose;

  const _PassengerSelectorOverlay({
    required this.fieldKey,
    required this.passengers,
    required this.passengerClasses,
    required this.onChanged,
    required this.onClose,
  });

  @override
  State<_PassengerSelectorOverlay> createState() =>
      _PassengerSelectorOverlayState();
}

class _PassengerSelectorOverlayState extends State<_PassengerSelectorOverlay> {
  Offset _getPosition() {
    final RenderBox? box =
        widget.fieldKey.currentContext?.findRenderObject() as RenderBox?;
    if (box != null && box.hasSize) return box.localToGlobal(Offset.zero);
    return Offset.zero;
  }

  double _getHeight() {
    final RenderBox? box =
        widget.fieldKey.currentContext?.findRenderObject() as RenderBox?;
    if (box != null && box.hasSize) return box.size.height;
    return 56.0;
  }

  @override
  Widget build(BuildContext context) {
    final position = _getPosition();
    final fieldHeight = _getHeight();
    final passengerTop = position.dy + fieldHeight + 8;
    final classLabels = widget.passengerClasses.map(
      (index, fc) => MapEntry(index, fc.label),
    );

    return Stack(
      children: [
        Positioned(
          top: passengerTop,
          left: 0,
          right: 0,
          bottom: 0,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: widget.onClose,
            child: Container(color: Colors.transparent),
          ),
        ),
        Positioned(
          left: position.dx,
          top: passengerTop,
          child: GestureDetector(
            onTap: () {},
            child: Material(
              elevation: 8,
              borderRadius: BorderRadius.circular(8),
              child: PassengerSelector(
                initialPassengers: widget.passengers,
                initialPassengerClasses: classLabels,
                onChanged: widget.onChanged,
                onClose: widget.onClose,
              ),
            ),
          ),
        ),
      ],
    );
  }
}



