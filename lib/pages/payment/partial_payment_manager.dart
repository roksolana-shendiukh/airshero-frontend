import 'package:flutter/material.dart';
import 'partial_payment_step.dart';

class PartialPaymentManager extends StatelessWidget {
  final double totalPrice;
  final List<Map<String, dynamic>> payments;
  final List<Map<String, dynamic>> paymentMethods;
  final Function(int, double) onAmountChanged;
  final Function(int, int) onMethodSelected;

  const PartialPaymentManager({
    super.key,
    required this.totalPrice,
    required this.payments,
    required this.paymentMethods,
    required this.onAmountChanged,
    required this.onMethodSelected,
  });

  double _getRemainingAfter(int index) {
    double totalPaidBefore = 0;
    for (int i = 0; i < index; i++) {
      totalPaidBefore += (payments[i]['amount'] as double? ?? 0);
    }
    return double.parse((totalPrice - totalPaidBefore).toStringAsFixed(2));
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(payments.length, (index) {
        final maxAllowed = _getRemainingAfter(index);
        final currentAmount = payments[index]['amount'] as double?;
        
        bool isBlocked = false;
        if (index > 0) {
          final previousAmount = payments[index - 1]['amount'] as double? ?? 0;
          if (previousAmount <= 0) isBlocked = true;
        }

        return PartialPaymentStep(
          index: index,
          maxAllowed: maxAllowed,
          totalPrice: totalPrice,
          currentAmount: currentAmount,
          selectedMethodId: payments[index]['methodId'],
          paymentMethods: paymentMethods,
          isDisabled: isBlocked,
          onAmountChanged: (val) => onAmountChanged(index, val),
          onMethodSelected: (id) => onMethodSelected(index, id),
        );
      }),
    );
  }
}