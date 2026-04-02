import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../services/planning_service.dart';
import '../../models/planning_overview_model.dart';
import '../../widgets/responsive_layout.dart';
import '../../widgets/custom/custom_button.dart';
import '../../widgets/custom/custom_select_field.dart';
import '../../widgets/admin/user_table_pagination.dart';
import '../../widgets/planning_table_row.dart';
import '../../widgets/planning/planning_date_picker.dart';

enum _ViewMode { all, day, month }

class PlanningFlightsPage extends StatefulWidget {
  const PlanningFlightsPage({super.key});

  @override
  State<PlanningFlightsPage> createState() => _PlanningFlightsPageState();
}

class _PlanningFlightsPageState extends State<PlanningFlightsPage> {
  late final PlanningService _service;
  final ScrollController _horizontalScroll = ScrollController();

  List<OverviewFlight> _flights = [];
  List<String> _availableDates = [];
  List<String> _availableMonths = [];

  bool _flightsLoading = true;
  String? _flightsError;

  _ViewMode _viewMode = _ViewMode.day;
  DateTime _selectedDate = DateTime.now();

  int _currentPage = 1;
  static const int _itemsPerPage = 10;

  String? _selectedStatus;
  String? _selectedAircraft;
  String _sortBy = 'default'; 

  static const List<({String key, String label, double width})> _colDefs = [
    (key: 'flight_number', label: 'Flight',    width: 100),
    (key: 'route',         label: 'Route',     width: 120),
    (key: 'departs',       label: 'Departure', width: 110),
    (key: 'arrives',       label: 'Arrival',   width: 100),
    (key: 'aircraft',      label: 'Aircraft',  width: 130),
    (key: 'classes',       label: 'Classes',   width: 160),
    (key: 'load',          label: 'Load',      width: 130),
    (key: 'status',        label: 'Status',    width: 130),
  ];

  late Map<String, double> _colWidths;

  List<OverviewFlight> get _filteredFlights {
    var list = _flights.where((f) {
      if (_selectedStatus != null && _selectedStatus != 'All' &&
          f.flightStatusName != _selectedStatus) return false;
      if (_selectedAircraft != null && _selectedAircraft != 'All' &&
          f.aircraftModel != _selectedAircraft) return false;
      return true;
    }).toList();

    if (_sortBy == 'load_asc') {
      list.sort((a, b) => a.loadPercent.compareTo(b.loadPercent));
    } else if (_sortBy == 'load_desc') {
      list.sort((a, b) => b.loadPercent.compareTo(a.loadPercent));
    }
    return list;
  }

  List<String> get _statusOptions =>
      ['All', ..._flights.map((f) => f.flightStatusName).toSet().toList()..sort()];

  List<String> get _aircraftOptions =>
      ['All', ..._flights.map((f) => f.aircraftModel).toSet().toList()..sort()];

  @override
  void initState() {
    super.initState();
    _colWidths = {for (final c in _colDefs) c.key: c.width};
    _service = PlanningService(context.read<AuthService>());
    Future.wait([_loadFlights(), _loadAvailableDates()]);
    Future.wait([_loadFlights(), _loadAvailableDates(), _loadAvailableMonths()]);
  }

  Future<void> _loadAvailableMonths() async {
    final months = await _service.getAvailableMonths();
    if (mounted) setState(() => _availableMonths = months);
  }

  bool _isMonthAvailable(int year, int month) {
  final key = '$year-${month.toString().padLeft(2, '0')}';
  return _availableMonths.isEmpty || _availableMonths.contains(key);
}

  Future<void> _pickMonth() async {
    final colors = Theme.of(context).colorScheme;
    int tempYear = _selectedDate.year;

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Text('Select month',
                        style: Theme.of(context).textTheme.titleMedium),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close, size: 20),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.chevron_left),
                      onPressed: () => setModalState(() => tempYear--),
                    ),
                    Text('$tempYear',
                        style: Theme.of(context)
                            .textTheme
                            .titleSmall
                            ?.copyWith(fontWeight: FontWeight.w500)),
                    IconButton(
                      icon: const Icon(Icons.chevron_right),
                      onPressed: () => setModalState(() => tempYear++),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                GridView.count(
                  shrinkWrap: true,
                  crossAxisCount: 3,
                  childAspectRatio: 2.2,
                  mainAxisSpacing: 8,
                  crossAxisSpacing: 8,
                  children: List.generate(12, (i) {
                    final m = i + 1;
                    final isSelected = m == _selectedDate.month &&
                        tempYear == _selectedDate.year;
                    final isAvail = _isMonthAvailable(tempYear, m);

                    return GestureDetector(
                      onTap: isAvail
                          ? () {
                              Navigator.of(context).pop();
                              setState(() {
                                _selectedDate = DateTime(tempYear, m);
                                _selectedStatus = null;
                                _selectedAircraft = null;
                              });
                              _loadFlights();
                            }
                          : null,
                      child: Container(
                        decoration: BoxDecoration(
                          color: isSelected
                              ? colors.primary
                              : colors.surfaceContainerHighest
                                  .withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Center(
                          child: Text(
                            _shortMonth(m),
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: isSelected
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                              color: isSelected
                                  ? colors.onPrimary
                                  : isAvail
                                      ? colors.onSurface
                                      : colors.onSurfaceVariant
                                          .withValues(alpha: 0.4),
                              decoration: !isAvail
                                  ? TextDecoration.lineThrough
                                  : null,
                              decorationColor: colors.onSurfaceVariant
                                  .withValues(alpha: 0.4),
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _horizontalScroll.dispose();
    super.dispose();
  }

  Future<void> _loadFlights() async {
    setState(() { _flightsLoading = true; _flightsError = null; });
    try {
      final result = await _service.getOverviewFlights(
        mode: _viewMode.name,
        date: _selectedDate,
        month: _selectedDate.month,
        year: _selectedDate.year,
      );
      if (mounted) setState(() { _flights = result; _currentPage = 1; });
    } catch (e) {
      if (mounted) setState(() => _flightsError = e.toString());
    } finally {
      if (mounted) setState(() => _flightsLoading = false);
    }
  }

  Future<void> _loadAvailableDates() async {
    final dates = await _service.getAvailableDates();
    if (mounted) setState(() => _availableDates = dates);
  }

  int get _totalPages =>
      (_filteredFlights.length / _itemsPerPage).ceil().clamp(1, 9999);

  List<OverviewFlight> get _paginatedFlights {
    final start = (_currentPage - 1) * _itemsPerPage;
    final end = (start + _itemsPerPage).clamp(0, _filteredFlights.length);
    return _filteredFlights.isEmpty ? [] : _filteredFlights.sublist(start, end);
  }

  double get _totalWidth => _colWidths.values.fold(0, (s, w) => s + w);

  void _onColumnResize(String key, double delta) {
    setState(() {
      final current = _colWidths[key] ?? 100;
      _colWidths[key] = (current + delta).clamp(60.0, 400.0);
    });
  }

  Future<void> _pickDate() async {
    if (_viewMode == _ViewMode.all) return;

    if (_viewMode == _ViewMode.month) {
      await _pickMonth();
      return;
    }

    await showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: PlanningDatePicker(
          selectedDate: _selectedDate,
          availableDates: _availableDates,
          onDateSelected: (date) {
            Navigator.of(context).pop();
            if (date != _selectedDate) {
              setState(() {
                _selectedDate = date;
                _selectedStatus = null;
                _selectedAircraft = null;
              });
              _loadFlights();
            }
          },
        ),
      ),
    );
  }


  String _periodLabel() {
    switch (_viewMode) {
      case _ViewMode.all:
        return 'All flights';
      case _ViewMode.day:
        return _fmtDate(_selectedDate);
      case _ViewMode.month:
        return '${_monthName(_selectedDate.month)} ${_selectedDate.year}';
    }
  }

  @override
  Widget build(BuildContext context) {
    return ResponsiveLayout(
      header: Padding(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildPageHeader(),
            const SizedBox(height: 16),
            _buildFilters(),
          ],
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        child: _buildTableCard(),
      ),
    );
  }

  Widget _buildPageHeader() {
    final colors = Theme.of(context).colorScheme;
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Flights', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 2),
              Text(_periodLabel(),
                  style: Theme.of(context).textTheme.bodyMedium),
            ],
          ),
        ),

        Container(
          decoration: BoxDecoration(
            color: colors.surfaceContainerHighest.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: colors.outline.withValues(alpha: 0.2)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: _ViewMode.values.map((mode) {
              final isActive = _viewMode == mode;
              return GestureDetector(
                onTap: () {
                  if (_viewMode == mode) return;
                  setState(() {
                    _viewMode = mode;
                    _selectedStatus = null;
                    _selectedAircraft = null;
                  });
                  _loadFlights();
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: isActive ? colors.primary : Colors.transparent,
                    borderRadius: BorderRadius.circular(7),
                  ),
                  child: Text(
                    mode.name[0].toUpperCase() + mode.name.substring(1),
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: isActive
                          ? FontWeight.w600
                          : FontWeight.normal,
                      color: isActive
                          ? colors.onPrimary
                          : colors.onSurfaceVariant,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),

        if (_viewMode != _ViewMode.all) ...[
          const SizedBox(width: 12),
          InkWell(
            onTap: _pickDate,
            borderRadius: BorderRadius.circular(6),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: colors.primaryContainer.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.calendar_today_rounded,
                      size: 15, color: colors.primary),
                  const SizedBox(width: 6),
                  Text(
                    _viewMode == _ViewMode.day
                        ? _fmtDate(_selectedDate)
                        : '${_shortMonth(_selectedDate.month)} ${_selectedDate.year}',
                    style:
                        TextStyle(fontSize: 13, color: colors.onSurface),
                  ),
                ],
              ),
            ),
          ),
        ],

        const SizedBox(width: 12),
        CustomButton(
          label: 'Add Flight',
          icon: Icons.add,
          isIconAfterLabel: false,
          verticalPadding: 12,
          horizontalPadding: 18,
          onPressed: () {},
        ),
      ],
    );
  }

  Widget _buildFilters() {
    if (_flights.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        children: [
          SizedBox(
            width: 200,
            child: CustomSelectField(
              label: 'Status',
              icon: Icons.circle_outlined,
              value: _selectedStatus ?? 'All',
              items: _statusOptions,
              onChanged: (v) => setState(() {
                _selectedStatus = v == 'All' ? null : v;
                _currentPage = 1;
              }),
            ),
          ),
          SizedBox(
            width: 220,
            child: CustomSelectField(
              label: 'Aircraft',
              icon: Icons.airplanemode_active_outlined,
              value: _selectedAircraft ?? 'All',
              items: _aircraftOptions,
              onChanged: (v) => setState(() {
                _selectedAircraft = v == 'All' ? null : v;
                _currentPage = 1;
              }),
            ),
          ),
          SizedBox(
            width: 200,
            child: CustomSelectField(
              label: 'Sort by Load',
              icon: Icons.sort_rounded,
              value: _sortBy == 'load_desc'
                  ? 'Highest first'
                  : _sortBy == 'load_asc'
                      ? 'Lowest first'
                      : 'Default',
              items: const ['Default', 'Highest first', 'Lowest first'],
              onChanged: (v) => setState(() {
                _sortBy = v == 'Highest first'
                    ? 'load_desc'
                    : v == 'Lowest first'
                        ? 'load_asc'
                        : 'default';
                _currentPage = 1;
              }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTableCard() {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        children: [
          Expanded(
            child: _flightsLoading
                ? const Center(child: CircularProgressIndicator())
                : _flightsError != null
                    ? Center(
                        child: _ErrorBanner(
                          message: 'Could not load flights',
                          onRetry: _loadFlights,
                        ),
                      )
                    : SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        controller: _horizontalScroll,
                        child: SizedBox(
                          width: _totalWidth,
                          child: Column(
                            children: [
                              _buildTableHeader(),
                              Expanded(
                                child: _paginatedFlights.isEmpty
                                    ? Center(
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(Icons.flight_rounded,
                                                size: 64,
                                                color: Theme.of(context)
                                                    .colorScheme
                                                    .onSurfaceVariant),
                                            const SizedBox(height: 16),
                                            Text(
                                              _selectedStatus != null ||
                                                      _selectedAircraft != null
                                                  ? 'No flights match the selected filters'
                                                  : 'No flights for the selected period',
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .titleMedium,
                                            ),
                                          ],
                                        ),
                                      )
                                    : ListView.builder(
                                        itemCount: _paginatedFlights.length,
                                        itemBuilder: (context, index) =>
                                            PlanningTableRow(
                                          flight: _paginatedFlights[index],
                                          columnWidths: _colWidths,
                                        ),
                                      ),
                              ),
                            ],
                          ),
                        ),
                      ),
          ),
          UserTablePagination(
            currentPage: _currentPage,
            totalPages: _totalPages,
            totalUsers: _filteredFlights.length,
            itemsPerPage: _itemsPerPage,
            onPrevious: () => setState(() => _currentPage--),
            onNext: () => setState(() => _currentPage++),
          ),
        ],
      ),
    );
  }

  Widget _buildTableHeader() {
    final colors = Theme.of(context).colorScheme;
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: colors.surfaceContainerHighest.withValues(alpha: 0.5),
        border: Border(
            bottom: BorderSide(color: colors.outline.withValues(alpha: 0.2))),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(6),
          topRight: Radius.circular(6),
        ),
      ),
      child: Row(
        children: _colDefs.map((col) {
          final isFirst = col == _colDefs.first;
          return SizedBox(
            width: _colWidths[col.key],
            child: Row(
              children: [
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(left: isFirst ? 16 : 4),
                    child: Text(
                      col.label,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),
                ),
                GestureDetector(
                  onHorizontalDragUpdate: (d) =>
                      _onColumnResize(col.key, d.delta.dx),
                  child: MouseRegion(
                    cursor: SystemMouseCursors.resizeColumn,
                    child: Container(
                      width: 8,
                      height: 48,
                      color: Colors.transparent,
                      child: Center(
                        child: Container(
                          width: 1,
                          height: 24,
                          color: colors.outline.withValues(alpha: 0.3),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  String _fmtDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}.${d.year}';

  String _shortMonth(int m) => const [
        '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
      ][m];

  String _monthName(int m) => const [
        '', 'January', 'February', 'March', 'April', 'May', 'June',
        'July', 'August', 'September', 'October', 'November', 'December',
      ][m];
}

class _ErrorBanner extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorBanner({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline,
              color: Theme.of(context).colorScheme.error),
          const SizedBox(width: 12),
          Expanded(
            child: Text(message,
                style: TextStyle(
                    color: Theme.of(context).colorScheme.onErrorContainer)),
          ),
          const SizedBox(width: 8),
          CustomButton(
              label: 'Retry',
              verticalPadding: 10,
              horizontalPadding: 14,
              onPressed: onRetry),
        ],
      ),
    );
  }
}