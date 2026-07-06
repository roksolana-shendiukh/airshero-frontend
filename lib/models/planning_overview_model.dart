class PlanningOverviewStats {
  final int activeFlightsCount;
  final int routesCount;
  final double averageLoadPercent;
  final double monthlyRevenueEur;

  const PlanningOverviewStats({
    required this.activeFlightsCount,
    required this.routesCount,
    required this.averageLoadPercent,
    required this.monthlyRevenueEur,
  });

  factory PlanningOverviewStats.fromJson(Map<String, dynamic> json) =>
      PlanningOverviewStats(
        activeFlightsCount: (json['active_flights_count'] as num).toInt(),
        routesCount:        (json['routes_count'] as num).toInt(),
        averageLoadPercent: (json['average_load_percent'] as num).toDouble(),
        monthlyRevenueEur:  (json['monthly_revenue_eur'] as num).toDouble(),
      );
}

class OverviewFlight {
  final int flightId;
  final String flightNumber;
  final String departsAirportCode;
  final String arrivesAirportCode;
  final DateTime departsDatetime;
  final DateTime arrivesDatetime;
  final String aircraftModel;
  final List<String> classNames;
  final int bookedSeats;
  final int totalSeats;
  final String flightStatusName;
  final String flightDuration;

  const OverviewFlight({
    required this.flightId,
    required this.flightNumber,
    required this.departsAirportCode,
    required this.arrivesAirportCode,
    required this.departsDatetime,
    required this.arrivesDatetime,
    required this.aircraftModel,
    required this.classNames,
    required this.bookedSeats,
    required this.totalSeats,
    required this.flightStatusName,
    required this.flightDuration,
  });

  double get loadPercent =>
      totalSeats == 0 ? 0 : (bookedSeats / totalSeats * 100);

  factory OverviewFlight.fromJson(Map<String, dynamic> json) => OverviewFlight(
        flightId:           (json['flight_id'] as num).toInt(),
        flightNumber:       json['flight_number'] as String,
        departsAirportCode: json['departs_code'] as String,
        arrivesAirportCode: json['arrives_code'] as String,
        departsDatetime:    DateTime.parse(json['departs_datetime'] as String),
        arrivesDatetime:    DateTime.parse(json['arrives_datetime'] as String),
        aircraftModel:      json['aircraft'] as String,
        classNames:         (json['classes'] as String)
            .split(', ')
            .where((s) => s.isNotEmpty)
            .toList(),
        bookedSeats:        (json['booked_seats'] as num).toInt(),
        totalSeats:         (json['seat_capacity'] as num).toInt(),
        flightStatusName:   json['flight_status'] as String,
        flightDuration:     json['flight_duration'] as String? ?? '00:00',
      );
}