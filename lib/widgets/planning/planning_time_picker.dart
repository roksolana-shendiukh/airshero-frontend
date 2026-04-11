import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';

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

  @override
  void initState() {
    super.initState();
    final parts = widget.initialTime.split(':');
    _hour = parts.length == 2 ? int.tryParse(parts[0]) ?? 0 : 0;
    _minute = parts.length == 2 ? int.tryParse(parts[1]) ?? 0 : 0;
    _hourCtrl = FixedExtentScrollController(initialItem: _hour);
    _minuteCtrl = FixedExtentScrollController(initialItem: _minute);
  }

  @override
  void dispose() {
    _hourCtrl.dispose();
    _minuteCtrl.dispose();
    super.dispose();
  }

  void _notify() {
    final formatted =
        '${_hour.toString().padLeft(2, '0')}:${_minute.toString().padLeft(2, '0')}';
    widget.onTimeSelected(formatted);
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
        child: Row(
          children: [
            Expanded(
              child: _WheelColumn(
                controller: _hourCtrl,
                items: List.generate(
                    24, (i) => i.toString().padLeft(2, '0')),
                selectedIndex: _hour,
                onChanged: (i) {
                  setState(() => _hour = i);
                  _notify();
                },
                colors: colors,
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                ':',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w300,
                  color: colors.onSurface,
                ),
              ),
            ),
            Expanded(
              child: _WheelColumn(
                controller: _minuteCtrl,
                items: List.generate(
                    60, (i) => i.toString().padLeft(2, '0')),
                selectedIndex: _minute,
                onChanged: (i) {
                  setState(() => _minute = i);
                  _notify();
                },
                colors: colors,
              ),
            ),
          ],
        ),
      ),
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
            border: Border.all(
                color: colors.primary.withValues(alpha: 0.3)),
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
                        fontWeight: isSelected
                            ? FontWeight.w600
                            : FontWeight.normal,
                        color: isSelected
                            ? colors.onSurface
                            : colors.onSurfaceVariant
                                .withValues(alpha: 0.5),
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
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: PlanningTimePickerOverlay(
        initialTime: initialTime,
        onTimeSelected: (v) => Navigator.of(context).pop(v),
        onClose: () => Navigator.of(context).pop(),
      ),
    ),
  );
}