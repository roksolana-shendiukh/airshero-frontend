class PassengerDocumentModel {
  final int documentId;
  final int citizenshipId;
  final String citizenshipName;
  final int documentTypeId;
  final String documentTypeName;
  final String documentNumber;
  final DateTime? documentDateOfIssue;
  final DateTime? documentDateOfExpire;

  const PassengerDocumentModel({
    required this.documentId,
    required this.citizenshipId,
    required this.citizenshipName,
    required this.documentTypeId,
    required this.documentTypeName,
    required this.documentNumber,
    this.documentDateOfIssue,
    this.documentDateOfExpire,
  });

  factory PassengerDocumentModel.fromJson(Map<String, dynamic> json) {
    return PassengerDocumentModel(
      documentId: json['document_id'] as int,
      citizenshipId: json['citizenship_id'] as int,
      citizenshipName: json['citizenship_name'] as String? ?? '',
      documentTypeId: json['document_type_id'] as int,
      documentTypeName: json['document_type_name'] as String? ?? '',
      documentNumber: json['document_number'] as String? ?? '',
      documentDateOfIssue: json['document_date_of_issue'] != null
          ? DateTime.tryParse(json['document_date_of_issue'] as String)
          : null,
      documentDateOfExpire: json['document_date_of_expire'] != null
          ? DateTime.tryParse(json['document_date_of_expire'] as String)
          : null,
    );
  }
}

class PassengerModel {
  final int passengerId;
  final String firstName;
  final String lastName;
  final String sex;
  final String? email;
  final DateTime? dateOfBirth;
  final List<PassengerDocumentModel> documents;

  const PassengerModel({
    required this.passengerId,
    required this.firstName,
    required this.lastName,
    required this.sex,
    this.email,
    this.dateOfBirth,
    this.documents = const [],
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

    final rawDocs = json['documents'];
    final List<PassengerDocumentModel> documents;
    if (rawDocs is List) {
      documents = rawDocs
          .map((e) => PassengerDocumentModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } else {
      documents = [];
    }

    return PassengerModel(
      passengerId: json['passenger_id'] as int,
      firstName: json['first_name'] as String? ?? '',
      lastName: json['last_name'] as String? ?? '',
      sex: sex,
      email: json['email'] as String?,
      dateOfBirth: json['date_of_birth'] != null
          ? DateTime.tryParse(json['date_of_birth'] as String)
          : null,
      documents: documents,
    );
  }

  PassengerDocumentModel? get document =>
      documents.isNotEmpty ? documents.first : null;

  String get fullName => '$firstName $lastName';
  String get citizenship => document?.citizenshipName ?? '';
  String get documentType => document?.documentTypeName ?? '';
  String get documentNumber => document?.documentNumber ?? '';
  DateTime? get documentExpire => document?.documentDateOfExpire;
  int? get citizenshipId => document?.citizenshipId;
  int? get documentTypeId => document?.documentTypeId;
}