import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../models/args/baggage_selection_args.dart';
import '../services/navigation_storage_service.dart';
import '../pages/baggage_selection_page.dart';

class BaggageSelectionLoader extends StatefulWidget {
  const BaggageSelectionLoader({super.key});

  @override
  State<BaggageSelectionLoader> createState() => _BaggageSelectionLoaderState();
}

class _BaggageSelectionLoaderState extends State<BaggageSelectionLoader> {
  BaggageSelectionArguments? _args;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final map = await NavigationStorageService.loadBaggageArgs();
    final args = BaggageSelectionArguments.fromMap(map);
    if (!mounted) return;
    if (args == null) {
      context.go('/sales/bookings');
    } else {
      setState(() => _args = args);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_args == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    return BaggageSelectionPage(
      fromCity: _args!.fromCity,
      toCity: _args!.toCity,
      departDate: _args!.departDate,
      returnDate: _args!.returnDate,
      passengers: _args!.passengers,
      passengerClassLabels: _args!.passengerClassLabels,
      airlineName: _args!.airlineName,
      airlineLogoUrl: _args!.airlineLogoUrl,
      fromAirportCode: _args!.fromAirportCode,
      toAirportCode: _args!.toAirportCode,
      departureTime: _args!.departureTime,
      arrivalTime: _args!.arrivalTime,
      duration: _args!.duration,
      basePrice: _args!.basePrice,
      isRoundTrip: _args!.isRoundTrip,
      outboundAssignments: _args!.outboundAssignments,
      returnAssignments: _args!.returnAssignments,
      outboundFlightClassId: _args!.outboundFlightClassId,
      bookingGroupDraft: _args!.bookingGroupDraft,
      segmentIndex: _args!.segmentIndex,
      initialPassengerData: _args!.initialPassengerData,
      bookingId: _args!.bookingId,
      bookingNumber: _args!.bookingNumber,
      bookingId2: _args!.bookingId2,
      bookingNumber2: _args!.bookingNumber2,
      expiresAt: _args!.expiresAt,
      leg2FlightClassId: _args!.leg2FlightClassId,
      leg2FromCity: _args!.leg2FromCity,
      leg2ToCity: _args!.leg2ToCity,
    );
  }
}