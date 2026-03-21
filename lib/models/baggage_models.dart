class BaggageType {
  final int id;
  final String name;

  const BaggageType({
    required this.id,
    required this.name,
  });

  factory BaggageType.fromJson(Map<String, dynamic> json) {
    return BaggageType(
      id: (json['id'] as num).toInt(),
      name: json['name'] as String,
    );
  }
}

class BaggagePricingRule {
  final int id;
  final int baggageTypeId;
  final String dimension;
  final double maxWeight;
  final double overweightFeePerKg;

  const BaggagePricingRule({
    required this.id,
    required this.baggageTypeId,
    required this.dimension,
    required this.maxWeight,
    required this.overweightFeePerKg,
  });

  factory BaggagePricingRule.fromJson(Map<String, dynamic> json) {
    return BaggagePricingRule(
      id: (json['id'] as num).toInt(),
      baggageTypeId: (json['baggageTypeId'] as num).toInt(),
      dimension: json['dimension'] as String,
      maxWeight: (json['maxWeight'] as num).toDouble(),
      overweightFeePerKg: (json['overweightFeePerKg'] as num).toDouble(),
    );
  }
}

class BaggagePricingInFlight {
  final int id;
  final int baggagePricingRuleId;
  final int flightId;
  final int flightClassId;
  final double price;
  final BaggagePricingRule rule;
  final BaggageType type;

  const BaggagePricingInFlight({
    required this.id,
    required this.baggagePricingRuleId,
    required this.flightId,
    required this.flightClassId,
    required this.price,
    required this.rule,
    required this.type,
  });

  factory BaggagePricingInFlight.fromJson(Map<String, dynamic> json) {
    return BaggagePricingInFlight(
      id: (json['baggagePricingInFlightId'] as num).toInt(),
      baggagePricingRuleId: (json['baggagePricingRuleId'] as num).toInt(),
      flightId: (json['flightId'] as num).toInt(),
      flightClassId: (json['flightClassId'] as num).toInt(),
      price: (json['price'] as num).toDouble(),
      rule: BaggagePricingRule.fromJson(json['rule'] as Map<String, dynamic>),
      type: BaggageType.fromJson(json['type'] as Map<String, dynamic>),
    );
  }
}