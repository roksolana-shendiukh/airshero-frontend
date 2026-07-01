class FlightOperationModel {
  final int flightOperationId;
  final int flightId;
  final String? flightNumber;
  final String? departsCode;
  final String? arrivesCode;
  final DateTime? departsDatetime;
  final DateTime? arrivesDatetime;
  final int statusId;
  final String? statusName;
  final int? airfleetId;
  final String? airlineName;
  final String? aircraftModel;
  final int? gateId;
  final String? gateCode;
  final String? actualDepartureDatetime;
  final String? actualArrivalDatetime;
  final String? boardingStartTime;
  final String? boardingEndTime;
  final String? baggageLoadingStartTime;
  final String? baggageLoadingEndTime;
  final String? stateDescription;

  const FlightOperationModel({
    required this.flightOperationId,
    required this.flightId,
    this.flightNumber,
    this.departsCode,
    this.arrivesCode,
    this.departsDatetime,
    this.arrivesDatetime,
    required this.statusId,
    this.statusName,
    this.airfleetId,
    this.airlineName,
    this.aircraftModel,
    this.gateId,
    this.gateCode,
    this.actualDepartureDatetime,
    this.actualArrivalDatetime,
    this.boardingStartTime,
    this.boardingEndTime,
    this.baggageLoadingStartTime,
    this.baggageLoadingEndTime,
    this.stateDescription,
  });

  factory FlightOperationModel.fromJson(Map<String, dynamic> json) =>
      FlightOperationModel(
        flightOperationId:       (json['flight_operation_id'] as num).toInt(),
        flightId:                (json['flight_id'] as num).toInt(),
        flightNumber:            json['flight_number'] as String?,
        departsCode:             json['departs_code'] as String?,
        arrivesCode:             json['arrives_code'] as String?,
        departsDatetime:         json['departs_datetime'] != null
            ? DateTime.parse(json['departs_datetime'] as String) : null,
        arrivesDatetime:         json['arrives_datetime'] != null
            ? DateTime.parse(json['arrives_datetime'] as String) : null,
        statusId:                (json['status_id'] as num).toInt(),
        statusName:              json['status_name'] as String?,
        airfleetId:              (json['airfleet_id'] as num?)?.toInt(),
        airlineName:             json['airline_name'] as String?,
        aircraftModel:           json['aircraft_model'] as String?,
        gateId:                  (json['gate_id'] as num?)?.toInt(),
        gateCode:                json['gate_code'] as String?,
        actualDepartureDatetime: json['actual_departure_datetime'] as String?,
        actualArrivalDatetime:   json['actual_arrival_datetime'] as String?,
        boardingStartTime:       json['boarding_start_time'] as String?,
        boardingEndTime:         json['boarding_end_time'] as String?,
        baggageLoadingStartTime: json['baggage_loading_start_time'] as String?,
        baggageLoadingEndTime:   json['baggage_loading_end_time'] as String?,
        stateDescription:        json['state_description'] as String?,
      );
}