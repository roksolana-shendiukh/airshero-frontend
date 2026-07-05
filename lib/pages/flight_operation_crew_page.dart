import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'dart:async';

import '../../models/flight_crew_model.dart';
import '../../models/flight_operation_model.dart';
import '../../services/auth_service.dart';
import '../../services/flight_operation_api_service.dart';
import '../../widgets/responsive_layout.dart';
import '../../widgets/custom/custom_button.dart';
import '../../widgets/custom/custom_input_field.dart';
import '../../widgets/custom/custom_select_field.dart';
import '../widgets/flight_operation/operation_status_bar.dart';
import '../../widgets/flight_operation/crew_validation_badge.dart';

const _activeStatuses = {'Waiting', 'Boarding', 'Baggage Loading'};

class FlightOperationCrewPage extends StatefulWidget {
  const FlightOperationCrewPage({super.key});

  @override
  State<FlightOperationCrewPage> createState() =>
      _FlightOperationCrewPageState();
}

class _FlightOperationCrewPageState extends State<FlightOperationCrewPage> {
  late final FlightOperationApiService _apiService;

  FlightOperationModel? _operation;
  List<FlightCrewModel> _crew = [];
  List<FlightCrewModel> _available = [];
  CrewValidationModel? _validation;

  bool _loadingOp = true;
  bool _loadingCrew = false;
  bool _loadingAvailable = false;

  String? _filterPosition = 'Pilot';
  String? _filterLicense;
  Timer? _debounce;

  static const _positionItems = [
    'Pilot',
    'Co-Pilot',
    'Flight Attendant',
    'Engineer',
  ];
  static const _licenseItems = [
    'Private Pilot License',
    'Commercial Pilot License',
    'Airline Transport Pilot License',
    'Flight Engineer License',
  ];
  static const _licenseLabels = ['PPL', 'CPL', 'ATPL', 'FEL'];
  static const _positionShort = {
    'Pilot': 'Pilot',
    'Co-Pilot': 'Co-Pilot',
    'Flight Attendant': 'FA',
    'Engineer': 'Eng',
  };

  @override
  void initState() {
    super.initState();
    _apiService = FlightOperationApiService(context.read<AuthService>());
    _loadOperation();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  Future<void> _loadOperation() async {
    setState(() => _loadingOp = true);
    final operationId = context.read<AuthService>().currentUser?.operationId;
    if (operationId == null) {
      setState(() => _loadingOp = false);
      return;
    }
    final op = await _apiService.getFlightOperation(operationId);
    if (!mounted) return;
    setState(() {
      _operation = op;
      _loadingOp = false;
    });
    if (op != null) {
      await Future.wait([_loadCrew(), _loadAvailable()]);
    }
  }

  Future<void> _loadCrew() async {
    if (_operation == null) return;
    setState(() => _loadingCrew = true);
    final results = await Future.wait([
      _apiService.getCrew(_operation!.flightOperationId),
      _apiService.validateCrew(_operation!.flightOperationId),
    ]);
    if (!mounted) return;
    setState(() {
      _crew = results[0] as List<FlightCrewModel>;
      _validation = results[1] as CrewValidationModel?;
      _loadingCrew = false;
    });
  }

  Future<void> _loadAvailable({String? search}) async {
    if (_operation == null) return;
    setState(() => _loadingAvailable = true);
    final list = await _apiService.getAvailableCrew(
      _operation!.flightOperationId,
      search: search,
      position: _filterPosition,
    );
    if (!mounted) return;
    setState(() {
      _available = list;
      _loadingAvailable = false;
    });
  }

  Future<void> _assign(FlightCrewModel member) async {
    if (_operation == null) return;
    final result = await _apiService.assignCrew(
      _operation!.flightOperationId,
      member.flightCrewId,
    );
    if (!mounted || !result.success) return;
    setState(() {
      _available.removeWhere((c) => c.flightCrewId == member.flightCrewId);
      _crew.add(member);
    });
    await _refreshValidation();
  }

  Future<void> _remove(FlightCrewModel member) async {
    if (_operation == null) return;
    final ok = await _apiService.removeCrew(
      _operation!.flightOperationId,
      member.flightCrewId,
    );
    if (!ok || !mounted) return;
    setState(() {
      _crew.removeWhere((c) => c.flightCrewId == member.flightCrewId);
      _available.insert(0, member);
    });
    await _refreshValidation();
  }

  Future<void> _refreshValidation() async {
    if (_operation == null) return;
    final v = await _apiService.validateCrew(_operation!.flightOperationId);
    if (mounted) setState(() => _validation = v);
  }

  bool get _canEdit =>
      _operation != null && _activeStatuses.contains(_operation!.statusName);

  Map<String, int> get _currentCounts {
    final counts = <String, int>{};
    for (final c in _crew) {
      if (c.position != null) {
        counts[c.position!] = (counts[c.position!] ?? 0) + 1;
      }
    }
    return counts;
  }

  String? _limitReachedMessage(String? position) {
    if (position == null) return null;
    final current = _currentCounts[position] ?? 0;
    if (position == 'Pilot' && current >= 1) return 'Maximum 1 Pilot allowed';
    if (position == 'Co-Pilot' && current >= 1)
      return 'Maximum 1 Co-Pilot allowed';
    if (position == 'Engineer' && current >= 1)
      return 'Maximum 1 Engineer allowed';
    if (position == 'Flight Attendant') {
      final recommended = (_validation?.required[position] ?? 0);
      final max = recommended + 2;
      if (current >= max) return 'Maximum $max Flight Attendants allowed';
    }
    return null;
  }

  // Фільтрація тільки по ліцензії — позиція фільтрується на бекенді
  List<FlightCrewModel> get _filtered => _available.where((c) {
    if (_filterLicense != null && c.licenseType != _filterLicense) return false;
    return true;
  }).toList();

  Color _positionColor(String? position, ColorScheme colors) {
    switch (position) {
      case 'Pilot':
        return colors.primary;
      case 'Co-Pilot':
        return Colors.blue;
      case 'Flight Attendant':
        return Colors.teal;
      case 'Engineer':
        return Colors.orange;
      default:
        return colors.onSurfaceVariant;
    }
  }

  String _shortLicense(String license) {
    switch (license) {
      case 'Private Pilot License':
        return 'PPL';
      case 'Commercial Pilot License':
        return 'CPL';
      case 'Airline Transport Pilot License':
        return 'ATPL';
      case 'Flight Engineer License':
        return 'FEL';
      default:
        return license;
    }
  }

  @override
  Widget build(BuildContext context) {
    return ResponsiveLayout(
      header: Column(
        mainAxisSize: MainAxisSize.min,
        children: [const OperatorStatusBar(), _buildHeader()],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildHeader() {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border(
          bottom: BorderSide(
            color: colors.outlineVariant.withValues(alpha: 0.4),
          ),
        ),
      ),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Crew Management',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 2),
              Text(
                _operation != null
                    ? '${_operation!.flightNumber ?? '—'} · '
                          '${_operation!.departsCode ?? '—'} → '
                          '${_operation!.arrivesCode ?? '—'}'
                    : 'No active operation',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const Spacer(),
          if (_validation != null) CrewValidationBadge(validation: _validation!),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.refresh_rounded, size: 20),
            onPressed: _loadOperation,
            tooltip: 'Refresh',
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_loadingOp) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_operation == null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.people_outline,
              size: 56,
              color: Theme.of(
                context,
              ).colorScheme.outline.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 12),
            Text(
              'No active operation',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Create a flight operation first',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 20),
            CustomButton(
              label: 'Go to Flight Operations',
              icon: Icons.flight_outlined,
              isIconAfterLabel: false,
              onPressed: () => context.go('/flight-operations'),
            ),
          ],
        ),
      );
    }

    if (!_canEdit) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.lock_outline,
              size: 48,
              color: Theme.of(
                context,
              ).colorScheme.outline.withValues(alpha: 0.4),
            ),
            const SizedBox(height: 12),
            Text(
              'Crew cannot be changed',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Operation status: ${_operation!.statusName}',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      );
    }

    final colors = Theme.of(context).colorScheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          flex: 6,
          child: Column(
            children: [
              _buildAvailableHeader(colors),
              Expanded(child: _buildAvailableList(colors)),
            ],
          ),
        ),

        VerticalDivider(
          width: 1,
          color: colors.outlineVariant.withValues(alpha: 0.4),
        ),

        Expanded(
          flex: 4,
          child: Column(
            children: [
              _buildAssignedHeader(colors),
              Expanded(child: _buildAssignedList(colors)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAvailableHeader(ColorScheme colors) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border(
          bottom: BorderSide(
            color: colors.outlineVariant.withValues(alpha: 0.3),
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: CustomInputField(
              label: 'Search by name',
              value: '',
              icon: Icons.search,
              onChanged: (v) {
                _debounce?.cancel();
                _debounce = Timer(
                  const Duration(milliseconds: 400),
                  () => _loadAvailable(search: v.isNotEmpty ? v : null),
                );
              },
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: CustomSelectField(
              label: 'Position',
              icon: Icons.badge_outlined,
              value: _filterPosition ?? '',
              items: ['', ..._positionItems],
              itemLabels: ['All', ..._positionItems],
              searchable: false,
              onChanged: (v) {
                setState(
                  () => _filterPosition = (v == null || v.isEmpty) ? null : v,
                );
                _loadAvailable();
              },
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: CustomSelectField(
              label: 'License',
              icon: Icons.card_membership_outlined,
              value: _filterLicense ?? '',
              items: ['', ..._licenseItems],
              itemLabels: ['All', ..._licenseLabels],
              searchable: false,
              onChanged: (v) => setState(
                () => _filterLicense = (v == null || v.isEmpty) ? null : v,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvailableList(ColorScheme colors) {
    if (_loadingAvailable) {
      return const Center(child: CircularProgressIndicator());
    }

    final list = _filtered;

    if (list.isEmpty) {
      return Center(
        child: Text(
          'No available crew',
          style: TextStyle(color: colors.onSurfaceVariant),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: list.length,
      separatorBuilder: (_, __) => const SizedBox(height: 6),
      itemBuilder: (_, i) {
        final c = list[i];
        final pColor = _positionColor(c.position, colors);
        final limitMsg = _limitReachedMessage(c.position);
        final isLimited = limitMsg != null;

        return ListTile(
          dense: true,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          tileColor: isLimited
              ? colors.surfaceContainerHighest.withValues(alpha: 0.5)
              : colors.surfaceContainerHighest,
          leading: CircleAvatar(
            radius: 16,
            backgroundColor: pColor.withValues(alpha: isLimited ? 0.07 : 0.15),
            child: Text(
              c.firstName?.isNotEmpty == true ? c.firstName![0] : '?',
              style: TextStyle(
                color: isLimited ? pColor.withValues(alpha: 0.4) : pColor,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
          ),
          title: Text(
            c.fullName,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: isLimited
                  ? colors.onSurface.withValues(alpha: 0.4)
                  : colors.onSurface,
            ),
          ),
          subtitle: Text(
            '${c.position ?? '—'}'
            '${c.experienceYears != null ? ' · ${c.experienceYears} yrs' : ''}'
            '${c.licenseType != null ? ' · ${_shortLicense(c.licenseType!)}' : ''}',
            style: TextStyle(
              fontSize: 11,
              color: isLimited ? pColor.withValues(alpha: 0.4) : pColor,
            ),
          ),
          trailing: isLimited
              ? Tooltip(
                  message: limitMsg,
                  child: Icon(
                    Icons.add_circle_outline,
                    size: 20,
                    color: colors.onSurfaceVariant.withValues(alpha: 0.25),
                  ),
                )
              : IconButton(
                  padding: EdgeInsets.zero,
                  icon: Icon(
                    Icons.add_circle_outline,
                    color: colors.primary,
                    size: 20,
                  ),
                  onPressed: () => _assign(c),
                ),
        );
      },
    );
  }

  Widget _buildAssignedHeader(ColorScheme colors) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: colors.outlineVariant.withValues(alpha: 0.3),
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.people_outline, size: 16, color: colors.primary),
              const SizedBox(width: 8),
              const Text(
                'ASSIGNED',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.0,
                ),
              ),
              const Spacer(),
              Text(
                '${_crew.length} member${_crew.length != 1 ? 's' : ''}',
                style: TextStyle(fontSize: 12, color: colors.onSurfaceVariant),
              ),
            ],
          ),
          if (_validation != null && _validation!.required.isNotEmpty) ...[
            const SizedBox(height: 10),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _validation!.required.entries.map((e) {
                  final cur = _currentCounts[e.key] ?? 0;
                  final isDone = cur >= e.value;
                  final pColor = _positionColor(e.key, colors);
                  final label = _positionShort[e.key] ?? e.key;
                  return Padding(
                    padding: const EdgeInsets.only(right: 5),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: isDone
                            ? Colors.green.withValues(alpha: 0.1)
                            : colors.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isDone
                              ? Colors.green.withValues(alpha: 0.4)
                              : colors.outlineVariant,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isDone ? Colors.green : Colors.transparent,
                              border: isDone
                                  ? null
                                  : Border.all(color: pColor, width: 1.5),
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '$label $cur/${e.value}',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: isDone
                                  ? Colors.green.shade700
                                  : colors.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAssignedList(ColorScheme colors) {
    if (_loadingCrew) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_crew.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.people_outline,
              size: 40,
              color: colors.outline.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 8),
            Text(
              'No crew assigned yet',
              style: TextStyle(fontSize: 13, color: colors.onSurfaceVariant),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _crew.length,
      separatorBuilder: (_, __) => const SizedBox(height: 6),
      itemBuilder: (_, i) {
        final c = _crew[i];
        final pColor = _positionColor(c.position, colors);
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: colors.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: pColor.withValues(alpha: 0.2)),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: pColor.withValues(alpha: 0.15),
                child: Text(
                  c.firstName?.isNotEmpty == true ? c.firstName![0] : '?',
                  style: TextStyle(
                    color: pColor,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      c.fullName,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      c.position ?? '—',
                      style: TextStyle(
                        fontSize: 11,
                        color: pColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: Icon(
                  Icons.remove_circle_outline,
                  size: 16,
                  color: colors.error,
                ),
                onPressed: () => _remove(c),
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
        );
      },
    );
  }
}
