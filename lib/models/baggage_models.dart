class BaggageType {
  final int id;
  final String name;

  const BaggageType({
    required this.id,
    required this.name,
  });
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
}