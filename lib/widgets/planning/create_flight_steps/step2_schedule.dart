import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../widgets/planning/schedule_date_picker.dart';
import '../../../widgets/planning/planning_time_picker.dart';
import '../../../widgets/custom/custom_input_field.dart';

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
      crossAxisAlignment: CrossAxisAlignment.start,
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
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 18, left: 12, right: 12),
          child: Icon(Icons.arrow_forward,
              size: 16,
              color: Theme.of(context).colorScheme.onSurfaceVariant),
        ),
        Expanded(
          child: _DateInputField(
            label: 'End date',
            date: _endDate,
            minDate: _startDate ?? DateTime.now(),
            onDateChanged: (d) {
              setState(() => _endDate = d);
              _notify();
            },
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
            style: TextStyle(fontSize: 13, color: colors.onSurfaceVariant),
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

// ─── Date input field (overlay) ───────────────────────────────────

class _DateInputField extends StatefulWidget {
  final String label;
  final DateTime? date;
  final DateTime minDate;
  final ValueChanged<DateTime> onDateChanged;

  const _DateInputField({
    required this.label,
    required this.date,
    required this.minDate,
    required this.onDateChanged,
  });

  @override
  State<_DateInputField> createState() => _DateInputFieldState();
}

class _DateInputFieldState extends State<_DateInputField> {
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
  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _overlay;
  bool _isOpen = false;

  String _displayValue = '';

  @override
  void initState() {
    super.initState();
    _displayValue = widget.value;
  }

  void _toggle() => _isOpen ? _close() : _open();

  void _open() {
    if (!mounted) return;
    setState(() => _isOpen = true);
    _insertOverlay();
  }

  void _insertOverlay() {
    _overlay?.remove();
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
            onTapOutside: (_) => _close(),
            child: Material(
              elevation: 4,
              borderRadius: BorderRadius.circular(12),
              child: SizedBox(
                width: 200,
                child: PlanningTimePickerOverlay(
                  initialTime: _displayValue.isNotEmpty
                      ? _displayValue
                      : '00:00',
                  onTimeSelected: _handleTimeSelected,
                  onClose: _close,
                ),
              ),
            ),
          ),
        ),
      ),
    );
    Overlay.of(context).insert(_overlay!);
  }

  void _handleTimeSelected(String v) {
    widget.onChanged(v); 
    if (mounted && _displayValue != v) {
      setState(() => _displayValue = v); 
    }
  }

  void _close() {
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
        value: _displayValue,
        icon: Icons.access_time_outlined,
        readOnly: true,
        isSelected: _isOpen,
        onTap: _toggle,
        onIconTap: _toggle,
      ),
    );
  }
}
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
        border: Border.all(color: colors.outline.withValues(alpha: 0.2)),
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ✅ Виправлення 3: прибрано зайві TapRegion навколо _TimeInputField
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
              Padding(
                padding: const EdgeInsets.only(top: 18, left: 12, right: 12),
                child: Icon(Icons.arrow_forward,
                    size: 16, color: colors.onSurfaceVariant),
              ),
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