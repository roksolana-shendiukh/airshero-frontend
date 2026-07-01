class FlightModel {
  final int flightId;
  final int flightClassId;
  final int flightPriceId;
  final String flightNumber;
  final String airlineName;
  final String? airlineLogoUrl;
  final String departsCode;
  final String departsAirport;
  final String arrivesCode;
  final String arrivesAirport;
  final DateTime departsDatetime;
  final DateTime arrivesDatetime;
  final String flightDuration;
  final String className;
  final double ticketPrice;
  final String flightStatus;

  const FlightModel({
    required this.flightId,
    required this.flightClassId,
    required this.flightPriceId,
    required this.flightNumber,
    required this.airlineName,
    this.airlineLogoUrl,
    required this.departsCode,
    required this.departsAirport,
    required this.arrivesCode,
    required this.arrivesAirport,
    required this.departsDatetime,
    required this.arrivesDatetime,
    required this.flightDuration,
    required this.className,
    required this.ticketPrice,
    required this.flightStatus,
  });

  factory FlightModel.fromJson(Map<String, dynamic> json) => FlightModel(
        flightId:        (json['flight_id'] as num?)?.toInt() ?? 0,
        flightClassId:   (json['flight_class_id'] as num?)?.toInt() ?? 0,
        flightPriceId:   (json['flight_price_id'] as num?)?.toInt() ?? 0,
        flightNumber:    json['flight_number'] as String? ?? 'N/A',
        airlineName:     json['airline_name'] as String? ?? 'Unknown',
        airlineLogoUrl:  json['airline_logo_url'] as String?,
        departsCode:     json['departs_code'] as String? ?? '',
        departsAirport:  json['departs_airport'] as String? ?? '',
        arrivesCode:     json['arrives_code'] as String? ?? '',
        arrivesAirport:  json['arrives_airport'] as String? ?? '',
        departsDatetime: json['departs_datetime'] != null
            ? DateTime.parse(json['departs_datetime'] as String)
            : DateTime.now(),
        arrivesDatetime: json['arrives_datetime'] != null
            ? DateTime.parse(json['arrives_datetime'] as String)
            : DateTime.now(),
        flightDuration:  json['flight_duration'] as String? ?? '0:00',
        className:       json['class_name'] as String? ?? 'Economy',
        ticketPrice:     (json['ticket_price'] as num?)?.toDouble() ?? 0.0,
        flightStatus:    json['flight_status'] as String? ?? '',
      );

  String get departureTime =>
      '${departsDatetime.hour.toString().padLeft(2, '0')}:${departsDatetime.minute.toString().padLeft(2, '0')}';

  String get arrivalTime =>
      '${arrivesDatetime.hour.toString().padLeft(2, '0')}:${arrivesDatetime.minute.toString().padLeft(2, '0')}';

  String get formattedDuration {
    final parts = flightDuration.split(':');
    if (parts.length < 2) return flightDuration;
    final h = int.tryParse(parts[0]) ?? 0;
    final m = int.tryParse(parts[1]) ?? 0;
    return '${h}h ${m}m';
  }
}