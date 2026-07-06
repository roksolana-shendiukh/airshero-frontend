import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class PaymentMethodSelector extends StatelessWidget {
  final List<Map<String, dynamic>> methods;
  final int? selectedId;
  final bool isExpired;
  final bool isLoading;
  final Function(int) onSelected;

  const PaymentMethodSelector({
    super.key,
    required this.methods,
    required this.selectedId,
    required this.onSelected,
    this.isExpired = false,
    this.isLoading = false,
  });

  IconData _getIcon(String name) {
    switch (name.trim().toLowerCase()) {
      case 'cash':
        return Icons.payments_outlined;
      case 'credit card':
        return Icons.credit_card;
      case 'debit card':
        return Icons.credit_card_outlined;
      case 'bank transfer':
        return Icons.account_balance_outlined;
      default:
        return Icons.payment;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    if (isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (methods.isEmpty) {
      return Text(
        'No payment methods available',
        style: TextStyle(color: colors.onSurfaceVariant),
      );
    }

    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: methods.map((method) {
        final id   = method['payment_method_id']   as int;
        final name = method['payment_method_name'] as String;
        final isSelected = selectedId == id;

        return InkWell(
          onTap: isExpired
              ? null
              : () {
                  HapticFeedback.lightImpact();
                  onSelected(id);
                },
          borderRadius: BorderRadius.circular(10),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isSelected 
                  ? colors.primaryContainer 
                  : colors.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isSelected ? colors.primary : Colors.transparent,
                width: 2,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: colors.primary.withValues(alpha: 0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      )
                    ]
                  : null,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _getIcon(name),
                  size: 20,
                  color: isSelected
                      ? colors.onPrimaryContainer
                      : colors.onSurfaceVariant,
                ),
                const SizedBox(width: 8),
                Text(
                  name,
                  style: TextStyle(
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    color: isSelected
                        ? colors.onPrimaryContainer
                        : colors.onSurface,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}