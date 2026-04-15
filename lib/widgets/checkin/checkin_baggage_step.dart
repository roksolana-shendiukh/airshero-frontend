import 'dart:async';
import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../services/checkin_api_service.dart';
import '../custom/custom_button.dart';
import '../../models/bag_detail.dart';
import 'bag_row.dart';
import 'baggage_widgets.dart';

typedef BaggageCompletedCallback = void Function(List<BagDetail> units, double totalFee);

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
  bool    _isLoading     = true;
  bool    _isCalculating = false;
  String? _error;

  Map<String, dynamic>?          _allowance;
  List<Map<String, dynamic>>     _baggageTypes       = [];
  List<double>                   _weights            = [];
  List<int?>                     _selectedTypes      = [];
  List<BagDetail>                _calculatedBags     = [];
  double                         _totalSurcharge     = 0.0;
  double                         _flightCheckedWeight = 0.0;
  double                         _baggageCapacity    = 0.0;
  Timer?                         _debounce;

  int get _paidQty => _allowance?['baggageQuantity'] as int? ?? 0;

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
      final types  = await api.getBaggageTypes();

      if (!mounted) return;

      final paidQty = info['baggageQuantity'] as int? ?? 0;

      setState(() {
        _allowance           = info;
        _baggageTypes        = types;
        _weights             = List.generate(paidQty, (_) => 0.0);
        _selectedTypes       = List.generate(paidQty, (_) => null);
        _flightCheckedWeight = (weight['totalCheckedWeightKg'] as num?)?.toDouble() ?? 0.0;
        _baggageCapacity     = (weight['baggageCapacityKg']    as num?)?.toDouble() ?? 0.0;
        _isLoading           = false;
      });
    } catch (e) {
      debugPrint('BAGGAGE LOAD ERROR: $e');
      if (!mounted) return;
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
        _calculatedBags = (result['bags'] as List).asMap().entries.map((e) {
          final bag = BagDetail.fromJson(e.value);
          final i   = e.key;
          if (i >= _paidQty && _selectedTypes.length > i && _selectedTypes[i] != null) {
            return BagDetail(
              weight:      bag.weight,
              typeId:      _selectedTypes[i]!,
              typeName:    bag.typeName,
              dimensions:  bag.dimensions,
              isPreBooked: bag.isPreBooked,
              surcharge:   bag.surcharge,
              message:     bag.message,
            );
          }
          return bag;
        }).toList();
        _isCalculating = false;
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

  void _onTypeChanged(int index, int? typeId) {
    setState(() => _selectedTypes[index] = typeId);
  }

  void _addExtraBag() {
    if (_isHoldFull) return;
    setState(() {
      _weights.add(0.0);
      _selectedTypes.add(null);
    });
  }

  void _removeExtraBag(int index) {
    setState(() {
      _weights.removeAt(index);
      _selectedTypes.removeAt(index);
      if (_calculatedBags.length > index) _calculatedBags.removeAt(index);
    });
    _syncWithBackend();
  }

  double get _currentPassengerWeight =>
      _weights.fold(0.0, (sum, w) => sum + w);

  bool get _isHoldFull =>
      _baggageCapacity > 0 &&
      (_flightCheckedWeight + _currentPassengerWeight) >= _baggageCapacity;

  bool get _allFilled {
    if (_weights.isEmpty) return true;
    for (int i = 0; i < _weights.length; i++) {
      if (_weights[i] <= 0) return false;
      // Extra bags require type selection
      if (i >= _paidQty && _selectedTypes[i] == null) return false;
    }
    return true;
  }

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

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: AllowanceBanner(allowance: _allowance)),
              const SizedBox(width: 8),
              Expanded(
                child: FlightWeightBanner(
                  flightCheckedWeight:    _flightCheckedWeight,
                  currentPassengerWeight: _currentPassengerWeight,
                  baggageCapacity:        _baggageCapacity,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          ..._weights.asMap().entries.map(
            (e) => BagRow(
              index:          e.key,
              weight:         e.value,
              calc:           _calculatedBags.length > e.key ? _calculatedBags[e.key] : null,
              isExtra:        e.key >= _paidQty,
              baggageTypes:   _baggageTypes,
              selectedTypeId: _selectedTypes.length > e.key ? _selectedTypes[e.key] : null,
              onTypeChanged:  (v) => _onTypeChanged(e.key, v),
              onChanged:      (v) => _onWeightChanged(e.key, v),
              onRemove:       () => _removeExtraBag(e.key),
            ),
          ),

          Padding(
            padding: const EdgeInsets.only(top: 4, bottom: 20),
            child: Tooltip(
              message: _isHoldFull ? 'Baggage hold is full' : '',
              child: TextButton.icon(
                onPressed: _isHoldFull ? null : _addExtraBag,
                icon: const Icon(Icons.add, size: 14),
                label: const Text('Add extra bag', style: TextStyle(fontSize: 13)),
                style: TextButton.styleFrom(
                  padding:       const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  minimumSize:   Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
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

          if (_isHoldFull) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color:        colors.error.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(6),
                border:       Border.all(color: colors.error.withValues(alpha: 0.25)),
              ),
              child: Row(
                children: [
                  Icon(Icons.warning_amber_outlined, size: 14, color: colors.error),
                  const SizedBox(width: 8),
                  Text(
                    'Baggage hold is at full capacity. No additional baggage can be accepted.',
                    style: TextStyle(fontSize: 12, color: colors.error),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          if (_totalSurcharge > 0) ...[
            SurchargeSummary(amount: _totalSurcharge),
            const SizedBox(height: 16),
          ],

          SizedBox(
            width: double.infinity,
            child: CustomButton(
              label: _totalSurcharge > 0
                  ? 'Proceed to Payment  ·  \$${_totalSurcharge.toStringAsFixed(2)}'
                  : 'Complete Check-in',
              onPressed: _allFilled && !_isCalculating && !_isHoldFull
                ? () => widget.onCompleted(_calculatedBags, _totalSurcharge)
                : null,
            ),
          ),
        ],
      ),
    );
  }
}