import 'flight_model.dart';

/// Один рейс з усіма доступними класами і цінами
class GroupedFlight {
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
  final String flightStatus;

  /// className → ticketPrice
  final Map<String, double> classPrices;

  const GroupedFlight({
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
    required this.flightStatus,
    required this.classPrices,
  });

  /// Групуємо плоский список FlightModel по flightNumber
  static List<GroupedFlight> fromFlightList(List<FlightModel> flights) {
    final Map<String, GroupedFlight> map = {};

    for (final f in flights) {
      if (map.containsKey(f.flightNumber)) {
        map[f.flightNumber]!.classPrices[f.className] = f.ticketPrice;
      } else {
        map[f.flightNumber] = GroupedFlight(
          flightNumber: f.flightNumber,
          airlineName: f.airlineName,
          airlineLogoUrl: f.airlineLogoUrl,
          departsCode: f.departsCode,
          departsAirport: f.departsAirport,
          arrivesCode: f.arrivesCode,
          arrivesAirport: f.arrivesAirport,
          departsDatetime: f.departsDatetime,
          arrivesDatetime: f.arrivesDatetime,
          flightDuration: f.flightDuration,
          flightStatus: f.flightStatus,
          classPrices: {f.className: f.ticketPrice},
        );
      }
    }

    return map.values.toList();
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

  Set<String> get availableClasses => classPrices.keys.toSet();

  double? priceFor(String className) => classPrices[className];
}