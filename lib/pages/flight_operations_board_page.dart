import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import '../../models/flight_without_operation_model.dart';
import '../../models/flight_operation_model.dart';
import '../../models/board_row.dart';
import '../../services/auth_service.dart';
import '../../services/flight_operation_api_service.dart';
import '../../widgets/responsive_layout.dart';
import '../widgets/flight_operation/operation_status_bar.dart';
import '../widgets/flight_operation/board_widgets.dart';
import '../../widgets/flight_operation/gate_picker_dialog.dart';
import '../../constants/board_constants.dart';
import '../../widgets/custom/custom_select_field.dart';
import '../../widgets/custom/custom_input_field.dart'; 
import '../widgets/flight_operation/flight_operations_table.dart';

class FlightOperationsBoardPage extends StatefulWidget {
  const FlightOperationsBoardPage({super.key});

  @override
  State<FlightOperationsBoardPage> createState() =>
      _FlightOperationsBoardPageState();
}

class _FlightOperationsBoardPageState extends State<FlightOperationsBoardPage> {
  late final FlightOperationApiService _apiService;

  List<BoardRow> _rows = [];
  bool _isLoading = true;
  String? _error;

  String _searchQuery = ''; 
  String? _filterStatus;
  String? _filterAircraft;
  int _currentPage = 1;

  @override
  void initState() {
    super.initState();
    _apiService = FlightOperationApiService(context.read<AuthService>());
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final results = await Future.wait([
        _apiService.getFlightsWithoutOperation(),
        _apiService.getFlightOperations(),
      ]);

      final flights = results[0] as List<FlightWithoutOperationModel>;
      final operations = results[1] as List<FlightOperationModel>;

      final activeOps = operations
          .where((o) => activeStatuses.contains(o.statusName))
          .toList();

      final rows = <BoardRow>[
        ...activeOps.map(BoardRow.fromOperation),
        ...flights.map(BoardRow.fromFlight),
      ]..sort((a, b) => a.departsDatetime.compareTo(b.departsDatetime));

      if (mounted) {
        setState(() {
          _rows = rows;
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

  List<BoardRow> get _filtered => _rows.where((r) {
        if (_searchQuery.isNotEmpty &&
            !r.flightNumber.toLowerCase().contains(_searchQuery.toLowerCase())) {
          return false;
        }
        if (_filterStatus != null &&
            _filterStatus != 'All' &&
            r.statusName != _filterStatus) {
          return false;
        }
        if (_filterAircraft != null &&
            _filterAircraft != 'All' &&
            (r.aircraftModel ?? '—') != _filterAircraft) {
          return false;
        }
        return true;
      }).toList();

  int get _totalPages =>
      (_filtered.length / itemsPerPage).ceil().clamp(1, 9999);

  List<BoardRow> get _paginated {
    final start = (_currentPage - 1) * itemsPerPage;
    final end = (start + itemsPerPage).clamp(0, _filtered.length);
    return _filtered.isEmpty ? [] : _filtered.sublist(start, end);
  }

  List<String> get _statusOptions => [
        'All',
        ..._rows.map((r) => r.statusName).toSet().toList()..sort(),
      ];

  List<String> get _aircraftOptions => [
        'All',
        ..._rows
            .map((r) => r.aircraftModel ?? '—')
            .where((a) => a != '—')
            .toSet()
            .toList()
          ..sort(),
      ];

  void _showGateChangeDialog(BoardRow row) async {
    final operationId = row.operation?.flightOperationId;
    if (operationId == null) return;

    final bool? updated = await showDialog<bool>(
      context: context,
      builder: (context) => GatePickerDialog(
        operationId: operationId,
        api: _apiService,
        operation: row.operation!,
      ),
    );

    if (updated == true) {
      if (mounted) {
        _load();
      }
    }
  }

  Widget _buildPageHeader() {
    final colors = Theme.of(context).colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Flight Operations',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 3),
            Row(
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                    color: Color(0xFF4ADE80),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  '${_rows.where((r) => activeStatuses.contains(r.statusName)).length} active'
                  '  ·  '
                  '${_rows.where((r) => r.statusName == 'Scheduled').length} scheduled',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ],
        ),
        const Spacer(),
        IconBtn(
          icon: Icons.refresh_rounded,
          tooltip: 'Refresh',
          onTap: _load,
          colors: colors,
        ),
      ],
    );
  }

  Widget _buildFilters() {
    final colors = Theme.of(context).colorScheme;
    return Row(
      children: [
        SizedBox(
          width: 320,
          child: CustomInputField(
            label: 'Search flight',
            value: _searchQuery,
            icon: Icons.search_rounded,
            onChanged: (v) => setState(() {
              _searchQuery = v;
              _currentPage = 1;
            }),
          ),
        ),
        const SizedBox(width: 12),
        SizedBox(
          width: 180,
          child: CustomSelectField(
            label: 'Status',
            value: _filterStatus ?? 'Scheduled',
            icon: Icons.circle_outlined,
            items: _statusOptions,
            onChanged: (v) => setState(() {
              _filterStatus = v == 'All' ? null : v;
              _currentPage = 1;
            }),
          ),
        ),
        const SizedBox(width: 10),
        SizedBox(
          width: 180,
          child: CustomSelectField(
            label: 'Aircraft',
            value: _filterAircraft ?? 'All',
            icon: Icons.airplanemode_active_rounded,
            items: _aircraftOptions,
            onChanged: (v) => setState(() {
              _filterAircraft = v == 'All' ? null : v;
              _currentPage = 1;
            }),
          ),
        ),
        const Spacer(),
        if (_filterStatus != null) ...[
          ActiveChip(
            label: _filterStatus!,
            onClear: () => setState(() {
              _filterStatus = null;
              _currentPage = 1;
            }),
            colors: colors,
          ),
          const SizedBox(width: 6),
        ],
        if (_filterAircraft != null)
          ActiveChip(
            label: _filterAircraft!,
            onClear: () => setState(() {
              _filterAircraft = null;
              _currentPage = 1;
            }),
            colors: colors,
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return ResponsiveLayout(
      header: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const OperatorStatusBar(),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildPageHeader(),
                const SizedBox(height: 16),
                if (!_isLoading && _error == null) _buildFilters(),
              ],
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 24), // Збільшено відступ зверху
        child: FlightOperationsTable(
          rows: _paginated,
          isLoading: _isLoading,
          error: _error,
          currentPage: _currentPage,
          totalPages: _totalPages,
          totalItems: _filtered.length,
          itemsPerPage: itemsPerPage,
          hasFiltersApplied: _filterStatus != null || _filterAircraft != null || _searchQuery.isNotEmpty,
          onRetry: _load,
          onClearFilters: () {
            setState(() {
              _filterStatus = null;
              _filterAircraft = null;
              _searchQuery = '';
              _currentPage = 1;
            });
          },
          onPageChanged: (newPage) {
            setState(() => _currentPage = newPage);
          },
          onStartOperation: (row) {
            if (row.flight != null) {
              context.go('/flight-operations/create', extra: row.flight!);
            }
          },
          onViewOperation: (row) {
            if (row.operation != null) {
              context.go('/flight-operations/active');
            }
          },
          onChangeGate: (row) => _showGateChangeDialog(row),
        ),
      ),
    );
  }
}