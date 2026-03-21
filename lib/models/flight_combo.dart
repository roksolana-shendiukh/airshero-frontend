import 'grouped_flight.dart';

class ClassWarning {
  final String passengerLabel;
  final String requestedClass;
  final Map<String, ClassPriceInfo> alternatives;

  const ClassWarning({
    required this.passengerLabel,
    required this.requestedClass,
    required this.alternatives,
  });
}

class PassengerClassAssignment {
  final String passengerLabel;
  final String assignedClass;
  final double price;
  final int flightPriceId;
  final int flightClassId;

  const PassengerClassAssignment({
    required this.passengerLabel,
    required this.assignedClass,
    required this.price,
    required this.flightPriceId,
    required this.flightClassId,
  });
}

class FlightCombo {
  final GroupedFlight outbound;
  final GroupedFlight? returnFlight;

  final List<PassengerClassAssignment> outboundAssignments;
  final List<PassengerClassAssignment> returnAssignments;

  final List<ClassWarning> outboundWarnings;
  final List<ClassWarning> returnWarnings;

  final double totalPrice;

  const FlightCombo({
    required this.outbound,
    this.returnFlight,
    required this.outboundAssignments,
    this.outboundWarnings = const [],
    this.returnAssignments = const [],
    this.returnWarnings = const [],
    required this.totalPrice,
  });

  bool get hasWarnings =>
      outboundWarnings.isNotEmpty || returnWarnings.isNotEmpty;
}