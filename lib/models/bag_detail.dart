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