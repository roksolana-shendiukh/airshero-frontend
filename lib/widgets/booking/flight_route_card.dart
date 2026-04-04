import 'package:flutter/material.dart';
import '../custom/custom_button.dart';
import 'flight_route_section.dart';
import '../../models/flight_combo.dart';
import '../../services/booking_api_service.dart';

class FlightRouteCard extends StatefulWidget {
  final FlightCombo combo;
  final void Function(FlightCombo resolvedCombo) onBook;
  final bool isSelected;
  final String bookLabel;
  final BookingApiService? apiService;

  const FlightRouteCard({
    super.key,
    required this.combo,
    required this.onBook,
    this.isSelected = false,
    this.bookLabel = 'Book Now',
    this.apiService,
  });

  @override
  State<FlightRouteCard> createState() => _FlightRouteCardState();
}

class _FlightRouteCardState extends State<FlightRouteCard> {
  late Map<String, String?> _outboundChoices;
  late Map<String, String?> _returnChoices;

  bool _isExpanded = false;
  bool _isLoadingAvailability = false;
  List<Map<String, dynamic>> _availability = [];
  List<Map<String, dynamic>> _returnAvailability = [];

  @override
  void initState() {
    super.initState();
    _outboundChoices = {
      for (final w in widget.combo.outboundWarnings) w.passengerLabel: null,
    };
    _returnChoices = {
      for (final w in widget.combo.returnWarnings) w.passengerLabel: null,
    };
  }

  Future<void> _loadAvailability() async {
    if (widget.apiService == null) return;
    if (_availability.isNotEmpty) return;

    setState(() => _isLoadingAvailability = true);

    try {
      final flightIds = [widget.combo.outbound.flightId];
      if (_isRoundTrip && widget.combo.returnFlight != null) {
        flightIds.add(widget.combo.returnFlight!.flightId);
      }

      final result =
          await widget.apiService!.getFlightsAvailability(flightIds);

      setState(() {
        _availability = result[widget.combo.outbound.flightId] ?? [];
        if (_isRoundTrip && widget.combo.returnFlight != null) {
          _returnAvailability =
              result[widget.combo.returnFlight!.flightId] ?? [];
        }
        _isLoadingAvailability = false;
      });
    } catch (e) {
      setState(() => _isLoadingAvailability = false);
    }
  }

  bool get _allChoicesMade {
    final outboundOk = _outboundChoices.values.every((v) => v != null);
    final returnOk = _returnChoices.values.every((v) => v != null);
    return outboundOk && returnOk;
  }

  List<PassengerClassAssignment> get _resolvedOutbound {
    return widget.combo.outboundAssignments.map((a) {
      final choice = _outboundChoices[a.passengerLabel];
      if (choice == null) return a;
      final warning = widget.combo.outboundWarnings
          .firstWhere((w) => w.passengerLabel == a.passengerLabel);
      final info = warning.alternatives[choice];
      return PassengerClassAssignment(
        passengerLabel: a.passengerLabel,
        assignedClass: choice,
        price: info?.price ?? a.price,
        flightPriceId: info?.flightPriceId ?? a.flightPriceId,
        flightClassId: info?.flightClassId ?? a.flightClassId,
      );
    }).toList();
  }

  List<PassengerClassAssignment> get _resolvedReturn {
    return widget.combo.returnAssignments.map((a) {
      final choice = _returnChoices[a.passengerLabel];
      if (choice == null) return a;
      final warning = widget.combo.returnWarnings
          .firstWhere((w) => w.passengerLabel == a.passengerLabel);
      final info = warning.alternatives[choice];
      return PassengerClassAssignment(
        passengerLabel: a.passengerLabel,
        assignedClass: choice,
        price: info?.price ?? a.price,
        flightPriceId: info?.flightPriceId ?? a.flightPriceId,
        flightClassId: info?.flightClassId ?? a.flightClassId,
      );
    }).toList();
  }

  double get _outboundTotal =>
      _resolvedOutbound.fold(0, (sum, a) => sum + a.price);
  double get _returnTotal =>
      _resolvedReturn.fold(0, (sum, a) => sum + a.price);
  double get _grandTotal => _outboundTotal + _returnTotal;
  bool get _isRoundTrip => widget.combo.returnFlight != null;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: () {
        setState(() => _isExpanded = !_isExpanded);
        if (_isExpanded) _loadAvailability();
      },
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(12),
          border: widget.isSelected
              ? Border.all(color: colors.primary, width: 2)
              : null,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            FlightRouteSection(
              airlineName: widget.combo.outbound.airlineName,
              airlineLogoUrl: widget.combo.outbound.airlineLogoUrl ?? '',
              flightClass: _resolvedOutbound
                  .map((a) => a.assignedClass)
                  .toSet()
                  .join(' / '),
              fromAirportCode: widget.combo.outbound.departsCode,
              toAirportCode: widget.combo.outbound.arrivesCode,
              departureTime: widget.combo.outbound.departureTime,
              arrivalTime: widget.combo.outbound.arrivalTime,
              duration: widget.combo.outbound.formattedDuration,
              isReturn: false,
            ),

            if (widget.combo.outboundWarnings.isNotEmpty) ...[
              const SizedBox(height: 12),
              _buildWarningSection(
                context,
                warnings: widget.combo.outboundWarnings,
                choices: _outboundChoices,
                onChoiceChanged: (label, cls) =>
                    setState(() => _outboundChoices[label] = cls),
              ),
            ],

            const SizedBox(height: 12),
            _buildDirectionPrice(
              context,
              label: _isRoundTrip ? 'Outbound' : 'Flight',
              assignments: _resolvedOutbound,
              total: _outboundTotal,
            ),

            if (_isRoundTrip) ...[
              const Divider(height: 28),
              FlightRouteSection(
                airlineName: widget.combo.returnFlight!.airlineName,
                airlineLogoUrl:
                    widget.combo.returnFlight!.airlineLogoUrl ?? '',
                flightClass: _resolvedReturn
                    .map((a) => a.assignedClass)
                    .toSet()
                    .join(' / '),
                fromAirportCode: widget.combo.returnFlight!.departsCode,
                toAirportCode: widget.combo.returnFlight!.arrivesCode,
                departureTime: widget.combo.returnFlight!.departureTime,
                arrivalTime: widget.combo.returnFlight!.arrivalTime,
                duration: widget.combo.returnFlight!.formattedDuration,
                isReturn: true,
              ),

              if (widget.combo.returnWarnings.isNotEmpty) ...[
                const SizedBox(height: 12),
                _buildWarningSection(
                  context,
                  warnings: widget.combo.returnWarnings,
                  choices: _returnChoices,
                  onChoiceChanged: (label, cls) =>
                      setState(() => _returnChoices[label] = cls),
                ),
              ],

              const SizedBox(height: 12),
              _buildDirectionPrice(
                context,
                label: 'Return',
                assignments: _resolvedReturn,
                total: _returnTotal,
              ),

              const Divider(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Grand Total',
                    style:
                        Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                  ),
                  Text(
                    '\$${_grandTotal.toStringAsFixed(2)}',
                    style:
                        Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: colors.primary,
                            ),
                  ),
                ],
              ),
            ],

            AnimatedCrossFade(
              firstChild: const SizedBox.shrink(),
              secondChild: Padding(
                padding: const EdgeInsets.only(top: 12),
                child: _buildAvailabilitySection(context, colors),
              ),
              crossFadeState: _isExpanded
                  ? CrossFadeState.showSecond
                  : CrossFadeState.showFirst,
              duration: const Duration(milliseconds: 200),
            ),

            const SizedBox(height: 16),

            if (widget.apiService != null)
              Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _isExpanded
                          ? Icons.keyboard_arrow_up
                          : Icons.keyboard_arrow_down,
                      size: 16,
                      color: colors.onSurfaceVariant,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _isExpanded
                          ? 'Hide seat availability'
                          : 'Show seat availability',
                      style:
                          Theme.of(context).textTheme.labelSmall?.copyWith(
                                color: colors.onSurfaceVariant,
                              ),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 8),

            Align(
              alignment: Alignment.centerRight,
              child: SizedBox(
                width: 220,
                child: CustomButton(
                  label: widget.bookLabel,
                  onPressed: _allChoicesMade
                      ? () => widget.onBook(FlightCombo(
                            outbound: widget.combo.outbound,
                            returnFlight: widget.combo.returnFlight,
                            outboundAssignments: _resolvedOutbound,
                            returnAssignments: _resolvedReturn,
                            totalPrice: _grandTotal,
                          ))
                      : null,
                ),
              ),
            ),

            if (!_allChoicesMade) ...[
              const SizedBox(height: 8),
              Center(
                child: Text(
                  'Please select a class for all passengers',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colors.error,
                      ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAvailabilitySection(BuildContext context, ColorScheme colors) {
    if (_isLoadingAvailability) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 8),
          child: SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }

    if (_availability.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildAvailabilityTable(
          context,
          colors,
          label: _isRoundTrip ? 'Outbound seat availability' : 'Seat availability',
          availability: _availability,
        ),
        if (_isRoundTrip && _returnAvailability.isNotEmpty) ...[
          const SizedBox(height: 8),
          _buildAvailabilityTable(
            context,
            colors,
            label: 'Return seat availability',
            availability: _returnAvailability,
          ),
        ],
      ],
    );
  }

  Widget _buildAvailabilityTable(
    BuildContext context,
    ColorScheme colors, {
    required String label,
    required List<Map<String, dynamic>> availability,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: colors.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 8),
          ...availability.map((a) {
            final available = a['availableSeats'] as int? ?? 0;
            final total = a['totalSeats'] as int? ?? 0;
            final className = a['className'] as String? ?? '';
            final Color color = available == 0
                ? colors.error
                : available <= 5
                    ? Colors.orange.shade700
                    : colors.primary;

            return Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                children: [
                  Icon(Icons.event_seat_outlined, size: 14, color: color),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      className,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                  Text(
                    available == 0 ? 'Sold out' : '$available / $total seats',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: color,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildDirectionPrice(
    BuildContext context, {
    required String label,
    required List<PassengerClassAssignment> assignments,
    required double total,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$label price breakdown',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 8),
          ...assignments.map((a) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${a.passengerLabel} · ${a.assignedClass}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    Text(
                      '\$${a.price.toStringAsFixed(2)}',
                      style:
                          Theme.of(context).textTheme.bodySmall?.copyWith(
                                fontWeight: FontWeight.w500,
                              ),
                    ),
                  ],
                ),
              )),
          const Divider(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '$label total',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              Text(
                '\$${total.toStringAsFixed(2)}',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWarningSection(
    BuildContext context, {
    required List<ClassWarning> warnings,
    required Map<String, String?> choices,
    required void Function(String label, String cls) onChoiceChanged,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context)
            .colorScheme
            .errorContainer
            .withOpacity(0.2),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color:
              Theme.of(context).colorScheme.error.withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: warnings.map((w) {
          final selected = choices[w.passengerLabel];
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.warning_amber_rounded,
                      size: 16,
                      color: Theme.of(context).colorScheme.error,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        '${w.passengerLabel}: ${w.requestedClass} is not available. '
                        'Please select an alternative:',
                        style:
                            Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: Theme.of(context).colorScheme.error,
                                  fontWeight: FontWeight.w500,
                                ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: w.alternatives.entries.map((e) {
                    final isSelected = selected == e.key;
                    return ChoiceChip(
                      label: Text(
                        '${e.key} (\$${e.value.price.toStringAsFixed(0)})',
                        style: const TextStyle(fontSize: 12),
                      ),
                      selected: isSelected,
                      selectedColor: Theme.of(context)
                          .colorScheme
                          .primaryContainer,
                      backgroundColor: Theme.of(context)
                          .colorScheme
                          .surfaceContainerHigh,
                      labelStyle: TextStyle(
                        color: isSelected
                            ? Theme.of(context)
                                .colorScheme
                                .onPrimaryContainer
                            : Theme.of(context)
                                .colorScheme
                                .onSurfaceVariant,
                        fontWeight: isSelected
                            ? FontWeight.w600
                            : FontWeight.normal,
                      ),
                      onSelected: (_) =>
                          onChoiceChanged(w.passengerLabel, e.key),
                    );
                  }).toList(),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}