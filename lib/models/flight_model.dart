class FlightModel {
  final int flightId;
  final String flightNumber;
  final String airline;
  final String fromAirportCode;
  final String fromAirportName;
  final String toAirportCode;
  final String toAirportName;
  final String departureDateTime;
  final String arrivalDateTime;
  final String duration;
  final String flightStatus;

  const FlightModel({
    required this.flightId,
    required this.flightNumber,
    required this.airline,
    required this.fromAirportCode,
    required this.fromAirportName,
    required this.toAirportCode,
    required this.toAirportName,
    required this.departureDateTime,
    required this.arrivalDateTime,
    required this.duration,
    required this.flightStatus,
  });

  factory FlightModel.fromJson(Map<String, dynamic> json) {
    return FlightModel(
      flightId: json['flightId'] as int,
      flightNumber: json['flightNumber'] as String,
      airline: json['airline'] as String,
      fromAirportCode: json['fromAirportCode'] as String,
      fromAirportName: json['fromAirportName'] as String,
      toAirportCode: json['toAirportCode'] as String,
      toAirportName: json['toAirportName'] as String,
      departureDateTime: json['departureDateTime'] as String,
      arrivalDateTime: json['arrivalDateTime'] as String,
      duration: json['duration'] as String,
      flightStatus: json['flightStatus'] as String,
    );
  }

  String get departureTime => departureDateTime.split('T').last;
  String get arrivalTime => arrivalDateTime.split('T').last;
}