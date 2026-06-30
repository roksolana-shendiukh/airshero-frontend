class FlightCrewModel {
  final int flightCrewId;
  final String? firstName;
  final String? lastName;
  final String? position;
  final int? positionId;
  final String? licenseType;
  final int? licenseTypeId;
  final int? experienceYears;
  final bool locationKnown;

  const FlightCrewModel({
    required this.flightCrewId,
    this.firstName,
    this.lastName,
    this.position,
    this.positionId,
    this.licenseType,
    this.licenseTypeId,
    this.experienceYears,
    this.locationKnown = true,
  });

  String get fullName => '${firstName ?? ''} ${lastName ?? ''}'.trim();

  factory FlightCrewModel.fromJson(Map<String, dynamic> json) => FlightCrewModel(
        flightCrewId:    (json['flight_crew_id'] as num).toInt(),
        firstName:       json['first_name']        as String?,
        lastName:        json['last_name']         as String?,
        position:        json['position']          as String?,
        positionId:      (json['position_id']      as num?)?.toInt(),
        licenseType:     json['license_type']      as String?,
        licenseTypeId:   (json['license_type_id']  as num?)?.toInt(),
        experienceYears: (json['experience_years'] as num?)?.toInt(),
        locationKnown:   json['location_known']    as bool? ?? true,
      );
}

class CrewValidationModel {
  final bool valid;
  final Map<String, int> missing;
  final List<String> warnings;
  final Map<String, int> required;

  const CrewValidationModel({
    required this.valid,
    required this.missing,
    required this.warnings,
    this.required = const {},
  });

  factory CrewValidationModel.fromJson(Map<String, dynamic> json) =>
      CrewValidationModel(
        valid:    json['valid'] as bool,
        missing:  (json['missing'] as Map<String, dynamic>?)
                      ?.map((k, v) => MapEntry(k, (v as num).toInt())) ?? {},
        warnings: (json['warnings'] as List<dynamic>?)
                      ?.map((e) => e as String).toList() ?? [],
        required: (json['required'] as Map<String, dynamic>?)
                      ?.map((k, v) => MapEntry(k, (v as num).toInt())) ?? {},
      );
}