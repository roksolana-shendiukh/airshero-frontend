import 'grouped_flight.dart';

class ClassWarning {
  final String passengerLabel;   
  final String requestedClass; 
  final Map<String, double> alternatives;

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

  const PassengerClassAssignment({
    required this.passengerLabel,
    required this.assignedClass,
    required this.price,
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