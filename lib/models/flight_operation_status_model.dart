class FlightOperationStatusModel {
  final int statusId;
  final String statusName;

  const FlightOperationStatusModel({
    required this.statusId,
    required this.statusName,
  });

  factory FlightOperationStatusModel.fromJson(Map<String, dynamic> json) =>
      FlightOperationStatusModel(
        statusId:   (json['flight_operation_status_id'] as num).toInt(),
        statusName: json['flight_operation_status_name'] as String,
      );
}