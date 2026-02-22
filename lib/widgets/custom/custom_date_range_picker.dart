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

  const CustomDateRangePicker({
    super.key,
    required this.departDate,
    required this.returnDate,
    required this.isSelectingReturn,
    required this.onDatesSelected,
    this.onSelectingReturnChanged,
    this.onClose,
    this.availableDates = const [], 
  });

  @override
  State<CustomDateRangePicker> createState() => _CustomDateRangePickerState();
}

class _CustomDateRangePickerState extends State<CustomDateRangePicker> {
  DateTime? _tempDepartDate;
  DateTime? _tempReturnDate;
  bool _isOneWay = false;
  late DateTime _focusedMonth;

  @override
  void initState() {
    super.initState();
    _tempDepartDate = widget.departDate;
    _tempReturnDate = widget.returnDate;
    _focusedMonth = _tempDepartDate ?? DateTime.now();
    _isOneWay = widget.returnDate == null && widget.departDate != null;
  }

  void _selectDate(DateTime date) {
    setState(() {
      if (widget.isSelectingReturn) {
        _tempReturnDate = date;
        
        if (_tempDepartDate != null && date.isBefore(_tempDepartDate!)) {
          _tempDepartDate = date;
          _tempReturnDate = null;
        }
      } else {
        _tempDepartDate = date;
        
        if (_tempReturnDate != null && date.isAfter(_tempReturnDate!)) {
          _tempReturnDate = null;
        }
      }

      widget.onDatesSelected(_tempDepartDate, _tempReturnDate);
    });
  }

  bool _isDateAvailable(DateTime date) {
    if (widget.availableDates.isEmpty) return true;

    final formattedDate = "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
    
    return widget.availableDates.contains(formattedDate);
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
              children: ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'].map((day) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Text(
                      day,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
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
                final dayNumber = weekIndex * 7 + dayIndex - startWeekday + 1;
                
                if (dayNumber < 1 || dayNumber > daysInMonth) {
                  return const SizedBox(height: 40);
                }

                final date = DateTime(month.year, month.month, dayNumber);
                final isToday = DateUtils.isSameDay(date, DateTime.now());
                final isDepart = DateUtils.isSameDay(date, _tempDepartDate);
                final isReturn = DateUtils.isSameDay(date, _tempReturnDate);
                final isInRange = _tempDepartDate != null &&
                    _tempReturnDate != null &&
                    date.isAfter(_tempDepartDate!) &&
                    date.isBefore(_tempReturnDate!);
                
                final isPast = date.isBefore(DateTime.now().subtract(const Duration(days: 1)));
                
                final isAvailable = _isDateAvailable(date);
                
                final isDisabled = isPast || !isAvailable;

                Color? bgColor;
                Color? textColor;

                if (isDisabled) {
                  textColor = Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.3);
                } else if (isDepart || isReturn) {
                  bgColor = Theme.of(context).colorScheme.primary;
                  textColor = Theme.of(context).colorScheme.onPrimary;
                } else if (isInRange) {
                  bgColor = Theme.of(context).colorScheme.primaryContainer;
                  textColor = Theme.of(context).colorScheme.onPrimaryContainer;
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
                        border: isToday && !isDepart && !isReturn && !isDisabled
                            ? Border.all(
                                color: Theme.of(context).colorScheme.primary,
                                width: 2,
                              )
                            : null,
                      ),
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              '$dayNumber',
                              style: TextStyle(
                                color: textColor,
                                fontWeight: isDepart || isReturn ? FontWeight.bold : FontWeight.normal,
                                fontSize: 14,
                                decoration: !isAvailable && !isPast ? TextDecoration.lineThrough : null, 
                              ),
                            ),
                            if (isDepart || isReturn)
                              Text(
                                isDepart ? 'Out' : 'In',
                                style: TextStyle(
                                  color: textColor,
                                  fontSize: 8,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                          ],
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
    final nextMonth = DateTime(_focusedMonth.year, _focusedMonth.month + 1);
    final isWideScreen = MediaQuery.of(context).size.width > 800;

    return Container(
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
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                widget.isSelectingReturn ? 'Inbound date' : 'Outbound date',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              if (isWideScreen)
                SegmentedButton<bool>(
                  segments: const [
                    ButtonSegment(value: false, label: Text('Round Trip')),
                    ButtonSegment(value: true, label: Text('One-Way')),
                  ],
                  selected: {_isOneWay},
                  onSelectionChanged: (Set<bool> selection) {
                    setState(() {
                      _isOneWay = selection.first;
                      if (_isOneWay) {
                        _tempReturnDate = null;
                        widget.onDatesSelected(_tempDepartDate, null);
                      }
                    });
                  },
                ),
            ],
          ),
          const Divider(height: 24),
          if (isWideScreen)
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left),
                  onPressed: () {
                    setState(() {
                      _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month - 1);
                    });
                  },
                ),
                Expanded(child: _buildCalendar(_focusedMonth)),
                const SizedBox(width: 16),
                Expanded(child: _buildCalendar(nextMonth)),
                IconButton(
                  icon: const Icon(Icons.chevron_right),
                  onPressed: () {
                    setState(() {
                      _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month + 1);
                    });
                  },
                ),
              ],
            )
          else
            Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.chevron_left),
                      onPressed: () {
                        setState(() {
                          _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month - 1);
                        });
                      },
                    ),
                    Expanded(child: _buildCalendar(_focusedMonth)),
                    IconButton(
                      icon: const Icon(Icons.chevron_right),
                      onPressed: () {
                        setState(() {
                          _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month + 1);
                        });
                      },
                    ),
                  ],
                ),
              ],
            ),
        ],
      ),
    );
  }
}