import 'dart:async';
import 'package:flutter/material.dart';

class BookingProgressHeader extends StatefulWidget {
  final String fromCity;
  final String toCity;
  final DateTime departDate;
  final DateTime? returnDate;
  final int totalPassengers;
  final String flightClass;
  final String currentStep;
  final VoidCallback? onBack;
  final VoidCallback? onForward;
  final String? airlineName;
  final String? selectedBaggage;
  final int? baggageCount;
  final DateTime? expiresAt;
  final VoidCallback? onExpired;

  const BookingProgressHeader({
    super.key,
    required this.fromCity,
    required this.toCity,
    required this.departDate,
    this.returnDate,
    required this.totalPassengers,
    required this.flightClass,
    required this.currentStep,
    this.onBack,
    this.onForward,
    this.airlineName,
    this.selectedBaggage,
    this.baggageCount,
    this.expiresAt,
    this.onExpired,
  });

  @override
  State<BookingProgressHeader> createState() => _BookingProgressHeaderState();
}

class _BookingProgressHeaderState extends State<BookingProgressHeader> {
  Timer? _timer;
  Duration _timeLeft = Duration.zero;
  bool _isExpired = false;

  bool get _showTimer =>
      widget.expiresAt != null &&
      (widget.currentStep == 'baggage' || widget.currentStep == 'payment');

  @override
  void initState() {
    debugPrint('BookingProgressHeader: expiresAt=${widget.expiresAt}, currentStep=${widget.currentStep}, showTimer=$_showTimer');
  
    super.initState();
    if (_showTimer) _startTimer();
  }

  @override
  void didUpdateWidget(BookingProgressHeader oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.expiresAt != oldWidget.expiresAt && _showTimer) {
      _timer?.cancel();
      _startTimer();
    }
  }

  void _startTimer() {
    _updateTimeLeft();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      _updateTimeLeft();
    });
  }

  void _updateTimeLeft() {
    if (widget.expiresAt == null) return;
    final now = DateTime.now();
    final diff = widget.expiresAt!.difference(now);
    setState(() {
      if (diff.isNegative) {
        _timeLeft = Duration.zero;
        _isExpired = true;
        _timer?.cancel();
        widget.onExpired?.call();
      } else {
        _timeLeft = diff;
        _isExpired = false;
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String _formatDate(DateTime date) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[date.month - 1]} ${date.day}';
  }

  List<String> _getProgressSteps() {
    switch (widget.currentStep) {
      case 'search':
        return ['Select Flight'];
      case 'baggage':
        return ['Flight Selected', 'Select Baggage'];
      case 'passengers':
        return ['Flight Selected', 'Baggage Selected', 'Enter Details'];
      case 'payment':
        return ['Flight Selected', 'Baggage Selected', 'Details Entered', 'Payment'];
      default:
        return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final isRoundTrip = widget.returnDate != null;
    final steps = _getProgressSteps();

    final isUrgent = !_isExpired &&
        _timeLeft.inSeconds > 0 &&
        _timeLeft.inSeconds < 120;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surfaceContainerHigh,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (widget.onBack != null)
                IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: widget.onBack,
                  tooltip: 'Back',
                ),

              const SizedBox(width: 4),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${widget.fromCity} → ${widget.toCity}',
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Wrap(
                      spacing: 4,
                      runSpacing: 4,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          '${_formatDate(widget.departDate)}${isRoundTrip ? ' - ${_formatDate(widget.returnDate!)}' : ''}',
                          style: textTheme.bodySmall?.copyWith(
                            color: colors.onSurfaceVariant,
                          ),
                        ),
                        Text(' • ',
                            style: textTheme.bodySmall
                                ?.copyWith(color: colors.onSurfaceVariant)),
                        Text(
                          '${widget.totalPassengers} passenger${widget.totalPassengers > 1 ? 's' : ''}',
                          style: textTheme.bodySmall?.copyWith(
                            color: colors.onSurfaceVariant,
                          ),
                        ),
                        Text(' • ',
                            style: textTheme.bodySmall
                                ?.copyWith(color: colors.onSurfaceVariant)),
                        Text(
                          widget.flightClass,
                          style: textTheme.bodySmall?.copyWith(
                            color: colors.onSurfaceVariant,
                          ),
                        ),
                        if (widget.baggageCount != null &&
                            widget.baggageCount! > 0) ...[
                          Text(' • ',
                              style: textTheme.bodySmall?.copyWith(
                                  color: colors.onSurfaceVariant)),
                          Icon(Icons.luggage,
                              size: 14, color: colors.primary),
                          const SizedBox(width: 2),
                          Text(
                            '${widget.baggageCount} bag${widget.baggageCount! > 1 ? 's' : ''}',
                            style: textTheme.bodySmall?.copyWith(
                              color: colors.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                        if (widget.airlineName != null) ...[
                          Text(' • ',
                              style: textTheme.bodySmall?.copyWith(
                                  color: colors.onSurfaceVariant)),
                          Icon(Icons.flight,
                              size: 14, color: colors.primary),
                          const SizedBox(width: 2),
                          Text(
                            widget.airlineName!,
                            style: textTheme.bodySmall?.copyWith(
                              color: colors.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),

              // Таймер — показується тільки на baggage і payment кроках
              if (_showTimer) ...[
                const SizedBox(width: 12),
                _buildTimer(colors, textTheme, isUrgent),
              ],

              if (widget.onForward != null)
                IconButton(
                  icon: const Icon(Icons.arrow_forward),
                  onPressed: widget.onForward,
                  tooltip: 'Continue',
                ),
            ],
          ),

          const SizedBox(height: 12),

          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: steps.asMap().entries.map((entry) {
              final index = entry.key;
              final step = entry.value;
              final isLast = index == steps.length - 1;

              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: isLast
                          ? colors.primaryContainer
                          : colors.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isLast
                            ? colors.primary
                            : colors.outline.withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (!isLast) ...[
                          Icon(Icons.check_circle,
                              size: 16, color: colors.primary),
                          const SizedBox(width: 4),
                        ],
                        Text(
                          step,
                          style: textTheme.bodySmall?.copyWith(
                            fontWeight: isLast
                                ? FontWeight.bold
                                : FontWeight.normal,
                            color: isLast
                                ? colors.onPrimaryContainer
                                : colors.onSurface,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (!isLast)
                    Icon(
                      Icons.arrow_forward_ios,
                      size: 12,
                      color: colors.onSurfaceVariant,
                    ),
                ],
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildTimer(
      ColorScheme colors, TextTheme textTheme, bool isUrgent) {
    final minutes = _timeLeft.inMinutes;
    final seconds = (_timeLeft.inSeconds % 60).toString().padLeft(2, '0');
    final timeString = '$minutes:$seconds';

    final Color bgColor;
    final Color borderColor;
    final Color textColor;
    final Color iconColor;

    if (_isExpired) {
      bgColor = colors.errorContainer;
      borderColor = colors.error;
      textColor = colors.onErrorContainer;
      iconColor = colors.error;
    } else if (isUrgent) {
      bgColor = colors.errorContainer.withOpacity(0.5);
      borderColor = colors.error.withOpacity(0.6);
      textColor = colors.error;
      iconColor = colors.error;
    } else {
      bgColor = colors.primaryContainer.withOpacity(0.4);
      borderColor = colors.primary.withOpacity(0.3);
      textColor = colors.primary;
      iconColor = colors.primary;
    }

    return Tooltip(
      message: _isExpired
          ? 'Booking expired'
          : 'Time remaining to complete payment',
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: borderColor),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _isExpired
                  ? Icons.timer_off_outlined
                  : Icons.timer_outlined,
              size: 16,
              color: iconColor,
            ),
            const SizedBox(width: 6),
            Text(
              _isExpired ? 'Expired' : timeString,
              style: textTheme.labelMedium?.copyWith(
                color: textColor,
                fontWeight: FontWeight.w700,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ],
        ),
      ),
    );
  }
}