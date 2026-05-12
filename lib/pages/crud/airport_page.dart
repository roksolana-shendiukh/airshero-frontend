import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../widgets/responsive_layout.dart';
import '../../services/auth_service.dart';
import '../../services/object_crud_service.dart';
import '../../widgets/generic_table_header.dart';
import '../../widgets/generic_table_row.dart';
import '../../widgets/custom/custom_input_field.dart';
import '../../widgets/crud/airport/airport_column.dart';
import '../../widgets/crud/airport/airport_form_dialog.dart';
import '../../widgets/crud/airport/airport_detail_panel.dart';
import '../../widgets/custom/custom_select_field.dart';
import '../../widgets/custom/custom_button.dart';
class AirportsPage extends StatefulWidget {
  const AirportsPage({super.key});

  @override
  State<AirportsPage> createState() => _AirportsPageState();
}

class _AirportsPageState extends State<AirportsPage> {
  List<Map<String, dynamic>> _airports = [];
  List<Map<String, dynamic>> _countries = [];
  List<Map<String, dynamic>> _cities = [];
  List<String> _terminalTypes = [];

  bool _isLoading = true;
  String _searchQuery = '';
  int? _filterCountryId;
  int? _filterCityId;
  String? _filterTerminalType;

  Map<String, dynamic>? _selectedAirport;
  final Map<String, double> _columnWidths = {};
  int _currentPage = 0;
  int _rowsPerPage = 10;
  final List<int> _availableRowsPerPage = [10, 25, 50];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final api = ObjectCrudService(context.read<AuthService>());
      final results = await Future.wait([
        api.getAirports(),
        api.getCountries(),
        api.getCities(),
        api.getTerminalTypes(),
      ]);

      setState(() {
        _airports = results[0] as List<Map<String, dynamic>>;
        _countries = results[1] as List<Map<String, dynamic>>;
        _cities = results[2] as List<Map<String, dynamic>>;
        _terminalTypes = (results[3] as List<Map<String, dynamic>>)
            .map((e) => e['terminalTypeName'].toString())
            .toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  List<Map<String, dynamic>> get _filteredAirports {
    return _airports.where((a) {
      final name = (a['airportName'] ?? a['airport_name'] ?? '').toString().toLowerCase();
      final code = (a['airportCode'] ?? a['airport_code'] ?? '').toString().toLowerCase();
      final query = _searchQuery.toLowerCase();
      final matchesSearch = name.contains(query) || code.contains(query);

      final airportCountryId = a['countryId'] ?? a['country_id'];
      final matchesCountry = _filterCountryId == null || 
          airportCountryId.toString() == _filterCountryId.toString();

      final airportCityId = a['cityId'] ?? a['city_id'];
      final matchesCity = _filterCityId == null || 
          airportCityId.toString() == _filterCityId.toString();
      
      final airportTerms = (a['terminalTypes'] ?? a['terminal_types'] ?? []) as List;
      final matchesTermType = _filterTerminalType == null || 
          airportTerms.contains(_filterTerminalType);

      return matchesSearch && matchesCountry && matchesCity && matchesTermType;
    }).toList();
  }

  List<Map<String, dynamic>> get _paginatedAirports {
    final filtered = _filteredAirports;
    final start = _currentPage * _rowsPerPage;
    if (start >= filtered.length) return [];
    final end = (start + _rowsPerPage).clamp(0, filtered.length);
    return filtered.sublist(start, end);
  }

  void _onColumnResize(String key, double delta) {
    setState(() {
      final current = _columnWidths[key] ?? 150.0;
      _columnWidths[key] = (current + delta).clamp(60.0, 500.0);
    });
  }

  void _initColumnWidths(List columns) {
    if (_columnWidths.isEmpty) {
      for (var col in columns) {
        _columnWidths[col.key] = col.initialWidth;
      }
    }
  }

  Future<void> _openCreateDialog() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (_) => const AirportFormDialog(),
    );
    if (result == true) _loadData();
  }

  Future<void> _openEditDialog(Map<String, dynamic> airport) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (_) => AirportFormDialog(airport: airport),
    );
    if (result == true) _loadData();
  }

  Future<void> _handleDelete(Map<String, dynamic> airport) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirm Delete'),
        content: Text('Delete ${airport['airport_name']}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete')),
        ],
      ),
    );
    if (confirmed == true) {
      final api = ObjectCrudService(context.read<AuthService>());
      await api.deleteAirport(airport['airport_id']);
      _loadData();
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final columns = buildAirportColumns(context: context, onEdit: _openEditDialog, onDelete: _handleDelete);
    _initColumnWidths(columns);

    final filtered = _filteredAirports;
    final paginated = _paginatedAirports;
    final totalItems = filtered.length;
    final totalPages = (totalItems / _rowsPerPage).ceil();

    return ResponsiveLayout(
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Airports',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      '$totalItems locations',
                      style: TextStyle(color: colors.onSurfaceVariant, fontSize: 13),
                    ),
                  ],
                ),
                const Spacer(),
                IconButton(
                  onPressed: _loadData,
                  icon: const Icon(Icons.refresh),
                  tooltip: 'Refresh',
                ),
                const SizedBox(width: 12),
                
                CustomButton(
                  label: 'Add Airport',
                  icon: Icons.add,
                  isIconAfterLabel: false,
                  onPressed: _openCreateDialog,
                  verticalPadding: 12, 
                  backgroundColor: colors.primary,
                  foregroundColor: colors.onPrimary,
                ),
              ],
            ),
          ),
                    
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: CustomInputField(
                    label: 'Search name or code',
                    icon: Icons.search,
                    value: _searchQuery,
                    onChanged: (v) => setState(() { _searchQuery = v; _currentPage = 0; }),
                  ),
                ),
                const SizedBox(width: 12),

                Expanded(
                  flex: 2,
                  child: CustomSelectField(
                    label: 'Country',
                    icon: Icons.public,
                    value: _countries.firstWhere(
                      (c) => (c['countryId'] ?? c['country_id']) == _filterCountryId, 
                      orElse: () => {'countryName': '', 'country_name': ''}
                    )['countryName'] ?? '',
                    items: ['', ..._countries.map((c) => (c['countryName'] ?? c['country_name']).toString())],
                    itemLabels: ['All Countries', ..._countries.map((c) => (c['countryName'] ?? c['country_name']).toString())], 
                    onChanged: (val) {
                      setState(() {
                        if (val == null || val.isEmpty) {
                          _filterCountryId = null;
                        } else {
                          final found = _countries.firstWhere((c) => (c['countryName'] ?? c['country_name']) == val);
                          _filterCountryId = found['countryId'] ?? found['country_id'];
                        }
                        _filterCityId = null;
                        _currentPage = 0;
                      });
                    },
                  ),
                ),
                const SizedBox(width: 12),

                Expanded(
                  flex: 2,
                  child: CustomSelectField(
                    label: 'City',
                    icon: Icons.location_city,
                    value: _cities.firstWhere(
                      (c) => (c['cityId'] ?? c['city_id']) == _filterCityId, 
                      orElse: () => {'cityName': '', 'city_name': ''}
                    )['cityName'] ?? '',
                    items: [
                      '', 
                      ..._cities.where((c) {
                        final cId = c['countryId'] ?? c['country_id'];
                        return _filterCountryId == null || cId == _filterCountryId;
                      }).map((c) => (c['cityName'] ?? c['city_name']).toString())
                    ],
                    itemLabels: [
                      'All Cities', 
                      ..._cities.where((c) {
                        final cId = c['countryId'] ?? c['country_id'];
                        return _filterCountryId == null || cId == _filterCountryId;
                      }).map((c) => (c['cityName'] ?? c['city_name']).toString())
                    ],
                    onChanged: (val) {
                      setState(() {
                        if (val == null || val.isEmpty) {
                          _filterCityId = null;
                        } else {
                          final found = _cities.firstWhere((c) => (c['cityName'] ?? c['city_name']) == val);
                          _filterCityId = found['cityId'] ?? found['city_id'];
                        }
                        _currentPage = 0;
                      });
                    },
                  ),
                ),
                
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: CustomSelectField(
                    label: 'Terminal Type',
                    icon: Icons.category,
                    value: _filterTerminalType ?? '',
                    items: ['', ..._terminalTypes],
                    itemLabels: ['All Types', ..._terminalTypes],
                    onChanged: (val) => setState(() {
                      _filterTerminalType = (val == null || val.isEmpty) ? null : val;
                      _currentPage = 0;
                    }),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: colors.surface,
                        border: Border.all(color: colors.outline.withOpacity(0.2)),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: _isLoading
                          ? const Center(child: CircularProgressIndicator())
                          : Column(
                              children: [
                                GenericTableHeader(
                                  columns: columns,
                                  columnWidths: _columnWidths,
                                  onColumnResize: _onColumnResize,
                                  selectAll: false,
                                  onToggleSelectAll: () {},
                                  showCheckbox: false,
                                ),
                                Expanded(
                                  child: paginated.isEmpty
                                      ? Center(child: Text('No results', style: TextStyle(color: colors.onSurfaceVariant)))
                                      : ListView.builder(
                                          itemCount: paginated.length,
                                          itemBuilder: (_, i) => GestureDetector(
                                            onTap: () => setState(() => _selectedAirport = paginated[i]),
                                            child: GenericTableRow(
                                              item: paginated[i],
                                              columns: columns,
                                              columnWidths: _columnWidths,
                                              isSelected: _selectedAirport?['airportId'] == paginated[i]['airportId'],
                                              showCheckbox: false,
                                              isLast: i == paginated.length - 1,
                                            ),
                                          ),
                                        ),
                                ),
                                _buildPaginationBar(colors, totalItems, totalPages),
                              ],
                            ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  SizedBox(
                    width: 380,
                    child: _selectedAirport != null
                        ? AirportDetailPanel(
                            airport: _selectedAirport!,
                            onEdit: () => _openEditDialog(_selectedAirport!),
                            onClose: () => setState(() => _selectedAirport = null),
                          )
                        : _buildEmptyDetail(colors),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaginationBar(ColorScheme colors, int total, int pages) {
    final start = total == 0 ? 0 : (_currentPage * _rowsPerPage) + 1;
    final end = ((_currentPage + 1) * _rowsPerPage).clamp(0, total);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(border: Border(top: BorderSide(color: colors.outline.withOpacity(0.2)))),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Text('Rows per page:', style: TextStyle(fontSize: 12, color: colors.onSurfaceVariant)),
          const SizedBox(width: 8),
          DropdownButton<int>(
            value: _rowsPerPage,
            underline: const SizedBox(),
            onChanged: (v) => setState(() { _rowsPerPage = v!; _currentPage = 0; }),
            items: _availableRowsPerPage.map((v) => DropdownMenuItem(value: v, child: Text('$v', style: const TextStyle(fontSize: 12)))).toList(),
          ),
          const SizedBox(width: 24),
          Text('$start-$end of $total', style: TextStyle(fontSize: 12, color: colors.onSurfaceVariant)),
          IconButton(icon: const Icon(Icons.chevron_left, size: 20), onPressed: _currentPage > 0 ? () => setState(() => _currentPage--) : null),
          IconButton(icon: const Icon(Icons.chevron_right, size: 20), onPressed: (_currentPage + 1) < pages ? () => setState(() => _currentPage++) : null),
        ],
      ),
    );
  }

  Widget _buildEmptyDetail(ColorScheme colors) {
    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border.all(color: colors.outline.withOpacity(0.2)),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.flight_land, size: 48, color: colors.outline.withOpacity(0.5)),
            const SizedBox(height: 16),
            Text('Select an airport to view\nTerminals and Gates', textAlign: TextAlign.center, style: TextStyle(color: colors.onSurfaceVariant)),
          ],
        ),
      ),
    );
  }
}