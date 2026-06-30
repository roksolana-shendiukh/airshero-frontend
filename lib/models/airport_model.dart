class AirportModel {
  final int airportId;
  final int? cityId;
  final String? cityName; 
  final String? airportName;
  final String? airportAddress;
  final String? airportCode;
  final double? latitude;
  final double? longitude;

  const AirportModel({
    required this.airportId,
    this.cityId,
    this.cityName,
    this.airportName,
    this.airportAddress,
    this.airportCode,
    this.latitude,
    this.longitude,
  });

  factory AirportModel.fromJson(Map<String, dynamic> json) => AirportModel(
        airportId:      (json['airport_id'] as num).toInt(),
        cityId:         (json['city_id'] as num?)?.toInt(),
        cityName:       json['city_name'] as String?,
        airportName:    json['airport_name'] as String?,
        airportAddress: json['airport_address'] as String?,
        airportCode:    json['airport_code'] as String?,
        latitude:       (json['latitude'] as num?)?.toDouble(),
        longitude:      (json['longitude'] as num?)?.toDouble(),
      );
}