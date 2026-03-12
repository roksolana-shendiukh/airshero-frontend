import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../widgets/custom/custom_input_field.dart';
import 'payment_method_selector.dart';

class PartialPaymentStep extends StatefulWidget {
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
  State<PartialPaymentStep> createState() => _PartialPaymentStepState();
}

class _PartialPaymentStepState extends State<PartialPaymentStep> {
  late final TextEditingController _controller;
  String? _amountError;

  @override
  void initState() {
    super.initState();
    final initial = widget.currentAmount != null && widget.currentAmount! > 0
        ? widget.currentAmount!.toStringAsFixed(2)
        : '';
    _controller = TextEditingController(text: initial);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onAmountChanged(String val) {
    if (val.isEmpty) {
      setState(() => _amountError = null);
      widget.onAmountChanged(0);
      return;
    }

    final parsed = double.tryParse(val);
    if (parsed == null) {
      setState(() => _amountError = 'Invalid number');
      return;
    }

    if (parsed > widget.maxAllowed) {
      setState(() => _amountError =
          'Amount exceeds remaining \$${widget.maxAllowed.toStringAsFixed(2)}');
      widget.onAmountChanged(0);
      return;
    }

    setState(() => _amountError = null);
    widget.onAmountChanged(parsed);
  }

  void _onEditingComplete() {
    final val = _controller.text;
    if (val.isEmpty) return;
    final parsed = double.tryParse(val);
    if (parsed == null || parsed > widget.maxAllowed) return;
    final formatted = parsed.toStringAsFixed(2);
    _controller.value = TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
    widget.onAmountChanged(parsed);
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final remaining = widget.maxAllowed;
    final isLastStep = widget.currentAmount != null &&
        (widget.currentAmount! - remaining).abs() < 0.01 &&
        remaining < widget.totalPrice;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: widget.isDisabled ? colors.surfaceContainerLowest : colors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Payment Part #${widget.index + 1}',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            'Remaining to pay: \$${remaining.toStringAsFixed(2)}',
            style: TextStyle(fontSize: 12, color: colors.onSurfaceVariant),
          ),
          const SizedBox(height: 12),

          Opacity(
            opacity: widget.isDisabled ? 0.5 : 1.0,
            child: IgnorePointer(
              ignoring: widget.isDisabled,
              child: CustomInputField(
                label: 'Amount (max \$${remaining.toStringAsFixed(2)})',
                value: _controller.text, // не змінюється ззовні
                icon: Icons.attach_money,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                ],
                errorText: _amountError,
                onChanged: _onAmountChanged,
                onEditingComplete: _onEditingComplete,
              ),
            ),
          ),

          
          const SizedBox(height: 16),
          Text('Method for this part:',
              style: TextStyle(fontSize: 12, color: colors.onSurfaceVariant)),
          const SizedBox(height: 8),
          IgnorePointer(
            ignoring: widget.isDisabled,
            child: PaymentMethodSelector(
              methods: widget.paymentMethods,
              selectedId: widget.selectedMethodId,
              onSelected: widget.onMethodSelected,
            ),
          ),
        ],
      ),
    );
  }
}





