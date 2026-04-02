class BookingSegmentDraft {
  final int flightId;
  final int flightClassId;
  final String fromCity;
  final String toCity;
  final int fromCityId;
  final int toCityId;
  final String fromAirportCode;
  final String toAirportCode;
  final String departureTime;
  final String arrivalTime;
  final String duration;
  final String airlineName;
  final String airlineLogoUrl;
  final DateTime departDate;
  final Map<String, String> passengerClassLabels;
  final double basePrice;
  final List<Map<String, dynamic>> assignments;

  final Map<int, Map<int, int>> baggageSelections;

  const BookingSegmentDraft({
    required this.flightId,
    required this.flightClassId,
    required this.fromCity,
    required this.toCity,
    required this.fromCityId,
    required this.toCityId,
    required this.fromAirportCode,
    required this.toAirportCode,
    required this.departureTime,
    required this.arrivalTime,
    required this.duration,
    required this.airlineName,
    required this.airlineLogoUrl,
    required this.departDate,
    required this.passengerClassLabels,
    required this.basePrice,
    required this.assignments,
    this.baggageSelections = const {},
  });

  BookingSegmentDraft copyWith({
    Map<int, Map<int, int>>? baggageSelections,
  }) {
    return BookingSegmentDraft(
      flightId: flightId,
      flightClassId: flightClassId,
      fromCity: fromCity,
      toCity: toCity,
      fromCityId: fromCityId,
      toCityId: toCityId,
      fromAirportCode: fromAirportCode,
      toAirportCode: toAirportCode,
      departureTime: departureTime,
      arrivalTime: arrivalTime,
      duration: duration,
      airlineName: airlineName,
      airlineLogoUrl: airlineLogoUrl,
      departDate: departDate,
      passengerClassLabels: passengerClassLabels,
      basePrice: basePrice,
      assignments: assignments,
      baggageSelections: baggageSelections ?? this.baggageSelections,
    );
  }
}

class BookingGroupDraft {
  final List<BookingSegmentDraft> segments;
  final Map<String, int> passengers;

  final int finalDestinationCityId;
  final String finalDestinationCity;

  const BookingGroupDraft({
    required this.segments,
    required this.passengers,
    required this.finalDestinationCityId,
    required this.finalDestinationCity,
  });

  bool get isMultiSegment => segments.length > 1;

  BookingSegmentDraft get firstSegment => segments[0];
  BookingSegmentDraft? get secondSegment =>
      segments.length > 1 ? segments[1] : null;

  double get totalPrice =>
      segments.fold(0.0, (sum, s) => sum + s.basePrice);

  BookingGroupDraft withSecondSegment(BookingSegmentDraft segment) {
    return BookingGroupDraft(
      segments: [segments[0], segment],
      passengers: passengers,
      finalDestinationCityId: finalDestinationCityId,
      finalDestinationCity: finalDestinationCity,
    );
  }

  BookingGroupDraft withBaggageForSegment(
    int segmentIndex,
    Map<int, Map<int, int>> baggageSelections,
  ) {
    final updated = List<BookingSegmentDraft>.from(segments);
    updated[segmentIndex] = updated[segmentIndex].copyWith(
      baggageSelections: baggageSelections,
    );
    return BookingGroupDraft(
      segments: updated,
      passengers: passengers,
      finalDestinationCityId: finalDestinationCityId,
      finalDestinationCity: finalDestinationCity,
    );
  }
}