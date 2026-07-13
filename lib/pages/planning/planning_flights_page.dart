import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../services/planning_service.dart';
import '../../models/planning_overview_model.dart';
import '../../widgets/responsive_layout.dart';
import '../../widgets/custom/custom_button.dart';
import '../../widgets/planning/planning_flights_table.dart';
import '../../widgets/planning/planning_flights_filters.dart';
import '../../widgets/planning/planning_month_picker.dart';
import '../../widgets/planning/planning_date_picker.dart';
import '../../widgets/planning/planning_time_picker.dart';
import 'dart:convert'; 


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
  List<String> _allFlightNumbers = [];

  bool _flightsLoading = true;
  String? _flightsError;

  _ViewMode _viewMode = _ViewMode.day;
  DateTime _selectedDate = DateTime.now();

  int _currentPage = 1;
  static const int _itemsPerPage = 10;

  String? _selectedStatus;
  String? _selectedAircraft;
  String _sortBy = 'default';
  String _searchQuery = '';

  static const List<({String key, String label, double width})> _colDefs = [
    (key: 'flight_number', label: 'Flight',    width: 90),
    (key: 'route',         label: 'Route',     width: 120),
    (key: 'date',          label: 'Date',      width: 100),     
    (key: 'schedule',      label: 'Schedule',  width: 130), 
    (key: 'aircraft',      label: 'Aircraft',  width: 120),
    (key: 'classes',       label: 'Classes',   width: 160),
    (key: 'load',          label: 'Load',      width: 120),
    (key: 'status',        label: 'Status',    width: 130),
    (key: 'actions',       label: '',          width: 50),
  ];

  late Map<String, double> _colWidths;

  List<OverviewFlight> get _filteredFlights {
    var list = _flights.where((f) {
      if (_selectedStatus != null &&
          _selectedStatus != 'All' &&
          f.flightStatusName != _selectedStatus) return false;
      if (_selectedAircraft != null &&
          _selectedAircraft != 'All' &&
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

  List<String> get _statusOptions => [
        'All',
        ..._flights.map((f) => f.flightStatusName).toSet().toList()..sort(),
      ];

  List<String> get _aircraftOptions => [
        'All',
        ..._flights.map((f) => f.aircraftModel).toSet().toList()..sort(),
      ];

  int get _totalPages =>
      (_filteredFlights.length / _itemsPerPage).ceil().clamp(1, 9999);

  List<OverviewFlight> get _paginatedFlights {
    final start = (_currentPage - 1) * _itemsPerPage;
    final end = (start + _itemsPerPage).clamp(0, _filteredFlights.length);
    return _filteredFlights.isEmpty ? [] : _filteredFlights.sublist(start, end);
  }

  @override
  void initState() {
    super.initState();
    _colWidths = {for (final c in _colDefs) c.key: c.width};
    _service = PlanningService(context.read<AuthService>());
    Future.wait([
      _loadFlights(),
      _loadAvailableDates(),
      _loadAvailableMonths(),
      _loadAllFlightNumbers(),
    ]);
  }

  @override
  void dispose() {
    _horizontalScroll.dispose();
    super.dispose();
  }

  Future<void> _loadFlights() async {
    setState(() {
      _flightsLoading = true;
      _flightsError = null;
    });
    try {
      final result = await _service.getOverviewFlights(
        mode: _viewMode.name,
        date: _selectedDate,
        month: _selectedDate.month,
        year: _selectedDate.year,
        flightNumber: _searchQuery.isNotEmpty ? _searchQuery : null,
      );
      if (mounted) setState(() {
        _flights = result;
        _currentPage = 1;
      });
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

  Future<void> _loadAvailableMonths() async {
    final months = await _service.getAvailableMonths();
    if (mounted) setState(() => _availableMonths = months);
  }

  Future<void> _loadAllFlightNumbers() async {
    final numbers = await _service.getAllFlightNumbers();
    if (mounted) setState(() => _allFlightNumbers = numbers);
  }

  void _onColumnResize(String key, double delta) {
    setState(() {
      final current = _colWidths[key] ?? 100;
      _colWidths[key] = (current + delta).clamp(60.0, 400.0);
    });
  }

  Future<void> _pickDate() async {
    if (_viewMode == _ViewMode.all) return;

    if (_viewMode == _ViewMode.month) {
      await showMonthPicker(
        context: context,
        selectedDate: _selectedDate,
        availableMonths: _availableMonths,
        onMonthSelected: (date) {
          setState(() {
            _selectedDate = date;
            _selectedStatus = null;
            _selectedAircraft = null;
          });
          _loadFlights();
        },
      );
      return;
    }

    await showDialog(
      context: context,
      builder: (context) => Dialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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

  Future<void> _onStatusTap(OverviewFlight flight) async {
    if (flight.flightStatusName == 'Cancelled') return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Flight'),
        content: Text('Do you really want to cancel flight ${flight.flightNumber}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('No')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Yes, Cancel', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _service.cancelFlight(flight.flightId);
        _loadFlights(); // Оновлення таблиці
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  

Future<void> _onEditTap(OverviewFlight flight) async {
  DateTime selectedDate = flight.departsDatetime;
  String depTime = '${flight.departsDatetime.hour.toString().padLeft(2, '0')}:${flight.departsDatetime.minute.toString().padLeft(2, '0')}';
  String arrTime = '${flight.arrivesDatetime.hour.toString().padLeft(2, '0')}:${flight.arrivesDatetime.minute.toString().padLeft(2, '0')}';
  
  String? errorMessage;

  await showDialog(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setDialogState) {
        final colors = Theme.of(context).colorScheme;

        return Dialog(
          backgroundColor: colors.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Container(
            width: 850,
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Icon(Icons.edit_calendar_rounded, color: colors.primary),
                    const SizedBox(width: 12),
                    Text('Edit Flight Schedule', style: Theme.of(context).textTheme.titleLarge),
                    const Spacer(),
                    IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close)),
                  ],
                ),
                const SizedBox(height: 24),
                
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 4,
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: colors.outlineVariant),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: PlanningDatePicker(
                          selectedDate: selectedDate,
                          availableDates: const [], 
                          onDateSelected: (date) => setDialogState(() => selectedDate = date),
                        ),
                      ),
                    ),
                    const SizedBox(width: 24),

                    Expanded(
                      flex: 5,
                      child: Column(
                        children: [
                          Row(
                            children: [
                              _buildTimeColumn(context, 'Departure', depTime, (t) => setDialogState(() => depTime = t)),
                              const SizedBox(width: 16),
                              _buildTimeColumn(context, 'Arrival', arrTime, (t) => setDialogState(() => arrTime = t)),
                            ],
                          ),
                          const SizedBox(height: 32),
                          
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: colors.errorContainer.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.timer_outlined, color: colors.error),
                                const SizedBox(width: 12),
                                const Text('Minimum route duration: '),
                                Text(
                                  flight.flightDuration.isNotEmpty ? flight.flightDuration : "00:00",
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                if (errorMessage != null) ...[
                  const SizedBox(height: 20),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: colors.errorContainer.withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: colors.error.withValues(alpha: 0.5)),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.error_outline, color: colors.error, size: 20),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            errorMessage!,
                            style: TextStyle(color: colors.error, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
                    const SizedBox(width: 12),
                    CustomButton(
                      label: 'Save Changes',
                      icon: Icons.save_rounded,
                      onPressed: () async {
                        final dParts = depTime.split(':');
                        final aParts = arrTime.split(':');
                        final finalDep = DateTime(selectedDate.year, selectedDate.month, selectedDate.day, int.parse(dParts[0]), int.parse(dParts[1]));
                        var finalArr = DateTime(selectedDate.year, selectedDate.month, selectedDate.day, int.parse(aParts[0]), int.parse(aParts[1]));
                        
                        if (finalArr.isBefore(finalDep)) finalArr = finalArr.add(const Duration(days: 1));

                        try {
                          await _service.updateFlightTimes(
                            flightId: flight.flightId,
                            departsDatetime: finalDep,
                            arrivesDatetime: finalArr,
                          );
                          if (context.mounted) {
                            Navigator.pop(context);
                            _loadFlights();
                          }

                       
                        } catch (e) {
                          setDialogState(() {
                            String rawError = e.toString().replaceAll('Exception: ', '').trim();
                            
                            try {
                              final Map<String, dynamic> errorMap = jsonDecode(rawError);
                              errorMessage = errorMap['detail'] ?? rawError;
                            } catch (_) {
                              errorMessage = rawError;
                            }
                          });
                        }
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    ),
  );
}

  Widget _buildTimeColumn(BuildContext context, String label, String time, Function(String) onSelected) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
          const SizedBox(height: 8),
          Container(
            height: 160,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(12),
            ),
            child: PlanningTimePickerOverlay(
              initialTime: time,
              onTimeSelected: onSelected,
              onClose: () {}, 
            ),
          ),
        ],
      ),
    );
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
            PlanningFlightsFilters(
              statusOptions: _statusOptions,
              aircraftOptions: _aircraftOptions,
              allFlightNumbers: _allFlightNumbers,
              selectedStatus: _selectedStatus,
              selectedAircraft: _selectedAircraft,
              sortBy: _sortBy,
              searchQuery: _searchQuery,
              onStatusChanged: (v) => setState(() {
                _selectedStatus = v;
                _currentPage = 1;
              }),
              onAircraftChanged: (v) => setState(() {
                _selectedAircraft = v;
                _currentPage = 1;
              }),
              onSortChanged: (v) => setState(() {
                _sortBy = v == 'Highest first'
                    ? 'load_desc'
                    : v == 'Lowest first'
                        ? 'load_asc'
                        : 'default';
                _currentPage = 1;
              }),
              onSearchChanged: (v) {
                setState(() {
                  _searchQuery = v;
                  _currentPage = 1;
                  if (v.isNotEmpty && _viewMode != _ViewMode.all) {
                    _viewMode = _ViewMode.all;
                  }
                });
                _loadFlights();
              },
            ),
          ],
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        child: PlanningFlightsTable(
          isLoading: _flightsLoading,
          error: _flightsError,
          flights: _paginatedFlights,
          colWidths: _colWidths,
          colDefs: _colDefs,
          horizontalScroll: _horizontalScroll,
          currentPage: _currentPage,
          totalPages: _totalPages,
          totalCount: _filteredFlights.length,
          itemsPerPage: _itemsPerPage,
          hasActiveFilters: _selectedStatus != null ||
              _selectedAircraft != null ||
              _searchQuery.isNotEmpty,
          onColumnResize: _onColumnResize,
          onRetry: _loadFlights,
          onPreviousPage: () => setState(() => _currentPage--),
          onNextPage: () => setState(() => _currentPage++),
          onStatusTap: _onStatusTap, 
          onEditTap: _onEditTap, 
        ),
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
              Text('Flights',
                  style: Theme.of(context).textTheme.titleLarge),
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
            border:
                Border.all(color: colors.outline.withValues(alpha: 0.2)),
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
                      fontWeight:
                          isActive ? FontWeight.w600 : FontWeight.normal,
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
              padding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 8),
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
                    style: TextStyle(
                        fontSize: 13, color: colors.onSurface),
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
          onPressed: () => context.go('/planning/create-route'),
        ),
      ],
    );
  }

  String _fmtDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}.${d.year}';

  String _shortMonth(int m) => const [
        '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
      ][m];

  String _monthName(int m) => const [
        '', 'January', 'February', 'March', 'April',
        'May', 'June', 'July', 'August',
        'September', 'October', 'November', 'December',
      ][m];


}