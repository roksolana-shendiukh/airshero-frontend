import 'package:flutter/material.dart';
import '../custom/custom_button.dart';
import 'flight_route_section.dart';
import '../../models/flight_combo.dart';
import '../../services/flight_api_service.dart';

class MultiSegmentPairCard extends StatefulWidget {
  final FlightCombo leg1;
  final FlightCombo leg2;
  final double totalPrice;
  final bool isSelected;
  final String fromCity;
  final String hubCity;
  final String destinationCity;
  final DateTime leg1Date;
  final DateTime leg2Date;
  final VoidCallback onBook;
  final VoidCallback onTap;
  final FlightApiService? apiService;

  const MultiSegmentPairCard({
    super.key,
    required this.leg1,
    required this.leg2,
    required this.totalPrice,
    required this.isSelected,
    required this.fromCity,
    required this.hubCity,
    required this.destinationCity,
    required this.leg1Date,
    required this.leg2Date,
    required this.onBook,
    required this.onTap,
    this.apiService,
  });

  @override
  State<MultiSegmentPairCard> createState() => _MultiSegmentPairCardState();
}

class _MultiSegmentPairCardState extends State<MultiSegmentPairCard> {
  bool _isExpanded = false;
  bool _isLoadingAvailability = false;
  List<Map<String, dynamic>> _leg1Availability = [];
  List<Map<String, dynamic>> _leg2Availability = [];

  Future<void> _loadAvailability() async {
    if (widget.apiService == null) return;
    if (_leg1Availability.isNotEmpty) return;

    setState(() => _isLoadingAvailability = true);

    try {
      final result = await widget.apiService!.getFlightsAvailability([
        widget.leg1.outbound.flightId,
        widget.leg2.outbound.flightId,
      ]);

      setState(() {
        _leg1Availability = result[widget.leg1.outbound.flightId] ?? [];
        _leg2Availability = result[widget.leg2.outbound.flightId] ?? [];
        _isLoadingAvailability = false;
      });
    } catch (e) {
      setState(() => _isLoadingAvailability = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final leg1Assignments = widget.leg1.outboundAssignments;
    final leg2Assignments = widget.leg2.outboundAssignments;
    final leg1Classes =
        leg1Assignments.map((a) => a.assignedClass).toSet().join(' / ');
    final leg2Classes =
        leg2Assignments.map((a) => a.assignedClass).toSet().join(' / ');

    return GestureDetector(
      onTap: () {
        widget.onTap();
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
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Leg-1
            FlightRouteSection(
              airlineName: widget.leg1.outbound.airlineName,
              airlineLogoUrl: widget.leg1.outbound.airlineLogoUrl ?? '',
              flightClass: leg1Classes,
              fromAirportCode: widget.leg1.outbound.departsCode,
              toAirportCode: widget.leg1.outbound.arrivesCode,
              departureTime: widget.leg1.outbound.departureTime,
              arrivalTime: widget.leg1.outbound.arrivalTime,
              duration: widget.leg1.outbound.formattedDuration,
              isReturn: false,
              directionLabel: 'Leg 1',
              showInfoButton: false,
            ),

            // Роздільник
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Container(
                decoration: BoxDecoration(
                  border: Border(
                    left: BorderSide(color: colors.primary, width: 3),
                  ),
                ),
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Row(
                  children: [
                    Icon(Icons.connecting_airports,
                        size: 14, color: colors.primary),
                    const SizedBox(width: 8),
                    Text(
                      'Connection in ${widget.hubCity}',
                      style: textTheme.bodySmall?.copyWith(
                        color: colors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      'max 24h transfer',
                      style: textTheme.labelSmall?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Leg-2
            FlightRouteSection(
              airlineName: widget.leg2.outbound.airlineName,
              airlineLogoUrl: widget.leg2.outbound.airlineLogoUrl ?? '',
              flightClass: leg2Classes,
              fromAirportCode: widget.leg2.outbound.departsCode,
              toAirportCode: widget.leg2.outbound.arrivesCode,
              departureTime: widget.leg2.outbound.departureTime,
              arrivalTime: widget.leg2.outbound.arrivalTime,
              duration: widget.leg2.outbound.formattedDuration,
              isReturn: false,
              directionLabel: 'Leg 2',
              showInfoButton: false,
            ),

            // Availability секція
            AnimatedCrossFade(
              firstChild: const SizedBox.shrink(),
              secondChild: Padding(
                padding: const EdgeInsets.only(top: 12),
                child: _buildAvailabilitySection(context, colors, textTheme),
              ),
              crossFadeState: _isExpanded
                  ? CrossFadeState.showSecond
                  : CrossFadeState.showFirst,
              duration: const Duration(milliseconds: 200),
            ),

            // Show/hide підказка
            if (widget.apiService != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Center(
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
                        style: textTheme.labelSmall?.copyWith(
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            const SizedBox(height: 12),

            // Price summary роздільник
            Row(
              children: [
                Expanded(child: Divider(color: colors.outlineVariant)),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text(
                    'PRICE SUMMARY',
                    style: textTheme.labelSmall?.copyWith(
                      color: colors.onSurfaceVariant,
                      letterSpacing: 1.2,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Expanded(child: Divider(color: colors.outlineVariant)),
              ],
            ),

            const SizedBox(height: 12),

            // Price breakdown
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colors.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Flight price breakdown',
                    style: textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...leg1Assignments.map((a) => Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '${a.passengerLabel}  ·  ${a.assignedClass}  ·  Leg 1',
                              style: textTheme.bodySmall,
                            ),
                            Text(
                              '\$${a.price.toStringAsFixed(2)}',
                              style: textTheme.bodySmall
                                  ?.copyWith(fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
                      )),
                  Divider(height: 12, color: colors.outlineVariant),
                  ...leg2Assignments.map((a) => Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '${a.passengerLabel}  ·  ${a.assignedClass}  ·  Leg 2',
                              style: textTheme.bodySmall,
                            ),
                            Text(
                              '\$${a.price.toStringAsFixed(2)}',
                              style: textTheme.bodySmall
                                  ?.copyWith(fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
                      )),
                  Divider(height: 12, color: colors.outlineVariant),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Flight total',
                        style: textTheme.bodyMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        '\$${widget.totalPrice.toStringAsFixed(2)}',
                        style: textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: colors.primary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            Align(
              alignment: Alignment.centerRight,
              child: SizedBox(
                width: 220,
                child: CustomButton(
                  label: 'Book Both',
                  onPressed: widget.onBook,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvailabilitySection(
    BuildContext context,
    ColorScheme colors,
    TextTheme textTheme,
  ) {
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

    if (_leg1Availability.isEmpty && _leg2Availability.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      children: [
        if (_leg1Availability.isNotEmpty)
          _buildAvailabilityTable(
            context,
            colors,
            textTheme,
            label: 'Leg 1 seat availability',
            availability: _leg1Availability,
          ),
        if (_leg2Availability.isNotEmpty) ...[
          const SizedBox(height: 8),
          _buildAvailabilityTable(
            context,
            colors,
            textTheme,
            label: 'Leg 2 seat availability',
            availability: _leg2Availability,
          ),
        ],
      ],
    );
  }

  Widget _buildAvailabilityTable(
    BuildContext context,
    ColorScheme colors,
    TextTheme textTheme, {
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
            style: textTheme.bodySmall?.copyWith(
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
                    child: Text(className, style: textTheme.bodySmall),
                  ),
                  Text(
                    available == 0 ? 'Sold out' : '$available / $total seats',
                    style: textTheme.bodySmall?.copyWith(
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
}