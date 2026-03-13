import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../../services/auth_service.dart';
import '../custom/custom_input_field.dart';
import '../custom/custom_button.dart';
import '../custom/custom_single_date_picker.dart';
import '../passenger_form_card/date_input_formatter.dart';
import 'checkin_document_search_field.dart';

part 'checkin_validators.dart';

class CheckInSearchStep extends StatefulWidget {
  final AuthService authService;
  final void Function({
    required String documentNumber,
    required String flightNumber,
    required DateTime departDate,
  }) onSearch;

  const CheckInSearchStep({
    super.key,
    required this.authService,
    required this.onSearch,
  });

  @override
  State<CheckInSearchStep> createState() => _CheckInSearchStepState();
}

class _CheckInSearchStepState extends State<CheckInSearchStep> {
  final _documentNumberController    = TextEditingController();
  final _flightNumberController      = TextEditingController();
  final _departureDateController     = TextEditingController();

  DateTime? _departDate;

  bool _documentNumberTouched = false;
  bool _flightNumberTouched   = false;
  bool _departDateTouched     = false;

  final LayerLink _dateLayerLink         = LayerLink();
  final FocusNode _dateFocusNode         = FocusNode();
  final FocusNode _flightNumberFocusNode = FocusNode();

  OverlayEntry? _datePickerOverlay;
  OverlayEntry? _datePickerBarrier;

  bool get _isPickerOpen => _datePickerOverlay != null;

  String get _flightNumberHint => 'Format: PS101 (2 chars + 1–4 digits)';
  String get _departDateHint   => 'DD.MM.YYYY';

  void _removeDatePicker() {
    _datePickerOverlay?.remove();
    _datePickerOverlay = null;
    _datePickerBarrier?.remove();
    _datePickerBarrier = null;
    if (mounted) setState(() {});
  }

  void _showDatePicker() {
    if (_datePickerOverlay != null) return;
    _removeDatePicker();

    _datePickerBarrier = OverlayEntry(
      builder: (_) => GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTapDown: (_) => _removeDatePicker(),
      ),
    );

    _datePickerOverlay = OverlayEntry(
      builder: (context) => CompositedTransformFollower(
        link: _dateLayerLink,
        showWhenUnlinked: false,
        offset: const Offset(0, 60),
        child: Align(
          alignment: Alignment.topLeft,
          child: Material(
            elevation: 8,
            borderRadius: BorderRadius.circular(12),
            child: SizedBox(
              width: 350,
              height: 280,
              child: NotificationListener<ScrollNotification>(
                onNotification: (_) => true,
                child: CustomSingleDatePicker(
                  selectedDate: _departDate,
                  firstDate: DateTime.now(),
                  lastDate: DateTime(DateTime.now().year + 2),
                  onDateSelected: (date) {
                    setState(() {
                      _departDate = date;
                      _departureDateController.text = DateFormat('dd.MM.yyyy').format(date);
                      _departDateTouched = true;
                    });
                  },
                  onClose: _removeDatePicker,
                ),
              ),
            ),
          ),
        ),
      ),
    );

    final overlay = Overlay.of(context);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_datePickerOverlay != null) {
        overlay.insert(_datePickerBarrier!);
        overlay.insert(_datePickerOverlay!);
        if (mounted) setState(() {});
      }
    });
  }

  void _toggleDatePicker() {
    if (_isPickerOpen) {
      _removeDatePicker();
    } else {
      _showDatePicker();
    }
  }

  void _handleDateInput(String value) {
    _departureDateController.text = value;
    if (value.length == 10) {
      try {
        final parsed = DateFormat('dd.MM.yyyy').parseStrict(value);
        setState(() {
          _departDate        = parsed;
          _departDateTouched = true;
        });
      } catch (_) {
        setState(() => _departDate = null);
      }
    } else {
      setState(() => _departDate = null);
    }
  }

  void _handleSearch() {
    setState(() {
      _documentNumberTouched = true;
      _flightNumberTouched   = true;
      _departDateTouched     = true;
    });

    if (!_isFormValid) return;

    widget.onSearch(
      documentNumber: _documentNumberController.text.trim().toUpperCase(),
      flightNumber:   _flightNumberController.text.trim().toUpperCase(),
      departDate:     _departDate!,
    );
  }

  @override
  void initState() {
    super.initState();
    _flightNumberFocusNode.addListener(() {
      if (mounted) setState(() {
        if (!_flightNumberFocusNode.hasFocus && _flightNumberController.text.isNotEmpty) {
          _flightNumberTouched = true;
        }
      });
    });
    _dateFocusNode.addListener(() { if (mounted) setState(() {}); });
  }

  @override
  void dispose() {
    _removeDatePicker();
    _documentNumberController.dispose();
    _flightNumberController.dispose();
    _departureDateController.dispose();
    _dateFocusNode.dispose();
    _flightNumberFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      margin:  const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color:        colors.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          CheckInDocumentSearchField(
            authService: widget.authService,
            value: _documentNumberController.text,
            onChanged: (v) {
              _documentNumberController.text = v;
              setState(() => _documentNumberTouched = v.isNotEmpty);
            },
          ),
          if (_documentNumberError != null) ...[
            const SizedBox(height: 4),
            Text(
              _documentNumberError!,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: colors.error),
            ),
          ],

          const SizedBox(height: 12),

          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Focus(
                      focusNode: _flightNumberFocusNode,
                      child: CustomInputField(
                        label: 'Flight Number',
                        value: _flightNumberController.text,
                        icon:  Icons.flight_outlined,
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9]')),
                          LengthLimitingTextInputFormatter(6),
                        ],
                        onChanged: (v) {
                          _flightNumberController.text = v.toUpperCase();
                          setState(() {});
                        },
                      ),
                    ),
                    if (_flightNumberFocusNode.hasFocus || _flightNumberTouched) ...[
                      const SizedBox(height: 4),
                      Text(
                        _flightNumberController.text.isEmpty && _flightNumberTouched && !_flightNumberFocusNode.hasFocus
                            ? 'Required field'
                            : _flightNumberHint,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: (_flightNumberTouched && !_flightNumberFocusNode.hasFocus &&
                                  (_flightNumberController.text.isEmpty ||
                                   !_isFlightNumberValid(_flightNumberController.text))) ||
                                 (_flightNumberFocusNode.hasFocus &&
                                  _flightNumberController.text.isNotEmpty &&
                                  !_isFlightNumberPartiallyValid(_flightNumberController.text))
                              ? colors.error
                              : colors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(width: 12),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CompositedTransformTarget(
                      link: _dateLayerLink,
                      child: Focus(
                        focusNode: _dateFocusNode,
                        child: CustomInputField(
                          label:           'Departure Date',
                          value:           _departureDateController.text,
                          icon:            Icons.calendar_today_outlined,
                          keyboardType:    TextInputType.number,
                          inputFormatters: [DateInputFormatter()],
                          isSelected:      _isPickerOpen,
                          onChanged:       _handleDateInput,
                          onIconTap:       _toggleDatePicker,
                        ),
                      ),
                    ),
                    if (_departDateError != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        _departDateError!,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(color: colors.error),
                      ),
                    ] else if (_dateFocusNode.hasFocus || _isPickerOpen) ...[
                      const SizedBox(height: 4),
                      Text(
                        _departDateHint,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(color: colors.onSurfaceVariant),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          SizedBox(
            width: double.infinity,
            child: CustomButton(
              label:     'Find Booking',
              onPressed: _isFormValid ? _handleSearch : null,
            ),
          ),
        ],
      ),
    );
  }
}