class CityModel {
  final int cityId;
  final int? countryId;
  final String? countryName; 
  final String? cityName;

  const CityModel({
    required this.cityId,
    this.countryId,
    this.countryName,
    this.cityName,
  });

  factory CityModel.fromJson(Map<String, dynamic> json) => CityModel(
        cityId:      (json['city_id'] as num).toInt(),
        countryId:   (json['country_id'] as num?)?.toInt(),
        countryName: json['country_name'] as String?,
        cityName:    json['city_name'] as String?,
      );
}