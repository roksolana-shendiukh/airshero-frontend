import 'package:flutter/material.dart';

class PartialPayment {
  double amount;
  int? paymentMethodId;
  TextEditingController controller;

  PartialPayment({double? amount, this.paymentMethodId, String? initialValue})
      : amount = amount ?? 0,
        controller = TextEditingController(text: initialValue ?? (amount?.toStringAsFixed(2) ?? '0'));
}