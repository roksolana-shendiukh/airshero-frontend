import 'package:flutter/material.dart';
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
  State<CustomSingleDatePicker> createState() => _CustomSingleDatePickerState();
}

class _CustomSingleDatePickerState extends State<CustomSingleDatePicker> {
  DateTime? _tempSelectedDate;
  late DateTime _focusedMonth;

  @override
  void initState() {
    super.initState();
    _tempSelectedDate = widget.selectedDate;
    _focusedMonth = widget.selectedDate ?? DateTime.now();
  }

  void _selectDate(DateTime date) {
    setState(() => _tempSelectedDate = date);
    widget.onDateSelected(date);
  }

  Widget _buildCalendar(DateTime month) {
    final firstDay = DateTime(month.year, month.month, 1);
    final lastDay = DateTime(month.year, month.month + 1, 0);
    final daysInMonth = lastDay.day;
    final startWeekday = firstDay.weekday % 7;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Text(
            DateFormat('MMMM yyyy').format(month),
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
        ),
        Table(
          children: [
            TableRow(
              children:
                  ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'].map((day) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Text(
                      day,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
        Table(
          children: List.generate(6, (weekIndex) {
            return TableRow(
              children: List.generate(7, (dayIndex) {
                final dayNumber =
                    weekIndex * 7 + dayIndex - startWeekday + 1;

                if (dayNumber < 1 || dayNumber > daysInMonth) {
                  return const SizedBox(height: 40);
                }

                final date =
                    DateTime(month.year, month.month, dayNumber);
                final isDisabled = date.isBefore(widget.firstDate) ||
                    date.isAfter(widget.lastDate);

                return _DayCell(
                  date: date,
                  isSelected:
                      DateUtils.isSameDay(date, _tempSelectedDate),
                  isToday: DateUtils.isSameDay(date, DateTime.now()),
                  isDisabled: isDisabled,
                  onTap: () => _selectDate(date),
                );
              }),
            );
          }),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    // GestureDetector з opaque щоб тапи всередині не закривали overlay
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {},
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left),
                  onPressed: () => setState(() {
                    _focusedMonth = DateTime(
                        _focusedMonth.year, _focusedMonth.month - 1);
                  }),
                ),
                Expanded(child: _buildCalendar(_focusedMonth)),
                IconButton(
                  icon: const Icon(Icons.chevron_right),
                  onPressed: () => setState(() {
                    _focusedMonth = DateTime(
                        _focusedMonth.year, _focusedMonth.month + 1);
                  }),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Окремий віджет для дня — має hover стан ─────────────────────────────────

class _DayCell extends StatefulWidget {
  final DateTime date;
  final bool isSelected;
  final bool isToday;
  final bool isDisabled;
  final VoidCallback onTap;

  const _DayCell({
    required this.date,
    required this.isSelected,
    required this.isToday,
    required this.isDisabled,
    required this.onTap,
  });

  @override
  State<_DayCell> createState() => _DayCellState();
}

class _DayCellState extends State<_DayCell> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    Color? bgColor;
    Color textColor;

    if (widget.isDisabled) {
      textColor = colors.onSurfaceVariant.withValues(alpha: 0.35);
    } else if (widget.isSelected) {
      bgColor = colors.primary;
      textColor = colors.onPrimary;
    } else if (_isHovered) {
      bgColor = colors.primaryContainer.withValues(alpha: 0.5);
      textColor = colors.onSurface;
    } else if (widget.isToday) {
      bgColor = colors.surfaceContainerHighest;
      textColor = colors.onSurface;
    } else {
      textColor = colors.onSurface;
    }

    return Padding(
      padding: const EdgeInsets.all(2),
      child: MouseRegion(
        cursor: widget.isDisabled
            ? SystemMouseCursors.forbidden
            : SystemMouseCursors.click,
        onEnter: (_) {
          if (!widget.isDisabled) setState(() => _isHovered = true);
        },
        onExit: (_) => setState(() => _isHovered = false),
        child: GestureDetector(
          onTap: widget.isDisabled ? null : widget.onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 100),
            height: 40,
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(8),
              border: widget.isToday && !widget.isSelected
                  ? Border.all(color: colors.primary, width: 2)
                  : null,
            ),
            child: Center(
              child: Text(
                '${widget.date.day}',
                style: TextStyle(
                  color: textColor,
                  fontWeight: widget.isSelected
                      ? FontWeight.bold
                      : FontWeight.normal,
                  fontSize: 14,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}