class BaggageUnit {
  String trackingNumber;
  int typeId;
  double weight;
  double length;
  double width;
  double height;

  BaggageUnit({
    required this.trackingNumber,
    required this.typeId,
    this.weight = 0.0,
    this.length = 0.0,
    this.width = 0.0,
    this.height = 0.0,
  });

  Map<String, dynamic> toJson() {
    return {
      'tracking_number': trackingNumber,
      'type_id': typeId,
      'weight': weight,
      'length': length,
      'width': width,
      'height': height,
    };
  }

  factory BaggageUnit.fromJson(Map<String, dynamic> json) {
    return BaggageUnit(
      trackingNumber: json['tracking_number']?.toString() ?? '',
      typeId: json['type_id'] as int? ?? 0,
      weight: (json['weight'] as num? ?? 0.0).toDouble(),
      length: (json['length'] as num? ?? 0.0).toDouble(),
      width: (json['width'] as num? ?? 0.0).toDouble(),
      height: (json['height'] as num? ?? 0.0).toDouble(),
    );
  }
}