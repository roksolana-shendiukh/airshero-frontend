import 'package:flutter/material.dart';
import '../planning/schedule_date_picker.dart';
import '../custom/custom_input_field.dart';

class ScheduleDateInputField extends StatefulWidget {
  final String label;
  final DateTime? date;
  final DateTime minDate;
  final ValueChanged<DateTime> onDateChanged;

  const ScheduleDateInputField({
    super.key,
    required this.label,
    required this.date,
    required this.minDate,
    required this.onDateChanged,
  });

  @override
  State<ScheduleDateInputField> createState() =>
      _ScheduleDateInputFieldState();
}

class _ScheduleDateInputFieldState extends State<ScheduleDateInputField> {
  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _overlay;
  bool _isOpen = false;

  static String _fmt(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}.${d.year}';

  void _openOverlay() {
    if (_isOpen) {
      _closeOverlay();
      return;
    }
    _isOpen = true;
    _overlay = OverlayEntry(
      builder: (context) => CompositedTransformFollower(
        link: _layerLink,
        showWhenUnlinked: false,
        targetAnchor: Alignment.bottomLeft,
        followerAnchor: Alignment.topLeft,
        offset: const Offset(0, 4),
        child: Align(
          alignment: Alignment.topLeft,
          child: TapRegion(
            onTapOutside: (_) => _closeOverlay(),
            child: Material(
              elevation: 4,
              borderRadius: BorderRadius.circular(12),
              child: ScheduleDatePicker(
                selectedDate: widget.date,
                minDate: widget.minDate,
                onDateSelected: (picked) {
                  _closeOverlay();
                  widget.onDateChanged(picked);
                },
              ),
            ),
          ),
        ),
      ),
    );
    Overlay.of(context).insert(_overlay!);
  }

  void _closeOverlay() {
    _overlay?.remove();
    _overlay = null;
    if (mounted) setState(() => _isOpen = false);
  }

  @override
  void dispose() {
    _overlay?.remove();
    _overlay = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _layerLink,
      child: CustomInputField(
        label: widget.label,
        value: widget.date != null ? _fmt(widget.date!) : '',
        icon: Icons.calendar_today_outlined,
        readOnly: true,
        onTap: _openOverlay,
        onIconTap: _openOverlay,
      ),
    );
  }
}