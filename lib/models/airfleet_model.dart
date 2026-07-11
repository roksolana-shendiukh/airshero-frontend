class AirfleetModel {
  final int airfleetId;
  final int? airfleetManufacturerId;
  final String? airfleetManufacturerName;
  final String? aircraftModel;
  final double? aircraftRangeKm;
  final double? aircraftSpeed;
  final int? seatCapacity;
  final double? baggageCapacity;
  final double? aircraftFuelConsumption;
  final double? aircraftPerformance; 
  final String? aircraftUrl;

  const AirfleetModel({
    required this.airfleetId,
    this.airfleetManufacturerId,
    this.airfleetManufacturerName,
    this.aircraftModel,
    this.aircraftRangeKm,
    this.aircraftSpeed,
    this.seatCapacity,
    this.baggageCapacity,
    this.aircraftFuelConsumption,
    this.aircraftPerformance,
    this.aircraftUrl,
  });

  factory AirfleetModel.fromJson(Map<String, dynamic> json) => AirfleetModel(
        airfleetId:               (json['airfleet_id'] as num).toInt(),
        airfleetManufacturerId:   (json['airfleet_manufacturer_id'] as num?)?.toInt(),
        airfleetManufacturerName: json['airfleet_manufacturer_name'] as String?,
        aircraftModel:            json['aircraft_model'] as String?,
        aircraftRangeKm:          (json['aircraft_range_km'] as num?)?.toDouble(),
        aircraftSpeed:            (json['aircraft_speed'] as num?)?.toDouble(),
        seatCapacity:             (json['seat_capacity'] as num?)?.toInt(),
        baggageCapacity:          (json['baggage_capacity'] as num?)?.toDouble(),
        aircraftFuelConsumption:  (json['aircraft_fuel_consumption'] as num?)?.toDouble(),
        aircraftPerformance:      (json['aircraft_performance'] as num?)?.toDouble(),
        aircraftUrl:              json['aircraft_url'] as String?,
      );

  String get label => airfleetManufacturerName != null
    ? '$airfleetManufacturerName $aircraftModel'
    : aircraftModel ?? '';
}