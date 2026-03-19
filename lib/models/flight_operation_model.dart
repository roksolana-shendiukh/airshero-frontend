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
        flightOperationId:      (json['flightOperationId'] as num).toInt(),
        flightId:               (json['flightId'] as num).toInt(),
        flightNumber:           json['flightNumber'] as String?,
        departsCode:            json['departsCode'] as String?,
        arrivesCode:            json['arrivesCode'] as String?,
        departsDatetime:        json['departsDatetime'] != null
            ? DateTime.parse(json['departsDatetime'] as String) : null,
        arrivesDatetime:        json['arrivesDdatetime'] != null
            ? DateTime.parse(json['arrivesDdatetime'] as String) : null,
        statusId:               (json['statusId'] as num).toInt(),
        statusName:             json['statusName'] as String?,
        airfleetId:             (json['airfleetId'] as num?)?.toInt(),
        aircraftModel:          json['aircraftModel'] as String?,
        gateId:                 (json['gateId'] as num?)?.toInt(),
        gateCode:               json['gateCode'] as String?,
        actualDepartureDatetime: json['actualDepartureDatetime'] as String?,
        actualArrivalDatetime:   json['actualArrivalDatetime'] as String?,
        boardingStartTime:       json['boardingStartTime'] as String?,
        boardingEndTime:         json['boardingEndTime'] as String?,
        baggageLoadingStartTime: json['baggageLoadingStartTime'] as String?,
        baggageLoadingEndTime:   json['baggageLoadingEndTime'] as String?,
        stateDescription:        json['stateDescription'] as String?,
      );
}