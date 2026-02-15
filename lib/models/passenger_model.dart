class PassengerModel {
  final String id;
  final String firstName;
  final String lastName;
  final String sex; 
  final DateTime dateOfBirth;
  final String citizenship;
  final String documentType; 
  final String documentNumber;
  final DateTime documentExpire;

  const PassengerModel({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.sex,
    required this.dateOfBirth,
    required this.citizenship,
    required this.documentType,
    required this.documentNumber,
    required this.documentExpire,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'firstName': firstName,
      'lastName': lastName,
      'sex': sex,
      'dateOfBirth': dateOfBirth.toIso8601String(),
      'citizenship': citizenship,
      'documentType': documentType,
      'documentNumber': documentNumber,
      'documentExpire': documentExpire.toIso8601String(),
    };
  }

  factory PassengerModel.fromJson(Map<String, dynamic> json) {
    return PassengerModel(
      id: json['id'] as String,
      firstName: json['firstName'] as String,
      lastName: json['lastName'] as String,
      sex: json['sex'] as String,
      dateOfBirth: DateTime.parse(json['dateOfBirth'] as String),
      citizenship: json['citizenship'] as String,
      documentType: json['documentType'] as String,
      documentNumber: json['documentNumber'] as String,
      documentExpire: DateTime.parse(json['documentExpire'] as String),
    );
  }

  String get fullName => '$firstName $lastName';
}