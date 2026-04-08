import 'dart:async';
import 'package:flutter/material.dart';
import '../../models/flight_crew_model.dart';
import '../../services/flight_operation_api_service.dart';
import '../custom/custom_input_field.dart';
import '../custom/custom_select_field.dart';
import '../custom/custom_button.dart';

class CrewSidePanel extends StatefulWidget {
  final int operationId;
  final FlightOperationApiService apiService;
  final VoidCallback onClose;

  const CrewSidePanel({
    super.key,
    required this.operationId,
    required this.apiService,
    required this.onClose,
  });

  @override
  State<CrewSidePanel> createState() => _CrewSidePanelState();
}

class _CrewSidePanelState extends State<CrewSidePanel>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<Offset> _slideAnim;

  bool _isAddMode = false;

  List<FlightCrewModel> _crew = [];
  CrewValidationModel? _validation;
  bool _isLoading = true;

  List<FlightCrewModel> _available = [];
  bool _isAvailableLoading = false;
  final Set<int> _assignedIds = {};
  final Map<String, int> _addedByPosition = {};
  String? _filterPosition;
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
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
    );
    _slideAnim = Tween<Offset>(
      begin: const Offset(1, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
    _controller.forward();
    _loadCrew();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  Future<void> _loadCrew() async {
    setState(() => _isLoading = true);
    final results = await Future.wait([
      widget.apiService.getCrew(widget.operationId),
      widget.apiService.validateCrew(widget.operationId),
    ]);
    if (!mounted) return;
    setState(() {
      _crew = results[0] as List<FlightCrewModel>;
      _validation = results[1] as CrewValidationModel?;
      _isLoading = false;
    });
  }

  Future<void> _loadAvailable({String? search}) async {
    setState(() => _isAvailableLoading = true);
    final crew = await widget.apiService.getAvailableCrew(
      widget.operationId,
      search: search,
    );
    if (!mounted) return;
    setState(() {
      _available = crew;
      _isAvailableLoading = false;
    });
  }

  Future<void> _refreshValidation() async {
    final validation = await widget.apiService.validateCrew(widget.operationId);
    if (mounted) setState(() => _validation = validation);
  }

  Future<void> _removeCrew(int crewId) async {
    final ok = await widget.apiService.removeCrew(widget.operationId, crewId);
    if (!ok || !mounted) return;
    setState(() => _crew.removeWhere((c) => c.flightCrewId == crewId));
    await _refreshValidation();
  }

  Future<void> _assign(int crewId, String? position) async {
    final result = await widget.apiService.assignCrew(widget.operationId, crewId);
    if (!mounted) return;
    if (!result.success) return;

    final member = _available.firstWhere((c) => c.flightCrewId == crewId);
    setState(() {
      _assignedIds.add(crewId);
      _available.removeWhere((c) => c.flightCrewId == crewId);
      _crew.add(member);
      if (position != null) {
        _addedByPosition[position] = (_addedByPosition[position] ?? 0) + 1;
      }
    });
    await _refreshValidation();
  }

  void _enterAddMode() {
    setState(() {
      _isAddMode = true;
      _assignedIds.clear();
      _addedByPosition.clear();
      _filterPosition = null;
      _filterLicense = null;
      _available = [];
    });
    _loadAvailable();
  }

  void _exitAddMode() {
    setState(() => _isAddMode = false);
  }

  void _closePanel() {
    _controller.reverse().then((_) => widget.onClose());
  }

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
    if (position == 'Co-Pilot' && current >= 1) return 'Maximum 1 Co-Pilot allowed';
    if (position == 'Engineer' && current >= 1) return 'Maximum 1 Engineer allowed';
    if (position == 'Flight Attendant') {
      final recommended = (_validation?.required[position] ?? 0);
      final max = recommended + 2;
      if (current >= max) {
        return 'Maximum $max Flight Attendants allowed '
            '(recommended $recommended, +2 allowed)';
      }
    }
    return null;
  }

  List<FlightCrewModel> get _filtered => _available.where((c) {
        if (_filterPosition != null && c.position != _filterPosition) return false;
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
    final colors = Theme.of(context).colorScheme;

    return SlideTransition(
      position: _slideAnim,
      child: Container(
        width: 300,
        decoration: BoxDecoration(
          color: colors.surface,
          border: Border(left: BorderSide(color: colors.outlineVariant)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
              blurRadius: 16,
              offset: const Offset(-4, 0),
            ),
          ],
        ),
        child: Column(
          children: [
            _buildHeader(colors),
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: _isAddMode
                    ? _AddModeBody(
                        key: const ValueKey('add'),
                        filtered: _filtered,
                        isLoading: _isAvailableLoading,
                        assignedIds: _assignedIds,
                        positionItems: _positionItems,
                        licenseItems: _licenseItems,
                        licenseLabels: _licenseLabels,
                        positionShort: _positionShort,
                        filterPosition: _filterPosition,
                        filterLicense: _filterLicense,
                        limitReachedMessage: _limitReachedMessage,
                        positionColor: _positionColor,
                        shortLicense: _shortLicense,
                        onSearch: (v) {
                          _debounce?.cancel();
                          _debounce = Timer(
                            const Duration(milliseconds: 400),
                            () => _loadAvailable(search: v.isNotEmpty ? v : null),
                          );
                        },
                        onFilterPosition: (v) => setState(
                            () => _filterPosition = (v == null || v.isEmpty) ? null : v),
                        onFilterLicense: (v) => setState(
                            () => _filterLicense = (v == null || v.isEmpty) ? null : v),
                        onAssign: _assign,
                        validation: _validation,
                        crew: _crew,
                      )
                    : _CrewModeBody(
                        key: const ValueKey('crew'),
                        crew: _crew,
                        validation: _validation,
                        isLoading: _isLoading,
                        positionColor: _positionColor,
                        onRemove: _removeCrew,
                        onRefresh: _loadCrew,
                      ),
              ),
            ),
            _buildFooter(colors),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(ColorScheme colors) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 8, 14),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: colors.outlineVariant)),
      ),
      child: Row(
        children: [
          if (_isAddMode) ...[
            Icon(Icons.person_add_outlined, size: 18, color: colors.primary),
            const SizedBox(width: 8),
            Text(
              'Add crew member',
              style: Theme.of(context)
                  .textTheme
                  .titleSmall
                  ?.copyWith(fontWeight: FontWeight.w600),
            ),
          ] else ...[
            Icon(Icons.people_outline, size: 18, color: colors.primary),
            const SizedBox(width: 8),
            Text(
              'Crew',
              style: Theme.of(context)
                  .textTheme
                  .titleSmall
                  ?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(width: 8),
            if (_validation != null) _validationBadge(_validation!, colors),
          ],
          const Spacer(),
          if (!_isAddMode)
            IconButton(
              icon: const Icon(Icons.refresh_outlined, size: 16),
              onPressed: _loadCrew,
              visualDensity: VisualDensity.compact,
            ),
          IconButton(
            icon: const Icon(Icons.close, size: 18),
            onPressed: _closePanel,
            visualDensity: VisualDensity.compact,
          ),
        ],
      ),
    );
  }

  Widget _buildFooter(ColorScheme colors) {
    if (_isAddMode) {
      final total = _assignedIds.length;
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: colors.outlineVariant)),
        ),
        child: CustomButton(
          label: total == 0 ? 'Done' : 'Done ($total added)',
          verticalPadding: 12,
          onPressed: _exitAddMode,
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: colors.outlineVariant)),
      ),
      child: CustomButton(
        label: 'Add crew member',
        icon: Icons.person_add_outlined,
        isIconAfterLabel: false,
        verticalPadding: 12,
        onPressed: _enterAddMode,
      ),
    );
  }

  Widget _validationBadge(CrewValidationModel v, ColorScheme colors) {
    final color = v.valid ? Colors.green : colors.error;
    final label = v.valid
        ? 'Complete'
        : '${v.missing.values.fold(0, (a, b) => a + b)} missing';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.w600),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Crew mode
// ---------------------------------------------------------------------------

class _CrewModeBody extends StatelessWidget {
  final List<FlightCrewModel> crew;
  final CrewValidationModel? validation;
  final bool isLoading;
  final Color Function(String?, ColorScheme) positionColor;
  final Future<void> Function(int) onRemove;
  final VoidCallback onRefresh;

  const _CrewModeBody({
    super.key,
    required this.crew,
    required this.validation,
    required this.isLoading,
    required this.positionColor,
    required this.onRemove,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      children: [
        if (validation != null) ...[
          if (validation!.warnings.isNotEmpty)
            _WarningBanner(message: validation!.warnings.first),
        ],
        Expanded(
          child: crew.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.people_outline,
                          size: 36,
                          color: colors.onSurfaceVariant.withValues(alpha: 0.4)),
                      const SizedBox(height: 8),
                      Text('No crew assigned',
                          style:
                              TextStyle(color: colors.onSurfaceVariant, fontSize: 13)),
                    ],
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(12),
                  itemCount: crew.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 6),
                  itemBuilder: (_, i) => _CrewTile(
                    member: crew[i],
                    positionColor: positionColor,
                    onRemove: onRemove,
                  ),
                ),
        ),
      ],
    );
  }
}

class _CrewTile extends StatelessWidget {
  final FlightCrewModel member;
  final Color Function(String?, ColorScheme) positionColor;
  final Future<void> Function(int) onRemove;

  const _CrewTile({
    required this.member,
    required this.positionColor,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final pColor = positionColor(member.position, colors);

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
              member.firstName?.isNotEmpty == true ? member.firstName![0] : '?',
              style: TextStyle(
                  color: pColor, fontWeight: FontWeight.w700, fontSize: 13),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(member.fullName,
                    style: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w600)),
                Text(member.position ?? '—',
                    style: TextStyle(
                        fontSize: 11,
                        color: pColor,
                        fontWeight: FontWeight.w500)),
              ],
            ),
          ),
          IconButton(
            icon: Icon(Icons.remove_circle_outline, size: 16, color: colors.error),
            onPressed: () => onRemove(member.flightCrewId),
            visualDensity: VisualDensity.compact,
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Add mode
// ---------------------------------------------------------------------------

class _AddModeBody extends StatelessWidget {
  final List<FlightCrewModel> filtered;
  final bool isLoading;
  final Set<int> assignedIds;
  final List<String> positionItems;
  final List<String> licenseItems;
  final List<String> licenseLabels;
  final Map<String, String> positionShort;
  final String? filterPosition;
  final String? filterLicense;
  final String? Function(String?) limitReachedMessage;
  final Color Function(String?, ColorScheme) positionColor;
  final String Function(String) shortLicense;
  final ValueChanged<String> onSearch;
  final ValueChanged<String?> onFilterPosition;
  final ValueChanged<String?> onFilterLicense;
  final Future<void> Function(int, String?) onAssign;
  final CrewValidationModel? validation;
  final List<FlightCrewModel> crew;

  const _AddModeBody({
    super.key,
    required this.filtered,
    required this.isLoading,
    required this.assignedIds,
    required this.positionItems,
    required this.licenseItems,
    required this.licenseLabels,
    required this.positionShort,
    required this.filterPosition,
    required this.filterLicense,
    required this.limitReachedMessage,
    required this.positionColor,
    required this.shortLicense,
    required this.onSearch,
    required this.onFilterPosition,
    required this.onFilterLicense,
    required this.onAssign,
    required this.validation,
    required this.crew,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Column(
      children: [
        // Search + filters + compact status — all together, minimal height
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CustomInputField(
                label: 'Search by name',
                value: '',
                icon: Icons.search,
                onChanged: onSearch,
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: CustomSelectField(
                      label: 'Position',
                      icon: Icons.badge_outlined,
                      value: filterPosition ?? '',
                      items: ['', ...positionItems],
                      itemLabels: ['All', ...positionItems],
                      searchable: false,
                      onChanged: onFilterPosition,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: CustomSelectField(
                      label: 'License',
                      icon: Icons.card_membership_outlined,
                      value: filterLicense ?? '',
                      items: ['', ...licenseItems],
                      itemLabels: ['All', ...licenseLabels],
                      searchable: false,
                      onChanged: onFilterLicense,
                    ),
                  ),
                ],
              ),
              if (validation != null && validation!.required.isNotEmpty) ...[
                const SizedBox(height: 8),
                _CompactStatusRow(
                  required: validation!.required,
                  crew: crew,
                  positionShort: positionShort,
                  positionColor: positionColor,
                ),
              ],
            ],
          ),
        ),

        Divider(height: 1, color: colors.outlineVariant),

        Expanded(
          child: isLoading
              ? const Center(child: CircularProgressIndicator())
              : filtered.isEmpty
                  ? Center(
                      child: Text(
                        'No crew matches filters',
                        style: TextStyle(color: colors.onSurfaceVariant),
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                      itemCount: filtered.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 4),
                      itemBuilder: (_, i) {
                        final c = filtered[i];
                        final pColor = positionColor(c.position, colors);
                        final justAdded = assignedIds.contains(c.flightCrewId);
                        final limitMsg = limitReachedMessage(c.position);
                        final isLimited = limitMsg != null;

                        return _AvailableTile(
                          member: c,
                          pColor: pColor,
                          justAdded: justAdded,
                          isLimited: isLimited,
                          limitMsg: limitMsg,
                          shortLicense: shortLicense,
                          onAssign: () => onAssign(c.flightCrewId, c.position),
                        );
                      },
                    ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Compact one-line status row (under filters in add mode)
// ---------------------------------------------------------------------------

class _CompactStatusRow extends StatelessWidget {
  final Map<String, int> required;
  final List<FlightCrewModel> crew;
  final Map<String, String> positionShort;
  final Color Function(String?, ColorScheme) positionColor;

  const _CompactStatusRow({
    required this.required,
    required this.crew,
    required this.positionShort,
    required this.positionColor,
  });

  Map<String, int> get _currentCounts {
    final counts = <String, int>{};
    for (final c in crew) {
      if (c.position != null) {
        counts[c.position!] = (counts[c.position!] ?? 0) + 1;
      }
    }
    return counts;
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final current = _currentCounts;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: required.entries.map((e) {
          final cur = current[e.key] ?? 0;
          final isDone = cur >= e.value;
          final pColor = positionColor(e.key, colors);
          final label = positionShort[e.key] ?? e.key;

          return Padding(
            padding: const EdgeInsets.only(right: 5),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
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
                  // Dot indicator
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
                      color: isDone ? Colors.green.shade700 : colors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Available tile
// ---------------------------------------------------------------------------

class _AvailableTile extends StatelessWidget {
  final FlightCrewModel member;
  final Color pColor;
  final bool justAdded;
  final bool isLimited;
  final String? limitMsg;
  final String Function(String) shortLicense;
  final VoidCallback onAssign;

  const _AvailableTile({
    required this.member,
    required this.pColor,
    required this.justAdded,
    required this.isLimited,
    required this.limitMsg,
    required this.shortLicense,
    required this.onAssign,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return ListTile(
      dense: true,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      tileColor: justAdded
          ? Colors.green.withValues(alpha: 0.08)
          : isLimited
              ? colors.surfaceContainerHighest.withValues(alpha: 0.5)
              : colors.surfaceContainerHighest,
      leading: CircleAvatar(
        radius: 16,
        backgroundColor: pColor.withValues(alpha: isLimited ? 0.07 : 0.15),
        child: Text(
          member.firstName?.isNotEmpty == true ? member.firstName![0] : '?',
          style: TextStyle(
              color: isLimited ? pColor.withValues(alpha: 0.4) : pColor,
              fontWeight: FontWeight.w700,
              fontSize: 13),
        ),
      ),
      title: Row(
        children: [
          Flexible(
            child: Text(
              member.fullName,
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isLimited
                      ? colors.onSurface.withValues(alpha: 0.4)
                      : colors.onSurface),
            ),
          ),
          if (!member.locationKnown) ...[
            const SizedBox(width: 6),
            Tooltip(
              message: 'Location unknown — no completed flights',
              child: Icon(Icons.help_outline,
                  size: 13, color: Colors.orange.withValues(alpha: 0.7)),
            ),
          ],
        ],
      ),
      subtitle: Text(
        '${member.position ?? "—"}'
        ' · ${member.experienceYears ?? 0} yrs'
        '${member.licenseType != null ? ' · ${shortLicense(member.licenseType!)}' : ''}',
        style: TextStyle(
            fontSize: 11,
            color: isLimited ? pColor.withValues(alpha: 0.4) : pColor),
      ),
      trailing: justAdded
          ? const SizedBox(
              width: 40,
              child: Icon(Icons.check_circle, color: Colors.green, size: 20),
            )
          : isLimited
              ? Tooltip(
                  message: limitMsg ?? '',
                  child: SizedBox(
                    width: 40,
                    child: Icon(Icons.add_circle_outline,
                        size: 20,
                        color: colors.onSurfaceVariant.withValues(alpha: 0.25)),
                  ),
                )
              : SizedBox(
                  width: 40,
                  child: IconButton(
                    padding: EdgeInsets.zero,
                    icon: Icon(Icons.add_circle_outline,
                        color: colors.primary, size: 20),
                    onPressed: onAssign,
                  ),
                ),
    );
  }
}

// ---------------------------------------------------------------------------
// Crew mode helpers
// ---------------------------------------------------------------------------

class _WarningBanner extends StatelessWidget {
  final String message;
  const _WarningBanner({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 8, 12, 0),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.orange.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_outlined, size: 14, color: Colors.orange),
          const SizedBox(width: 6),
          Expanded(
            child: Text(message,
                style: TextStyle(fontSize: 11, color: Colors.orange.shade800)),
          ),
        ],
      ),
    );
  }
}


