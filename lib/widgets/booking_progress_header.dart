import 'package:flutter/material.dart';

class BookingProgressHeader extends StatelessWidget {
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
    final isRoundTrip = returnDate != null;
    final steps = _getProgressSteps();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHigh,
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
                      '$fromCity → $toCity',
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
                        Text(
                          '${_formatDate(departDate)}${isRoundTrip ? ' - ${_formatDate(returnDate!)}' : ''}',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                        Text(
                          ' • ',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                        Text(
                          '$totalPassengers passenger${totalPassengers > 1 ? 's' : ''}',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                        Text(
                          ' • ',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                        Text(
                          flightClass,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                        if (baggageCount != null && baggageCount! > 0) ...[
                          Text(
                            ' • ',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                          ),
                          Icon(
                            Icons.luggage,
                            size: 14,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          const SizedBox(width: 2),
                          Text(
                            '$baggageCount bag${baggageCount! > 1 ? 's' : ''}',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).colorScheme.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                        if (airlineName != null) ...[
                          Text(
                            ' • ',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                          ),
                          Icon(
                            Icons.flight,
                            size: 14,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          const SizedBox(width: 2),
                          Text(
                            airlineName!,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              
              if (onForward != null)
                IconButton(
                  icon: const Icon(Icons.arrow_forward),
                  onPressed: onForward,
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
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: isLast 
                          ? Theme.of(context).colorScheme.primaryContainer
                          : Theme.of(context).colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isLast
                            ? Theme.of(context).colorScheme.primary
                            : Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (!isLast)
                          Icon(
                            Icons.check_circle,
                            size: 16,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        if (!isLast) const SizedBox(width: 4),
                        Text(
                          step,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            fontWeight: isLast ? FontWeight.bold : FontWeight.normal,
                            color: isLast 
                                ? Theme.of(context).colorScheme.onPrimaryContainer
                                : Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (!isLast)
                    Icon(
                      Icons.arrow_forward_ios,
                      size: 12,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                ],
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}