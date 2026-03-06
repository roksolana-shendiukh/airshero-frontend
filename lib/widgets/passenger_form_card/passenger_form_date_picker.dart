part of 'passenger_form_card.dart';

extension PassengerFormDatePicker on _PassengerFormCardState {
  void _removeDatePicker() {
    _datePickerOverlay?.remove();
    _datePickerOverlay = null;
    _datePickerBarrier?.remove();
    _datePickerBarrier = null;
  }

  void _showDatePicker(LayerLink layerLink, _DatePickerType type) {
    if (type == _DatePickerType.dateOfBirth && _foundPassengerId != null) return;
  
    if (_datePickerOverlay != null) return;
    _removeDatePicker();

    DateTime? selectedDate;
    DateTime firstDate;
    DateTime lastDate;

    switch (type) {
      case _DatePickerType.dateOfBirth:
        selectedDate = _dateOfBirth;
        firstDate    = DateTime(1920);
        lastDate     = DateTime.now();
        break;
      case _DatePickerType.documentIssue:
        selectedDate = _documentIssue;
        firstDate    = _dateOfBirth != null
            ? DateTime(_dateOfBirth!.year + 1)
            : DateTime(1920);
        lastDate     = DateTime.now();
        break;
      case _DatePickerType.documentExpire:
        selectedDate = _documentExpire;
        firstDate    = _documentIssue != null
            ? _documentIssue!.add(const Duration(days: 1))
            : DateTime.now();
        lastDate     = DateTime(2050);
        break;
    }

    _datePickerOverlay = OverlayEntry(
  builder: (context) => Stack(
    children: [
      Positioned.fill(
        child: GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTapDown: (details) {
            print('[DatePicker] onTapDown on barrier: ${details.globalPosition}');
            _removeDatePicker();
          },
        ),
      ),
      CompositedTransformFollower(
        link: layerLink,
        showWhenUnlinked: false,
        offset: const Offset(0, 60),
        child: Align(
          alignment: Alignment.topLeft,
          child: KeyboardListener(
            focusNode: FocusNode()..requestFocus(),
            onKeyEvent: (event) {
              if (event is KeyDownEvent &&
                  event.logicalKey == LogicalKeyboardKey.enter) {
                _removeDatePicker();
              }
            },
            child: Material(
  elevation: 8,
  borderRadius: BorderRadius.circular(12),
  child: SizedBox(
    width: 350,
    height: 280,
    child: CustomSingleDatePicker(
      selectedDate: selectedDate,
      firstDate: firstDate,
      lastDate: lastDate,
      onDateSelected: (date) {
        setState(() {
          switch (type) {
            case _DatePickerType.dateOfBirth:
              selectedDate = _dateOfBirth;
              firstDate    = DateTime(1950);
              lastDate     = DateTime.now();
              break;
            case _DatePickerType.documentIssue:
              selectedDate = _documentIssue;
              firstDate    = DateTime(2010);
              lastDate     = DateTime.now();
              break;
            case _DatePickerType.documentExpire:
              selectedDate = _documentExpire;
              firstDate    = DateTime(2010);
              lastDate     = DateTime(2035);
              break;
          }
        });

        _datePickerDebounce?.cancel();
        _datePickerDebounce = Timer(
          const Duration(milliseconds: 300),
          _notifyParent,
        );
      },
      onClose: _removeDatePicker,
    ),
  ),
),
          
          ),
        ),
      ),
    ],
  ),
);
final overlay = Overlay.of(context);
WidgetsBinding.instance.addPostFrameCallback((_) {
  if (_datePickerOverlay != null) {
    overlay.insert(_datePickerOverlay!);
  }
});
  }
}