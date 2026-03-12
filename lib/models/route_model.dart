class RouteModel {
  final int routeId;
  final String flightNumber;
  final double departsLat;
  final double departsLng;
  final String departsCode;
  final double arrivesLat;
  final double arrivesLng;
  final String arrivesCode;

  const RouteModel({
    required this.routeId,
    required this.flightNumber,
    required this.departsLat,
    required this.departsLng,
    required this.departsCode,
    required this.arrivesLat,
    required this.arrivesLng,
    required this.arrivesCode,
  });

  factory RouteModel.fromJson(Map<String, dynamic> json) {
    final dep = json['departsAirport'] as Map<String, dynamic>;
    final arr = json['arrivesAirport'] as Map<String, dynamic>;
    return RouteModel(
      routeId:      json['routeId'] as int,
      flightNumber: json['flightNumber'] as String,
      departsLat:   (dep['latitude'] as num).toDouble(),
      departsLng:   (dep['longitude'] as num).toDouble(),
      departsCode:  dep['airportCode'] as String,
      arrivesLat:   (arr['latitude'] as num).toDouble(),
      arrivesLng:   (arr['longitude'] as num).toDouble(),
      arrivesCode:  arr['airportCode'] as String,
    );
  }
}