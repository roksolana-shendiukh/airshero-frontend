import 'dart:async';
import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../services/crew_api_service.dart';
import '../../models/flight_crew_model.dart';
import '../../widgets/responsive_layout.dart';
import '../../widgets/custom/custom_input_field.dart';
import '../../widgets/custom/custom_select_field.dart';
import '../../widgets/custom/custom_button.dart';
import '../../widgets/table_column_def.dart';
import '../../widgets/generic_table_header.dart';
import '../../widgets/generic_table_row.dart';
import '../../widgets/crew/crew_table_columns.dart';
import '../../widgets/admin/user_table_pagination.dart';
import '../../widgets/crew/crew_form_dialog.dart';

class CrewPage extends StatefulWidget {
  final AuthService authService;
  const CrewPage({super.key, required this.authService});

  @override
  State<CrewPage> createState() => _CrewPageState();
}

class _CrewPageState extends State<CrewPage> {
  late final CrewApiService _api;

  List<FlightCrewModel>        _crew         = [];
  List<Map<String, dynamic>>   _positions    = [];
  List<Map<String, dynamic>>   _licenseTypes = [];

  bool    _loading        = true;
  String? _error;
  String  _search         = '';
  String? _filterPosition = 'Pilot'; 
  String? _filterLicense;
  Timer?  _debounce;
  final Map<String, double> _baseWidths = {};

  double _minExp = 0;
  double _maxExp = 30;
  RangeValues _expRange = const RangeValues(0, 30);

  int _currentPage    = 1;
  static const _perPage = 15;

  late final List<TableColumnDef<FlightCrewModel>> _columns;
  final Map<String, double> _columnWidths   = {};
  final ScrollController    _hScroll        = ScrollController();

  static const _positionItems = ['Pilot', 'Co-Pilot', 'Flight Attendant', 'Engineer'];
  static const _licenseItems  = [
    'Private Pilot License', 'Commercial Pilot License',
    'Airline Transport Pilot License', 'Flight Engineer License',
  ];
  static const _licenseLabels = ['PPL', 'CPL', 'ATPL', 'FEL'];

  @override
  void initState() {
    super.initState();
    _api = CrewApiService(widget.authService);
    _columns = CrewTableColumns.buildColumns(
      onEdit:   _showEditDialog,
      onDelete: _confirmDelete,
    );
    for (final col in _columns) {
      _columnWidths[col.key] = col.initialWidth;
      _baseWidths[col.key]   = col.initialWidth;
    }
    _loadData();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _hScroll.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() { _loading = true; _error = null; });
    try {
      final results = await Future.wait([
        _api.getAll(
          search:   _search.isNotEmpty ? _search : null,
          position: _filterPosition,
        ),
        _api.getPositions(),
        _api.getLicenseTypes(),
      ]);
      if (!mounted) return;
      setState(() {
        _crew         = results[0] as List<FlightCrewModel>;
        _positions    = results[1] as List<Map<String, dynamic>>;
        _licenseTypes = results[2] as List<Map<String, dynamic>>;
        _currentPage  = 1;
        _loading      = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() { _error = e.toString(); _loading = false; });
    }
  }

  List<FlightCrewModel> get _filtered {
    return _crew.where((c) {
      if (_filterLicense != null && c.licenseType != _filterLicense) return false;
      final exp = c.experienceYears ?? 0;
      if (exp < _expRange.start || exp > _expRange.end) return false;
      return true;
    }).toList();
  }

  int get _totalPages => (_filtered.length / _perPage).ceil().clamp(1, 9999);

  List<FlightCrewModel> get _paginated {
    final list  = _filtered;
    final total = list.length;
    if (total == 0) return [];
    final start = ((_currentPage - 1) * _perPage).clamp(0, total);
    final end   = (start + _perPage).clamp(0, total);
    return list.sublist(start, end);
  }

  void _onColumnResize(String key, double delta) {
    setState(() {
      final current = _columnWidths[key] ?? 100;
      _columnWidths[key] = (current + delta).clamp(80.0, 400.0);
    });
  }

  Future<void> _confirmDelete(FlightCrewModel crew) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title:   const Text('Delete crew member?'),
        content: Text('${crew.fullName} will be permanently removed.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style:     FilledButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.error),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    final success = await _api.delete(crew.flightCrewId);
    if (!mounted) return;
    if (success) {
      _loadData();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to delete crew member')),
      );
    }
  }

  void _showCreateDialog()                   => _showFormDialog(null);
  
  void _showEditDialog(FlightCrewModel crew)  => _showFormDialog(crew);

  Future<void> _showFormDialog(FlightCrewModel? crew) async {
    await showDialog(
      context: context,
      builder: (_) => CrewFormDialog(
        api:          _api,
        crew:         crew,
        positions:    _positions,
        licenseTypes: _licenseTypes,
      ),
    );
    _loadData();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return ResponsiveLayout(
      header: _buildHeader(colors),
      body:   _buildBody(colors),
    );
  }

  Widget _buildHeader(ColorScheme colors) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
          child: Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Crew Management',
                      style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 2),
                  Text('${_filtered.length} members',
                      style: Theme.of(context).textTheme.bodyMedium
                          ?.copyWith(color: colors.onSurfaceVariant)),
                ],
              ),
              const Spacer(),
              CustomButton(
                label:            'Add Crew Member',
                icon:             Icons.person_add_outlined,
                isIconAfterLabel: false,
                onPressed:        _showCreateDialog,
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 12),
          decoration: BoxDecoration(
            color:  colors.surface,
            border: Border(
              bottom: BorderSide(
                  color: colors.outlineVariant.withValues(alpha: 0.3)),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                flex: 2,
                child: CustomInputField(
                  label:     'Search by name',
                  value:     _search,
                  icon:      Icons.search,
                  onChanged: (v) {
                    _debounce?.cancel();
                    _debounce = Timer(const Duration(milliseconds: 400), () {
                      setState(() => _search = v);
                      _loadData();
                    });
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: CustomSelectField(
                  label:      'Position',
                  icon:       Icons.badge_outlined,
                  value:      _filterPosition ?? '',
                  items:      ['', ..._positionItems],
                  itemLabels: ['All', ..._positionItems],
                  searchable: false,
                  onChanged:  (v) {
                    setState(() =>
                        _filterPosition = (v == null || v.isEmpty) ? null : v);
                    _loadData();
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: CustomSelectField(
                  label:      'License',
                  icon:       Icons.card_membership_outlined,
                  value:      _filterLicense ?? '',
                  items:      ['', ..._licenseItems],
                  itemLabels: ['All', ..._licenseLabels],
                  searchable: false,
                  onChanged:  (v) => setState(() {
                    _filterLicense = (v == null || v.isEmpty) ? null : v;
                    _currentPage   = 1;
                  }),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.work_outline, size: 13,
                            color: colors.onSurfaceVariant),
                        const SizedBox(width: 4),
                        Text(
                          'Experience: ${_expRange.start.toInt()}–${_expRange.end.toInt()} yrs',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: colors.onSurfaceVariant),
                        ),
                        const Spacer(),
                        if (_expRange.start > _minExp || _expRange.end < _maxExp)
                          GestureDetector(
                            onTap: () => setState(() {
                              _expRange    = RangeValues(_minExp, _maxExp);
                              _currentPage = 1;
                            }),
                            child: Text('Reset',
                                style: TextStyle(
                                    fontSize: 11,
                                    color:    colors.primary)),
                          ),
                      ],
                    ),
                    RangeSlider(
                      values:    _expRange,
                      min:       _minExp,
                      max:       _maxExp,
                      divisions: _maxExp > 0 ? _maxExp.toInt() : 1,
                      labels: RangeLabels(
                        '${_expRange.start.toInt()}',
                        '${_expRange.end.toInt()}',
                      ),
                      onChanged: (v) => setState(() {
                        _expRange    = v;
                        _currentPage = 1;
                      }),
                    ),
                  ],
                ),
              ),
            ],
          ),
        
        
        ),
      ],
    );
  }

  Widget _buildBody(ColorScheme colors) {
    if (_loading) return const Center(child: CircularProgressIndicator());

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 48, color: colors.error),
            const SizedBox(height: 12),
            Text(_error!, style: TextStyle(color: colors.error)),
            const SizedBox(height: 16),
            CustomButton(label: 'Retry', onPressed: _loadData),
          ],
        ),
      );
    }

    final list = _paginated;

    if (_filtered.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.people_outline, size: 56,
                color: colors.outline.withValues(alpha: 0.3)),
            const SizedBox(height: 12),
            Text('No crew members found',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            CustomButton(
              label:            'Add Crew Member',
              icon:             Icons.person_add_outlined,
              isIconAfterLabel: false,
              onPressed:        _showCreateDialog,
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Container(
        decoration: BoxDecoration(
          color:        colors.surface,
          borderRadius: BorderRadius.circular(6),
          border:       Border.all(color: colors.outline.withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                controller:      _hScroll,
                scrollDirection: Axis.horizontal,
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    // таблиця розтягується на всю доступну ширину
                    final minW = _columnWidths.values.fold(0.0, (s, w) => s + w);
                    final tableW = minW.clamp(minW, double.infinity);
                    return SizedBox(
                      width: tableW,
                      child: Column(
                        children: [
                          GenericTableHeader<FlightCrewModel>(
                            selectAll:         false,
                            onToggleSelectAll: () {},
                            columnWidths:      _columnWidths,
                            onColumnResize:    _onColumnResize,
                            columns:           _columns,
                            showCheckbox:      false,
                          ),
                          Expanded(
                            child: ListView.builder(
                              itemCount: list.length,
                              itemBuilder: (_, i) =>
                                  GenericTableRow<FlightCrewModel>(
                                item:         list[i],
                                columns:      _columns,
                                columnWidths: _columnWidths,
                                showCheckbox: false,
                                isLast:       i == list.length - 1,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
            if (_filtered.length > _perPage)
              UserTablePagination(
                currentPage:  _currentPage,
                totalPages:   _totalPages,
                totalUsers:   _filtered.length,
                itemsPerPage: _perPage,
                onPrevious:   () => setState(() => _currentPage--),
                onNext:       () => setState(() => _currentPage++),
              ),
          ],
        ),
      ),
    );
  }
}








