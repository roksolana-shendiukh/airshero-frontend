class FlightOperationStatusModel {
  final int statusId;
  final String statusName;

  const FlightOperationStatusModel({
    required this.statusId,
    required this.statusName,
  });

  factory FlightOperationStatusModel.fromJson(Map<String, dynamic> json) =>
      FlightOperationStatusModel(
        statusId:   (json['flightOperationStatusId'] as num).toInt(),
        statusName: json['flightOperationStatusName'] as String,
      );
}