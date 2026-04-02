class FlightAlternatives {
  final List<NearbyCity> nearbyCities;
  final List<ConnectingHub> connectingHubs;

  FlightAlternatives({
    required this.nearbyCities,
    required this.connectingHubs,
  });

  factory FlightAlternatives.fromJson(Map<String, dynamic> json) {
    return FlightAlternatives(
      nearbyCities: (json['nearbyCities'] as List<dynamic>?)
              ?.map((e) => NearbyCity.fromJson(e))
              .toList() ??
          [],
      connectingHubs: (json['connectingHubs'] as List<dynamic>?)
              ?.map((e) => ConnectingHub.fromJson(e))
              .toList() ??[],
    );
  }
}

class NearbyCity {
  final int cityId;
  final String cityName;
  final int distanceKm;

  NearbyCity({
    required this.cityId,
    required this.cityName,
    required this.distanceKm,
  });

  factory NearbyCity.fromJson(Map<String, dynamic> json) {
    return NearbyCity(
      cityId: json['cityId'] ?? 0,
      cityName: json['cityName'] ?? '',
      distanceKm: json['distanceKm'] ?? 0,
    );
  }
}

class ConnectingHub {
  final int cityId;
  final String cityName;

  ConnectingHub({
    required this.cityId,
    required this.cityName,
  });

  factory ConnectingHub.fromJson(Map<String, dynamic> json) {
    return ConnectingHub(
      cityId: json['cityId'] ?? 0,
      cityName: json['cityName'] ?? '',
    );
  }
}