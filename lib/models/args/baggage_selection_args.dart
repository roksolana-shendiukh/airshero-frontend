import 'package:flutter/material.dart';
import '../../models/booking_group_draft.dart';

class BaggageSelectionArguments {
  final String fromCity;
  final String toCity;
  final DateTime departDate;
  final DateTime? returnDate;
  final Map<String, int> passengers;
  final Map<String, String> passengerClassLabels;
  final String airlineName;
  final String airlineLogoUrl;
  final String fromAirportCode;
  final String toAirportCode;
  final String departureTime;
  final String arrivalTime;
  final String duration;
  final double basePrice;
  final bool isRoundTrip;
  final List<Map<String, dynamic>> outboundAssignments;
  final List<Map<String, dynamic>> returnAssignments;
  final int outboundFlightId;
  final int outboundFlightClassId;
  final BookingGroupDraft? bookingGroupDraft;
  final int segmentIndex;
  final Map<int, Map<String, dynamic>>? initialPassengerData;
  final int? bookingId;
  final String? bookingNumber;
  final int? bookingId2;
  final String? bookingNumber2;
  final DateTime? expiresAt;
  final int? leg2FlightClassId;
  final String? leg2FromCity;
  final String? leg2ToCity;

  BaggageSelectionArguments({
    required this.fromCity,
    required this.toCity,
    required this.departDate,
    this.returnDate,
    required this.passengers,
    required this.passengerClassLabels,
    required this.airlineName,
    required this.airlineLogoUrl,
    required this.fromAirportCode,
    required this.toAirportCode,
    required this.departureTime,
    required this.arrivalTime,
    required this.duration,
    required this.basePrice,
    required this.isRoundTrip,
    required this.outboundAssignments,
    this.returnAssignments = const [],
    required this.outboundFlightId,
    required this.outboundFlightClassId,
    this.bookingGroupDraft,
    this.segmentIndex = 0,
    this.initialPassengerData,
    this.bookingId,
    this.bookingNumber,
    this.bookingId2,
    this.bookingNumber2,
    this.expiresAt,
    this.leg2FlightClassId,
    this.leg2FromCity,
    this.leg2ToCity,
  });

  Map<String, dynamic> toMap() => {
        'fromCity': fromCity,
        'toCity': toCity,
        'departDate': departDate.toIso8601String(),
        'returnDate': returnDate?.toIso8601String(),
        'passengers': passengers,
        'passengerClassLabels': passengerClassLabels,
        'airlineName': airlineName,
        'airlineLogoUrl': airlineLogoUrl,
        'fromAirportCode': fromAirportCode,
        'toAirportCode': toAirportCode,
        'departureTime': departureTime,
        'arrivalTime': arrivalTime,
        'duration': duration,
        'basePrice': basePrice,
        'isRoundTrip': isRoundTrip,
        'outboundAssignments': outboundAssignments,
        'returnAssignments': returnAssignments,
        'outboundFlightId': outboundFlightId,
        'outboundFlightClassId': outboundFlightClassId,
        'segmentIndex': segmentIndex,
        'bookingId': bookingId,
        'bookingNumber': bookingNumber,
        'bookingId2': bookingId2,
        'bookingNumber2': bookingNumber2,
        'expiresAt': expiresAt?.toIso8601String(),
        'leg2FlightClassId': leg2FlightClassId,
        'leg2FromCity': leg2FromCity,
        'leg2ToCity': leg2ToCity,
      };

  static BaggageSelectionArguments? fromMap(Map<String, dynamic>? map) {
    if (map == null) return null;
    try {
      DateTime parseDate(dynamic val) {
        if (val is DateTime) return val;
        return DateTime.parse(val as String);
      }

      List<Map<String, dynamic>> parseAssignments(dynamic raw) {
        if (raw == null) return [];
        return (raw as List)
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList();
      }

      return BaggageSelectionArguments(
        fromCity: map['fromCity'] as String,
        toCity: map['toCity'] as String,
        departDate: parseDate(map['departDate']),
        returnDate:
            map['returnDate'] != null ? parseDate(map['returnDate']) : null,
        passengers: Map<String, int>.from(map['passengers'] as Map),
        passengerClassLabels:
            Map<String, String>.from(map['passengerClassLabels'] as Map),
        airlineName: map['airlineName'] as String,
        airlineLogoUrl: map['airlineLogoUrl'] as String,
        fromAirportCode: map['fromAirportCode'] as String,
        toAirportCode: map['toAirportCode'] as String,
        departureTime: map['departureTime'] as String,
        arrivalTime: map['arrivalTime'] as String,
        duration: map['duration'] as String,
        basePrice: (map['basePrice'] as num).toDouble(),
        isRoundTrip: map['isRoundTrip'] as bool,
        outboundAssignments: parseAssignments(map['outboundAssignments']),
        returnAssignments: parseAssignments(map['returnAssignments']),
        outboundFlightId: (map['outboundFlightId'] as num).toInt(),
        outboundFlightClassId: (map['outboundFlightClassId'] as num).toInt(),
        segmentIndex: (map['segmentIndex'] as num?)?.toInt() ?? 0,
        bookingId: map['bookingId'] as int?,
        bookingNumber: map['bookingNumber'] as String?,
        bookingId2: map['bookingId2'] as int?,
        bookingNumber2: map['bookingNumber2'] as String?,
        expiresAt: map['expiresAt'] != null
            ? DateTime.parse(map['expiresAt'] as String)
            : null,
        leg2FlightClassId: map['leg2FlightClassId'] as int?,
        leg2FromCity: map['leg2FromCity'] as String?,
        leg2ToCity: map['leg2ToCity'] as String?,
      );
    } catch (e) {
      debugPrint('BaggageSelectionArguments.fromMap error: $e');
      return null;
    }
  }
}