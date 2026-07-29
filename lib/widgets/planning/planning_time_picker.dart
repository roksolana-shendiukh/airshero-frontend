import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';

class PlanningTimePickerOverlay extends StatefulWidget {
  final String initialTime;
  final void Function(String) onTimeSelected;
  final VoidCallback onClose;

  const PlanningTimePickerOverlay({
    super.key,
    required this.initialTime,
    required this.onTimeSelected,
    required this.onClose,
  });

  @override
  State<PlanningTimePickerOverlay> createState() =>
      _PlanningTimePickerOverlayState();
}

class _PlanningTimePickerOverlayState
    extends State<PlanningTimePickerOverlay> {
  late int _hour;
  late int _minute;
  late FixedExtentScrollController _hourCtrl;
  late FixedExtentScrollController _minuteCtrl;

  bool _isManualInput = false;
  late TextEditingController _textCtrl;
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    final parts = widget.initialTime.split(':');
    _hour = parts.length == 2 ? int.tryParse(parts[0]) ?? 0 : 0;
    _minute = parts.length == 2 ? int.tryParse(parts[1]) ?? 0 : 0;
    _hourCtrl = FixedExtentScrollController(initialItem: _hour);
    _minuteCtrl = FixedExtentScrollController(initialItem: _minute);
    _textCtrl = TextEditingController(text: _formattedTime);
  }

  @override
  void dispose() {
    _hourCtrl.dispose();
    _minuteCtrl.dispose();
    _textCtrl.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  String get _formattedTime =>
      '${_hour.toString().padLeft(2, '0')}:${_minute.toString().padLeft(2, '0')}';

  void _notify() {
    widget.onTimeSelected(_formattedTime);
  }

  void _applyManualInput() {
    final raw = _textCtrl.text.trim();
    final normalized = raw.replaceAll(':', '');
    if (normalized.length == 4) {
      final h = int.tryParse(normalized.substring(0, 2));
      final m = int.tryParse(normalized.substring(2, 4));
      if (h != null && m != null && h >= 0 && h <= 23 && m >= 0 && m <= 59) {
        setState(() {
          _hour = h;
          _minute = m;
          _isManualInput = false;
        });
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _hourCtrl.jumpToItem(_hour);
          _minuteCtrl.jumpToItem(_minute);
        });
        _notify();
        return;
      }
    }
    setState(() => _isManualInput = false);
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return RawGestureDetector(
      behavior: HitTestBehavior.deferToChild,
      gestures: {
        TapGestureRecognizer:
            GestureRecognizerFactoryWithHandlers<TapGestureRecognizer>(
          () => TapGestureRecognizer(),
          (i) => i.onTapDown = (_) {},
        ),
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_isManualInput) ...[
              _buildManualInputRow(colors),
              const SizedBox(height: 8),
            ],

            Row(
              children: [
                Expanded(
                  child: _WheelColumn(
                    controller: _hourCtrl,
                    items: List.generate(24, (i) => i.toString().padLeft(2, '0')),
                    selectedIndex: _hour,
                    onChanged: (i) {
                      setState(() {
                        _hour = i;
                        if (_isManualInput) {
                          _textCtrl.text = _formattedTime;
                        }
                      });
                      _notify();
                    },
                    colors: colors,
                  ),
                ),
                
                Expanded(
                  child: _WheelColumn(
                    controller: _minuteCtrl,
                    items: List.generate(60, (i) => i.toString().padLeft(2, '0')),
                    selectedIndex: _minute,
                    onChanged: (i) {
                      setState(() {
                        _minute = i;
                        if (_isManualInput) {
                          _textCtrl.text = _formattedTime;
                        }
                      });
                      _notify();
                    },
                    colors: colors,
                  ),
                ),
              ],
            ),
            
          ],
        ),
      ),
    );
  }

  Widget _buildManualInputRow(ColorScheme colors) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _textCtrl,
            focusNode: _focusNode,
            textAlign: TextAlign.center,
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[\d:]')),
              _TimeInputFormatter(),
            ],
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              letterSpacing: 2,
              color: colors.onSurface,
            ),
            decoration: InputDecoration(
              isDense: true,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              hintText: 'HH:MM',
              hintStyle: TextStyle(
                color: colors.onSurfaceVariant.withValues(alpha: 0.5),
                fontWeight: FontWeight.normal,
                letterSpacing: 1,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: colors.primary),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: colors.primary, width: 2),
              ),
            ),
            onSubmitted: (_) => _applyManualInput(),
          ),
        ),
        const SizedBox(width: 8),
        IconButton.filled(
          onPressed: _applyManualInput,
          icon: const Icon(Icons.check, size: 18),
          style: IconButton.styleFrom(
            minimumSize: const Size(36, 36),
            padding: EdgeInsets.zero,
          ),
        ),
        IconButton(
          onPressed: () => setState(() => _isManualInput = false),
          icon: const Icon(Icons.close, size: 18),
          style: IconButton.styleFrom(
            minimumSize: const Size(36, 36),
            padding: EdgeInsets.zero,
            foregroundColor: colors.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _TimeInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    final digits = newValue.text.replaceAll(RegExp(r'[^\d]'), '');
    if (digits.isEmpty) {
      return newValue.copyWith(text: '');
    }

    final clamped = digits.length > 4 ? digits.substring(0, 4) : digits;

    String formatted;
    if (clamped.length <= 2) {
      formatted = clamped;
    } else {
      formatted = '${clamped.substring(0, 2)}:${clamped.substring(2)}';
    }

    return newValue.copyWith(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

class _WheelColumn extends StatelessWidget {
  final FixedExtentScrollController controller;
  final List<String> items;
  final int selectedIndex;
  final ValueChanged<int> onChanged;
  final ColorScheme colors;

  const _WheelColumn({
    required this.controller,
    required this.items,
    required this.selectedIndex,
    required this.onChanged,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          height: 40,
          decoration: BoxDecoration(
            color: colors.primaryContainer.withValues(alpha: 0.4),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: colors.primary.withValues(alpha: 0.3)),
          ),
        ),
        SizedBox(
          height: 140,
          child: ListWheelScrollView.useDelegate(
            controller: controller,
            itemExtent: 40,
            diameterRatio: 2.5,
            physics: const FixedExtentScrollPhysics(),
            onSelectedItemChanged: onChanged,
            childDelegate: ListWheelChildBuilderDelegate(
              childCount: items.length,
              builder: (context, index) {
                final isSelected = index == selectedIndex;
                return GestureDetector(
                  onTap: () {
                    controller.animateToItem(
                      index,
                      duration: const Duration(milliseconds: 250),
                      curve: Curves.easeInOut,
                    );
                    onChanged(index);
                  },
                  child: Center(
                    child: Text(
                      items[index],
                      style: TextStyle(
                        fontSize: isSelected ? 16 : 13,
                        fontWeight:
                            isSelected ? FontWeight.w600 : FontWeight.normal,
                        color: isSelected
                            ? colors.onSurface
                            : colors.onSurfaceVariant.withValues(alpha: 0.5),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}


Future<String?> showPlanningTimePicker({
  required BuildContext context,
  required String initialTime,
}) async {
  return showDialog<String>(
    context: context,
    builder: (context) => Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: PlanningTimePickerOverlay(
        initialTime: initialTime,
        onTimeSelected: (v) => Navigator.of(context).pop(v),
        onClose: () => Navigator.of(context).pop(),
      ),
    ),
  );
}