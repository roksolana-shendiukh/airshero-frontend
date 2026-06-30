class CountryModel {
  final int countryId;
  final String? countryName;

  const CountryModel({
    required this.countryId,
    this.countryName,
  });

  factory CountryModel.fromJson(Map<String, dynamic> json) => CountryModel(
        countryId:   (json['country_id'] as num).toInt(),
        countryName: json['country_name'] as String?,
      );
}