import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../planning/planning_time_picker.dart';
import '../custom/custom_input_field.dart';

class ScheduleTimeInputField extends StatefulWidget {
  final String label;
  final String value;
  final void Function(String) onChanged;

  const ScheduleTimeInputField({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  State<ScheduleTimeInputField> createState() =>
      _ScheduleTimeInputFieldState();
}

class _ScheduleTimeInputFieldState extends State<ScheduleTimeInputField> {
  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _overlay;
  bool _isWheelOpen = false;
  Key _fieldKey = UniqueKey();

  @override
  void dispose() {
    _overlay?.remove();
    _overlay = null;
    super.dispose();
  }

  void _openWheel() {
    if (_isWheelOpen) {
      _closeWheel();
      return;
    }
    setState(() => _isWheelOpen = true);

    _overlay = OverlayEntry(
      builder: (ctx) => CompositedTransformFollower(
        link: _layerLink,
        showWhenUnlinked: false,
        targetAnchor: Alignment.bottomLeft,
        followerAnchor: Alignment.topLeft,
        offset: const Offset(0, 4),
        child: Align(
          alignment: Alignment.topLeft,
          child: TapRegion(
            onTapOutside: (_) => _closeWheel(),
            child: Material(
              elevation: 4,
              borderRadius: BorderRadius.circular(12),
              child: SizedBox(
                width: 200,
                child: PlanningTimePickerOverlay(
                  initialTime:
                      widget.value.isNotEmpty ? widget.value : '00:00',
                  onTimeSelected: (v) {
                    setState(() => _fieldKey = UniqueKey());
                    widget.onChanged(v);
                  },
                  onClose: _closeWheel,
                ),
              ),
            ),
          ),
        ),
      ),
    );
    Overlay.of(context).insert(_overlay!);
  }

  void _closeWheel() {
    _overlay?.remove();
    _overlay = null;
    if (mounted) setState(() => _isWheelOpen = false);
  }

  void _onChanged(String raw) {
    final digits = raw.replaceAll(':', '');
    if (digits.length == 4) {
      final h = int.tryParse(digits.substring(0, 2));
      final m = int.tryParse(digits.substring(2, 4));
      if (h != null && m != null && h >= 0 && h <= 23 && m >= 0 && m <= 59) {
        widget.onChanged(
          '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}',
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _layerLink,
      child: CustomInputField(
        key: _fieldKey,
        label: widget.label,
        value: widget.value,
        icon: Icons.access_time_outlined,
        isSelected: _isWheelOpen,
        onIconTap: _openWheel,
        onTap: null,
        onChanged: _onChanged,
        keyboardType: TextInputType.number,
        inputFormatters: [
          FilteringTextInputFormatter.allow(RegExp(r'[\d:]')),
          ScheduleTimeFormatter(),
        ],
        focusHint: 'Format: HH:MM  (e.g. 14:30)',
      ),
    );
  }
}

class ScheduleTimeFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(RegExp(r'[^\d]'), '');
    if (digits.isEmpty) return newValue.copyWith(text: '');

    final validated = _validateDigits(digits);
    final formatted = validated.length <= 2
        ? validated
        : '${validated.substring(0, 2)}:${validated.substring(2)}';

    return newValue.copyWith(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }

  String _validateDigits(String digits) {
    final buf = StringBuffer();
    for (int i = 0; i < digits.length && i < 4; i++) {
      final d = int.parse(digits[i]);
      if (i == 0) {
        if (d > 2) break;
      } else if (i == 1) {
        final firstHour = int.parse(digits[0]);
        if (firstHour == 2 && d > 3) break;
      } else if (i == 2) {
        if (d > 5) break;
      }
      buf.write(digits[i]);
    }
    return buf.toString();
  }
}