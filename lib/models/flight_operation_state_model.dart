class FlightOperationStateModel {
  final int stateId;
  final String description;

  const FlightOperationStateModel({
    required this.stateId,
    required this.description,
  });

  factory FlightOperationStateModel.fromJson(Map<String, dynamic> json) =>
      FlightOperationStateModel(
        stateId:     (json['stateId'] as num).toInt(),
        description: json['description'] as String,
      );
}