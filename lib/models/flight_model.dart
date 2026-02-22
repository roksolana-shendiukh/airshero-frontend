class FlightModel {
  final int flightId;
  final String flightNumber;
  final String airlineName;
  final String? airlineLogoUrl;
  final String departsCode;
  final String departsAirport;
  final String arrivesCode;
  final String arrivesAirport;
  final String departsCity;
  final String arrivesCity;
  final DateTime departsDatetime;
  final DateTime arrivesDatetime;
  final String flightDuration;
  final String className;
  final double ticketPrice;

  const FlightModel({
    required this.flightId,
    required this.flightNumber,
    required this.airlineName,
    this.airlineLogoUrl,
    required this.departsCode,
    required this.departsAirport,
    required this.arrivesCode,
    required this.arrivesAirport,
    required this.departsCity,
    required this.arrivesCity,
    required this.departsDatetime,
    required this.arrivesDatetime,
    required this.flightDuration,
    required this.className,
    required this.ticketPrice,
  });

  factory FlightModel.fromJson(Map<String, dynamic> json) {
    return FlightModel(
      flightId: json['flightId'] as int,
      flightNumber: json['flightNumber'] as String,
      airlineName: json['airlineName'] as String,
      airlineLogoUrl: json['airlineLogoUrl'] as String?,
      departsCode: json['departsCode'] as String,
      departsAirport: json['departsAirport'] as String,
      arrivesCode: json['arrivesCode'] as String,
      arrivesAirport: json['arrivesAirport'] as String,
      departsCity: json['departsCity'] as String,
      arrivesCity: json['arrivesCity'] as String,
      departsDatetime: DateTime.parse(json['departsDatetime'] as String),
      arrivesDatetime: DateTime.parse(json['arrivesDatetime'] as String),
      flightDuration: json['flightDuration'] as String,
      className: json['className'] as String,
      ticketPrice: (json['ticketPrice'] as num).toDouble(),
    );
  }

  String get departureTime =>
      '${departsDatetime.hour.toString().padLeft(2, '0')}:${departsDatetime.minute.toString().padLeft(2, '0')}';

  String get arrivalTime =>
      '${arrivesDatetime.hour.toString().padLeft(2, '0')}:${arrivesDatetime.minute.toString().padLeft(2, '0')}';
}