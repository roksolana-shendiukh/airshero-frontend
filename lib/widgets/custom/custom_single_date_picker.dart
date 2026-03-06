import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:intl/intl.dart';

class CustomSingleDatePicker extends StatefulWidget {
  final DateTime? selectedDate;
  final DateTime firstDate;
  final DateTime lastDate;
  final Function(DateTime) onDateSelected;
  final VoidCallback? onClose;

  const CustomSingleDatePicker({
    super.key,
    required this.selectedDate,
    required this.firstDate,
    required this.lastDate,
    required this.onDateSelected,
    this.onClose,
  });

  @override
  State<CustomSingleDatePicker> createState() =>
      _CustomSingleDatePickerState();
}

class _CustomSingleDatePickerState extends State<CustomSingleDatePicker> {
  late int _selectedYear;
  late int _selectedMonth;
  late int _selectedDay;

  late List<int> _years;
  late FixedExtentScrollController _yearController;
  late FixedExtentScrollController _monthController;
  late FixedExtentScrollController _dayController;
  

  @override
  void initState() {
    super.initState();
    final initial = widget.selectedDate ?? DateTime.now(); 
    _selectedYear  = initial.year;
    _selectedMonth = initial.month;
    _selectedDay   = initial.day;

    _years = List.generate(
      widget.lastDate.year - widget.firstDate.year + 1,
      (i) => widget.firstDate.year + i,
    );

    _yearController = FixedExtentScrollController(
      initialItem: _years.indexOf(_selectedYear).clamp(0, _years.length - 1),
    );
    _monthController = FixedExtentScrollController(
      initialItem: _selectedMonth - 1,
    );
    _dayController = FixedExtentScrollController(
      initialItem: _selectedDay - 1,
    );
  }

  @override
  void dispose() {
    _yearController.dispose();
    _monthController.dispose();
    _dayController.dispose();
    super.dispose();
  }

  int get _daysInMonth =>
      DateTime(_selectedYear, _selectedMonth + 1, 0).day;

  void _notify() {
    final day = _selectedDay.clamp(1, _daysInMonth);
    widget.onDateSelected(DateTime(_selectedYear, _selectedMonth, day));
  }

  void _onYearChanged(int index) {
    setState(() {
      _selectedYear = _years[index];
      _selectedDay  = _selectedDay.clamp(1, _daysInMonth);
    });
    _notify();
  }

  void _onMonthChanged(int index) {
    setState(() {
      _selectedMonth = index + 1;
      _selectedDay   = _selectedDay.clamp(1, _daysInMonth);
    });
    _notify();
  }

  void _onDayChanged(int index) {
    setState(() => _selectedDay = index + 1);
    _notify();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final months = List.generate(
        12, (i) => DateFormat('MMMM').format(DateTime(2000, i + 1)));
    final days = List.generate(_daysInMonth, (i) => '${i + 1}');

    return RawGestureDetector(
      behavior: HitTestBehavior.opaque,
      gestures: {
        TapGestureRecognizer:
            GestureRecognizerFactoryWithHandlers<TapGestureRecognizer>(
          () => TapGestureRecognizer(),
          (instance) => instance.onTapDown = (details) {
            print('[DatePicker] onTapDown INSIDE picker — should NOT close');
          },
        ),
        PanGestureRecognizer:
            GestureRecognizerFactoryWithHandlers<PanGestureRecognizer>(
          () => PanGestureRecognizer(),
          (instance) {
            instance.onDown = (details) {
              print('[DatePicker] onPanDown INSIDE picker');
            };
            instance.onStart = (details) {
              print('[DatePicker] onPanStart INSIDE picker — scroll started');
            };
          },
        ),
      },
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Column headers
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: Text(
                    'Month',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: colors.onSurfaceVariant,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ),
                Expanded(
                  child: Text(
                    'Day',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: colors.onSurfaceVariant,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ),
                Expanded(
                  child: Text(
                    'Year',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: colors.onSurfaceVariant,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 200,
              child: Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: _ScrollColumn(
                      controller: _monthController,
                      items: months,
                      selectedIndex: _selectedMonth - 1,
                      onChanged: _onMonthChanged,
                      colors: colors,
                    ),
                  ),
                  Expanded(
                    child: _ScrollColumn(
                      controller: _dayController,
                      items: days,
                      selectedIndex:
                          (_selectedDay - 1).clamp(0, days.length - 1),
                      onChanged: _onDayChanged,
                      colors: colors,
                    ),
                  ),
                  Expanded(
                    child: _ScrollColumn(
                      controller: _yearController,
                      items: _years.map((y) => '$y').toList(),
                      selectedIndex: _years
                          .indexOf(_selectedYear)
                          .clamp(0, _years.length - 1),
                      onChanged: _onYearChanged,
                      colors: colors,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ScrollColumn extends StatelessWidget {
  final FixedExtentScrollController controller;
  final List<String> items;
  final int selectedIndex;
  final ValueChanged<int> onChanged;
  final ColorScheme colors;

  const _ScrollColumn({
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
          margin: const EdgeInsets.symmetric(horizontal: 4),
          decoration: BoxDecoration(
            color: colors.primaryContainer.withValues(alpha: 0.4),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: colors.primary.withValues(alpha: 0.3),
            ),
          ),
        ),
        ListWheelScrollView.useDelegate(
          controller: controller,
          itemExtent: 40,
          diameterRatio: 2.5,
          physics: const FixedExtentScrollPhysics(),
          onSelectedItemChanged: onChanged,
          childDelegate: ListWheelChildBuilderDelegate(
            childCount: items.length,
            builder: (context, index) {
              final isSelected = index == selectedIndex;
              return _ScrollItem(
                label: items[index],
                isSelected: isSelected,
                colors: colors,
                onTap: () {
                  controller.animateToItem(
                    index,
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                  );
                  onChanged(index);
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

// ─── Scroll item ──────────────────────────────────────────────────────────────

class _ScrollItem extends StatefulWidget {
  final String label;
  final bool isSelected;
  final ColorScheme colors;
  final VoidCallback onTap;

  const _ScrollItem({
    required this.label,
    required this.isSelected,
    required this.colors,
    required this.onTap,
  });

  @override
  State<_ScrollItem> createState() => _ScrollItemState();
}

class _ScrollItemState extends State<_ScrollItem> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 100),
          margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
          decoration: BoxDecoration(
            color: _isHovered && !widget.isSelected
                ? widget.colors.primaryContainer.withValues(alpha: 0.3)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Center(
            child: Text(
              widget.label,
              style: TextStyle(
                fontSize: widget.isSelected ? 15 : 13,
                fontWeight: widget.isSelected
                    ? FontWeight.bold
                    : FontWeight.normal,
                color: widget.isSelected
                    ? widget.colors.onSurface
                    : _isHovered
                        ? widget.colors.primary
                        : widget.colors.onSurfaceVariant
                            .withValues(alpha: 0.5),
              ),
            ),
          ),
        ),
      ),
    );
  }
}