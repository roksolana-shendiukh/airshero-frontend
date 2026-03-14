class CreateFlightOperationDTO {
  final int flightId;
  final int? airfleetId;
  final int? gateId;

  const CreateFlightOperationDTO({
    required this.flightId,
    this.airfleetId,
    this.gateId,
  });

  Map<String, dynamic> toJson() => {
        'flight_id': flightId,
        if (airfleetId != null) 'airfleet_id': airfleetId,
        if (gateId != null) 'gate_id': gateId,
      };
}