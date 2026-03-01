class PassengerDocumentModel {
  final int documentId;
  final int citizenshipId;
  final String? citizenshipName;
  final int documentTypeId;
  final String? documentTypeName;
  final String documentNumber;
  final DateTime? documentDateOfIssue;
  final DateTime? documentDateOfExpire;

  const PassengerDocumentModel({
    required this.documentId,
    required this.citizenshipId,
    this.citizenshipName,
    required this.documentTypeId,
    this.documentTypeName,
    required this.documentNumber,
    this.documentDateOfIssue,
    this.documentDateOfExpire,
  });

  factory PassengerDocumentModel.fromJson(Map<String, dynamic> json) {
    return PassengerDocumentModel(
      documentId: json['documentId'] as int,
      citizenshipId: json['citizenshipId'] as int,
      citizenshipName: json['citizenshipName'] as String?,
      documentTypeId: json['documentTypeId'] as int,
      documentTypeName: json['documentTypeName'] as String?,
      documentNumber: json['documentNumber'] as String,
      documentDateOfIssue: json['documentDateOfIssue'] != null
          ? DateTime.parse(json['documentDateOfIssue'] as String)
          : null,
      documentDateOfExpire: json['documentDateOfExpire'] != null
          ? DateTime.parse(json['documentDateOfExpire'] as String)
          : null,
    );
  }
}


class PassengerModel {
  final String id;
  final String firstName;
  final String lastName;
  final String sex;
  final DateTime? dateOfBirth;
  final PassengerDocumentModel? document;

  const PassengerModel({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.sex,
    this.dateOfBirth,
    this.document,
  });

  static String sexFromBool(bool? value) {
    if (value == true) return 'Male';
    if (value == false) return 'Female';
    return 'Other';
  }

  static bool? sexToBool(String value) {
    if (value == 'Male') return true;
    if (value == 'Female') return false;
    return null;
  }

  factory PassengerModel.fromJson(Map<String, dynamic> json) {
    final rawSex = json['sex'];
    final String sex;
    if (rawSex is bool) {
      sex = sexFromBool(rawSex);
    } else {
      sex = rawSex as String? ?? 'Other';
    }

    return PassengerModel(
      id: json['passengerId'].toString(),
      firstName: json['firstName'] as String,
      lastName: json['lastName'] as String,
      sex: sex,
      dateOfBirth: json['dateOfBirth'] != null
          ? DateTime.parse(json['dateOfBirth'] as String)
          : null,
      document: json['document'] != null
          ? PassengerDocumentModel.fromJson(json['document'] as Map<String, dynamic>)
          : null,
    );
  }

  String get fullName => '$firstName $lastName';

  String get citizenship => document?.citizenshipName ?? '';
  String get documentType => document?.documentTypeName ?? '';
  String get documentNumber => document?.documentNumber ?? '';
  DateTime? get documentExpire => document?.documentDateOfExpire;
  int? get citizenshipId => document?.citizenshipId;
  int? get documentTypeId => document?.documentTypeId;
}