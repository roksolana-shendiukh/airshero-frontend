import 'dart:async';
import 'package:flutter/material.dart';
import '../../models/flight_crew_model.dart';
import '../../services/flight_operation_api_service.dart';

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
  late final Animation<Offset>   _slideAnim;

  List<FlightCrewModel> _crew       = [];
  CrewValidationModel?  _validation;
  bool                  _isLoading  = true;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync:    this,
      duration: const Duration(milliseconds: 220),
    );
    _slideAnim = Tween<Offset>(
      begin: const Offset(1, 0),
      end:   Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
    _controller.forward();
    _loadCrew();
  }

  @override
  void dispose() {
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
      _crew       = results[0] as List<FlightCrewModel>;
      _validation = results[1] as CrewValidationModel?;
      _isLoading  = false;
    });
  }

  void _closePanel() {
    _controller.reverse().then((_) => widget.onClose());
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
              color:      Colors.black.withValues(alpha: 0.12),
              blurRadius: 16,
              offset:     const Offset(-4, 0),
            ),
          ],
        ),
        child: Column(
          children: [
            _buildHeader(colors),
            Expanded(
              child: _CrewBody(
                crew:          _crew,
                validation:    _validation,
                isLoading:     _isLoading,
                positionColor: _positionColor,
                onRefresh:     _loadCrew,
              ),
            ),
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
          const Spacer(),
          IconButton(
            icon:          const Icon(Icons.refresh_outlined, size: 16),
            onPressed:     _loadCrew,
            visualDensity: VisualDensity.compact,
          ),
          IconButton(
            icon:          const Icon(Icons.close, size: 18),
            onPressed:     _closePanel,
            visualDensity: VisualDensity.compact,
          ),
        ],
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
        color:        color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        label,
        style: TextStyle(
            fontSize: 10, color: color, fontWeight: FontWeight.w600),
      ),
    );
  }
}

// ── Crew body ─────────────────────────────────────────────────────────────────

class _CrewBody extends StatelessWidget {
  final List<FlightCrewModel>                  crew;
  final CrewValidationModel?                   validation;
  final bool                                   isLoading;
  final Color Function(String?, ColorScheme)   positionColor;
  final VoidCallback                           onRefresh;

  const _CrewBody({
    required this.crew,
    required this.validation,
    required this.isLoading,
    required this.positionColor,
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
        Expanded(
          child: crew.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.people_outline,
                          size:  36,
                          color: colors.onSurfaceVariant
                              .withValues(alpha: 0.4)),
                      const SizedBox(height: 8),
                      Text('No crew assigned',
                          style: TextStyle(
                              color:    colors.onSurfaceVariant,
                              fontSize: 13)),
                    ],
                  ),
                )
              : ListView.separated(
                  padding:          const EdgeInsets.all(12),
                  itemCount:        crew.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 6),
                  itemBuilder: (_, i) => _CrewTile(
                    member:        crew[i],
                    positionColor: positionColor,
                  ),
                ),
        ),
      ],
    );
  }
}

// ── Crew tile (view only) ─────────────────────────────────────────────────────

class _CrewTile extends StatelessWidget {
  final FlightCrewModel                        member;
  final Color Function(String?, ColorScheme)   positionColor;

  const _CrewTile({
    required this.member,
    required this.positionColor,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final pColor = positionColor(member.position, colors);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color:        colors.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
        border:       Border.all(color: pColor.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius:          16,
            backgroundColor: pColor.withValues(alpha: 0.15),
            child: Text(
              member.firstName?.isNotEmpty == true
                  ? member.firstName![0]
                  : '?',
              style: TextStyle(
                  color:      pColor,
                  fontWeight: FontWeight.w700,
                  fontSize:   13),
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
                        fontSize:   11,
                        color:      pColor,
                        fontWeight: FontWeight.w500)),
              ],
            ),
          ),
          if (member.licenseType != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color:        pColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                _shortLicense(member.licenseType!),
                style: TextStyle(
                    fontSize:   10,
                    color:      pColor,
                    fontWeight: FontWeight.w600),
              ),
            ),
        ],
      ),
    );
  }

  String _shortLicense(String license) {
    switch (license) {
      case 'Private Pilot License':          return 'PPL';
      case 'Commercial Pilot License':       return 'CPL';
      case 'Airline Transport Pilot License': return 'ATPL';
      case 'Flight Engineer License':        return 'FEL';
      default:                               return license;
    }
  }
}

class _WarningBanner extends StatelessWidget {
  final String message;
  const _WarningBanner({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin:  const EdgeInsets.fromLTRB(12, 8, 12, 0),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color:        Colors.orange.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_outlined,
              size: 14, color: Colors.orange),
          const SizedBox(width: 6),
          Expanded(
            child: Text(message,
                style: TextStyle(
                    fontSize: 11, color: Colors.orange.shade800)),
          ),
        ],
      ),
    );
  }
}