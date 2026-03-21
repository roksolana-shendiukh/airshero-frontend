import 'package:flutter/material.dart';

class PaymentStatusSelector extends StatelessWidget {
  final String selectedStatus; // 'paid' або 'partially_paid'
  final ValueChanged<String> onStatusChanged;
  final double totalAmount;

  const PaymentStatusSelector({
    super.key,
    required this.selectedStatus,
    required this.onStatusChanged,
    required this.totalAmount,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Payment Status',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          
          // Paid
          InkWell(
            onTap: () => onStatusChanged('paid'),
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: selectedStatus == 'paid'
                    ? Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.3)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: selectedStatus == 'paid'
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
                  width: selectedStatus == 'paid' ? 2 : 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    selectedStatus == 'paid'
                        ? Icons.radio_button_checked
                        : Icons.radio_button_unchecked,
                    color: selectedStatus == 'paid'
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Paid',
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          'Fully paid (\$${totalAmount.toStringAsFixed(2)})',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (selectedStatus == 'paid')
                    Icon(
                      Icons.check_circle,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 12),
          
          // Partially Paid
          InkWell(
            onTap: () => onStatusChanged('partially_paid'),
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: selectedStatus == 'partially_paid'
                    ? Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.3)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: selectedStatus == 'partially_paid'
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
                  width: selectedStatus == 'partially_paid' ? 2 : 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    selectedStatus == 'partially_paid'
                        ? Icons.radio_button_checked
                        : Icons.radio_button_unchecked,
                    color: selectedStatus == 'partially_paid'
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Partially Paid',
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          'Deposit now, complete later',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (selectedStatus == 'partially_paid')
                    Icon(
                      Icons.check_circle,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}