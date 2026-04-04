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
  final String dimensions;
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
      weight:      (json['weight'] as num).toDouble(),
      typeId:      json['determinedTypeId']     ?? 0,
      typeName:    json['determinedTypeName']   ?? 'Unknown',
      dimensions:  json['determinedDimensions'] ?? 'No limits',
      isPreBooked: json['isPreBookedSlot']      ?? false,
      surcharge:   (json['surcharge'] as num).toDouble(),
      message:     json['message']              ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'baggage_unit_weight_kg': weight,
    'baggage_type_id':        typeId,
  };
}

class CheckInBaggageStep extends StatefulWidget {
  final AuthService authService;
  final int bookingItemId;
  final int passengerClassId;
  final int flightOperationId;
  final BaggageCompletedCallback onCompleted;

  const CheckInBaggageStep({
    super.key,
    required this.authService,
    required this.bookingItemId,
    required this.passengerClassId,
    required this.flightOperationId,
    required this.onCompleted,
  });

  @override
  State<CheckInBaggageStep> createState() => _CheckInBaggageStepState();
}

class _CheckInBaggageStepState extends State<CheckInBaggageStep> {
  bool _isLoading     = true;
  bool _isCalculating = false;
  String? _error;

  Map<String, dynamic>? _allowance;
  List<double>    _weights        = [];
  List<BagDetail> _calculatedBags = [];
  double          _totalSurcharge = 0.0;
  double          _flightCheckedWeight = 0.0;
  double _baggageCapacity = 0.0;
  Timer?          _debounce;

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
      final api    = CheckInApiService(widget.authService);
      final info   = await api.getBaggageInfo(widget.bookingItemId);
      final weight = await api.getCheckedBaggageWeight(widget.flightOperationId);
      debugPrint('WEIGHT RESPONSE: $weight');

      if (!mounted) return;

      final paidQty = info['baggageQuantity'] as int? ?? 0;

      setState(() {
        _allowance           = info;
        _weights             = List.generate(paidQty, (_) => 0.0);
        _flightCheckedWeight = (weight['totalCheckedWeightKg'] is Map
            ? ((weight['totalCheckedWeightKg'] as Map)['totalCheckedWeightKg'] as num?)?.toDouble()
            : (weight['totalCheckedWeightKg'] as num?)?.toDouble()) ?? 0.0;
        _baggageCapacity = (weight['totalCheckedWeightKg'] is Map
            ? ((weight['totalCheckedWeightKg'] as Map)['baggageCapacityKg'] as num?)?.toDouble()
            : (weight['baggageCapacityKg'] as num?)?.toDouble()) ?? 0.0;
        _isLoading           = false;
      });
    } catch (e) {
      debugPrint('BAGGAGE LOAD ERROR: $e');
      setState(() {
        _error     = 'Failed to load baggage info';
        _isLoading = false;
      });
    }
  }

  Future<void> _syncWithBackend() async {
    if (_weights.isEmpty) return;
    setState(() => _isCalculating = true);
    try {
      final api    = CheckInApiService(widget.authService);
      final result = await api.calculateBaggageSurcharge(
        bookingItemId: widget.bookingItemId,
        bagWeights:    _weights,
      );
      if (!mounted) return;
      setState(() {
        _totalSurcharge = (result['totalSurcharge'] as num).toDouble();
        _calculatedBags = (result['bags'] as List)
            .map((b) => BagDetail.fromJson(b))
            .toList();
        _isCalculating  = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isCalculating = false);
    }
  }

  void _onWeightChanged(int index, String value) {
    _weights[index] = double.tryParse(value) ?? 0.0;
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 600), _syncWithBackend);
  }

  void _addExtraBag() => setState(() => _weights.add(0.0));

  void _removeExtraBag(int index) {
    setState(() {
      _weights.removeAt(index);
      if (_calculatedBags.length > index) _calculatedBags.removeAt(index);
    });
    _syncWithBackend();
  }

  double get _currentPassengerWeight =>
      _weights.fold(0.0, (sum, w) => sum + w);

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    if (_isLoading) {
      return const Center(
        child: Padding(padding: EdgeInsets.all(48), child: CircularProgressIndicator()),
      );
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Text(_error!, style: TextStyle(color: colors.error)),
        ),
      );
    }

    final allFilled = _weights.isEmpty || _weights.every((w) => w > 0);

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _AllowanceBanner(allowance: _allowance),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _FlightWeightBanner(
                  flightCheckedWeight:    _flightCheckedWeight,
                  currentPassengerWeight: _currentPassengerWeight,
                  baggageCapacity:        _baggageCapacity,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ..._weights.asMap().entries.map(
            (e) => _BagRow(
              index:     e.key,
              weight:    e.value,
              calc:      _calculatedBags.length > e.key ? _calculatedBags[e.key] : null,
              isExtra:   e.key >= (_allowance?['baggageQuantity'] ?? 0),
              onChanged: (v) => _onWeightChanged(e.key, v),
              onRemove:  () => _removeExtraBag(e.key),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 4, bottom: 20),
            child: TextButton.icon(
              onPressed: _addExtraBag,
              icon: const Icon(Icons.add, size: 14),
              label: const Text('Add extra bag', style: TextStyle(fontSize: 13)),
              style: TextButton.styleFrom(
                padding:       const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                minimumSize:   Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
          ),
          if (_isCalculating) ...[
            LinearProgressIndicator(
              minHeight:       1,
              color:           colors.primary.withValues(alpha: 0.5),
              backgroundColor: Colors.transparent,
            ),
            const SizedBox(height: 16),
          ],
          if (_totalSurcharge > 0) ...[
            _SurchargeSummary(amount: _totalSurcharge),
            const SizedBox(height: 16),
          ],
          SizedBox(
            width: double.infinity,
            child: CustomButton(
              label: _totalSurcharge > 0
                  ? 'Proceed to Payment  ·  \$${_totalSurcharge.toStringAsFixed(2)}'
                  : 'Complete Check-in',
              onPressed: allFilled
                  ? () => widget.onCompleted(_calculatedBags, _totalSurcharge)
                  : null,
            ),
          ),
        ],
      ),
    );
  }
}

class _AllowanceBanner extends StatelessWidget {
  final Map<String, dynamic>? allowance;
  const _AllowanceBanner({required this.allowance});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final qty    = allowance?['baggageQuantity'] ?? 0;
    final weight = allowance?['baggageMaxWeight'] ?? 0;
    final type   = allowance?['baggageTypeName']  ?? '—';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color:        colors.primaryContainer.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(6),
        border:       Border.all(color: colors.outline.withValues(alpha: 0.15)),
      ),
      child: Row(
        children: [
          Icon(Icons.luggage_outlined, size: 16, color: colors.primary),
          const SizedBox(width: 10),
          Text(
            'Allowance:',
            style: TextStyle(
              fontSize:   12,
              color:      colors.onSurfaceVariant,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            '$qty × $type · max ${weight}kg/bag',
            style: TextStyle(
              fontSize:   13,
              fontWeight: FontWeight.w600,
              color:      colors.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}

class _FlightWeightBanner extends StatelessWidget {
  final double flightCheckedWeight;
  final double currentPassengerWeight;
  final double baggageCapacity;

  const _FlightWeightBanner({
    required this.flightCheckedWeight,
    required this.currentPassengerWeight,
    required this.baggageCapacity,
  });

  @override
  Widget build(BuildContext context) {
    final colors      = Theme.of(context).colorScheme;
    final total       = flightCheckedWeight + currentPassengerWeight;
    final progress    = baggageCapacity > 0
        ? (total / baggageCapacity).clamp(0.0, 1.0)
        : 0.0;
    final percent     = (progress * 100).toStringAsFixed(1);
    final isNearFull  = progress > 0.85;
    final isFull      = progress >= 1.0;
    final accentColor = isFull
        ? colors.error
        : isNearFull
            ? const Color(0xFFE65100)
            : colors.primary;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color:        colors.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(8),
        border:       Border.all(color: colors.outline.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.flight_outlined, size: 14, color: colors.onSurfaceVariant),
              const SizedBox(width: 6),
              Text(
                'Baggage hold',
                style: TextStyle(
                  fontSize:   12,
                  color:      colors.onSurfaceVariant,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Spacer(),
              Text(
                '$percent%',
                style: TextStyle(
                  fontSize:   13,
                  fontWeight: FontWeight.w700,
                  color:      accentColor,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                '${total.toStringAsFixed(1)} / ${baggageCapacity.toStringAsFixed(0)} kg',
                style: TextStyle(
                  fontSize: 12,
                  color:    colors.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value:           progress,
              minHeight:       6,
              backgroundColor: colors.outline.withValues(alpha: 0.15),
              valueColor:      AlwaysStoppedAnimation<Color>(accentColor),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _WeightChip(
                label: 'Already checked',
                value: '${flightCheckedWeight.toStringAsFixed(1)} kg',
                colors: colors,
              ),
              const SizedBox(width: 8),
              if (currentPassengerWeight > 0)
                _WeightChip(
                  label:    'This passenger',
                  value:    '+${currentPassengerWeight.toStringAsFixed(1)} kg',
                  colors:   colors,
                  accent:   accentColor,
                ),
              const Spacer(),
              _WeightChip(
                label:  'Remaining',
                value:  '${(baggageCapacity - total).clamp(0, baggageCapacity).toStringAsFixed(1)} kg',
                colors: colors,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _WeightChip extends StatelessWidget {
  final String      label;
  final String      value;
  final ColorScheme colors;
  final Color?      accent;

  const _WeightChip({
    required this.label,
    required this.value,
    required this.colors,
    this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 10, color: colors.onSurfaceVariant),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize:   12,
            fontWeight: FontWeight.w600,
            color:      accent ?? colors.onSurface,
          ),
        ),
      ],
    );
  }
}

class _BagRow extends StatelessWidget {
  final int        index;
  final double     weight;
  final BagDetail? calc;
  final bool       isExtra;
  final ValueChanged<String> onChanged;
  final VoidCallback         onRemove;

  const _BagRow({
    required this.index,
    required this.weight,
    required this.calc,
    required this.isExtra,
    required this.onChanged,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final colors       = Theme.of(context).colorScheme;
    final hasSurcharge = (calc?.surcharge ?? 0) > 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              color:        colors.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(8),
              border:       Border.all(color: colors.outline.withValues(alpha: 0.12)),
            ),
            padding: const EdgeInsets.fromLTRB(20, 12, 16, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'BAG ${index + 1}',
                      style: TextStyle(
                        fontSize:      10,
                        fontWeight:    FontWeight.w700,
                        letterSpacing: 1.2,
                        color:         colors.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: isExtra
                            ? colors.tertiaryContainer.withValues(alpha: 0.4)
                            : colors.primaryContainer.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(3),
                      ),
                      child: Text(
                        isExtra ? 'Extra' : 'Included',
                        style: TextStyle(
                          fontSize:   10,
                          fontWeight: FontWeight.w600,
                          color: isExtra ? colors.tertiary : colors.primary,
                        ),
                      ),
                    ),
                    const Spacer(),
                    if (isExtra)
                      InkWell(
                        onTap:        onRemove,
                        borderRadius: BorderRadius.circular(4),
                        child: Padding(
                          padding: const EdgeInsets.all(4),
                          child: Icon(Icons.close, size: 14, color: colors.onSurfaceVariant),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 190,
                      child: CustomInputField(
                        label: 'Weight (kg)',
                        value: weight > 0 ? weight.toStringAsFixed(1) : '',
                        icon:  Icons.scale_outlined,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,1}')),
                        ],
                        onChanged: onChanged,
                      ),
                    ),
                    const SizedBox(width: 20),
                    if (calc != null) ...[
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              calc!.typeName,
                              style: TextStyle(
                                fontSize:   13,
                                fontWeight: FontWeight.w600,
                                color:      colors.onSurface,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Row(
                              children: [
                                Icon(Icons.straighten, size: 12, color: colors.onSurfaceVariant),
                                const SizedBox(width: 4),
                                Text(
                                  calc!.dimensions,
                                  style: TextStyle(fontSize: 12, color: colors.onSurfaceVariant),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      if (hasSurcharge)
                        Text(
                          '+\$${calc!.surcharge.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize:   15,
                            fontWeight: FontWeight.w700,
                            color:      Color(0xFFE65100),
                          ),
                        ),
                    ],
                  ],
                ),
                if (calc != null && calc!.message.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        size:  12,
                        color: hasSurcharge ? const Color(0xFFE65100) : colors.onSurfaceVariant,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          calc!.message,
                          style: TextStyle(
                            fontSize: 11,
                            color: hasSurcharge ? const Color(0xFFE65100) : colors.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          if (hasSurcharge)
            Positioned(
              left:   0,
              top:    0,
              bottom: 0,
              child: Container(
                width: 3,
                decoration: const BoxDecoration(
                  color: Color(0xFFE65100),
                  borderRadius: BorderRadius.only(
                    topLeft:    Radius.circular(8),
                    bottomLeft: Radius.circular(8),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _SurchargeSummary extends StatelessWidget {
  final double amount;
  const _SurchargeSummary({required this.amount});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color:        const Color(0xFFE65100).withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(6),
        border:       Border.all(color: const Color(0xFFE65100).withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Excess baggage surcharge',
            style: TextStyle(
              fontSize:   13,
              color:      colors.onSurface,
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            '\$${amount.toStringAsFixed(2)}',
            style: const TextStyle(
              fontSize:   14,
              fontWeight: FontWeight.w700,
              color:      Color(0xFFE65100),
            ),
          ),
        ],
      ),
    );
  }
}