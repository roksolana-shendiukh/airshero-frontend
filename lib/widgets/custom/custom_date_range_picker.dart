import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class CustomDateRangePicker extends StatefulWidget {
  final DateTime? departDate;
  final DateTime? returnDate;
  final bool isSelectingReturn;
  final Function(DateTime?, DateTime?) onDatesSelected;
  final ValueChanged<bool>? onSelectingReturnChanged;
  final VoidCallback? onClose;
  final List<String> availableDates;
  final List<String> returnAvailableDates;

  const CustomDateRangePicker({
    super.key,
    required this.departDate,
    required this.returnDate,
    required this.isSelectingReturn,
    required this.onDatesSelected,
    this.onSelectingReturnChanged,
    this.onClose,
    this.availableDates = const [],
    this.returnAvailableDates = const[],
  });

  @override
  State<CustomDateRangePicker> createState() => _CustomDateRangePickerState();
}

class _CustomDateRangePickerState extends State<CustomDateRangePicker> {
  late DateTime _focusedMonth;

  List<String> get _activeDates =>
      widget.isSelectingReturn ? widget.returnAvailableDates : widget.availableDates;

  DateTime? get _firstAvailableDate {
    if (_activeDates.isEmpty) return null;
    try {
      final today = DateTime.now();
      final sorted = List<String>.from(_activeDates)..sort();
      final future = sorted.where((d) {
        final date = DateTime.tryParse(d);
        if (date == null) return false;
        return !date.isBefore(DateTime(today.year, today.month, today.day));
      }).toList();
      if (future.isEmpty) return null;
      return DateTime.parse(future.first);
    } catch (_) {
      return null;
    }
  }

  @override
  void initState() {
    super.initState();
    _focusedMonth = _firstAvailableDate ?? 
        (widget.isSelectingReturn ? widget.returnDate : widget.departDate) ?? 
        DateTime.now();
  }

  void _selectDate(DateTime date) {
    if (widget.isSelectingReturn) {
      widget.onDatesSelected(widget.departDate, date);
    } else {
      DateTime? newReturn = widget.returnDate;
      if (newReturn != null && date.isAfter(newReturn)) {
        newReturn = null;
      }
      widget.onDatesSelected(date, newReturn);
    }
    widget.onClose?.call(); 
  }

  bool _isDateAvailable(DateTime date) {
    if (_activeDates.isEmpty) return false; 
    final formatted =
        '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    return _activeDates.contains(formatted);
  }

  Widget _buildCalendar(DateTime month) {
    final firstDay = DateTime(month.year, month.month, 1);
    final lastDay = DateTime(month.year, month.month + 1, 0);
    final daysInMonth = lastDay.day;
    final startWeekday = firstDay.weekday % 7;
    final now = DateTime.now();
    final todayDate = DateTime(now.year, now.month, now.day);

    return Column(
      children:[
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Text(
            DateFormat('MMMM yyyy').format(month),
            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
        ),
        Table(
          children: [
            TableRow(
              children:['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'].map((day) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Text(day,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            )),
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
                final dayNumber = weekIndex * 7 + dayIndex - startWeekday + 1;
                if (dayNumber < 1 || dayNumber > daysInMonth) return const SizedBox(height: 40);

                final date = DateTime(month.year, month.month, dayNumber);
                final isToday = DateUtils.isSameDay(date, DateTime.now());
                
                final isSelected = widget.isSelectingReturn 
                    ? DateUtils.isSameDay(date, widget.returnDate)
                    : DateUtils.isSameDay(date, widget.departDate);

                final isPast = date.isBefore(todayDate);
                final isAvailable = _isDateAvailable(date);
                
                final isBeforeDepart = widget.isSelectingReturn && 
                                       widget.departDate != null && 
                                       date.isBefore(widget.departDate!);

                final isDisabled = isPast || !isAvailable || isBeforeDepart;

                Color? bgColor;
                Color? textColor;

                if (isDisabled) {
                  textColor = Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.3);
                } else if (isSelected) {
                  bgColor = Theme.of(context).colorScheme.primary;
                  textColor = Theme.of(context).colorScheme.onPrimary;
                } else if (isToday) {
                  bgColor = Theme.of(context).colorScheme.surfaceContainerHighest;
                  textColor = Theme.of(context).colorScheme.onSurface;
                } else {
                  textColor = Theme.of(context).colorScheme.onSurface;
                }

                return Padding(
                  padding: const EdgeInsets.all(2),
                  child: GestureDetector(
                    onTap: isDisabled ? null : () => _selectDate(date),
                    child: Container(
                      height: 40,
                      decoration: BoxDecoration(
                        color: bgColor,
                        borderRadius: BorderRadius.circular(8),
                        border: isToday && !isSelected && !isDisabled
                            ? Border.all(color: Theme.of(context).colorScheme.primary, width: 2)
                            : null,
                      ),
                      child: Center(
                        child: Text(
                          '$dayNumber',
                          style: TextStyle(
                            color: textColor,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            fontSize: 14,
                            decoration: isDisabled ? TextDecoration.lineThrough : null,
                          ),
                        ),
                      ),
                    ),
                  ),
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
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow:[
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children:[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children:[
              Text(
                widget.isSelectingReturn ? 'Select Inbound date' : 'Select Outbound date',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),               
            ],
          ),
          const Divider(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children:[
              IconButton(
                icon: const Icon(Icons.chevron_left),
                onPressed: () => setState(() {
                  _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month - 1);
                }),
              ),
              Expanded(child: _buildCalendar(_focusedMonth)),
              IconButton(
                icon: const Icon(Icons.chevron_right),
                onPressed: () => setState(() {
                  _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month + 1);
                }),
              ),
            ],
          ),
        ],
      ),
    );
  }
}