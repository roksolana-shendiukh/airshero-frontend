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
      typeId:      json['determined_type_id']     ?? 0,
      typeName:    json['determined_type_name']   ?? 'Unknown',
      dimensions:  json['determined_dimensions']  ?? 'No limits',
      isPreBooked: json['is_pre_booked_slot']     ?? false,
      surcharge:   (json['surcharge'] as num).toDouble(),
      message:     json['message']                ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'baggage_unit_weight_kg': weight,
    'baggage_type_id':        typeId,
  };
}