import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../custom/custom_select_field.dart';
import '../../../services/planning_service.dart';

class Step1RouteDate extends StatefulWidget {
  final PlanningService service;
  final Map<String, dynamic>? selectedRoute;
  final int? selectedFlightScheduleId;
  final DateTime? selectedDate;
  final String? departsTime;
  final String? arrivesTime;
  final void Function({
    required Map<String, dynamic> route,
    required int flightScheduleId,
    required DateTime date,
    required String departsTime,
    required String arrivesTime,
  }) onChanged;

  const Step1RouteDate({
    super.key,
    required this.service,
    required this.selectedRoute,
    required this.selectedFlightScheduleId,
    required this.selectedDate,
    required this.departsTime,
    required this.arrivesTime,
    required this.onChanged,
  });

  @override
  State<Step1RouteDate> createState() => _Step1RouteDateState();
}

class _Step1RouteDateState extends State<Step1RouteDate> {
  List<Map<String, dynamic>> _routes = [];
  List<Map<String, dynamic>> _schedules = [];
  Set<String> _bookedDates = {};

  bool _loadingRoutes = true;
  bool _loadingSchedules = false;

  Map<String, dynamic>? _route;
  DateTime? _selectedDate;
  int? _scheduleId;
  String? _departsTime;
  String? _arrivesTime;

  DateTime _focusedMonth = DateTime.now();

  @override
  void initState() {
    super.initState();
    _route = widget.selectedRoute;
    _selectedDate = widget.selectedDate;
    _scheduleId = widget.selectedFlightScheduleId;
    _departsTime = widget.departsTime;
    _arrivesTime = widget.arrivesTime;
    _loadRoutes();
    if (_route != null) _loadSchedules(_route!['routeId'] as int);
  }

  Future<void> _loadRoutes() async {
    try {
      final routes = await widget.service.getRoutes();
      if (mounted) setState(() { _routes = routes; _loadingRoutes = false; });
    } catch (_) { if (mounted) setState(() => _loadingRoutes = false); }
  }

  Future<void> _loadSchedules(int routeId) async {
    setState(() { _loadingSchedules = true; _bookedDates = {}; });
    try {
      final schedules = await widget.service.getRouteSchedules(routeId);
      final allBooked = <String>{};
      for (final s in schedules) {
        final dates = await widget.service.getBookedDatesForSchedule(s['flightScheduleId']);
        allBooked.addAll(dates);
      }
      if (mounted) setState(() {
        _schedules = schedules;
        _bookedDates = allBooked;
        _loadingSchedules = false;
        final first = _firstAvailableDate();
        if (first != null) _focusedMonth = DateTime(first.year, first.month);
      });
    } catch (_) { if (mounted) setState(() => _loadingSchedules = false); }
  }

  bool _isBooked(DateTime date) => _bookedDates.contains(
      '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}');

  Map<String, dynamic>? _scheduleForDate(DateTime date) {
    final dayOfWeek = date.weekday;
    final d = DateTime(date.year, date.month, date.day);
    for (final s in _schedules) {
      final start = DateTime.parse(s['flightStartDate']);
      final end = DateTime.parse(s['flightEndDate']);
      if (s['dayId'] == dayOfWeek && !d.isBefore(start) && !d.isAfter(end)) return s;
    }
    return null;
  }

  bool _isInRange(DateTime date) {
    final todayOnly = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
    if (DateTime(date.year, date.month, date.day).isBefore(todayOnly)) return false;
    return _scheduleForDate(date) != null;
  }

  DateTime? _firstAvailableDate() {
    final today = DateTime.now();
    for (int i = 0; i < 120; i++) {
      final d = today.add(Duration(days: i));
      if (_isInRange(d) && !_isBooked(d)) return d;
    }
    return null;
  }

  void _onDateSelected(DateTime date) {
    final s = _scheduleForDate(date)!;
    final depStr = s['departureTime']?.toString() ?? '00:00:00';
    final arrStr = s['arrivalTime']?.toString() ?? '00:00:00';

    setState(() {
      _selectedDate = date;
      _scheduleId = s['flightScheduleId'];
      _departsTime = depStr.length >= 5 ? depStr.substring(0, 5) : depStr;
      _arrivesTime = arrStr.length >= 5 ? arrStr.substring(0, 5) : arrStr;
    });
    
    widget.onChanged(
        route: _route!, 
        flightScheduleId: _scheduleId!, 
        date: _selectedDate!, 
        departsTime: _departsTime!, 
        arrivesTime: _arrivesTime!
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeader(colors),
        const SizedBox(height: 16),
        if (_route != null && !_loadingSchedules)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildCalendarSide(colors),
              const SizedBox(width: 24),
              Expanded(child: _buildInfoSide(colors)),
            ],
          ),
        if (_loadingSchedules)
          const Padding(padding: EdgeInsets.only(top: 60), child: Center(child: CircularProgressIndicator())),
      ],
    );
  }

  Widget _buildHeader(ColorScheme colors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionLabel('Select Route'),
        const SizedBox(height: 8),
        CustomSelectField(
          label: 'Route number',
          icon: Icons.flight_takeoff,
          value: _route != null ? '${_route!['flightNumber']} (${_route!['departsCode']} → ${_route!['arrivesCode']})' : '',
          items: _routes.map((r) => '${r['flightNumber']} (${r['departsCode']} → ${r['arrivesCode']})').toList(),
          onChanged: (v) {
            final r = _routes.firstWhere((r) => '${r['flightNumber']} (${r['departsCode']} → ${r['arrivesCode']})' == v);
            setState(() { _route = r; _selectedDate = null; _scheduleId = null; });
            _loadSchedules(r['routeId']);
          },
        ),
      ],
    );
  }

  Widget _buildCalendarSide(ColorScheme colors) {
    return Container(
      width: 310,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(onPressed: () => setState(() => _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month - 1)), icon: const Icon(Icons.chevron_left, size: 20)),
              Text('${_monthName(_focusedMonth.month)} ${_focusedMonth.year}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              IconButton(onPressed: () => setState(() => _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month + 1)), icon: const Icon(Icons.chevron_right, size: 20)),
            ],
          ),
          const SizedBox(height: 8),
          _buildWeekHeaders(colors),
          _buildGrid(colors),
          const SizedBox(height: 12),
          _buildLegend(colors),
        ],
      ),
    );
  }

  Widget _buildInfoSide(ColorScheme colors) {
    if (_schedules.isEmpty) return const SizedBox.shrink();

    final starts = _schedules.map((s) => DateTime.parse(s['flightStartDate'])).toList()..sort();
    final ends = _schedules.map((s) => DateTime.parse(s['flightEndDate'])).toList()..sort();
    String rangeText = "${DateFormat('dd.MM.yyyy').format(starts.first)} — ${DateFormat('dd.MM.yyyy').format(ends.last)}";

    Map<String, List<String>> groupedTimes = {};
    for (var s in _schedules) {
      String dep = (s['departureTime'] ?? '--:--').toString().substring(0, 5);
      String arr = (s['arrivalTime'] ?? '--:--').toString().substring(0, 5);
      String timeKey = "$dep → $arr";
      String day = s['dayName']?.toString().substring(0, 3) ?? '';
      if (!groupedTimes.containsKey(timeKey)) groupedTimes[timeKey] = [];
      groupedTimes[timeKey]!.add(day);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionLabel('Schedule Overview'),
        const SizedBox(height: 12),
        _infoRow(colors, Icons.calendar_today, 'Validity', rangeText),
        const SizedBox(height: 24),
        const _SectionLabel('Flight Times'),
        const SizedBox(height: 12),
        ...groupedTimes.entries.map((entry) {
          bool isDaily = entry.value.length == 7;
          String daysLabel = isDaily ? "Daily" : entry.value.join(', ');
          
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: colors.surfaceContainerHighest.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Icon(Icons.access_time, size: 16, color: colors.primary),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(entry.key, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    const SizedBox(height: 2),
                    Text(daysLabel, style: TextStyle(fontSize: 11, color: colors.onSurfaceVariant)),
                  ],
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _infoRow(ColorScheme colors, IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 16, color: colors.primary),
        const SizedBox(width: 8),
        Text('$label: ', style: TextStyle(fontSize: 12, color: colors.onSurfaceVariant)),
        Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildWeekHeaders(ColorScheme colors) {
    return Row(children: ['Mo', 'Tu', 'We', 'Th', 'Fr', 'Sa', 'Su'].map((d) => Expanded(child: Center(child: Text(d, style: TextStyle(fontSize: 11, color: colors.onSurfaceVariant.withValues(alpha: 0.5)))))).toList());
  }

  Widget _buildGrid(ColorScheme colors) {
    final first = DateTime(_focusedMonth.year, _focusedMonth.month, 1);
    final days = DateTime(_focusedMonth.year, _focusedMonth.month + 1, 0).day;
    final startOffset = first.weekday - 1;

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 7, childAspectRatio: 1.1),
      itemCount: startOffset + days,
      itemBuilder: (context, index) {
        if (index < startOffset) return const SizedBox.shrink();
        final date = DateTime(_focusedMonth.year, _focusedMonth.month, index - startOffset + 1);
        final isSelected = _selectedDate != null && DateUtils.isSameDay(date, _selectedDate!);
        final inRange = _isInRange(date);
        final booked = inRange && _isBooked(date);
        final available = inRange && !booked;

        return GestureDetector(
          onTap: available ? () => _onDateSelected(date) : null,
          child: Container(
            margin: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: isSelected ? colors.primary : (booked ? colors.secondaryContainer.withValues(alpha: 0.4) : (available ? colors.primaryContainer.withValues(alpha: 0.15) : null)),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(child: Text('${date.day}', style: TextStyle(
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              color: isSelected ? colors.onPrimary : (booked ? colors.onSecondaryContainer.withValues(alpha: 0.5) : (inRange ? colors.onSurface : colors.onSurface.withValues(alpha: 0.2))),
            ))),
          ),
        );
      },
    );
  }

  Widget _buildLegend(ColorScheme colors) {
    return Row(
      children: [
        _legendItem(colors.primaryContainer.withValues(alpha: 0.5), 'Available'),
        const SizedBox(width: 16),
        _legendItem(colors.secondaryContainer.withValues(alpha: 0.5), 'Scheduled'),
      ],
    );
  }

  Widget _legendItem(Color c, String label) => Row(children: [
    Container(width: 10, height: 10, decoration: BoxDecoration(color: c, borderRadius: BorderRadius.circular(3))),
    const SizedBox(width: 6),
    Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
  ]);

  String _monthName(int m) => ['', 'January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'][m];
}

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel(this.label);
  @override
  Widget build(BuildContext context) => Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold));
}