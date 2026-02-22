class CityModel {
  final int cityId;
  final String cityName;
  final String countryName;

  const CityModel({
    required this.cityId,
    required this.cityName,
    required this.countryName,
  });

  factory CityModel.fromJson(Map<String, dynamic> json) {
    return CityModel(
      cityId: json['cityId'] as int,
      cityName: json['cityName'] as String,
      countryName: json['countryName'] as String,
    );
  }

  String get displayName => '$cityName, $countryName';
}