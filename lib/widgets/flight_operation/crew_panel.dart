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

  List<FlightCrewModel> _crew      = [];
  CrewValidationModel?  _validation;
  bool _isLoading = true;

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
    _load();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    final results = await Future.wait([
      widget.apiService.getCrew(widget.operationId),
      widget.apiService.validateCrew(widget.operationId),
    ]);
    if (mounted) setState(() {
      _crew       = results[0] as List<FlightCrewModel>;
      _validation = results[1] as CrewValidationModel?;
      _isLoading  = false;
    });
  }

  Future<void> _removeCrew(int crewId) async {
    final ok = await widget.apiService.removeCrew(widget.operationId, crewId);
    if (ok && mounted) _load();
  }

  void _closePanel() {
    _controller.reverse().then((_) => widget.onClose());
  }

  void _openAddDialog() {
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.3),
      builder: (ctx) => _AddCrewDialog(
        operationId: widget.operationId,
        apiService:  widget.apiService,
        onDone: () {
          Navigator.of(ctx).pop();
          _load();
        },
      ),
    );
  }

  Color _positionColor(String? position, ColorScheme colors) {
    switch (position) {
      case 'Pilot':            return colors.primary;
      case 'Co-Pilot':         return Colors.blue;
      case 'Flight Attendant': return Colors.teal;
      case 'Engineer':         return Colors.orange;
      default:                 return colors.onSurfaceVariant;
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
            Container(
              padding: const EdgeInsets.fromLTRB(16, 14, 8, 14),
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: colors.outlineVariant)),
              ),
              child: Row(
                children: [
                  Icon(Icons.people_outline, size: 18, color: colors.primary),
                  const SizedBox(width: 8),
                  Text('Crew',
                      style: Theme.of(context)
                          .textTheme
                          .titleSmall
                          ?.copyWith(fontWeight: FontWeight.w600)),
                  const SizedBox(width: 8),
                  if (_validation != null) _validationBadge(colors),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.refresh_outlined, size: 16),
                    onPressed: _load,
                    visualDensity: VisualDensity.compact,
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 18),
                    onPressed: _closePanel,
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ),
            ),

            if (_validation != null) ...[
              if (_validation!.warnings.isNotEmpty)
                _warningBanner(_validation!.warnings.first, colors),
              if (_validation!.missing.isNotEmpty)
                _missingBanner(_validation!.missing, colors),
            ],

            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _crew.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.people_outline,
                                  size: 36,
                                  color: colors.onSurfaceVariant
                                      .withValues(alpha: 0.4)),
                              const SizedBox(height: 8),
                              Text('No crew assigned',
                                  style: TextStyle(
                                      color: colors.onSurfaceVariant,
                                      fontSize: 13)),
                            ],
                          ),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.all(12),
                          itemCount: _crew.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 6),
                          itemBuilder: (_, i) => _crewTile(_crew[i], colors),
                        ),
            ),

            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: colors.outlineVariant)),
              ),
              child: CustomButton(
                label: 'Add crew member',
                icon: Icons.person_add_outlined,
                isIconAfterLabel: false,
                verticalPadding: 12,
                onPressed: _openAddDialog,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _crewTile(FlightCrewModel c, ColorScheme colors) {
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
              style: TextStyle(color: pColor, fontWeight: FontWeight.w700, fontSize: 13),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(c.fullName,
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                Text(c.position ?? '—',
                    style: TextStyle(fontSize: 11, color: pColor, fontWeight: FontWeight.w500)),
              ],
            ),
          ),
          IconButton(
            icon: Icon(Icons.remove_circle_outline, size: 16, color: colors.error),
            onPressed: () => _removeCrew(c.flightCrewId),
            visualDensity: VisualDensity.compact,
          ),
        ],
      ),
    );
  }

  Widget _validationBadge(ColorScheme colors) {
    final valid = _validation!.valid;
    final color = valid ? Colors.green : colors.error;
    final label = valid
        ? 'Complete'
        : '${_validation!.missing.values.fold(0, (a, b) => a + b)} missing';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(label,
          style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.w600)),
    );
  }

  Widget _warningBanner(String message, ColorScheme colors) {
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

  Widget _missingBanner(Map<String, int> missing, ColorScheme colors) {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 8, 12, 0),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: colors.errorContainer.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Still needed:',
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: colors.onErrorContainer)),
          const SizedBox(height: 4),
          Wrap(
            spacing: 4,
            runSpacing: 4,
            children: missing.entries.map((e) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: colors.errorContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text('${e.value}× ${e.key}',
                  style: TextStyle(fontSize: 11, color: colors.onErrorContainer)),
            )).toList(),
          ),
        ],
      ),
    );
  }
}


// ── Add Crew Dialog ────────────────────────────────────────────────────────────

class _AddCrewDialog extends StatefulWidget {
  final int operationId;
  final FlightOperationApiService apiService;
  final VoidCallback onDone;

  const _AddCrewDialog({
    required this.operationId,
    required this.apiService,
    required this.onDone,
  });

  @override
  State<_AddCrewDialog> createState() => _AddCrewDialogState();
}

class _AddCrewDialogState extends State<_AddCrewDialog> {
  List<FlightCrewModel> _available          = [];
  Set<int>             _assignedThisSession = {};
  bool   _isLoading       = true;
  Timer? _debounce;

  String  _search         = '';
  String? _filterPosition;
  String? _filterLicense;

  static const _positionItems = [
    'Pilot', 'Co-Pilot', 'Flight Attendant', 'Engineer',
  ];

  static const _licenseItems = [
    'Private Pilot License',
    'Commercial Pilot License',
    'Airline Transport Pilot License',
    'Flight Engineer License',
  ];

  static const _licenseLabels = ['PPL', 'CPL', 'ATPL', 'FEL'];

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  Future<void> _load({String? search}) async {
    setState(() => _isLoading = true);
    final crew = await widget.apiService.getAvailableCrew(
      widget.operationId,
      search: search,
    );
    if (mounted) setState(() {
      _available = crew;
      _isLoading = false;
    });
  }

  Future<void> _assign(int crewId) async {
    final ok = await widget.apiService.assignCrew(widget.operationId, crewId);
    if (ok && mounted) {
      setState(() {
        _assignedThisSession.add(crewId);
        _available.removeWhere((c) => c.flightCrewId == crewId);
      });
    }
  }

  List<FlightCrewModel> get _filtered => _available.where((c) {
        if (_filterPosition != null && c.position != _filterPosition) return false;
        if (_filterLicense != null && c.licenseType != _filterLicense) return false;
        return true;
      }).toList();

  Color _positionColor(String? position, ColorScheme colors) {
    switch (position) {
      case 'Pilot':            return colors.primary;
      case 'Co-Pilot':         return Colors.blue;
      case 'Flight Attendant': return Colors.teal;
      case 'Engineer':         return Colors.orange;
      default:                 return colors.onSurfaceVariant;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520, maxHeight: 700),
        child: Container(
          decoration: BoxDecoration(
            color: colors.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Header ────────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 12, 16),
                child: Row(
                  children: [
                    const SizedBox(width: 10),
                    Text('Add crew members',
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(fontWeight: FontWeight.w600)),
                    if (_assignedThisSession.isNotEmpty) ...[
                      const SizedBox(width: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.green.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text('${_assignedThisSession.length} added',
                            style: const TextStyle(
                                fontSize: 11,
                                color: Colors.green,
                                fontWeight: FontWeight.w600)),
                      ),
                    ],
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: widget.onDone,
                    ),
                  ],
                ),
              ),

              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CustomInputField(
                      label: 'Search by name or surname',
                      value: _search,
                      icon: Icons.search,
                      onChanged: (v) {
                        setState(() => _search = v);
                        _debounce?.cancel();
                        _debounce = Timer(
                          const Duration(milliseconds: 400),
                          () => _load(search: v.isNotEmpty ? v : null),
                        );
                      },
                    ),
                    const SizedBox(height: 10),

                    Row(
                      children: [
                        Expanded(
                          child: CustomSelectField(
                            label: 'Position',
                            icon: Icons.badge_outlined,
                            value: _filterPosition ?? '',
                            items: ['', ..._positionItems],
                            itemLabels: ['All', ..._positionItems],
                            searchable: false,
                            onChanged: (v) => setState(
                                () => _filterPosition =
                                    (v == null || v.isEmpty) ? null : v),
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
                                () => _filterLicense =
                                    (v == null || v.isEmpty) ? null : v),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 8),
              const Divider(height: 1),

              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _filtered.isEmpty
                        ? Center(
                            child: Text('No crew matches filters',
                                style: TextStyle(color: colors.onSurfaceVariant)),
                          )
                        : ListView.separated(
                            padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                            itemCount: _filtered.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 4),
                            itemBuilder: (_, i) {
                              final c      = _filtered[i];
                              final pColor = _positionColor(c.position, colors);
                              final justAdded =
                                  _assignedThisSession.contains(c.flightCrewId);

                              return ListTile(
                                dense: true,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8)),
                                tileColor: justAdded
                                    ? Colors.green.withValues(alpha: 0.08)
                                    : colors.surfaceContainerHighest,
                                leading: CircleAvatar(
                                  radius: 16,
                                  backgroundColor: pColor.withValues(alpha: 0.15),
                                  child: Text(
                                    c.firstName?.isNotEmpty == true
                                        ? c.firstName![0]
                                        : '?',
                                    style: TextStyle(
                                        color: pColor,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 13),
                                  ),
                                ),
                                title: Text(c.fullName,
                                    style: const TextStyle(
                                        fontSize: 13, fontWeight: FontWeight.w600)),
                                subtitle: Text(
                                  '${c.position ?? "—"}'
                                  ' · ${c.experienceYears ?? 0} yrs'
                                  '${c.licenseType != null ? ' · ${_shortLicense(c.licenseType!)}' : ''}',
                                  style: TextStyle(fontSize: 11, color: pColor),
                                ),
                                trailing: justAdded
                                    ? const Icon(Icons.check_circle,
                                        color: Colors.green, size: 20)
                                    : IconButton(
                                        icon: Icon(Icons.add_circle_outline,
                                            color: colors.primary),
                                        onPressed: () => _assign(c.flightCrewId),
                                      ),
                              );
                            },
                          ),
              ),

              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                child: CustomButton(
                  label: _assignedThisSession.isEmpty
                      ? 'Close'
                      : 'Done',
                  verticalPadding: 14,
                  onPressed: widget.onDone,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _shortLicense(String license) {
    switch (license) {
      case 'Private Pilot License':           return 'PPL';
      case 'Commercial Pilot License':        return 'CPL';
      case 'Airline Transport Pilot License': return 'ATPL';
      case 'Flight Engineer License':         return 'FEL';
      default:                                return license;
    }
  }
}