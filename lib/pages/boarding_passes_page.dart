import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../widgets/responsive_layout.dart';
import '../services/auth_service.dart';
import '../services/checkin_api_service.dart';
import '../widgets/checkin/boarding_passes_table.dart';
import '../widgets/booking/booking_search_bar.dart';
import '../widgets/custom/custom_select_field.dart';

class BoardingPassesPage extends StatefulWidget {
  const BoardingPassesPage({super.key});

  @override
  State<BoardingPassesPage> createState() => _BoardingPassesPageState();
}

class _BoardingPassesPageState extends State<BoardingPassesPage> {
  List<Map<String, dynamic>> _passes = [];
  List<String> _cities = [];
  List<String> _classes = [];
  bool _isLoading = true;
  String? _error;

  String _searchQuery = '';
  String? _selectedCity;
  String? _selectedClass;
  String _selectedDateFilter = 'today';

  final Map<String, String> _dateFilterMap = {
    'Today': 'today',
    'This week': 'this_week',
    'This month': 'this_month',
    'All time': 'all_time',
  };

  final Map<String, String> _dateFilterReverseMap = {
    'today': 'Today',
    'this_week': 'This week',
    'this_month': 'This month',
    'all_time': 'All time',
  };

  @override
  void initState() {
    super.initState();
    _loadFiltersAndPasses();
  }

  Future<void> _loadFiltersAndPasses() async {
    final authService = context.read<AuthService>();
    final api = CheckInApiService(authService);
    await Future.wait([
      _loadCitiesAndClasses(api),
      _loadPasses(api),
    ]);
  }

  Future<void> _loadCitiesAndClasses(CheckInApiService api) async {
    try {
      final results = await Future.wait([
        api.getBoardingPassCities(),
        api.getBoardingPassClasses(),
      ]);
      if (mounted) {
        setState(() {
          _cities  = results[0];
          _classes = results[1];
        });
      }
    } catch (e) {
      debugPrint('Error loading filters: $e');
    }
  }

  Future<void> _loadPasses([CheckInApiService? apiOverride]) async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final authService = context.read<AuthService>();
      final api = apiOverride ?? CheckInApiService(authService);
      final passes = await api.getBoardingPassesHistory(
        search: _searchQuery.isNotEmpty ? _searchQuery : null,
        routeCity: _selectedCity,
        className: _selectedClass,
        dateFilter: _selectedDateFilter,
      );
      if (mounted) {
        setState(() {
          _passes = passes;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final authService = context.read<AuthService>();

    return ResponsiveLayout(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
            child: Row(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Boarding Passes',
                      style: Theme.of(context)
                          .textTheme
                          .headlineSmall
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Issued boarding passes history',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: colors.onSurfaceVariant,
                          ),
                    ),
                  ],
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => _loadPasses(),
                  icon: const Icon(Icons.refresh),
                  tooltip: 'Refresh',
                ),
              ],
            ),
          ),

          // Filters row
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
            child: Row(
              children: [
                // Search
                Expanded(
                  child: BookingSearchBar(
                    value: _searchQuery,
                    onChanged: (q) => setState(() => _searchQuery = q),
                  ),
                ),
                const SizedBox(width: 12),

                // City filter
                SizedBox(
                  width: 180,
                  child: CustomSelectField(
                    label: 'City',
                    value: _selectedCity ?? 'All cities',
                    icon: Icons.location_city_outlined,
                    items: ['All cities', ..._cities],
                    onChanged: (val) {
                      setState(() =>
                          _selectedCity = val == 'All cities' ? null : val);
                      _loadPasses();
                    },
                  ),
                ),
                const SizedBox(width: 12),

                // Class filter
                SizedBox(
                  width: 180,
                  child: CustomSelectField(
                    label: 'Class',
                    value: _selectedClass ?? 'All classes',
                    icon: Icons.airline_seat_recline_extra_outlined,
                    items: ['All classes', ..._classes],
                    onChanged: (val) {
                      setState(() =>
                          _selectedClass = val == 'All classes' ? null : val);
                      _loadPasses();
                    },
                  ),
                ),
                const SizedBox(width: 12),

                // Date filter
                SizedBox(
                  width: 160,
                  child: CustomSelectField(
                    label: 'Period',
                    value: _dateFilterReverseMap[_selectedDateFilter] ?? 'Today',
                    icon: Icons.calendar_today_outlined,
                    items: _dateFilterMap.keys.toList(),
                    onChanged: (val) {
                      if (val == null) return;
                      setState(() => _selectedDateFilter =
                          _dateFilterMap[val] ?? 'today');
                      _loadPasses();
                    },
                  ),
                ),
              ],
            ),
          ),

          // Content
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _error != null
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.error_outline,
                                  size: 48, color: colors.error),
                              const SizedBox(height: 16),
                              Text(_error!),
                              const SizedBox(height: 16),
                              FilledButton(
                                onPressed: () => _loadPasses(),
                                child: const Text('Retry'),
                              ),
                            ],
                          ),
                        )
                      : _passes.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.airplane_ticket_outlined,
                                      size: 64,
                                      color: colors.onSurfaceVariant),
                                  const SizedBox(height: 16),
                                  Text(
                                    'No boarding passes found',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium
                                        ?.copyWith(
                                            color: colors.onSurfaceVariant),
                                  ),
                                ],
                              ),
                            )
                          : BoardingPassesTable(
                              passes: _passes,
                              authService: authService,
                            ),
            ),
          ),

          if (!_isLoading && _error == null)
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
              child: Text(
                '${_passes.length} boarding pass${_passes.length != 1 ? 'es' : ''} found',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
              ),
            ),
        ],
      ),
    );
  }
}