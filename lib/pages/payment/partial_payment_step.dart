import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../widgets/custom/custom_input_field.dart';
import 'payment_method_selector.dart';

class PartialPaymentStep extends StatelessWidget {
  final int index;
  final double maxAllowed;
  final double totalPrice;
  final double? currentAmount;
  final int? selectedMethodId;
  final List<Map<String, dynamic>> paymentMethods;
  final bool isDisabled;
  final Function(double) onAmountChanged;
  final Function(int) onMethodSelected;

  const PartialPaymentStep({
    super.key,
    required this.index,
    required this.maxAllowed,
    required this.totalPrice,
    required this.currentAmount,
    required this.selectedMethodId,
    required this.paymentMethods,
    this.isDisabled = false,
    required this.onAmountChanged,
    required this.onMethodSelected,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final bool isFullPayment = currentAmount != null &&
        (currentAmount! - maxAllowed).abs() < 0.01 &&
        maxAllowed == totalPrice;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDisabled ? colors.surfaceContainerLowest : colors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Payment Part #${index + 1}',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),

          Opacity(
            opacity: isDisabled ? 0.5 : 1.0,
            child: IgnorePointer(
              ignoring: isDisabled,
              child: CustomInputField(
                label: 'Amount (Max \$${maxAllowed.toStringAsFixed(2)})',
                value: currentAmount != null && currentAmount! > 0
                    ? currentAmount!.toStringAsFixed(2)
                    : '',
                icon: Icons.attach_money,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                ],
                onChanged: (val) {
                  double parsed = double.tryParse(val) ?? 0;
                  onAmountChanged(parsed > maxAllowed ? maxAllowed : parsed);
                },
              ),
            ),
          ),

          if (isFullPayment)
            Container(
              width: double.infinity,
              margin: const EdgeInsets.only(top: 8),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.yellow.shade100,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: Colors.orange.shade300),
              ),
              child: Text(
                'This is a full payment. Further parts are disabled.',
                style: TextStyle(color: Colors.orange.shade900, fontSize: 12),
              ),
            ),

          const SizedBox(height: 16),
          const Text('Method for this part:', style: TextStyle(fontSize: 12)),
          const SizedBox(height: 8),
          IgnorePointer(
            ignoring: isDisabled,
            child: PaymentMethodSelector(
              methods: paymentMethods,
              selectedId: selectedMethodId,
              onSelected: onMethodSelected,
            ),
          ),
        ],
      ),
    );
  }
}