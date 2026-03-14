class AirfleetModel {
  final int airfleetId;
  final String aircraftModel;
  final String? manufacturerName;
  final int? seatCapacity;
  final double? aircraftRangeKm;
  final double? aircraftSpeed;
  final double? baggageCapacity;
  final double? aircraftFuelConsumption;
  final String? aircraftPerformance;
  final String? aircraftUrl;

  const AirfleetModel({
    required this.airfleetId,
    required this.aircraftModel,
    this.manufacturerName,
    this.seatCapacity,
    this.aircraftRangeKm,
    this.aircraftSpeed,
    this.baggageCapacity,
    this.aircraftFuelConsumption,
    this.aircraftPerformance,
    this.aircraftUrl,
  });

  factory AirfleetModel.fromJson(Map<String, dynamic> json) => AirfleetModel(
        airfleetId:              (json['airfleetId'] as num).toInt(),
        aircraftModel:           json['aircraftModel'] as String,
        manufacturerName:        json['manufacturerName'] as String?,
        seatCapacity:            (json['seatCapacity'] as num?)?.toInt(),
        aircraftRangeKm:         (json['aircraftRangeKm'] as num?)?.toDouble(),
        aircraftSpeed:           (json['aircraftSpeed'] as num?)?.toDouble(),
        baggageCapacity:         (json['baggageCapacity'] as num?)?.toDouble(),
        aircraftFuelConsumption: (json['aircraftFuelConsumption'] as num?)?.toDouble(),
        aircraftPerformance:     json['aircraftPerformance'] as String?,
        aircraftUrl:             json['aircraftUrl'] as String?,
      );

  String get label =>
      manufacturerName != null ? '$manufacturerName $aircraftModel' : aircraftModel;
}