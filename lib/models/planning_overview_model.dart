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

  factory PlanningOverviewStats.fromJson(Map<String, dynamic> json) {
    return PlanningOverviewStats(
      activeFlightsCount: json['activeFlightsCount'] as int,
      routesCount: json['routesCount'] as int,
      averageLoadPercent: (json['averageLoadPercent'] as num).toDouble(),
      monthlyRevenueEur: (json['monthlyRevenueEur'] as num).toDouble(),
    );
  }
}

class OverviewFlight {
  final int flightId;
  final String flightNumber;
  final String departsAirportCode;
  final String arrivesAirportCode;
  final DateTime departsDatetime;
  final DateTime arrivesDattime;
  final String aircraftModel;
  final List<String> classNames;
  final int bookedSeats;
  final int totalSeats;
  final String flightStatusName;

  const OverviewFlight({
    required this.flightId,
    required this.flightNumber,
    required this.departsAirportCode,
    required this.arrivesAirportCode,
    required this.departsDatetime,
    required this.arrivesDattime,
    required this.aircraftModel,
    required this.classNames,
    required this.bookedSeats,
    required this.totalSeats,
    required this.flightStatusName,
  });

  double get loadPercent =>
      totalSeats == 0 ? 0 : (bookedSeats / totalSeats * 100);

  factory OverviewFlight.fromJson(Map<String, dynamic> json) {
    return OverviewFlight(
      flightId: json['flightId'] as int,
      flightNumber: json['flightNumber'] as String,
      departsAirportCode: json['departsCode'] as String,
      arrivesAirportCode: json['arrivesCode'] as String,
      departsDatetime: DateTime.parse(json['departsDatetime'] as String),
      arrivesDattime: DateTime.parse(json['arrivesDatetime'] as String),
      aircraftModel: json['aircraft'] as String,
      classNames: (json['classes'] as String)
          .split(', ')
          .where((s) => s.isNotEmpty)
          .toList(),
      bookedSeats: json['bookedSeats'] as int,
      totalSeats: json['seatCapacity'] as int,
      flightStatusName: json['flightStatus'] as String,
    );
  }
}