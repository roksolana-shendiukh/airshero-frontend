import 'dart:async';
import 'package:flutter/material.dart';
import '../../models/flight_operation_model.dart';
import '../../services/flight_operation_api_service.dart';
import '../custom/error_dialog.dart';
import '../flight_operation/operation_state_dialog.dart';

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
  late final AnimationController _slideController;
  late final Animation<Offset>   _slideAnim;
  late FlightOperationModel      _op;

  bool     _isProcessing    = false;
  bool     _crewValid       = false;
  bool     _crewValidLoaded = false;
  Timer?   _ticker;
  DateTime _now = DateTime.now();

  @override
  void initState() {
    super.initState();
    _op = widget.operation;
    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
    );
    _slideAnim = Tween<Offset>(
      begin: const Offset(-1, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slideController, curve: Curves.easeOut));
    _slideController.forward();
    _loadCrewValidation();
    _startTicker();
  }

  @override
  void didUpdateWidget(TimelinePanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.operation != widget.operation) {
      setState(() => _op = widget.operation);
    }
  }

  @override
  void dispose() {
    _slideController.dispose();
    _ticker?.cancel();
    super.dispose();
  }

  void _startTicker() {
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _now = DateTime.now());
    });
  }

  Future<void> _loadCrewValidation() async {
    final v = await widget.apiService.validateCrew(_op.flightOperationId);
    if (mounted) setState(() {
      _crewValid       = v?.valid ?? false;
      _crewValidLoaded = true;
    });
  }

  void _closePanel() {
    _slideController.reverse().then((_) => widget.onClose());
  }

  Future<void> _setStep(String step) async {
    setState(() => _isProcessing = true);
    final result = await widget.apiService
        .setTimelineStep(_op.flightOperationId, step);
    if (!mounted) return;

    if (result.operation != null) {
      setState(() {
        _op           = result.operation!;
        _isProcessing = false;
      });
      widget.onOperationUpdated(result.operation!);
    } else if (result.isWarning && result.error != null) {
      setState(() => _isProcessing = false);
      _showWarningConfirm(result.error!, step);
    } else if (result.error != null) {
      setState(() => _isProcessing = false);
      ErrorDialog.show(context, result.error!);
    } else {
      setState(() => _isProcessing = false);
    }
  }

  void _showWarningConfirm(String message, String step) {
    final colors = Theme.of(context).colorScheme;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        icon: const Icon(Icons.warning_amber_outlined,
            color: Colors.orange, size: 32),
        title: const Text('Warning', textAlign: TextAlign.center),
        content: Text(
          message.replaceAll(' Are you sure?', ''),
          textAlign: TextAlign.center,
          style: TextStyle(color: colors.onSurfaceVariant),
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              setState(() => _isProcessing = true);
              final updated = await widget.apiService
                  .forceTimelineStep(_op.flightOperationId, step);
              debugPrint('[force] updated=${updated?.statusName}, step=$step');
              if (mounted) {
                setState(() {
                  if (updated != null) _op = updated;
                  _isProcessing = false;
                });
                if (updated != null) {
                  widget.onOperationUpdated(updated);
                }
              }
            },
            child: const Text('Confirm anyway'),
          ),
        ],
      ),
    );
  }

  bool get _isCancelled  => _op.statusName == 'Cancelled';
  bool get _isCompleted  => _op.statusName == 'Completed';
  bool get _isTerminated => _isCancelled || _isCompleted;

  bool get _canStartBoarding =>
      !_isTerminated && _crewValid && _op.boardingStartTime == null;

  bool get _canStartBaggage =>
      !_isTerminated &&
      _op.boardingStartTime != null &&
      _op.baggageLoadingStartTime == null;

  bool get _canEndBoarding =>
      !_isTerminated &&
      _op.boardingStartTime != null &&
      _op.boardingEndTime == null;

  bool get _canEndBaggage =>
      !_isTerminated &&
      _op.baggageLoadingStartTime != null &&
      _op.baggageLoadingEndTime == null;

  bool get _canDepart =>
      !_isTerminated &&
      _op.boardingEndTime != null &&
      _op.baggageLoadingEndTime != null &&
      _op.actualDepartureDatetime == null;

  bool get _canArrive =>
      !_isTerminated &&
      _op.actualDepartureDatetime != null &&
      _op.actualArrivalDatetime == null;

  bool get _canComplete =>
      !_isTerminated && _op.actualArrivalDatetime != null;

  bool get _canCancel => !_isTerminated && _op.statusName != 'Arrived';

  DateTime? _parseTime(String? t) {
    if (t == null) return null;
    try {
      final parts = t.split(':');
      debugPrint('[_parseTime] input=$t parts=$parts');
      final now = DateTime.now();
      return DateTime(
        now.year, now.month, now.day,
        int.parse(parts[0]),
        int.parse(parts[1]),
        parts.length > 2 ? int.parse(parts[2].split('.').first) : 0, // ← фікс мілісекунд
      );
    } catch (e) {
      debugPrint('[_parseTime] error=$e');
      return null;
    }
  }

  String _fmtTime(String? t) {
    if (t == null) return '—';
    return t.length >= 5 ? t.substring(0, 5) : t;
  }

  String _fmtDatetime(String? t) {
    if (t == null) return '—';
    try {
      final d = DateTime.parse(t);
      return '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return _fmtTime(t);
    }
  }

  String _duration(DateTime start, DateTime end) {
    final diff = end.difference(start);
    final h = diff.inHours;
    final m = diff.inMinutes % 60;
    if (h > 0) return '${h}h ${m}m';
    return '${m}m';
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
              padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: colors.outlineVariant)),
              ),
              child: Row(
                children: [
                  Icon(Icons.timeline, size: 16, color: colors.primary),
                  const SizedBox(width: 8),
                  Text('Timeline',
                      style: Theme.of(context)
                          .textTheme
                          .titleSmall
                          ?.copyWith(fontWeight: FontWeight.w600)),
                  if (_crewValidLoaded && !_crewValid) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: colors.errorContainer.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text('Crew incomplete',
                          style: TextStyle(
                              fontSize: 10,
                              color: colors.error,
                              fontWeight: FontWeight.w500)),
                    ),
                  ],
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close, size: 16),
                    onPressed: _closePanel,
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                child: Column(
                  children: [
                    _buildStep(
                      icon:      Icons.people_outline,
                      label:     'Boarding',
                      startTime: _op.boardingStartTime,
                      endTime:   _op.boardingEndTime,
                      startStep: 'boarding-start',
                      endStep:   'boarding-end',
                      canStart:  _canStartBoarding,
                      canEnd:    _canEndBoarding,
                      isLast:    false,
                    ),
                    _buildStep(
                      icon:      Icons.luggage_outlined,
                      label:     'Baggage loading',
                      startTime: _op.baggageLoadingStartTime,
                      endTime:   _op.baggageLoadingEndTime,
                      startStep: 'baggage-start',
                      endStep:   'baggage-end',
                      canStart:  _canStartBaggage,
                      canEnd:    _canEndBaggage,
                      isLast:    false,
                    ),
                    _buildSingleStep(
                      icon:       Icons.flight_takeoff_outlined,
                      label:      'Departure',
                      time:       _op.actualDepartureDatetime,
                      step:       'departure',
                      canSet:     _canDepart,
                      isDatetime: true,
                      isLast:     false,
                    ),
                    _buildSingleStep(
                      icon:       Icons.flight_land_outlined,
                      label:      'Arrival',
                      time:       _op.actualArrivalDatetime,
                      endTime:    _op.actualDepartureDatetime, 
                      step:       'arrival',
                      canSet:     _canArrive,
                      isDatetime: true,
                      isLast:     false,
                    ),
                    _buildCompleteStep(colors),

                    if (_canCancel) ...[
                      const SizedBox(height: 16),
                      const Divider(height: 1),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: _isProcessing ? null : _confirmCancel,
                          icon: Icon(Icons.cancel_outlined,
                              size: 15, color: colors.error),
                          label: Text('Cancel operation',
                              style: TextStyle(
                                  color: colors.error, fontSize: 13)),
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(
                                color: colors.error.withValues(alpha: 0.5)),
                            padding:
                                const EdgeInsets.symmetric(vertical: 10),
                          ),
                        ),
                      ),
                    ],

                    if (_isCancelled)
                      _statusBanner(
                          'Operation cancelled', colors.error, colors),
                    if (_isCompleted)
                      _statusBanner(
                          'Operation completed', Colors.green, colors),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStep({
    required IconData icon,
    required String   label,
    required String?  startTime,
    required String?  endTime,
    required String   startStep,
    required String   endStep,
    required bool     canStart,
    required bool     canEnd,
    required bool     isLast,
  }) {
    final colors   = Theme.of(context).colorScheme;
    final hasStart = startTime != null;
    final hasEnd   = endTime != null;
    final startDt  = _parseTime(startTime);
    final endDt    = _parseTime(endTime);
    final isDone   = hasEnd;
    final isActive = hasStart && !hasEnd;

    return _StepWrapper(
      icon:       icon,
      isDone:     isDone,
      isActive:   isActive || canStart,
      isLast:     isLast,
      lineHeight: hasStart ? 80 : 56,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(label,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: isDone || isActive || canStart
                          ? colors.onSurface
                          : colors.onSurfaceVariant,
                    )),
              ),
              if (hasStart)
                Text(_fmtTime(startTime),
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isDone ? Colors.green : colors.primary)),
            ],
          ),
          if (hasEnd && startDt != null && endDt != null) ...[
            const SizedBox(height: 2),
            Row(
              children: [
                Expanded(
                  child: Text('Ended ${_fmtTime(endTime)}',
                      style: TextStyle(
                          fontSize: 11, color: colors.onSurfaceVariant)),
                ),
                _DurationBadge(
                    label: _duration(startDt, endDt), colors: colors),
              ],
            ),
          ] else if (isActive && startDt != null) ...[
            const SizedBox(height: 4),
            _LiveTimer(start: startDt, now: _now, colors: colors),
          ],
          if (canStart) ...[
            const SizedBox(height: 6),
            _ActionButton(
              label:     'Start $label',
              onPressed: _isProcessing ? null : () => _setStep(startStep),
            ),
          ] else if (canEnd) ...[
            const SizedBox(height: 6),
            _ActionButton(
              label:     'End $label',
              onPressed: _isProcessing ? null : () => _setStep(endStep),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSingleStep({
    required IconData icon,
    required String   label,
    required String?  time,
    required String   step,
    required bool     canSet,
    required bool     isLast,
    bool    isDatetime = false,
    String? endTime,
  }) {
    final colors  = Theme.of(context).colorScheme;
    final hasTime = time != null;

    DateTime? _parseAny(String? t) {
      if (t == null) return null;
      try { return DateTime.parse(t); } catch (_) { return null; }
    }

    final startDt = _parseAny(endTime); 
    final endDt   = _parseAny(time);    

    return _StepWrapper(
      icon:       icon,
      isDone:     hasTime,
      isActive:   canSet,
      isLast:     isLast,
      lineHeight: 56,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(label,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: hasTime || canSet
                          ? colors.onSurface
                          : colors.onSurfaceVariant,
                    )),
              ),
              if (hasTime)
                Text(
                  isDatetime ? _fmtDatetime(time) : _fmtTime(time),
                  style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.green),
                ),
            ],
          ),
          if (hasTime && startDt != null && endDt != null) ...[
            const SizedBox(height: 2),
            Row(
              children: [
                Expanded(
                  child: Text('Flight duration',
                      style: TextStyle(
                          fontSize: 11, color: colors.onSurfaceVariant)),
                ),
                _DurationBadge(
                    label: _duration(startDt, endDt), colors: colors),
              ],
            ),
          ],
          if (canSet) ...[
            const SizedBox(height: 6),
            _ActionButton(
              label:     'Record $label',
              onPressed: _isProcessing ? null : () => _setStep(step),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCompleteStep(ColorScheme colors) {
    return _StepWrapper(
      icon:       Icons.check_circle_outline,
      isDone:     _isCompleted,
      isActive:   _canComplete,
      isLast:     true,
      lineHeight: 56,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Complete operation',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: _isCompleted || _canComplete
                    ? colors.onSurface
                    : colors.onSurfaceVariant,
              )),
          if (_canComplete) ...[
            const SizedBox(height: 6),
            _ActionButton(
              label:      'Mark as completed',
              onPressed:  _isProcessing ? null : _completeOperation,
              isComplete: true,
            ),
          ],
        ],
      ),
    );
  }

  Widget _statusBanner(String text, Color color, ColorScheme colors) {
    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, size: 14, color: color),
          const SizedBox(width: 8),
          Text(text,
              style: TextStyle(
                  fontSize: 12,
                  color: color,
                  fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  void _confirmCancel() {
    OperationStateDialog.show(
      context,
      apiService: widget.apiService,
      isCancel:   true,
      onConfirm:  (stateId, customReason) async {
        setState(() => _isProcessing = true);
        final updated = await widget.apiService.cancelOperation(
          _op.flightOperationId,
          stateId:      stateId,
          customReason: customReason,
        );
        if (mounted) {
          setState(() {
            if (updated != null) _op = updated;
            _isProcessing = false;
          });
          if (updated != null) {
            widget.onOperationUpdated(updated);
            await widget.apiService.authService.refreshSession();
          }
        }
      },
    );
  }

  Future<void> _completeOperation() async {
    OperationStateDialog.show(
      context,
      apiService: widget.apiService,
      isCancel:   false,
      onConfirm:  (stateId, customReason) async {
        setState(() => _isProcessing = true);
        final updated = await widget.apiService.completeOperation(
          _op.flightOperationId,
          stateId:      stateId,
          customReason: customReason,
        );
        if (mounted) {
          setState(() {
            if (updated != null) _op = updated;
            _isProcessing = false;
          });
          if (updated != null) {
            widget.onOperationUpdated(updated);
            await widget.apiService.authService.refreshSession();
          }
        }
      },
    );
  }
}

class _StepWrapper extends StatelessWidget {
  final IconData icon;
  final bool     isDone;
  final bool     isActive;
  final bool     isLast;
  final double   lineHeight;
  final Widget   child;

  const _StepWrapper({
    required this.icon,
    required this.isDone,
    required this.isActive,
    required this.isLast,
    required this.lineHeight,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    final dotColor = isDone
        ? Colors.green
        : isActive
            ? colors.primary
            : colors.onSurfaceVariant.withValues(alpha: 0.3);

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
                        ? colors.primaryContainer.withValues(alpha: 0.35)
                        : colors.surfaceContainerHighest,
                border: Border.all(color: dotColor, width: 1.5),
              ),
              child: Icon(isDone ? Icons.check : icon,
                  size: 14, color: dotColor),
            ),
            if (!isLast)
              Container(
                width: 2,
                height: lineHeight,
                color: isDone
                    ? Colors.green.withValues(alpha: 0.3)
                    : colors.outlineVariant,
              ),
          ],
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Padding(
            padding: EdgeInsets.only(top: 6, bottom: isLast ? 0 : 12),
            child: child,
          ),
        ),
      ],
    );
  }
}

class _LiveTimer extends StatelessWidget {
  final DateTime    start;
  final DateTime    now;
  final ColorScheme colors;

  const _LiveTimer({
    required this.start,
    required this.now,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    final diff  = now.difference(start);
    final h     = diff.inHours;
    final m     = diff.inMinutes % 60;
    final s     = diff.inSeconds % 60;
    final label = h > 0
        ? '${h}h ${m.toString().padLeft(2, '0')}m'
        : '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';

    return Row(
      children: [
        Icon(Icons.timer_outlined, size: 12, color: colors.primary),
        const SizedBox(width: 4),
        Text(label,
            style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: colors.primary)),
        const SizedBox(width: 4),
        Text('in progress',
            style: TextStyle(fontSize: 11, color: colors.onSurfaceVariant)),
      ],
    );
  }
}

class _DurationBadge extends StatelessWidget {
  final String      label;
  final ColorScheme colors;

  const _DurationBadge({required this.label, required this.colors});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.green.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.timer_outlined, size: 11, color: Colors.green),
          const SizedBox(width: 3),
          Text(label,
              style: const TextStyle(
                  fontSize: 11,
                  color: Colors.green,
                  fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}


class _ActionButton extends StatelessWidget {
  final String        label;
  final VoidCallback? onPressed;
  final bool          isComplete;

  const _ActionButton({
    required this.label,
    required this.onPressed,
    this.isComplete = false,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 8),
          side: BorderSide(
            color: isComplete
                ? Colors.green.withValues(alpha: 0.6)
                : colors.primary.withValues(alpha: 0.5),
          ),
          foregroundColor: isComplete ? Colors.green : colors.primary,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isComplete
                  ? Icons.check_circle_outline
                  : Icons.access_time_outlined,
              size: 14,
            ),
            const SizedBox(width: 6),
            Text(label,
                style: const TextStyle(
                    fontSize: 12, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}