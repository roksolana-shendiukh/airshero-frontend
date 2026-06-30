class BaggageType {
  final int baggageTypeId;
  final String? baggageTypeName;

  const BaggageType({
    required this.baggageTypeId,
    this.baggageTypeName,
  });

  factory BaggageType.fromJson(Map<String, dynamic> json) => BaggageType(
        baggageTypeId:   (json['baggage_type_id'] as num).toInt(),
        baggageTypeName: json['baggage_type_name'] as String?,
      );
}

class BaggagePricingRule {
  final int baggagePricingRuleId;
  final int? baggageTypeId;
  final String? baggageDimension;
  final double? baggageMaxWeight;

  const BaggagePricingRule({
    required this.baggagePricingRuleId,
    this.baggageTypeId,
    this.baggageDimension,
    this.baggageMaxWeight,
  });

  factory BaggagePricingRule.fromJson(Map<String, dynamic> json) => BaggagePricingRule(
        baggagePricingRuleId: (json['baggage_pricing_rule_id'] as num).toInt(),
        baggageTypeId:        (json['baggage_type_id'] as num?)?.toInt(),
        baggageDimension:     json['baggage_dimension'] as String?,
        baggageMaxWeight:     (json['baggage_max_weight'] as num?)?.toDouble(),
      );
}

class BaggagePricingInFlight {
  final int baggagePricingInFlightId;
  final int? baggagePricingRuleId;
  final int? flightClassId;
  final double? baggagePrice;
  final BaggagePricingRule? rule;
  final BaggageType? type;

  const BaggagePricingInFlight({
    required this.baggagePricingInFlightId,
    this.baggagePricingRuleId,
    this.flightClassId,
    this.baggagePrice,
    this.rule,
    this.type,
  });

  factory BaggagePricingInFlight.fromJson(Map<String, dynamic> json) => BaggagePricingInFlight(
        baggagePricingInFlightId: (json['baggage_pricing_in_flight_id'] as num).toInt(),
        baggagePricingRuleId:     (json['baggage_pricing_rule_id'] as num?)?.toInt(),
        flightClassId:            (json['flight_class_id'] as num?)?.toInt(),
        baggagePrice:             (json['baggage_price'] as num?)?.toDouble(),
        rule: json['rule'] != null
            ? BaggagePricingRule.fromJson(json['rule'] as Map<String, dynamic>)
            : null,
        type: json['type'] != null
            ? BaggageType.fromJson(json['type'] as Map<String, dynamic>)
            : null,
      );
}