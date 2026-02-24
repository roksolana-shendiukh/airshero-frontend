import '../models/class.dart';
import '../models/grouped_flight.dart';
import '../models/flight_combo.dart';

class FlightComboBuilder {
  static List<FlightCombo> build({
    required List<GroupedFlight> outboundFlights,
    required List<GroupedFlight> returnFlights,
    required Map<int, Class> passengerClasses,
    required Map<String, int> passengers,
  }) {
    final passengerLabels = _buildPassengerLabels(passengers);
    final multipliers = _buildMultipliers(passengers, passengerLabels.length);
    final List<FlightCombo> result = [];

    for (final outbound in outboundFlights) {
      final outboundVariants = _generateVariants(
        flight: outbound,
        passengerClasses: passengerClasses,
        passengerLabels: passengerLabels,
        multipliers: multipliers,
        passengers: passengers,
      );

      if (returnFlights.isEmpty) {
        for (final variant in outboundVariants) {
          result.add(FlightCombo(
            outbound: outbound,
            outboundAssignments: variant.assignments,
            outboundWarnings: variant.warnings,
            totalPrice: variant.total,
          ));
        }
      } else {
        for (final ret in returnFlights) {
          final returnVariants = _generateVariants(
            flight: ret,
            passengerClasses: passengerClasses,
            passengerLabels: passengerLabels,
            multipliers: multipliers,
            passengers: passengers,
          );

          for (final outVariant in outboundVariants) {
            for (final retVariant in returnVariants) {
              result.add(FlightCombo(
                outbound: outbound,
                returnFlight: ret,
                outboundAssignments: outVariant.assignments,
                outboundWarnings: outVariant.warnings,
                returnAssignments: retVariant.assignments,
                returnWarnings: retVariant.warnings,
                totalPrice: outVariant.total + retVariant.total,
              ));
            }
          }
        }
      }
    }

    result.sort((a, b) {
      final aW = a.hasWarnings ? 1 : 0;
      final bW = b.hasWarnings ? 1 : 0;
      if (aW != bW) return aW.compareTo(bW);
      return a.totalPrice.compareTo(b.totalPrice);
    });

    return result;
  }

  static List<_FlightVariant> _generateVariants({
    required GroupedFlight flight,
    required Map<int, Class> passengerClasses,
    required List<String> passengerLabels,
    required List<double> multipliers,
    required Map<String, int> passengers,
  }) {
    final adults = passengers['adults'] ?? 0;
    final children = passengers['children'] ?? 0;

    // Групуємо індекси пасажирів по типу
    // Тип: 0 = Adult, 1 = Child, 2 = Infant
    final Map<int, List<int>> typeGroups = {};
    for (int i = 0; i < passengerLabels.length; i++) {
      final type = i < adults ? 0 : i < adults + children ? 1 : 2;
      typeGroups.putIfAbsent(type, () => []).add(i);
    }

    // Для кожного типу генеруємо комбінації (з повторенням, без перестановок)
    // якщо всі пасажири цього типу мають Any.
    // Якщо хтось має конкретний клас — звичайна логіка.
    List<_FlightVariant> variants = [_FlightVariant.empty()];

    for (int i = 0; i < passengerLabels.length; i++) {
      final label = passengerLabels[i];
      final requestedClass = passengerClasses[i] ?? Class.economy;
      final multiplier = multipliers[i];
      final type = i < adults ? 0 : i < adults + children ? 1 : 2;
      final groupIndices = typeGroups[type]!;

      // Чи всі пасажири цього типу мають Any?
      final allAnyInGroup = groupIndices
          .every((idx) => (passengerClasses[idx] ?? Class.economy) == Class.any);

      // Позиція поточного пасажира всередині своєї групи
      final posInGroup = groupIndices.indexOf(i);

      final List<_FlightVariant> nextVariants = [];

      if (requestedClass == Class.any) {
        if (allAnyInGroup) {
          // Комбінації без перестановок:
          // для поточного пасажира дозволяємо тільки класи >= класу попереднього
          // пасажира тієї ж групи
          final availableClasses = flight.classPrices.keys.toList()..sort();

          for (final variant in variants) {
            // Знаходимо клас попереднього пасажира з тієї ж групи
            String? minClass;
            if (posInGroup > 0) {
              final prevIdx = groupIndices[posInGroup - 1];
              final prevLabel = passengerLabels[prevIdx];
              final prevAssignment = variant.assignments
                  .where((a) => a.passengerLabel == prevLabel)
                  .firstOrNull;
              minClass = prevAssignment?.assignedClass;
            }

            for (final cls in availableClasses) {
              // Пропускаємо класи що йдуть "до" класу попереднього пасажира
              if (minClass != null &&
                  availableClasses.indexOf(cls) <
                      availableClasses.indexOf(minClass)) {
                continue;
              }

              final price = flight.classPrices[cls]! * multiplier;
              nextVariants.add(variant.withAssignment(
                PassengerClassAssignment(
                  passengerLabel: label,
                  assignedClass: cls,
                  price: price,
                ),
              ));
            }
          }
        } else {
          // В групі є пасажири з конкретним класом — розгортаємо всі класи
          for (final variant in variants) {
            for (final entry in flight.classPrices.entries) {
              final price = entry.value * multiplier;
              nextVariants.add(variant.withAssignment(
                PassengerClassAssignment(
                  passengerLabel: label,
                  assignedClass: entry.key,
                  price: price,
                ),
              ));
            }
          }
        }
      } else {
        final price = flight.priceFor(requestedClass.label);

        if (price != null) {
          for (final variant in variants) {
            nextVariants.add(variant.withAssignment(
              PassengerClassAssignment(
                passengerLabel: label,
                assignedClass: requestedClass.label,
                price: price * multiplier,
              ),
            ));
          }
        } else {
          // Немає потрібного класу — попередження, пасажир обере в картці
          for (final variant in variants) {
            nextVariants.add(variant.withWarning(
              ClassWarning(
                passengerLabel: label,
                requestedClass: requestedClass.label,
                alternatives: Map<String, double>.from(flight.classPrices),
              ),
              PassengerClassAssignment(
                passengerLabel: label,
                assignedClass: '',
                price: 0,
              ),
            ));
          }
        }
      }

      variants = nextVariants.isEmpty ? variants : nextVariants;
    }

    return variants;
  }

  static List<String> _buildPassengerLabels(Map<String, int> passengers) {
    final labels = <String>[];
    final adults = passengers['adults'] ?? 0;
    final children = passengers['children'] ?? 0;
    final infants = passengers['infants'] ?? 0;
    for (int i = 0; i < adults; i++) labels.add('Adult ${i + 1}');
    for (int i = 0; i < children; i++) labels.add('Child ${i + 1}');
    for (int i = 0; i < infants; i++) labels.add('Infant ${i + 1}');
    return labels;
  }

  static List<double> _buildMultipliers(
      Map<String, int> passengers, int total) {
    final multipliers = <double>[];
    final adults = passengers['adults'] ?? 0;
    final children = passengers['children'] ?? 0;
    for (int i = 0; i < total; i++) {
      if (i < adults) {
        multipliers.add(1.0);
      } else if (i < adults + children) {
        multipliers.add(0.75);
      } else {
        multipliers.add(0.1);
      }
    }
    return multipliers;
  }
}

/// Внутрішня модель для побудови варіантів
class _FlightVariant {
  final List<PassengerClassAssignment> assignments;
  final List<ClassWarning> warnings;
  final double total;

  const _FlightVariant({
    required this.assignments,
    required this.warnings,
    required this.total,
  });

  factory _FlightVariant.empty() => const _FlightVariant(
        assignments: [],
        warnings: [],
        total: 0,
      );

  _FlightVariant withAssignment(PassengerClassAssignment assignment) {
    return _FlightVariant(
      assignments: [...assignments, assignment],
      warnings: warnings,
      total: total + assignment.price,
    );
  }

  _FlightVariant withWarning(
      ClassWarning warning, PassengerClassAssignment placeholder) {
    return _FlightVariant(
      assignments: [...assignments, placeholder],
      warnings: [...warnings, warning],
      total: total,
    );
  }
}