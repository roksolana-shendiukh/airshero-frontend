import 'package:flutter/material.dart';
import 'custom_input_field.dart';
import 'custom_date_range_picker.dart';
import 'custom_button.dart';
import 'passenger_selector.dart';

typedef SearchCallback = void Function({
  required String fromLocation,
  required String toLocation,
  required DateTime departDate,
  DateTime? returnDate,
  required Map<String, int> passengers,
  required String flightClass,
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
  String fromLocation = 'Kyiv, Ukraine';
  String toLocation = '';
  DateTime? departDate;
  DateTime? returnDate;
  Map<String, int> passengers = {'adults': 1, 'children': 0, 'infants': 0};
  String flightClass = 'Economy';
  final ValueNotifier<bool> _isSelectingReturnNotifier = ValueNotifier<bool>(false);
  bool _isPassengerSelectorOpen = false;
  final GlobalKey _passengerFieldKey = GlobalKey();
  final GlobalKey _departFieldKey = GlobalKey();
  final GlobalKey _returnFieldKey = GlobalKey();
  OverlayEntry? _passengerOverlay;
  OverlayEntry? _calendarOverlay;
  Size? _lastConstraints;

  bool get _isSelectingReturn => _isSelectingReturnNotifier.value;
  set _isSelectingReturn(bool value) => _isSelectingReturnNotifier.value = value;

  String _formatDate(DateTime? date) {
    if (date == null) return 'Select date';
    return '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';
  }

  String _formatPassengers() {
    final total = passengers.values.reduce((a, b) => a + b);
    return '$total passenger${total > 1 ? 's' : ''}, $flightClass';
  }

  void _showPassengerSelector() {
    if (_passengerFieldKey.currentContext == null) return;

    final RenderBox? box = _passengerFieldKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return;

    _passengerOverlay?.remove();

    _passengerOverlay = OverlayEntry(
      builder: (context) => _PassengerSelectorOverlay(
        fieldKey: _passengerFieldKey,
        passengers: passengers,
        flightClass: flightClass,
        onChanged: (data) {
          setState(() {
            passengers = {
              'adults': data['adults'],
              'children': data['children'],
              'infants': data['infants'],
            };
            flightClass = data['class'];
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

    if (_departFieldKey.currentContext == null) {
      return;
    }

    final RenderBox? box = _departFieldKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) {
      return;
    }

    _calendarOverlay = OverlayEntry(
      builder: (context) => _CalendarOverlay(
        departFieldKey: _departFieldKey,
        returnFieldKey: _returnFieldKey,
        departDate: departDate,
        returnDate: returnDate,
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
        if (widget.isCalendarOpen && mounted) {
          _showCalendar();
        }
      });
    }
    
    if (!widget.isCalendarOpen && oldWidget.isCalendarOpen) {
      _hideCalendar();
    }
  }

  void _handleSearch() {
    // if (fromLocation.isEmpty || toLocation.isEmpty) {
    //   ScaffoldMessenger.of(context).showSnackBar(
    //     const SnackBar(content: Text('Please select departure and arrival cities')),
    //   );
    //   return;
    // }

    // if (departDate == null) {
    //   ScaffoldMessenger.of(context).showSnackBar(
    //     const SnackBar(content: Text('Please select departure date')),
    //   );
    //   return;
    // }

    widget.onSearch?.call(
      fromLocation: fromLocation,
      toLocation: toLocation,
      departDate: departDate!,
      returnDate: returnDate,
      passengers: passengers,
      flightClass: flightClass,
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
              if (_isPassengerSelectorOpen) {
                _passengerOverlay?.markNeedsBuild();
              }
              if (widget.isCalendarOpen) {
                _calendarOverlay?.markNeedsBuild();
              }
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
                children: [
                  Expanded(
                    child: CustomInputField(
                      label: 'From',
                      value: fromLocation,
                      icon: Icons.flight_takeoff,
                      nearestAirports: [
                        {'name': 'Boryspil', 'iata': 'KBP'},
                        {'name': 'Zhulyany', 'iata': 'IEV'},
                      ],
                      previousSearches: [
                        {'from': 'Kyiv', 'to': 'Lviv'},
                        {'from': 'Kyiv', 'to': 'Paris'},
                      ],
                      onChanged: (value) {
                        setState(() => fromLocation = value);
                      },
                      onTap: _closeAllOverlays,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: IconButton(
                      onPressed: () {
                        setState(() {
                          final temp = fromLocation;
                          fromLocation = toLocation;
                          toLocation = temp;
                        });
                      },
                      icon: Icon(
                        Icons.swap_horiz,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      tooltip: 'Swap locations',
                    ),
                  ),
                  Expanded(
                    child: CustomInputField(
                      label: 'To',
                      value: toLocation,
                      icon: Icons.flight_land,
                      nearestAirports: [
                        {'name': 'Heathrow', 'iata': 'LHR'},
                        {'name': 'Gatwick', 'iata': 'LGW'},
                      ],
                      previousSearches: [
                        {'from': 'Kyiv', 'to': 'London'},
                      ],
                      onChanged: (value) {
                        setState(() => toLocation = value);
                      },
                      onTap: _closeAllOverlays,
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
                        setState(() {
                          _isPassengerSelectorOpen = false;
                        });

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
                        setState(() {
                          _isPassengerSelectorOpen = false;
                        });

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
                          setState(() {
                            _isPassengerSelectorOpen = false;
                          });
                        } else {
                          setState(() {
                            _isPassengerSelectorOpen = true;
                          });
                          widget.onCalendarToggle(false);
                          _hideCalendar();
                          
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            if (_isPassengerSelectorOpen) {
                              _showPassengerSelector();
                            }
                          });
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: CustomButton(
                      label: 'Search',
                      onPressed: _handleSearch,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _PassengerSelectorOverlay extends StatefulWidget {
  final GlobalKey fieldKey;
  final Map<String, int> passengers;
  final String flightClass;
  final ValueChanged<Map<String, dynamic>> onChanged;
  final VoidCallback onClose;

  const _PassengerSelectorOverlay({
    required this.fieldKey,
    required this.passengers,
    required this.flightClass,
    required this.onChanged,
    required this.onClose,
  });

  @override
  State<_PassengerSelectorOverlay> createState() => _PassengerSelectorOverlayState();
}

class _PassengerSelectorOverlayState extends State<_PassengerSelectorOverlay> {
  Offset _getPosition() {
    final RenderBox? box = widget.fieldKey.currentContext?.findRenderObject() as RenderBox?;
    if (box != null && box.hasSize) {
      return box.localToGlobal(Offset.zero);
    }
    return Offset.zero;
  }

  double _getHeight() {
    final RenderBox? box = widget.fieldKey.currentContext?.findRenderObject() as RenderBox?;
    if (box != null && box.hasSize) {
      return box.size.height;
    }
    return 56.0;
  }

  @override
  Widget build(BuildContext context) {
    final position = _getPosition();
    final fieldHeight = _getHeight();
    final passengerTop = position.dy + fieldHeight + 8;

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
                initialClass: widget.flightClass,
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

class _CalendarOverlay extends StatefulWidget {
  final GlobalKey departFieldKey;
  final GlobalKey returnFieldKey;
  final DateTime? departDate;
  final DateTime? returnDate;
  final ValueNotifier<bool> isSelectingReturnNotifier; 
  final Function(DateTime?, DateTime?) onDatesSelected;
  final VoidCallback onClose;

  const _CalendarOverlay({
    required this.departFieldKey,
    required this.returnFieldKey,
    required this.departDate,
    required this.returnDate,
    required this.isSelectingReturnNotifier,
    required this.onDatesSelected,
    required this.onClose,
  });

  @override
  State<_CalendarOverlay> createState() => _CalendarOverlayState();
}

class _CalendarOverlayState extends State<_CalendarOverlay> {
  Offset _getPosition() {
    final RenderBox? box = widget.departFieldKey.currentContext?.findRenderObject() as RenderBox?;
    if (box != null && box.hasSize) {
      return box.localToGlobal(Offset.zero);
    }
    return Offset.zero;
  }

  double _getHeight() {
    final RenderBox? box = widget.departFieldKey.currentContext?.findRenderObject() as RenderBox?;
    if (box != null && box.hasSize) {
      return box.size.height;
    }
    return 56.0;
  }

  double _getWidth() {
    final RenderBox? box = widget.departFieldKey.currentContext?.findRenderObject() as RenderBox?;
    if (box != null && box.hasSize) {
      return box.size.width;
    }
    return 300.0;
  }

  @override
  Widget build(BuildContext context) {
    final position = _getPosition();
    final fieldHeight = _getHeight();
    final fieldWidth = _getWidth();

    final double calendarTop = position.dy + fieldHeight + 8;

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