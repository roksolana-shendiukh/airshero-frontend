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
        flightId:         (json['flightId'] as num).toInt(),
        flightNumber:     json['flightNumber'] as String,
        departsAirportId: (json['departsAirportId'] as num).toInt(),
        departsCode:      json['departsCode'] as String,
        arrivesCode:      json['arrivesCode'] as String,
        departsDatetime:  DateTime.parse(json['departsDatetime'] as String),
        arrivesDatetime:  DateTime.parse(json['arrivesDatetime'] as String),
        flightStatus:     json['flightStatus'] as String,
        airlineName:      json['airlineName'] as String?,
      );

  String get label =>
      '$flightNumber  $departsCode → $arrivesCode  '
      '${departsDatetime.day.toString().padLeft(2, '0')}.'
      '${departsDatetime.month.toString().padLeft(2, '0')}.'
      '${departsDatetime.year}';
}