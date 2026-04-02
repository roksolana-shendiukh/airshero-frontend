import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../services/auth_service.dart';
import '../../services/checkin_api_service.dart';
import '../custom/custom_button.dart';
import '../custom/custom_input_field.dart';

typedef BaggageCompletedCallback = void Function(List<BagDetail> units, double totalFee);

class BagDetail {
  final double weight;
  final int typeId;
  final String typeName;
  final String dimensions; // Ліміт розміру з БД
  final bool isPreBooked;
  final double surcharge;
  final String message;

  BagDetail({
    required this.weight,
    required this.typeId,
    required this.typeName,
    required this.dimensions,
    required this.isPreBooked,
    required this.surcharge,
    required this.message,
  });

  factory BagDetail.fromJson(Map<String, dynamic> json) {
    return BagDetail(
      weight: (json['weight'] as num).toDouble(),
      typeId: json['determinedTypeId'] ?? 0,
      typeName: json['determinedTypeName'] ?? 'Unknown',
      dimensions: json['determinedDimensions'] ?? 'No limits', 
      isPreBooked: json['isPreBookedSlot'] ?? false,
      surcharge: (json['surcharge'] as num).toDouble(),
      message: json['message'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'baggage_unit_weight_kg': weight,
      'baggage_type_id': typeId,
    };
  }
}

class CheckInBaggageStep extends StatefulWidget {
  final AuthService authService;
  final int bookingItemId;
  final int passengerClassId;
  final BaggageCompletedCallback onCompleted;

  const CheckInBaggageStep({
    super.key,
    required this.authService,
    required this.bookingItemId,
    required this.passengerClassId,
    required this.onCompleted,
  });

  @override
  State<CheckInBaggageStep> createState() => _CheckInBaggageStepState();
}

class _CheckInBaggageStepState extends State<CheckInBaggageStep> {
  bool _isLoading = true;
  bool _isCalculating = false;
  String? _error;

  Map<String, dynamic>? _allowance;
  List<double> _weights = [];
  List<BagDetail> _calculatedBags = [];
  double _totalSurcharge = 0.0;
  Timer? _debounce;

  // Використовуємо Amber/Orange для перевісу (менш агресивно ніж червоний)
  final Color _warningColor = Colors.orange.shade900;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    try {
      final api = CheckInApiService(widget.authService);
      final info = await api.getBaggageInfo(widget.bookingItemId);

      if (!mounted) return;

      final paidQty = info['baggageQuantity'] as int? ?? 0;
      setState(() {
        _allowance = info;
        _weights = List.generate(paidQty, (_) => 0.0);
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load baggage info';
        _isLoading = false;
      });
    }
  }

  Future<void> _syncWithBackend() async {
    if (_weights.isEmpty) return;

    setState(() => _isCalculating = true);
    try {
      final api = CheckInApiService(widget.authService);
      final result = await api.calculateBaggageSurcharge(
        bookingItemId: widget.bookingItemId,
        bagWeights: _weights,
      );

      if (!mounted) return;

      setState(() {
        _totalSurcharge = (result['totalSurcharge'] as num).toDouble();
        _calculatedBags = (result['bags'] as List)
            .map((b) => BagDetail.fromJson(b))
            .toList();
        _isCalculating = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isCalculating = false);
    }
  }

  void _onWeightChanged(int index, String value) {
    final val = double.tryParse(value) ?? 0.0;
    _weights[index] = val;

    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 600), () {
      _syncWithBackend();
    });
  }

  void _addExtraBag() {
    setState(() => _weights.add(0.0));
  }

  void _removeExtraBag(int index) {
    setState(() {
      _weights.removeAt(index);
      if (_calculatedBags.length > index) _calculatedBags.removeAt(index);
    });
    _syncWithBackend();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    if (_isLoading) {
      return const Center(child: Padding(padding: EdgeInsets.all(32), child: CircularProgressIndicator()));
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0), // Додано відступи від боків
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildAllowanceBanner(),
          const SizedBox(height: 24),
          ..._weights.asMap().entries.map((e) => _buildBagInput(e.key)),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: _addExtraBag,
            icon: const Icon(Icons.add, size: 16),
            label: const Text('Add extra bag'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
          const SizedBox(height: 24),
          if (_isCalculating) const Padding(padding: EdgeInsets.only(bottom: 16), child: LinearProgressIndicator()),
          if (_totalSurcharge > 0) _buildSurchargeBanner(),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: CustomButton(
              label: _totalSurcharge > 0 ? 'Pay \$${_totalSurcharge.toStringAsFixed(2)} & Finish' : 'Finish Check-in',
              onPressed: _weights.any((w) => w <= 0) ? null : () => widget.onCompleted(_calculatedBags, _totalSurcharge),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAllowanceBanner() {
    final colors = Theme.of(context).colorScheme;
    final qty = _allowance?['baggageQuantity'] ?? 0;
    final weight = _allowance?['baggageMaxWeight'] ?? 0;
    final type = _allowance?['baggageTypeName'] ?? '—';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.primaryContainer.withOpacity(0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.primary.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('PRE-BOOKED ALLOWANCE', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: colors.primary, letterSpacing: 1)),
          const SizedBox(height: 8),
          Text('$qty x $type (up to ${weight}kg per bag)', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildBagInput(int index) {
  final colors = Theme.of(context).colorScheme;
  final calc = _calculatedBags.length > index ? _calculatedBags[index] : null;
  final isExtra = index >= (_allowance?['baggageQuantity'] ?? 0);
  final hasSurcharge = (calc?.surcharge ?? 0) > 0;

  return Container(
    margin: const EdgeInsets.only(bottom: 16),
    padding: const EdgeInsets.all(20), 
    decoration: BoxDecoration(
      color: colors.surfaceContainerHigh,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(
        color: hasSurcharge ? _warningColor : colors.outlineVariant.withOpacity(0.4),
        width: hasSurcharge ? 2.0 : 1.0,
      ),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: isExtra ? Colors.orange.withOpacity(0.1) : colors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                isExtra ? 'EXTRA BAG' : 'INCLUDED SLOT',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.8,
                  color: isExtra ? Colors.orange.shade900 : colors.primary,
                ),
              ),
            ),
            if (isExtra)
              IconButton(
                onPressed: () => _removeExtraBag(index),
                icon: Icon(Icons.delete_outline, size: 20, color: colors.error),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
          ],
        ),
        const SizedBox(height: 20),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 2,
              child: CustomInputField(
                label: 'Weight (kg)',
                value: _weights[index] > 0 ? _weights[index].toStringAsFixed(1) : '',
                icon: Icons.scale_outlined,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,1}')),
                ],
                onChanged: (v) => _onWeightChanged(index, v),
              ),
            ),
            const SizedBox(width: 32),
            if (calc != null)
              Expanded(
                flex: 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      calc.typeName, 
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)
                    ),
                    const SizedBox(height: 10),
                    
                    // Блок виведення розмірів (лише чисте значення з БД)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: colors.surface,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: colors.outlineVariant.withOpacity(0.3)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.straighten, size: 16, color: colors.primary),
                          const SizedBox(width: 10),
                          Text(
                            calc.dimensions, // Тут буде чітко "50x35x20" або "158x75x70"
                            style: TextStyle(
                              fontSize: 13, 
                              fontWeight: FontWeight.w700, 
                              color: colors.onSurface,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    if (hasSurcharge)
                      Padding(
                        padding: const EdgeInsets.only(top: 14),
                        child: Text(
                          '+\$${calc.surcharge.toStringAsFixed(2)}',
                          style: TextStyle(
                            color: _warningColor, 
                            fontWeight: FontWeight.w900, 
                            fontSize: 22
                          ),
                        ),
                      ),
                  ],
                ),
              ),
          ],
        ),
        if (calc != null && calc.message.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 18),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: hasSurcharge ? _warningColor.withOpacity(0.08) : colors.surface,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline, 
                    size: 16, 
                    color: hasSurcharge ? _warningColor : colors.onSurfaceVariant
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      calc.message,
                      style: TextStyle(
                        fontSize: 11, 
                        fontWeight: FontWeight.w600, 
                        color: hasSurcharge ? _warningColor : colors.onSurfaceVariant
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    ),
  );
}
  
  
  Widget _buildSurchargeBanner() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _warningColor.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _warningColor.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(Icons.payments_outlined, color: _warningColor, size: 28),
              const SizedBox(width: 16),
              const Text('Total Surcharge:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ],
          ),
          Text(
            '\$${_totalSurcharge.toStringAsFixed(2)}',
            style: TextStyle(color: _warningColor, fontWeight: FontWeight.w900, fontSize: 28),
          ),
        ],
      ),
    );
  }
}