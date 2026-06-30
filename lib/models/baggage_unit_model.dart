class BaggageUnit {
  String trackingNumber;
  int baggageTypeId;
  double baggageUnitWeightKg;
  double length;
  double width;
  double height;

  BaggageUnit({
    required this.trackingNumber,
    required this.baggageTypeId,
    this.baggageUnitWeightKg = 0.0,
    this.length = 0.0,
    this.width = 0.0,
    this.height = 0.0,
  });

  Map<String, dynamic> toJson() => {
        'baggage_unit_tracking_number': trackingNumber,
        'baggage_type_id':              baggageTypeId,
        'baggage_unit_weight_kg':       baggageUnitWeightKg,
      };

  factory BaggageUnit.fromJson(Map<String, dynamic> json) => BaggageUnit(
        trackingNumber:      json['baggage_unit_tracking_number']?.toString() ?? '',
        baggageTypeId:       (json['baggage_type_id'] as num?)?.toInt() ?? 0,
        baggageUnitWeightKg: (json['baggage_unit_weight_kg'] as num? ?? 0.0).toDouble(),
      );
}