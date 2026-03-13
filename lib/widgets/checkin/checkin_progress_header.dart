import 'package:flutter/material.dart';

class CheckInProgressHeader extends StatelessWidget {
  final String currentStep;
  final VoidCallback? onBack;

  final String? documentNumber;
  final String? flightNumber;
  final DateTime? departDate;
  final String? passengerName;
  final String? flightClass;
  final String? selectedSeat;
  final int? baggageCount;
  final bool hasExtraPayment;

  const CheckInProgressHeader({
    super.key,
    required this.currentStep,
    this.onBack,
    this.documentNumber,
    this.flightNumber,
    this.departDate,
    this.passengerName,
    this.flightClass,
    this.selectedSeat,
    this.baggageCount,
    this.hasExtraPayment = false,
  });

  String _formatDate(DateTime date) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[date.month - 1]} ${date.day}';
  }

  List<String> _getProgressSteps() {
    switch (currentStep) {
      case 'search':
        return ['Find Booking'];
      case 'confirmPassenger':
        return ['Booking Found', 'Confirm Passenger'];
      case 'selectSeat':
        return ['Booking Found', 'Passenger Confirmed', 'Select Seat'];
      case 'baggage':
        return ['Booking Found', 'Passenger Confirmed', 'Seat Selected', 'Baggage'];
      case 'payment':
        return ['Booking Found', 'Passenger Confirmed', 'Seat Selected', 'Baggage Done', 'Payment'];
      case 'boardingPass':
        return ['Booking Found', 'Passenger Confirmed', 'Seat Selected', 'Baggage Done', 'Boarding Pass'];
      default:
        return ['Find Booking'];
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final steps  = _getProgressSteps();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surfaceContainerHigh,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Top row: back button + summary info ─────────────────────────
          Row(
            children: [
              if (onBack != null)
                IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: onBack,
                  tooltip: 'Back',
                ),

              const SizedBox(width: 8),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Check-In',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    const SizedBox(height: 2),
                    Wrap(
                      spacing: 4,
                      runSpacing: 4,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        // Flight number
                        if (flightNumber != null) ...[
                          Icon(Icons.flight, size: 14, color: colors.primary),
                          const SizedBox(width: 2),
                          Text(
                            flightNumber!,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: colors.onSurfaceVariant,
                                ),
                          ),
                        ],

                        // Depart date
                        if (departDate != null) ...[
                          Text(' • ',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: colors.onSurfaceVariant,
                                  )),
                          Text(
                            _formatDate(departDate!),
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: colors.onSurfaceVariant,
                                ),
                          ),
                        ],

                        // Passenger name
                        if (passengerName != null) ...[
                          Text(' • ',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: colors.onSurfaceVariant,
                                  )),
                          Icon(Icons.person_outline, size: 14, color: colors.primary),
                          const SizedBox(width: 2),
                          Text(
                            passengerName!,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: colors.onSurfaceVariant,
                                ),
                          ),
                        ],

                        // Class
                        if (flightClass != null) ...[
                          Text(' • ',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: colors.onSurfaceVariant,
                                  )),
                          Text(
                            flightClass!,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: colors.onSurfaceVariant,
                                ),
                          ),
                        ],

                        // Seat
                        if (selectedSeat != null) ...[
                          Text(' • ',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: colors.onSurfaceVariant,
                                  )),
                          Icon(Icons.airline_seat_recline_normal_outlined,
                              size: 14, color: colors.primary),
                          const SizedBox(width: 2),
                          Text(
                            'Seat $selectedSeat',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: colors.onSurfaceVariant,
                                ),
                          ),
                        ],

                        // Baggage
                        if (baggageCount != null && baggageCount! > 0) ...[
                          Text(' • ',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: colors.onSurfaceVariant,
                                  )),
                          Icon(Icons.luggage, size: 14, color: colors.primary),
                          const SizedBox(width: 2),
                          Text(
                            '$baggageCount bag${baggageCount! > 1 ? 's' : ''}',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: colors.primary,
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // ── Step chips ───────────────────────────────────────────────────
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: steps.asMap().entries.map((entry) {
              final index  = entry.key;
              final step   = entry.value;
              final isLast = index == steps.length - 1;

              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: isLast
                          ? colors.primaryContainer
                          : colors.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isLast
                            ? colors.primary
                            : colors.outline.withValues(alpha: 0.3),
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
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                fontWeight:
                                    isLast ? FontWeight.bold : FontWeight.normal,
                                color: isLast
                                    ? colors.onPrimaryContainer
                                    : colors.onSurface,
                              ),
                        ),
                      ],
                    ),
                  ),
                  if (!isLast)
                    Icon(Icons.arrow_forward_ios,
                        size: 12, color: colors.onSurfaceVariant),
                ],
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}