import 'package:flutter/material.dart';

class PlanningDatePicker extends StatefulWidget {
  final DateTime selectedDate;
  final List<String> availableDates;
  final ValueChanged<DateTime> onDateSelected;

  const PlanningDatePicker({
    super.key,
    required this.selectedDate,
    required this.availableDates,
    required this.onDateSelected,
  });

  @override
  State<PlanningDatePicker> createState() => _PlanningDatePickerState();
}

class _PlanningDatePickerState extends State<PlanningDatePicker> {
  late DateTime _focusedMonth;

  @override
  void initState() {
    super.initState();
    _focusedMonth = DateTime(widget.selectedDate.year, widget.selectedDate.month);
  }

  bool _isAvailable(DateTime date) {
    final s =
        '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    return widget.availableDates.contains(s);
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 360),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Text(
                  'Select date',
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.w500),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close, size: 20),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 8),

            Row(
              children: [
                _NavButton(
                  icon: Icons.chevron_left,
                  onPressed: () => setState(() {
                    _focusedMonth = DateTime(
                        _focusedMonth.year, _focusedMonth.month - 1);
                  }),
                ),
                Expanded(
                  child: Center(
                    child: Text(
                      '${_monthName(_focusedMonth.month)} ${_focusedMonth.year}',
                      style: Theme.of(context)
                          .textTheme
                          .titleSmall
                          ?.copyWith(fontWeight: FontWeight.w500),
                    ),
                  ),
                ),
                _NavButton(
                  icon: Icons.chevron_right,
                  onPressed: () => setState(() {
                    _focusedMonth = DateTime(
                        _focusedMonth.year, _focusedMonth.month + 1);
                  }),
                ),
              ],
            ),
            const SizedBox(height: 8),

            Row(
              children: ['Mo', 'Tu', 'We', 'Th', 'Fr', 'Sa', 'Su']
                  .map((d) => Expanded(
                        child: Center(
                          child: Text(
                            d,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: colors.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ))
                  .toList(),
            ),
            const SizedBox(height: 4),

            _buildGrid(colors),

            const SizedBox(height: 12),
            Divider(color: colors.outline.withValues(alpha: 0.2), height: 1),
            const SizedBox(height: 10),
            Row(
              children: [
                _LegendItem(
                  color: colors.primary,
                  label: 'Selected',
                ),
                const SizedBox(width: 16),
                _LegendItem(
                  color: Colors.transparent,
                  borderColor: colors.primary,
                  label: 'Today',
                ),
                const SizedBox(width: 16),
                _LegendItem(
                  color: colors.surfaceContainerHighest,
                  label: 'No flights',
                  strikethrough: true,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGrid(ColorScheme colors) {
    final firstDay = DateTime(_focusedMonth.year, _focusedMonth.month, 1);
    final daysInMonth =
        DateTime(_focusedMonth.year, _focusedMonth.month + 1, 0).day;
    final startWeekday = firstDay.weekday - 1; // Mon = 0

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7,
        childAspectRatio: 1,
      ),
      itemCount: startWeekday + daysInMonth,
      itemBuilder: (context, index) {
        if (index < startWeekday) return const SizedBox.shrink();

        final dayNum = index - startWeekday + 1;
        final date =
            DateTime(_focusedMonth.year, _focusedMonth.month, dayNum);
        final isSelected = DateUtils.isSameDay(date, widget.selectedDate);
        final isAvailable = _isAvailable(date);
        final isToday = DateUtils.isSameDay(date, DateTime.now());

        Color? bg;
        Color fg = colors.onSurface;

        if (isSelected) {
          bg = colors.primary;
          fg = colors.onPrimary;
        } else if (!isAvailable) {
          fg = colors.onSurfaceVariant.withValues(alpha: 0.4);
        }

        return GestureDetector(
          onTap: isAvailable ? () => widget.onDateSelected(date) : null,
          child: Container(
            margin: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(8),
              border: isToday && !isSelected
                  ? Border.all(color: colors.primary, width: 1.5)
                  : null,
            ),
            child: Center(
              child: Text(
                '$dayNum',
                style: TextStyle(
                  fontSize: 13,
                  color: fg,
                  fontWeight:
                      isSelected ? FontWeight.w600 : FontWeight.normal,
                  decoration: !isAvailable
                      ? TextDecoration.lineThrough
                      : null,
                  decorationColor:
                      colors.onSurfaceVariant.withValues(alpha: 0.4),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  String _monthName(int m) => const [
        '',
        'January', 'February', 'March',     'April',
        'May',     'June',     'July',       'August',
        'September','October', 'November',  'December',
      ][m];
}


class _NavButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;

  const _NavButton({required this.icon, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
              color: colors.outline.withValues(alpha: 0.2)),
        ),
        child: Icon(icon, size: 18, color: colors.onSurfaceVariant),
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final Color? borderColor;
  final String label;
  final bool strikethrough;

  const _LegendItem({
    required this.color,
    required this.label,
    this.borderColor,
    this.strikethrough = false,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 14,
          height: 14,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
            border: borderColor != null
                ? Border.all(color: borderColor!, width: 1.5)
                : null,
          ),
        ),
        const SizedBox(width: 5),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: colors.onSurfaceVariant,
            decoration:
                strikethrough ? TextDecoration.lineThrough : null,
          ),
        ),
      ],
    );
  }
}