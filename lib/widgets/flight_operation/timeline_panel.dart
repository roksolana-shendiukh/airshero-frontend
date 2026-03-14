import 'package:flutter/material.dart';
import '../../models/flight_operation_model.dart';
import '../../models/gate_model.dart';
import '../../services/flight_operation_api_service.dart';
import '../custom/custom_button.dart';
import '../custom/custom_select_field.dart';

class TimelinePanel extends StatefulWidget {
  final FlightOperationModel operation;
  final FlightOperationApiService apiService;
  final VoidCallback onClose;
  final ValueChanged<FlightOperationModel> onOperationUpdated;

  const TimelinePanel({
    super.key,
    required this.operation,
    required this.apiService,
    required this.onClose,
    required this.onOperationUpdated,
  });

  @override
  State<TimelinePanel> createState() => _TimelinePanelState();
}

class _TimelinePanelState extends State<TimelinePanel>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<Offset>   _slideAnim;
  late FlightOperationModel      _op;

  List<GateModel> _gates       = [];
  bool _loadingGates            = false;
  bool _showGateSelector        = false;
  String? _selectedGateId;
  bool _isProcessing            = false;

  @override
  void initState() {
    super.initState();
    _op = widget.operation;
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
    );
    _slideAnim = Tween<Offset>(
      begin: const Offset(-1, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _closePanel() {
    _controller.reverse().then((_) => widget.onClose());
  }

  Future<void> _loadGates() async {
    setState(() => _loadingGates = true);
    final gates = await widget.apiService.getAvailableGates(_op.flightOperationId);
    if (mounted) setState(() {
      _gates       = gates;
      _loadingGates = false;
    });
  }

  Future<void> _setStep(String step) async {
    setState(() => _isProcessing = true);
    final updated = await widget.apiService.setTimelineStep(
        _op.flightOperationId, step);
    if (mounted && updated != null) {
      setState(() {
        _op           = updated;
        _isProcessing = false;
      });
      widget.onOperationUpdated(updated);
    } else {
      setState(() => _isProcessing = false);
    }
  }

  Future<void> _assignGate() async {
    if (_selectedGateId == null) return;
    setState(() => _isProcessing = true);
    final updated = await widget.apiService.assignGate(
        _op.flightOperationId, int.parse(_selectedGateId!));
    if (mounted && updated != null) {
      setState(() {
        _op              = updated;
        _showGateSelector = false;
        _selectedGateId   = null;
        _isProcessing     = false;
      });
      widget.onOperationUpdated(updated);
    } else {
      setState(() => _isProcessing = false);
    }
  }

  bool get _crewReady => true; 

  bool get _gateAssigned => _op.gateId != null;

  bool get _canStartBoarding =>
      _gateAssigned && _crewReady && _op.boardingStartTime == null;

  bool get _canEndBoarding =>
      _op.boardingStartTime != null && _op.boardingEndTime == null;

  bool get _canStartBaggage =>
      _op.baggageLoadingStartTime == null;

  bool get _canEndBaggage =>
      _op.baggageLoadingStartTime != null && _op.baggageLoadingEndTime == null;

  bool get _canDepart =>
      _op.boardingEndTime != null &&
      _op.baggageLoadingEndTime != null &&
      _op.actualDepartureDatetime == null;

  bool get _canArrive =>
      _op.actualDepartureDatetime != null &&
      _op.actualArrivalDatetime == null;

  bool get _canComplete =>
      _op.actualArrivalDatetime != null &&
      _op.statusName != 'Completed';

  bool get _canCancel => _op.statusName != 'Completed' &&
      _op.statusName != 'Cancelled';

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return SlideTransition(
      position: _slideAnim,
      child: Container(
        width: 300,
        decoration: BoxDecoration(
          color: colors.surface,
          border: Border(right: BorderSide(color: colors.outlineVariant)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
              blurRadius: 16,
              offset: const Offset(4, 0),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(16, 14, 8, 14),
              decoration: BoxDecoration(
                border: Border(
                    bottom: BorderSide(color: colors.outlineVariant)),
              ),
              child: Row(
                children: [
                  Icon(Icons.timeline, size: 18, color: colors.primary),
                  const SizedBox(width: 8),
                  Text('Timeline',
                      style: Theme.of(context)
                          .textTheme
                          .titleSmall
                          ?.copyWith(fontWeight: FontWeight.w600)),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close, size: 18),
                    onPressed: _closePanel,
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _TimelineStep(
                      icon: Icons.door_sliding_outlined,
                      label: 'Assign Gate',
                      value: _op.gateCode != null
                          ? 'Gate ${_op.gateCode}'
                          : null,
                      isDone:    _gateAssigned,
                      isActive:  !_gateAssigned,
                      isLast:    false,
                      action: _gateAssigned
                          ? null
                          : CustomButton(
                              label: 'Select',
                              verticalPadding: 6,
                              horizontalPadding: 12,
                              onPressed: _isProcessing ? null : () async {
                                setState(() => _showGateSelector = !_showGateSelector);
                                if (_showGateSelector && _gates.isEmpty) {
                                  await _loadGates();
                                }
                              },
                            ),
                    ),

                    if (_showGateSelector) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: colors.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: colors.outlineVariant),
                        ),
                        child: _loadingGates
                            ? const Center(child: CircularProgressIndicator())
                            : Column(
                                children: [
                                  CustomSelectField(
                                    label: 'Gate',
                                    icon: Icons.door_sliding_outlined,
                                    value: _selectedGateId ?? '',
                                    items: _gates
                                        .map((g) => g.gateId.toString())
                                        .toList(),
                                    itemLabels:
                                        _gates.map((g) => g.label).toList(),
                                    searchable: false,
                                    onChanged: (v) => setState(
                                        () => _selectedGateId = v),
                                  ),
                                  const SizedBox(height: 8),
                                  CustomButton(
                                    label: 'Confirm',
                                    verticalPadding: 10,
                                    onPressed: _selectedGateId != null
                                        ? _assignGate
                                        : null,
                                  ),
                                ],
                              ),
                      ),
                      const SizedBox(height: 8),
                    ],

                    _TimelineStep(
                      icon: Icons.people_outline,
                      label: 'Boarding start',
                      value: _op.boardingStartTime,
                      isDone:   _op.boardingStartTime != null,
                      isActive: _canStartBoarding,
                      isLast:   false,
                      action: _canStartBoarding
                          ? CustomButton(
                              label: 'Set now',
                              verticalPadding: 6,
                              horizontalPadding: 12,
                              onPressed: _isProcessing
                                  ? null
                                  : () => _setStep('boarding-start'),
                            )
                          : null,
                    ),

                    _TimelineStep(
                      icon: Icons.people,
                      label: 'Boarding end',
                      value: _op.boardingEndTime,
                      isDone:   _op.boardingEndTime != null,
                      isActive: _canEndBoarding,
                      isLast:   false,
                      action: _canEndBoarding
                          ? CustomButton(
                              label: 'Set now',
                              verticalPadding: 6,
                              horizontalPadding: 12,
                              onPressed: _isProcessing
                                  ? null
                                  : () => _setStep('boarding-end'),
                            )
                          : null,
                    ),

                    _TimelineStep(
                      icon: Icons.luggage_outlined,
                      label: 'Baggage start',
                      value: _op.baggageLoadingStartTime,
                      isDone:   _op.baggageLoadingStartTime != null,
                      isActive: _canStartBaggage,
                      isLast:   false,
                      action: _canStartBaggage
                          ? CustomButton(
                              label: 'Set now',
                              verticalPadding: 6,
                              horizontalPadding: 12,
                              onPressed: _isProcessing
                                  ? null
                                  : () => _setStep('baggage-start'),
                            )
                          : null,
                    ),

                    _TimelineStep(
                      icon: Icons.luggage,
                      label: 'Baggage end',
                      value: _op.baggageLoadingEndTime,
                      isDone:   _op.baggageLoadingEndTime != null,
                      isActive: _canEndBaggage,
                      isLast:   false,
                      action: _canEndBaggage
                          ? CustomButton(
                              label: 'Set now',
                              verticalPadding: 6,
                              horizontalPadding: 12,
                              onPressed: _isProcessing
                                  ? null
                                  : () => _setStep('baggage-end'),
                            )
                          : null,
                    ),

                    _TimelineStep(
                      icon: Icons.flight_takeoff_outlined,
                      label: 'Departure',
                      value: _op.actualDepartureDatetime,
                      isDone:   _op.actualDepartureDatetime != null,
                      isActive: _canDepart,
                      isLast:   false,
                      action: _canDepart
                          ? CustomButton(
                              label: 'Set now',
                              verticalPadding: 6,
                              horizontalPadding: 12,
                              onPressed: _isProcessing
                                  ? null
                                  : () => _setStep('departure'),
                            )
                          : null,
                    ),

                    _TimelineStep(
                      icon: Icons.flight_land_outlined,
                      label: 'Arrival',
                      value: _op.actualArrivalDatetime,
                      isDone:   _op.actualArrivalDatetime != null,
                      isActive: _canArrive,
                      isLast:   false,
                      action: _canArrive
                          ? CustomButton(
                              label: 'Set now',
                              verticalPadding: 6,
                              horizontalPadding: 12,
                              onPressed: _isProcessing
                                  ? null
                                  : () => _setStep('arrival'),
                            )
                          : null,
                    ),

                    _TimelineStep(
                      icon: Icons.check_circle_outline,
                      label: 'Complete',
                      value: _op.statusName == 'Completed' ? 'Done' : null,
                      isDone:   _op.statusName == 'Completed',
                      isActive: _canComplete,
                      isLast:   true,
                      action: _canComplete
                          ? CustomButton(
                              label: 'Complete',
                              verticalPadding: 6,
                              horizontalPadding: 12,
                              onPressed: _isProcessing
                                  ? null
                                  : () => _setStep('arrival'),
                            )
                          : null,
                    ),

                    const SizedBox(height: 16),
                    const Divider(),
                    const SizedBox(height: 8),

                    // Cancel
                    if (_canCancel)
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: _isProcessing ? null : _confirmCancel,
                          icon: Icon(Icons.cancel_outlined,
                              size: 16, color: colors.error),
                          label: Text('Cancel operation',
                              style: TextStyle(color: colors.error)),
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: colors.error),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmCancel() {
    final colors = Theme.of(context).colorScheme;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancel operation?'),
        content: const Text(
            'This action cannot be undone. The operation will be marked as Cancelled.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Back'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              // TODO: cancel endpoint
            },
            child: Text('Cancel operation',
                style: TextStyle(color: colors.error)),
          ),
        ],
      ),
    );
  }
}


class _TimelineStep extends StatelessWidget {
  final IconData icon;
  final String   label;
  final String?  value;
  final bool     isDone;
  final bool     isActive;
  final bool     isLast;
  final Widget?  action;

  const _TimelineStep({
    required this.icon,
    required this.label,
    required this.isDone,
    required this.isActive,
    required this.isLast,
    this.value,
    this.action,
  });

  String _fmtTime(String? t) {
    if (t == null) return '—';
    return t.length >= 5 ? t.substring(0, 5) : t;
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    final dotColor = isDone
        ? Colors.green
        : isActive
            ? colors.primary
            : colors.onSurfaceVariant.withValues(alpha: 0.3);

    final lineColor = isDone
        ? Colors.green.withValues(alpha: 0.4)
        : colors.outlineVariant;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isDone
                    ? Colors.green.withValues(alpha: 0.12)
                    : isActive
                        ? colors.primaryContainer.withValues(alpha: 0.4)
                        : colors.surfaceContainerHighest,
                border: Border.all(color: dotColor, width: 1.5),
              ),
              child: Icon(
                isDone ? Icons.check : icon,
                size: 15,
                color: dotColor,
              ),
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 40,
                color: lineColor,
              ),
          ],
        ),
        const SizedBox(width: 12),

        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 6, bottom: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        label,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: isDone || isActive
                              ? colors.onSurface
                              : colors.onSurfaceVariant,
                        ),
                      ),
                    ),
                    if (isDone || value != null)
                      Text(
                        _fmtTime(value),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isDone ? Colors.green : colors.onSurfaceVariant,
                        ),
                      ),
                  ],
                ),
                if (action != null) ...[
                  const SizedBox(height: 6),
                  action!,
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}