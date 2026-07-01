class FlightWithoutOperationModel {
  final int flightId;
  final String flightNumber;
  final int departsAirportId;
  final String departsCode;
  final String arrivesCode;
  final DateTime departsDatetime;
  final DateTime arrivesDatetime;
  final String flightStatus;
  final String? airlineName;

  const FlightWithoutOperationModel({
    required this.flightId,
    required this.flightNumber,
    required this.departsAirportId,
    required this.departsCode,
    required this.arrivesCode,
    required this.departsDatetime,
    required this.arrivesDatetime,
    required this.flightStatus,
    this.airlineName,
  });

  factory FlightWithoutOperationModel.fromJson(Map<String, dynamic> json) =>
      FlightWithoutOperationModel(
        flightId:         (json['flight_id'] as num).toInt(),
        flightNumber:     json['flight_number'] as String,
        departsAirportId: (json['departs_airport_id'] as num).toInt(),
        departsCode:      json['departs_code'] as String,
        arrivesCode:      json['arrives_code'] as String,
        departsDatetime:  DateTime.parse(json['departs_datetime'] as String),
        arrivesDatetime:  DateTime.parse(json['arrives_datetime'] as String),
        flightStatus:     json['flight_status'] as String,
        airlineName:      json['airline_name'] as String?,
      );

  String get label =>
      '$flightNumber  $departsCode → $arrivesCode  '
      '${departsDatetime.day.toString().padLeft(2, '0')}.'
      '${departsDatetime.month.toString().padLeft(2, '0')}.'
      '${departsDatetime.year}';
}