class FlightAlternatives {
  final List<NearbyCity> nearbyCities;
  final List<ConnectingHub> connectingHubs;

  FlightAlternatives({
    required this.nearbyCities,
    required this.connectingHubs,
  });

  factory FlightAlternatives.fromJson(Map<String, dynamic> json) =>
      FlightAlternatives(
        nearbyCities: (json['nearby_cities'] as List<dynamic>?)
                ?.map((e) => NearbyCity.fromJson(e))
                .toList() ?? [],
        connectingHubs: (json['connecting_hubs'] as List<dynamic>?)
                ?.map((e) => ConnectingHub.fromJson(e))
                .toList() ?? [],
      );
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

  factory NearbyCity.fromJson(Map<String, dynamic> json) => NearbyCity(
        cityId:     (json['city_id'] as num?)?.toInt() ?? 0,
        cityName:   json['city_name'] as String? ?? '',
        distanceKm: (json['distance_km'] as num?)?.toInt() ?? 0,
      );
}

class ConnectingHub {
  final int cityId;
  final String cityName;

  ConnectingHub({
    required this.cityId,
    required this.cityName,
  });

  factory ConnectingHub.fromJson(Map<String, dynamic> json) => ConnectingHub(
        cityId:   (json['city_id'] as num?)?.toInt() ?? 0,
        cityName: json['city_name'] as String? ?? '',
      );
}