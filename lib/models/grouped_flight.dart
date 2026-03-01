import 'flight_model.dart';

class ClassPriceInfo {
  final int flightPriceId;
  final double price;

  const ClassPriceInfo({
    required this.flightPriceId,
    required this.price,
  });
}

class GroupedFlight {
  final int flightId;
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

  final Map<String, ClassPriceInfo> classPrices;

  const GroupedFlight({
    required this.flightId,
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

  static List<GroupedFlight> fromFlightList(List<FlightModel> flights) {
    final Map<String, GroupedFlight> map = {};

    for (final f in flights) {
      if (map.containsKey(f.flightNumber)) {
        map[f.flightNumber]!.classPrices[f.className] = ClassPriceInfo(
          flightPriceId: f.flightPriceId,
          price: f.ticketPrice,
        );
      } else {
        map[f.flightNumber] = GroupedFlight(
          flightId: f.flightId,
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
          classPrices: {
            f.className: ClassPriceInfo(
              flightPriceId: f.flightPriceId,
              price: f.ticketPrice,
            ),
          },
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

  double? priceFor(String className) => classPrices[className]?.price;

  int? flightPriceIdFor(String className) => classPrices[className]?.flightPriceId;
}