class FlightCrewModel {
  final int flightCrewId;
  final String? firstName;
  final String? lastName;
  final String? position;
  final String? licenseType;
  final int? experienceYears;

  const FlightCrewModel({
    required this.flightCrewId,
    this.firstName,
    this.lastName,
    this.position,
    this.licenseType,
    this.experienceYears,
  });

  String get fullName => '${firstName ?? ''} ${lastName ?? ''}'.trim();

  factory FlightCrewModel.fromJson(Map<String, dynamic> json) =>
      FlightCrewModel(
        flightCrewId:    (json['flightCrewId'] as num).toInt(),
        firstName:       json['firstName'] as String?,
        lastName:        json['lastName'] as String?,
        position:        json['position'] as String?,
        licenseType:     json['licenseType'] as String?,
        experienceYears: (json['experienceYears'] as num?)?.toInt(),
      );
}

class CrewValidationModel {
  final bool valid;
  final Map<String, int> missing;
  final List<String> warnings;

  const CrewValidationModel({
    required this.valid,
    required this.missing,
    required this.warnings,
  });

  factory CrewValidationModel.fromJson(Map<String, dynamic> json) =>
      CrewValidationModel(
        valid:    json['valid'] as bool,
        missing:  (json['missing'] as Map<String, dynamic>?)
                      ?.map((k, v) => MapEntry(k, (v as num).toInt())) ?? {},
        warnings: (json['warnings'] as List<dynamic>?)
                      ?.map((e) => e as String).toList() ?? [],
      );
}