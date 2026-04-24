import 'package:flutter/material.dart';
import '../../../models/schedule_group_model.dart';
import '../../../widgets/planning/schedule_date_input_field.dart';
import '../../../widgets/planning/schedule_group_card.dart';

class Step2Schedule extends StatefulWidget {
  final List<Map<String, dynamic>> scheduleGroups;
  final DateTime? flightStartDate;
  final DateTime? flightEndDate;
  final Duration? flightDuration;
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
    this.flightDuration,
  });

  @override
  State<Step2Schedule> createState() => _Step2ScheduleState();
}

class _Step2ScheduleState extends State<Step2Schedule> {
  late List<ScheduleGroup> _groups;
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
    _groups = widget.scheduleGroups
        .map(ScheduleGroup.fromMap)
        .toList();
    if (_groups.isEmpty) _groups.add(ScheduleGroup());
  }

  Set<int> get _usedDayIds =>
      _groups.expand((g) => g.dayIds).toSet();

  void _notify() {
    widget.onChanged(
      scheduleGroups: _groups
          .where((g) => g.dayIds.isNotEmpty && g.departureTime.isNotEmpty)
          .map((g) => g.toMap())
          .toList(),
      flightStartDate: _startDate,
      flightEndDate: _endDate,
    );
  }

  void _addGroup() {
    setState(() => _groups.add(ScheduleGroup()));
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

  String _calcArrival(String departureTime) {
    if (departureTime.isEmpty || widget.flightDuration == null) return '';
    final parts = departureTime.split(':');
    if (parts.length != 2) return '';
    final h = int.tryParse(parts[0]);
    final m = int.tryParse(parts[1]);
    if (h == null || m == null) return '';
    final dep = Duration(hours: h, minutes: m);
    final arr = dep + widget.flightDuration!;
    final totalMin = arr.inMinutes % (24 * 60);
    final arrH = totalMin ~/ 60;
    final arrM = totalMin % 60;
    final nextDay =
        dep + widget.flightDuration! >= const Duration(hours: 24);
    return '${arrH.toString().padLeft(2, '0')}:${arrM.toString().padLeft(2, '0')}'
        '${nextDay ? ' (+1)' : ''}';
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
          'Add groups of days that share the same departure time. '
          'Arrival time is calculated automatically.',
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
            child: ScheduleGroupCard(
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
              calcArrival: _calcArrival,
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
          child: ScheduleDateInputField(
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
          child: Icon(
            Icons.arrow_forward,
            size: 16,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        Expanded(
          child: ScheduleDateInputField(
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