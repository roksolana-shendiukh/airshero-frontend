import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'schedule_date_picker.dart';
import 'planning_time_picker.dart';
import '../../../widgets/custom/custom_input_field.dart';


class _DateFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue old,
    TextEditingValue next,
  ) {
    final raw = next.text.replaceAll(RegExp(r'[^\d]'), '');
    if (raw.isEmpty) return next.copyWith(text: '');

    final buf = StringBuffer();

    for (int i = 0; i < raw.length && i < 8; i++) {
      final digit = int.parse(raw[i]);

      if (i == 0) {
        if (digit > 3) return old;
        buf.write(raw[i]);
      } else if (i == 1) {
        final day = int.parse(raw[0]) * 10 + digit;
        if (day < 1 || day > 31) return old;
        buf.write(raw[i]);
        buf.write('.');
      } else if (i == 2) {
        if (digit > 1) return old;
        buf.write(raw[i]);
      } else if (i == 3) {
        final month = int.parse(raw[2]) * 10 + digit;
        if (month < 1 || month > 12) return old;
        buf.write(raw[i]);
        buf.write('.');
      } else {
        buf.write(raw[i]);
      }
    }

    final text = buf.toString();
    return next.copyWith(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}

// ─── Time formatter ───────────────────────────────────────────────

class _TimeFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue old,
    TextEditingValue next,
  ) {
    final raw = next.text.replaceAll(RegExp(r'[^\d]'), '');
    if (raw.isEmpty) return next.copyWith(text: '');

    final buf = StringBuffer();

    for (int i = 0; i < raw.length && i < 4; i++) {
      final digit = int.parse(raw[i]);

      if (i == 0) {
        if (digit > 2) return old;
        buf.write(raw[i]);
      } else if (i == 1) {
        final hour = int.parse(raw[0]) * 10 + digit;
        if (hour > 23) return old;
        buf.write(raw[i]);
        buf.write(':');
      } else if (i == 2) {
        if (digit > 5) return old;
        buf.write(raw[i]);
      } else {
        buf.write(raw[i]);
      }
    }

    final text = buf.toString();
    return next.copyWith(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}

// ─── Step2Schedule ────────────────────────────────────────────────

class Step2Schedule extends StatefulWidget {
  final List<Map<String, dynamic>> scheduleGroups;
  final DateTime? flightStartDate;
  final DateTime? flightEndDate;
  final void Function({
    required List<Map<String, dynamic>> scheduleGroups,
    required DateTime? flightStartDate,
    required DateTime? flightEndDate,
  }) onChanged;

  const Step2Schedule({
    super.key,
    required this.scheduleGroups,
    required this.flightStartDate,
    required this.flightEndDate,
    required this.onChanged,
  });

  @override
  State<Step2Schedule> createState() => _Step2ScheduleState();
}

class _Step2ScheduleState extends State<Step2Schedule> {
  late List<_ScheduleGroup> _groups;
  late DateTime? _startDate;
  late DateTime? _endDate;

  static const _days = [
    (id: 1, label: 'Mon'),
    (id: 2, label: 'Tue'),
    (id: 3, label: 'Wed'),
    (id: 4, label: 'Thu'),
    (id: 5, label: 'Fri'),
    (id: 6, label: 'Sat'),
    (id: 7, label: 'Sun'),
  ];

  @override
  void initState() {
    super.initState();
    _startDate = widget.flightStartDate;
    _endDate = widget.flightEndDate;
    _groups = widget.scheduleGroups.map((g) {
      return _ScheduleGroup(
        dayIds: Set<int>.from(g['dayIds'] as List),
        departureTime: g['departureTime'] as String,
        arrivalTime: g['arrivalTime'] as String,
      );
    }).toList();
    if (_groups.isEmpty) _groups.add(_ScheduleGroup());
  }

  Set<int> get _usedDayIds =>
      _groups.expand((g) => g.dayIds).toSet();

  void _notify() {
    widget.onChanged(
      scheduleGroups: _groups
          .where((g) =>
              g.dayIds.isNotEmpty &&
              g.departureTime.isNotEmpty &&
              g.arrivalTime.isNotEmpty)
          .map((g) => {
                'dayIds': g.dayIds.toList(),
                'departureTime': g.departureTime,
                'arrivalTime': g.arrivalTime,
              })
          .toList(),
      flightStartDate: _startDate,
      flightEndDate: _endDate,
    );
  }

  Future<void> _pickDate({required bool isStart}) async {
    final minDate =
        isStart ? DateTime.now() : (_startDate ?? DateTime.now());
    final initial = isStart ? _startDate : _endDate;

    await showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12)),
        child: ScheduleDatePicker(
          selectedDate: initial,
          minDate: minDate,
          onDateSelected: (picked) {
            Navigator.of(context).pop();
            setState(() {
              if (isStart) {
                _startDate = picked;
                if (_endDate != null &&
                    _endDate!.isBefore(picked)) {
                  _endDate = null;
                }
              } else {
                _endDate = picked;
              }
            });
            _notify();
          },
        ),
      ),
    );
  }

  void _addGroup() {
    setState(() => _groups.add(_ScheduleGroup()));
    _notify();
  }

  void _removeGroup(int index) {
    setState(() => _groups.removeAt(index));
    _notify();
  }

  int _estimatedFlights() {
    if (_startDate == null || _endDate == null) return 0;
    int count = 0;
    for (final group in _groups) {
      if (group.dayIds.isEmpty) continue;
      var current = _startDate!;
      while (!current.isAfter(_endDate!)) {
        if (group.dayIds.contains(current.weekday)) count++;
        current = current.add(const Duration(days: 1));
      }
    }
    return count;
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionLabel(
            context, Icons.date_range_outlined, 'Schedule period'),
        const SizedBox(height: 12),
        _buildDateRow(),
        const SizedBox(height: 28),
        _buildSectionLabel(
            context, Icons.schedule_outlined, 'Day & time groups'),
        const SizedBox(height: 4),
        Text(
          'Add groups of days that share the same departure and arrival time.',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: colors.onSurfaceVariant,
              ),
        ),
        const SizedBox(height: 12),
        ..._groups.asMap().entries.map((entry) {
          final index = entry.key;
          final group = entry.value;
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _GroupCard(
              group: group,
              index: index,
              days: _days,
              usedDayIds: _usedDayIds.difference(group.dayIds),
              canRemove: _groups.length > 1,
              onRemove: () => _removeGroup(index),
              onChanged: () {
                setState(() {});
                _notify();
              },
            ),
          );
        }),
        const SizedBox(height: 4),
        TextButton.icon(
          onPressed: _usedDayIds.length < 7 ? _addGroup : null,
          icon: const Icon(Icons.add, size: 16),
          label: const Text('Add another group'),
          style: TextButton.styleFrom(
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
        ),
        if (_startDate != null &&
            _endDate != null &&
            _groups.any((g) => g.dayIds.isNotEmpty)) ...[
          const SizedBox(height: 24),
          _buildEstimate(colors),
        ],
      ],
    );
  }

  Widget _buildSectionLabel(
      BuildContext context, IconData icon, String label) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 8),
        Text(
          label,
          style: Theme.of(context)
              .textTheme
              .titleSmall
              ?.copyWith(fontWeight: FontWeight.w600),
        ),
      ],
    );
  }

  Widget _buildDateRow() {
    return Row(
      children: [
        Expanded(
          child: _DateInputField(
            label: 'Start date',
            date: _startDate,
            minDate: DateTime.now(),
            onDateChanged: (d) {
              setState(() {
                _startDate = d;
                if (_endDate != null && _endDate!.isBefore(d)) {
                  _endDate = null;
                }
              });
              _notify();
            },
            onPickerTap: () => _pickDate(isStart: true),
          ),
        ),
        const SizedBox(width: 12),
        Icon(Icons.arrow_forward,
            size: 16,
            color: Theme.of(context).colorScheme.onSurfaceVariant),
        const SizedBox(width: 12),
        Expanded(
          child: _DateInputField(
            label: 'End date',
            date: _endDate,
            minDate: _startDate ?? DateTime.now(),
            onDateChanged: (d) {
              setState(() => _endDate = d);
              _notify();
            },
            onPickerTap:
                _startDate != null ? () => _pickDate(isStart: false) : null,
          ),
        ),
      ],
    );
  }

  Widget _buildEstimate(ColorScheme colors) {
    final count = _estimatedFlights();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: colors.primaryContainer.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colors.primary.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Icon(Icons.flight_takeoff, size: 16, color: colors.primary),
          const SizedBox(width: 10),
          Text(
            'Estimated flights to generate: ',
            style:
                TextStyle(fontSize: 13, color: colors.onSurfaceVariant),
          ),
          Text(
            '$count',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: colors.primary,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Models ───────────────────────────────────────────────────────

class _ScheduleGroup {
  Set<int> dayIds;
  String departureTime;
  String arrivalTime;

  _ScheduleGroup({
    Set<int>? dayIds,
    this.departureTime = '',
    this.arrivalTime = '',
  }) : dayIds = dayIds ?? {};
}

// ─── Date input field ─────────────────────────────────────────────

class _DateInputField extends StatefulWidget {
  final String label;
  final DateTime? date;
  final DateTime minDate;
  final ValueChanged<DateTime> onDateChanged;
  final VoidCallback? onPickerTap;

  const _DateInputField({
    required this.label,
    required this.date,
    required this.minDate,
    required this.onDateChanged,
    required this.onPickerTap,
  });

  @override
  State<_DateInputField> createState() => _DateInputFieldState();
}

class _DateInputFieldState extends State<_DateInputField> {
  late final TextEditingController _ctrl;

  static String _fmt(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}.${d.year}';

  DateTime? _parse(String s) {
    if (s.length != 10) return null;
    final parts = s.split('.');
    if (parts.length != 3) return null;
    final d = int.tryParse(parts[0]);
    final m = int.tryParse(parts[1]);
    final y = int.tryParse(parts[2]);
    if (d == null || m == null || y == null) return null;
    if (m < 1 || m > 12 || d < 1 || d > 31 || y < 2000) return null;
    try {
      final date = DateTime(y, m, d);
      final min = DateTime(widget.minDate.year, widget.minDate.month,
          widget.minDate.day);
      if (!date.isBefore(min)) return date;
    } catch (_) {}
    return null;
  }

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(
        text: widget.date != null ? _fmt(widget.date!) : '');
  }

  @override
  void didUpdateWidget(_DateInputField old) {
    super.didUpdateWidget(old);
    if (widget.date != old.date) {
      final newText =
          widget.date != null ? _fmt(widget.date!) : '';
      if (_ctrl.text != newText) {
        _ctrl.text = newText;
        _ctrl.selection =
            TextSelection.collapsed(offset: newText.length);
      }
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CustomInputField(
      label: widget.label,
      value: _ctrl.text,
      icon: Icons.calendar_today_outlined,
      focusHint: 'DD.MM.YYYY',
      onIconTap: widget.onPickerTap,
      keyboardType: TextInputType.number,
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
        _DateFormatter(),
      ],
      onChanged: (v) {
        final parsed = _parse(v);
        if (parsed != null) widget.onDateChanged(parsed);
      },
    );
  }
}

// ─── Time input field ─────────────────────────────────────────────

class _TimeInputField extends StatefulWidget {
  final String label;
  final String value;
  final void Function(String) onChanged;

  const _TimeInputField({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  State<_TimeInputField> createState() => _TimeInputFieldState();
}

class _TimeInputFieldState extends State<_TimeInputField> {
  late final TextEditingController _ctrl;

  static bool _isValid(String s) {
    if (s.length != 5) return false;
    final parts = s.split(':');
    if (parts.length != 2) return false;
    final h = int.tryParse(parts[0]);
    final m = int.tryParse(parts[1]);
    if (h == null || m == null) return false;
    return h >= 0 && h <= 23 && m >= 0 && m <= 59;
  }

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.value);
  }

  @override
  void didUpdateWidget(_TimeInputField old) {
    super.didUpdateWidget(old);
    if (widget.value != old.value && _ctrl.text != widget.value) {
      _ctrl.text = widget.value;
      _ctrl.selection =
          TextSelection.collapsed(offset: widget.value.length);
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _pick() async {
    final initial =
        _isValid(widget.value) ? widget.value : '00:00';
    final result = await showPlanningTimePicker(
      context: context,
      initialTime: initial,
    );
    if (result != null) {
      _ctrl.text = result;
      _ctrl.selection =
          TextSelection.collapsed(offset: result.length);
      widget.onChanged(result);
    }
  }

  @override
  Widget build(BuildContext context) {
    return CustomInputField(
      label: widget.label,
      value: _ctrl.text,
      icon: Icons.access_time_outlined,
      focusHint: 'HH:MM',
      onIconTap: _pick,
      keyboardType: TextInputType.number,
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
        _TimeFormatter(),
      ],
      onChanged: (v) {
        if (_isValid(v)) widget.onChanged(v);
      },
    );
  }
}

// ─── Group card ───────────────────────────────────────────────────

class _GroupCard extends StatelessWidget {
  final _ScheduleGroup group;
  final int index;
  final List<({int id, String label})> days;
  final Set<int> usedDayIds;
  final bool canRemove;
  final VoidCallback onRemove;
  final VoidCallback onChanged;

  const _GroupCard({
    required this.group,
    required this.index,
    required this.days,
    required this.usedDayIds,
    required this.canRemove,
    required this.onRemove,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(10),
        border:
            Border.all(color: colors.outline.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Group ${index + 1}',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: colors.onSurfaceVariant,
                ),
              ),
              const Spacer(),
              if (canRemove)
                IconButton(
                  onPressed: onRemove,
                  icon: const Icon(Icons.close, size: 16),
                  style: IconButton.styleFrom(
                    foregroundColor: colors.onSurfaceVariant,
                    minimumSize: const Size(28, 28),
                    padding: EdgeInsets.zero,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: days.map((d) {
              final isSelected = group.dayIds.contains(d.id);
              final isDisabled =
                  !isSelected && usedDayIds.contains(d.id);
              return MouseRegion(
                cursor: isDisabled
                    ? SystemMouseCursors.basic
                    : SystemMouseCursors.click,
                child: GestureDetector(
                  onTap: isDisabled
                      ? null
                      : () {
                          if (isSelected) {
                            group.dayIds.remove(d.id);
                          } else {
                            group.dayIds.add(d.id);
                          }
                          onChanged();
                        },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 120),
                    width: 44,
                    height: 36,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? colors.primary
                          : isDisabled
                              ? colors.surfaceContainerHighest
                                  .withValues(alpha: 0.3)
                              : colors.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: isSelected
                            ? colors.primary
                            : colors.outline.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Center(
                      child: Text(
                        d.label,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: isSelected
                              ? FontWeight.w600
                              : FontWeight.normal,
                          color: isSelected
                              ? colors.onPrimary
                              : isDisabled
                                  ? colors.onSurfaceVariant
                                      .withValues(alpha: 0.35)
                                  : colors.onSurface,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _TimeInputField(
                  label: 'Departure',
                  value: group.departureTime,
                  onChanged: (v) {
                    group.departureTime = v;
                    onChanged();
                  },
                ),
              ),
              const SizedBox(width: 12),
              Icon(Icons.arrow_forward,
                  size: 16, color: colors.onSurfaceVariant),
              const SizedBox(width: 12),
              Expanded(
                child: _TimeInputField(
                  label: 'Arrival',
                  value: group.arrivalTime,
                  onChanged: (v) {
                    group.arrivalTime = v;
                    onChanged();
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}