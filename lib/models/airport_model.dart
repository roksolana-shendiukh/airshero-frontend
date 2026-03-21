class AirportModel {
  final int airportId;
  final String airportName;
  final String airportCode;
  final String? airportAddress;
  final double latitude;
  final double longitude;

  const AirportModel({
    required this.airportId,
    required this.airportName,
    required this.airportCode,
    this.airportAddress,
    required this.latitude,
    required this.longitude,
  });

  factory AirportModel.fromJson(Map<String, dynamic> json) => AirportModel(
        airportId:      json['airportId'] as int,
        airportName:    json['airportName'] as String,
        airportCode:    json['airportCode'] as String,
        airportAddress: json['airportAddress'] as String?,
        latitude:       (json['latitude'] as num).toDouble(),
        longitude:      (json['longitude'] as num).toDouble(),
      );
}