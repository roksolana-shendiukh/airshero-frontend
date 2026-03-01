class FlightModel {
  final int flightId;
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

  factory FlightModel.fromJson(Map<String, dynamic> json) {
    return FlightModel(
      flightId: (json['flightId'] as num?)?.toInt() ?? 0,
      flightPriceId: (json['flightPriceId'] as num?)?.toInt() ?? 0,
      flightNumber: json['flightNumber'] as String? ?? 'N/A',
      airlineName: json['airlineName'] as String? ?? 'Unknown',
      airlineLogoUrl: json['airlineLogoUrl'] as String?,
      departsCode: json['departsCode'] as String? ?? '',
      departsAirport: json['departsAirport'] as String? ?? '',
      arrivesCode: json['arrivesCode'] as String? ?? '',
      arrivesAirport: json['arrivesAirport'] as String? ?? '',
      departsDatetime: json['departsDatetime'] != null
          ? DateTime.parse(json['departsDatetime'] as String)
          : DateTime.now(),
      arrivesDatetime: json['arrivesDatetime'] != null
          ? DateTime.parse(json['arrivesDatetime'] as String)
          : DateTime.now(),
      flightDuration: json['flightDuration'] as String? ?? '0:00',
      className: json['className'] as String? ?? 'Economy',
      ticketPrice: (json['ticketPrice'] as num?)?.toDouble() ?? 0.0,
      flightStatus: json['flightStatus'] as String? ?? '',
    );
  }

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