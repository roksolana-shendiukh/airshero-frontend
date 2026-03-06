part of 'passenger_form_card.dart';

extension PassengerFormDatePicker on _PassengerFormCardState {
  void _removeDatePicker() {
    _datePickerBarrier?.remove();
    _datePickerBarrier = null;
    _datePickerOverlay?.remove();
    _datePickerOverlay = null;
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

    _datePickerBarrier = OverlayEntry(
      builder: (_) => GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: _removeDatePicker,
        child: const SizedBox.expand(),
      ),
    );

    _datePickerOverlay = OverlayEntry(
      builder: (context) => CompositedTransformFollower(
        link: layerLink,
        showWhenUnlinked: false,
        offset: const Offset(0, 60),
        child: Align(
          alignment: Alignment.topLeft,
          child: Material(
            elevation: 8,
            borderRadius: BorderRadius.circular(12),
            child: SizedBox(
              width: 350,
              child: CustomSingleDatePicker(
                selectedDate: selectedDate,
                firstDate: firstDate,
                lastDate: lastDate,
                onDateSelected: (date) {
                  setState(() {
                    switch (type) {
                      case _DatePickerType.dateOfBirth:
                        _dateOfBirth = date;
                        _dateOfBirthController.text =
                            DateFormat('dd.MM.yyyy').format(date);
                        break;
                      case _DatePickerType.documentIssue:
                        _documentIssue = date;
                        _documentIssueController.text =
                            DateFormat('dd.MM.yyyy').format(date);
                        _checkDocumentChanged();
                        break;
                      case _DatePickerType.documentExpire:
                        _documentExpire = date;
                        _documentExpireController.text =
                            DateFormat('dd.MM.yyyy').format(date);
                        _checkDocumentChanged();
                        break;
                    }
                  });
                  _notifyParent();
                  _removeDatePicker();
                },
                onClose: _removeDatePicker,
              ),
            ),
          ),
        ),
      ),
    );

    final overlay = Overlay.of(context);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_datePickerBarrier != null && _datePickerOverlay != null) {
        overlay.insert(_datePickerBarrier!);
        overlay.insert(_datePickerOverlay!);
      }
    });
  }
}