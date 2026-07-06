import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../services/checkin_api_service.dart';
import '../../widgets/custom/custom_button.dart';
import 'payment_method_selector.dart';
import 'partial_payment_step.dart';

class CheckInPaymentStep extends StatefulWidget {
  final AuthService authService;
    final int bookingItemId;
  final int seatLayoutId;
  final int flightOperationId;
  final List<Map<String, dynamic>> bags;
  final double totalSurcharge;
  final String passengerName;
  final String flightNumber;
  final String flightClass;
  final String seat;
  final int bagCount;
  final void Function(String ticketNumber, int boardingPassId, List<Map<String, dynamic>> bags) onSuccess;

  const CheckInPaymentStep({
    super.key,
    required this.authService,
    required this.bookingItemId,
    required this.seatLayoutId,
    required this.flightOperationId,
    required this.bags,
    required this.totalSurcharge,
    required this.passengerName,
    required this.flightNumber,
    required this.flightClass,
    required this.seat,
    required this.bagCount,
    required this.onSuccess,
  });

  @override
  State<CheckInPaymentStep> createState() => _CheckInPaymentStepState();
}

class _CheckInPaymentStepState extends State<CheckInPaymentStep> {
  List<Map<String, dynamic>> _paymentMethods = [];
  List<Map<String, dynamic>> _issuedBags     = [];
  bool _isLoadingMethods = true;
  bool _isProcessing     = false;

  bool _isPartialPayment      = false;
  int? _singlePaymentMethodId;

  List<Map<String, dynamic>> _partialPayments = [
    {'amount': 0.0, 'methodId': null},
  ];

  @override
  void initState() {
    super.initState();
    _loadMethods();
  }

  Future<void> _loadMethods() async {
    try {
      final api     = CheckInApiService(widget.authService);
      final methods = await api.getPaymentMethods();
      if (!mounted) return;
      setState(() {
        _paymentMethods   = methods;
        _isLoadingMethods = false;
      });
    } catch (_) {
      if (mounted) setState(() => _isLoadingMethods = false);
    }
  }

  void _handleAmountChanged(int index, double amount) {
    setState(() {
      _partialPayments[index]['amount'] = amount;
      _partialPayments.removeRange(index + 1, _partialPayments.length);
      final paid = _partialPayments.fold(0.0, (s, p) => s + (p['amount'] as double));
      if (amount > 0 && paid < widget.totalSurcharge - 0.01) {
        _partialPayments.add({'amount': 0.0, 'methodId': null});
      }
    });
  }

  String? get _disabledReason {
    if (_isPartialPayment) {
      final hasZero     = _partialPayments.any((p) => (p['amount'] as double) <= 0);
      final hasNoMethod = _partialPayments.any((p) => p['methodId'] == null);
      final paid        = _partialPayments.fold(0.0, (s, p) => s + (p['amount'] as double));
      final notCovered  = (paid - widget.totalSurcharge).abs() > 0.01 && paid < widget.totalSurcharge;
      if (hasZero)     return 'Enter amount for each payment part';
      if (hasNoMethod) return 'Select payment method for each part';
      if (notCovered)  return 'Total does not cover \$${widget.totalSurcharge.toStringAsFixed(2)}';
    } else {
      if (_singlePaymentMethodId == null) return 'Select a payment method';
    }
    return null;
  }

  Future<void> _confirm(String status) async {
    setState(() => _isProcessing = true);
    try {
      final api      = CheckInApiService(widget.authService);
      final methodId = _isPartialPayment
          ? _partialPayments.first['methodId'] as int?
          : _singlePaymentMethodId;

      final result = await api.issueWithBaggage(
        bookingItemId:     widget.bookingItemId,
        seatLayoutId:      widget.seatLayoutId,
        flightOperationId: widget.flightOperationId,
        bags:              widget.bags,
        paymentMethodId:   methodId,
        totalSurcharge:    widget.totalSurcharge,
        status:            status,
      );

      if (!mounted) return;

      setState(() {
        _isProcessing = false;
        _issuedBags   = List<Map<String, dynamic>>.from(result['bags'] ?? []);
      });

      if (status == 'Failed') {
        _showFailedDialog();
      } else {
        _showSuccessDialog(
          result['ticket_number']    as String,
          result['boarding_pass_id'] as int,
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isProcessing = false);
      _showErrorDialog(e.toString().replaceAll('Exception: ', ''));
    }
  }

  void _showSuccessDialog(String ticketNumber, int boardingPassId) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        final colors = Theme.of(ctx).colorScheme;
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: SizedBox(
            width: 320,
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.check_circle, color: Colors.green, size: 56),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Payment Successful',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Boarding pass issued for ${widget.passengerName}',
                    style: TextStyle(color: colors.onSurfaceVariant, fontSize: 13),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: CustomButton(
                      label: 'Done',
                      onPressed: () {
                        Navigator.of(ctx).pop();
                        widget.onSuccess(ticketNumber, boardingPassId, _issuedBags);
                      },
                      borderRadius: 12,
                      verticalPadding: 14,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
  
  void _showFailedDialog() {
    showDialog(
      context:            context,
      barrierDismissible: false,
      builder: (ctx) {
        final colors = Theme.of(ctx).colorScheme;
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: colors.error.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.cancel, color: colors.error, size: 64),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Payment Failed',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  'Payment for ${widget.passengerName} was marked as failed.',
                  style: TextStyle(color: colors.onSurfaceVariant),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: CustomButton(
                    label: 'Close',
                    onPressed: () => Navigator.of(ctx).pop(),
                    borderRadius:    12,
                    verticalPadding: 14,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (ctx) {
        final colors = Theme.of(ctx).colorScheme;
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          title: Row(
            children: [
              Icon(Icons.error_outline, color: colors.error),
              const SizedBox(width: 8),
              const Text('Error'),
            ],
          ),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color:        colors.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(8),
              border:       Border.all(color: colors.outline.withValues(alpha: 0.12)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.person_outline, size: 14, color: colors.onSurfaceVariant),
                    const SizedBox(width: 6),
                    Text(widget.passengerName,
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                  ],
                ),
                const SizedBox(height: 10),
                const Divider(height: 1),
                const SizedBox(height: 10),
                _InfoRow(label: 'Flight', value: widget.flightNumber),
                const SizedBox(height: 6),
                _InfoRow(label: 'Class',  value: widget.flightClass),
                const SizedBox(height: 6),
                _InfoRow(label: 'Seat',   value: widget.seat),
                const SizedBox(height: 6),
                _InfoRow(
                  label: 'Bags',
                  value: '${widget.bagCount} bag${widget.bagCount == 1 ? '' : 's'}',
                ),
                const SizedBox(height: 10),
                const Divider(height: 1),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Excess surcharge',
                        style: TextStyle(fontSize: 12, color: colors.onSurfaceVariant)),
                    Text(
                      '\$${widget.totalSurcharge.toStringAsFixed(2)}',
                      style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFFE65100)),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          Row(
            children: [
              Switch(
                value:     _isPartialPayment,
                onChanged: (v) => setState(() {
                  _isPartialPayment = v;
                  _partialPayments  = [{'amount': 0.0, 'methodId': null}];
                }),
              ),
              const SizedBox(width: 8),
              Text('Partial Payment', style: TextStyle(color: colors.onSurface)),
            ],
          ),

          const SizedBox(height: 12),

          if (_isLoadingMethods)
            const Center(child: CircularProgressIndicator())
          else if (_isPartialPayment)
            ..._partialPayments.asMap().entries.map((e) {
              final idx       = e.key;
              final paid      = _partialPayments
                  .sublist(0, idx)
                  .fold(0.0, (s, p) => s + (p['amount'] as double));
              final remaining = widget.totalSurcharge - paid;
              return PartialPaymentStep(
                index:            idx,
                maxAllowed:       remaining,
                totalPrice:       widget.totalSurcharge,
                currentAmount:    e.value['amount'] as double?,
                selectedMethodId: e.value['methodId'] as int?,
                paymentMethods:   _paymentMethods,
                isDisabled: idx > 0 &&
                    (_partialPayments[idx - 1]['amount'] as double) <= 0,
                onAmountChanged:  (v) => _handleAmountChanged(idx, v),
                onMethodSelected: (id) =>
                    setState(() => _partialPayments[idx]['methodId'] = id),
              );
            })
          else
            PaymentMethodSelector(
              methods:    _paymentMethods,
              selectedId: _singlePaymentMethodId,
              onSelected: (id) => setState(() => _singlePaymentMethodId = id),
            ),

          const SizedBox(height: 24),

          if (_isProcessing)
            const Center(
              child: Padding(
                padding: EdgeInsets.only(bottom: 16),
                child:   CircularProgressIndicator(),
              ),
            ),

          Row(
            children: [
              Expanded(
                child: Tooltip(
                  message: _disabledReason ?? '',
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: colors.errorContainer,
                      foregroundColor: colors.onErrorContainer,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    icon:      const Icon(Icons.cancel_outlined),
                    label:     const Text('Failed'),
                    onPressed: (!_isProcessing && _disabledReason == null)
                        ? () => _confirm('Failed')
                        : null,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Tooltip(
                  message: _disabledReason ?? '',
                  child: CustomButton(
                    label: _isPartialPayment ? 'Confirm Partial' : 'Confirm Payment',
                    onPressed: (!_isProcessing && _disabledReason == null)
                        ? () => _confirm('Paid')
                        : null,
                    borderRadius:    12,
                    verticalPadding: 16,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: TextStyle(fontSize: 12, color: colors.onSurfaceVariant)),
        Text(value,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
      ],
    );
  }
}