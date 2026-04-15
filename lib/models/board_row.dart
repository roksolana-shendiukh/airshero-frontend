import '../../models/flight_without_operation_model.dart';
import '../../models/flight_operation_model.dart';

class BoardRow {
  final String   flightNumber;
  final String   departsCode;
  final String   arrivesCode;
  final DateTime departsDatetime;
  final String?  aircraftModel;
  final String?  airlineName;
  final String   statusName;

  final FlightWithoutOperationModel? flight;
  final FlightOperationModel?        operation;

  const BoardRow({
    required this.flightNumber,
    required this.departsCode,
    required this.arrivesCode,
    required this.departsDatetime,
    required this.aircraftModel,
    required this.airlineName,
    required this.statusName,
    this.flight,
    this.operation,
  });

  factory BoardRow.fromFlight(FlightWithoutOperationModel f) => BoardRow(
        flightNumber:    f.flightNumber,
        departsCode:     f.departsCode,
        arrivesCode:     f.arrivesCode,
        departsDatetime: f.departsDatetime,
        aircraftModel:   null,
        airlineName:     f.airlineName,  
        statusName:      'Scheduled',
        flight:          f,
      );

  factory BoardRow.fromOperation(FlightOperationModel o) => BoardRow(
        flightNumber:    o.flightNumber ?? '—',
        departsCode:     o.departsCode ?? '—',
        arrivesCode:     o.arrivesCode ?? '—',
        departsDatetime: o.departsDatetime ?? DateTime.now(),
        aircraftModel:   o.aircraftModel,
        airlineName:     o.airlineName,  
        statusName:      o.statusName ?? '—',
        operation:       o,
      );

  String get timeLabel {
    final h = departsDatetime.hour.toString().padLeft(2, '0');
    final m = departsDatetime.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }
}