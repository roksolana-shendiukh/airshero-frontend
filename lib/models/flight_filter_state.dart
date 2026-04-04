import 'package:flutter/material.dart';
import '../models/flight_combo.dart';
import '../models/class.dart';

enum TimeSlot {
  night,
  morning,
  afternoon,
  evening;

  String get label {
    switch (this) {
      case TimeSlot.night:     return 'Night';
      case TimeSlot.morning:   return 'Morning';
      case TimeSlot.afternoon: return 'Afternoon';
      case TimeSlot.evening:   return 'Evening';
    }
  }

  IconData get icon {
    switch (this) {
      case TimeSlot.night:     return Icons.bedtime_outlined;
      case TimeSlot.morning:   return Icons.wb_twilight;
      case TimeSlot.afternoon: return Icons.wb_sunny_outlined;
      case TimeSlot.evening:   return Icons.nights_stay_outlined;
    }
  }

  bool matches(int hour) {
    switch (this) {
      case TimeSlot.night:     return hour >= 0 && hour < 6;
      case TimeSlot.morning:   return hour >= 6 && hour < 12;
      case TimeSlot.afternoon: return hour >= 12 && hour < 18;
      case TimeSlot.evening:   return hour >= 18 && hour < 24;
    }
  }
}

enum SortOrder {
  priceAsc,
  priceDesc;

  String get label {
    switch (this) {
      case SortOrder.priceAsc:  return 'Cheapest first';
      case SortOrder.priceDesc: return 'Most expensive first';
    }
  }

  IconData get icon {
    switch (this) {
      case SortOrder.priceAsc:  return Icons.arrow_upward;
      case SortOrder.priceDesc: return Icons.arrow_upward;
    }
  }
}

class FlightFilterState {
  final Map<int, Class> passengerClasses;
  final Map<int, Class> returnPassengerClasses;

  final double minPrice;
  final double maxPrice;
  final double selectedMinPrice;
  final double selectedMaxPrice;

  final Set<String> selectedAirlines;
  final Set<String> availableAirlines;

  final int minDurationMinutes;
  final int maxDurationMinutes;
  final int selectedMinDuration;
  final int selectedMaxDuration;

  final Set<TimeSlot> departureSlots;
  final Set<TimeSlot> returnSlots;

  final Set<String> availableOutboundClasses;
  final Set<String> availableReturnClasses;
  final Set<TimeSlot> availableDepartureSlots;
  final Set<TimeSlot> availableReturnSlots;

  final SortOrder sortOrder;

 
  const FlightFilterState({
    required this.passengerClasses,
    required this.returnPassengerClasses,
    required this.minPrice,
    required this.maxPrice,
    required this.selectedMinPrice,
    required this.selectedMaxPrice,
    required this.selectedAirlines,
    required this.availableAirlines,
    required this.minDurationMinutes,
    required this.maxDurationMinutes,
    required this.selectedMinDuration,
    required this.selectedMaxDuration,
    required this.departureSlots,
    required this.returnSlots,
    required this.availableOutboundClasses,
    required this.availableReturnClasses,
    required this.availableDepartureSlots,
    required this.availableReturnSlots,
    this.sortOrder = SortOrder.priceAsc,
  });

  bool get hasDurationRange => minDurationMinutes != maxDurationMinutes;

  factory FlightFilterState.fromCombos({
    required List<FlightCombo> combos,
    required Map<int, Class> passengerClasses,
    List<FlightCombo> leg2Combos = const [],
  }) {
    if (combos.isEmpty) {
      return FlightFilterState(
        passengerClasses: passengerClasses,
        returnPassengerClasses: Map.from(passengerClasses),
        minPrice: 0,
        maxPrice: 0,
        selectedMinPrice: 0,
        selectedMaxPrice: 0,
        selectedAirlines: {},
        availableAirlines: {},
        minDurationMinutes: 0,
        maxDurationMinutes: 0,
        selectedMinDuration: 0,
        selectedMaxDuration: 0,
        departureSlots: {},
        returnSlots: {},
        availableOutboundClasses: {},
        availableReturnClasses: {},
        availableDepartureSlots: {},
        availableReturnSlots: {},
        sortOrder: SortOrder.priceAsc,
      );
    }

    final prices = combos.map((c) => c.totalPrice).toList();
    final minP = prices.reduce((a, b) => a < b ? a : b);
    final maxP = prices.reduce((a, b) => a > b ? a : b);

    final airlines = combos
        .map((c) => c.outbound.airlineName)
        .where((n) => n.isNotEmpty)
        .toSet();

    final durations = combos
        .map((c) => _parseDurationMinutes(c.outbound.flightDuration))
        .toList();
    final minD = durations.reduce((a, b) => a < b ? a : b);
    final maxD = durations.reduce((a, b) => a > b ? a : b);

    final outboundClasses = <String>{};
    final returnClasses = <String>{};
    for (final combo in combos) {
      for (final a in combo.outboundAssignments) {
        if (a.assignedClass.isNotEmpty) outboundClasses.add(a.assignedClass);
      }
      for (final a in combo.returnAssignments) {
        if (a.assignedClass.isNotEmpty) returnClasses.add(a.assignedClass);
      }
    }

    if (leg2Combos.isNotEmpty) {
      for (final combo in leg2Combos) {
        for (final a in combo.outboundAssignments) {
          if (a.assignedClass.isNotEmpty) returnClasses.add(a.assignedClass);
        }
      }
    }


    final depSlots = <TimeSlot>{};
    final retSlots = <TimeSlot>{};
    for (final combo in combos) {
      final depHour = combo.outbound.departsDatetime.hour;
      for (final slot in TimeSlot.values) {
        if (slot.matches(depHour)) {
          depSlots.add(slot);
          break;
        }
      }
      if (combo.returnFlight != null) {
        final retHour = combo.returnFlight!.departsDatetime.hour;
        for (final slot in TimeSlot.values) {
          if (slot.matches(retHour)) {
            retSlots.add(slot);
            break;
          }
        }
      }
    }

    return FlightFilterState(
      passengerClasses: passengerClasses,
      returnPassengerClasses: Map.from(passengerClasses),
      minPrice: minP,
      maxPrice: maxP,
      selectedMinPrice: minP,
      selectedMaxPrice: maxP,
      selectedAirlines: {},
      availableAirlines: airlines,
      minDurationMinutes: minD,
      maxDurationMinutes: maxD,
      selectedMinDuration: minD,
      selectedMaxDuration: maxD,
      departureSlots: {},
      returnSlots: {},
      availableOutboundClasses: outboundClasses,
      availableReturnClasses: returnClasses,
      availableDepartureSlots: depSlots,
      availableReturnSlots: retSlots,
      sortOrder: SortOrder.priceAsc,
    );
  }

  static int _parseDurationMinutes(String duration) {
    final parts = duration.split(':');
    if (parts.length < 2) return 0;
    final h = int.tryParse(parts[0]) ?? 0;
    final m = int.tryParse(parts[1]) ?? 0;
    return h * 60 + m;
  }

  bool get isDefault =>
      selectedMinPrice == minPrice &&
      selectedMaxPrice == maxPrice &&
      selectedAirlines.isEmpty &&
      selectedMinDuration == minDurationMinutes &&
      selectedMaxDuration == maxDurationMinutes &&
      departureSlots.isEmpty &&
      returnSlots.isEmpty &&
      sortOrder == SortOrder.priceAsc &&
      passengerClasses.values.every((c) => c == Class.any) &&
      returnPassengerClasses.values.every((c) => c == Class.any);

  List<FlightCombo> apply(List<FlightCombo> combos) {
    var result = combos.where((combo) {
      if (combo.totalPrice < selectedMinPrice ||
          combo.totalPrice > selectedMaxPrice) return false;

      if (selectedAirlines.isNotEmpty &&
          !selectedAirlines.contains(combo.outbound.airlineName)) return false;

      if (hasDurationRange) {
        final dur = _parseDurationMinutes(combo.outbound.flightDuration);
        if (dur < selectedMinDuration || dur > selectedMaxDuration) return false;
      }

      if (departureSlots.isNotEmpty) {
        final hour = combo.outbound.departsDatetime.hour;
        if (!departureSlots.any((s) => s.matches(hour))) return false;
      }

      if (returnSlots.isNotEmpty && combo.returnFlight != null) {
        final hour = combo.returnFlight!.departsDatetime.hour;
        if (!returnSlots.any((s) => s.matches(hour))) return false;
      }

      for (final entry in passengerClasses.entries) {
        final requested = entry.value;
        if (requested == Class.any) continue;
        final hasMatch = combo.outboundAssignments
            .any((a) => a.assignedClass == requested.label);
        if (!hasMatch) return false;
      }

      if (combo.returnFlight != null) {
        for (final entry in returnPassengerClasses.entries) {
          final requested = entry.value;
          if (requested == Class.any) continue;
          final hasMatch = combo.returnAssignments
              .any((a) => a.assignedClass == requested.label);
          if (!hasMatch) return false;
        }
      }

      return true;
    }).toList();

    result.sort((a, b) {
      switch (sortOrder) {
        case SortOrder.priceAsc:
          return a.totalPrice.compareTo(b.totalPrice);
        case SortOrder.priceDesc:
          return b.totalPrice.compareTo(a.totalPrice);
      }
    });

    return result;
  }

  FlightFilterState copyWith({
    Map<int, Class>? passengerClasses,
    Map<int, Class>? returnPassengerClasses,
    double? selectedMinPrice,
    double? selectedMaxPrice,
    Set<String>? selectedAirlines,
    int? selectedMinDuration,
    int? selectedMaxDuration,
    Set<TimeSlot>? departureSlots,
    Set<TimeSlot>? returnSlots,
    SortOrder? sortOrder,
  }) {
    return FlightFilterState(
      passengerClasses: passengerClasses ?? this.passengerClasses,
      returnPassengerClasses:
          returnPassengerClasses ?? this.returnPassengerClasses,
      minPrice: minPrice,
      maxPrice: maxPrice,
      selectedMinPrice: selectedMinPrice ?? this.selectedMinPrice,
      selectedMaxPrice: selectedMaxPrice ?? this.selectedMaxPrice,
      selectedAirlines: selectedAirlines ?? this.selectedAirlines,
      availableAirlines: availableAirlines,
      minDurationMinutes: minDurationMinutes,
      maxDurationMinutes: maxDurationMinutes,
      selectedMinDuration: selectedMinDuration ?? this.selectedMinDuration,
      selectedMaxDuration: selectedMaxDuration ?? this.selectedMaxDuration,
      departureSlots: departureSlots ?? this.departureSlots,
      returnSlots: returnSlots ?? this.returnSlots,
      availableOutboundClasses: availableOutboundClasses,
      availableReturnClasses: availableReturnClasses,
      availableDepartureSlots: availableDepartureSlots,
      availableReturnSlots: availableReturnSlots,
      sortOrder: sortOrder ?? this.sortOrder,
    );
  }
}

String formatDuration(int minutes) {
  final h = minutes ~/ 60;
  final m = minutes % 60;
  if (h == 0) return '${m}m';
  if (m == 0) return '${h}h';
  return '${h}h ${m}m';
}