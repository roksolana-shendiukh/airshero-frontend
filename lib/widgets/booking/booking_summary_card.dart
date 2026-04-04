import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/booking_group_draft.dart';

class BookingSummaryCard extends StatelessWidget {
  final double totalPrice;
  final String? bookingNumber;

  final String fromCity;
  final String toCity;
  final DateTime departDate;
  final DateTime? returnDate;
  final String fromAirportCode;
  final String toAirportCode;
  final String departureTime;
  final String arrivalTime;
  final bool isRoundTrip;
  final double basePrice;
  final Map<String, int> passengers;
  final Map<String, String> passengerClassLabels;
  final Map<int, Map<int, int>> baggageSelections;

  // Multi-segment
  final bool isMultiSegment;
  final BookingGroupDraft? bookingGroupDraft;
  final String? bookingNumber1;
  final String? bookingNumber2;

  const BookingSummaryCard({
    super.key,
    required this.totalPrice,
    this.bookingNumber,
    required this.fromCity,
    required this.toCity,
    required this.departDate,
    this.returnDate,
    required this.fromAirportCode,
    required this.toAirportCode,
    required this.departureTime,
    required this.arrivalTime,
    required this.isRoundTrip,
    required this.basePrice,
    required this.passengers,
    required this.passengerClassLabels,
    required this.baggageSelections,
    this.isMultiSegment = false,
    this.bookingGroupDraft,
    this.bookingNumber1,
    this.bookingNumber2,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    final displayBookingNumber = isMultiSegment
        ? '${bookingNumber1 ?? ''} + ${bookingNumber2 ?? ''}'
        : bookingNumber;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: colors.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Booking Summary',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                if (displayBookingNumber != null &&
                    displayBookingNumber.isNotEmpty)
                  Chip(
                    label: Text(
                      displayBookingNumber,
                      style: const TextStyle(fontSize: 12),
                    ),
                    backgroundColor: colors.primaryContainer,
                  ),
              ],
            ),
            const Divider(height: 32),

            if (isMultiSegment && bookingGroupDraft != null) ...[
              _buildSegmentSection(
                context,
                colors,
                segment: bookingGroupDraft!.firstSegment,
                bookingNumber: bookingNumber1,
                segmentLabel: 'Booking 1',
              ),
              const SizedBox(height: 24),
              _buildSegmentSection(
                context,
                colors,
                segment: bookingGroupDraft!.secondSegment!,
                bookingNumber: bookingNumber2,
                segmentLabel: 'Booking 2',
              ),
            ] else ...[
              _buildFlightRoute(
                context,
                title: 'Outbound Flight',
                from: fromAirportCode,
                to: toAirportCode,
                departure: departureTime,
                arrival: arrivalTime,
                date: departDate,
                colors: colors,
              ),
              if (isRoundTrip && returnDate != null) ...[
                const SizedBox(height: 16),
                _buildFlightRoute(
                  context,
                  title: 'Return Flight',
                  from: toAirportCode,
                  to: fromAirportCode,
                  departure: departureTime,
                  arrival: arrivalTime,
                  date: returnDate!,
                  colors: colors,
                  isReturn: true,
                ),
              ],
            ],

            const Divider(height: 32),

            const Text(
              'Price Details',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            if (isMultiSegment && bookingGroupDraft != null) ...[
              _buildPriceRow(
                'Flight 1 (${bookingGroupDraft!.firstSegment.fromCity} → ${bookingGroupDraft!.firstSegment.toCity})',
                '\$${bookingGroupDraft!.firstSegment.basePrice.toStringAsFixed(2)}',
                colors,
              ),
              ..._buildSegmentBaggageRows(
                colors,
                bookingGroupDraft!.firstSegment.baggageSelections,
                'Leg 1',
              ),
              const SizedBox(height: 8),
              _buildPriceRow(
                'Flight 2 (${bookingGroupDraft!.secondSegment!.fromCity} → ${bookingGroupDraft!.secondSegment!.toCity})',
                '\$${bookingGroupDraft!.secondSegment!.basePrice.toStringAsFixed(2)}',
                colors,
              ),
              ..._buildSegmentBaggageRows(
                colors,
                bookingGroupDraft!.secondSegment!.baggageSelections,
                'Leg 2',
              ),
            ] else ...[
              ...passengers.entries.where((e) => e.value > 0).map((e) {
                final label = passengerClassLabels[e.key] ?? e.key;
                return _buildPriceRow(
                  '$label x${e.value}',
                  '\$${(basePrice * e.value).toStringAsFixed(2)}',
                  colors,
                );
              }),
              ..._buildBaggageRows(colors),
            ],

            const Divider(height: 32),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Total Amount',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                Text(
                  '\$${totalPrice.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: colors.primary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSegmentSection(
    BuildContext context,
    ColorScheme colors, {
    required BookingSegmentDraft segment,
    required String? bookingNumber,
    required String segmentLabel,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              segmentLabel,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: colors.primary,
                fontSize: 14,
              ),
            ),
            if (bookingNumber != null && bookingNumber.isNotEmpty) ...[
              const SizedBox(width: 8),
              Chip(
                label: Text(
                  '#$bookingNumber',
                  style: const TextStyle(fontSize: 11),
                ),
                backgroundColor: colors.secondaryContainer,
                padding: EdgeInsets.zero,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ],
          ],
        ),
        const SizedBox(height: 12),
        _buildFlightRoute(
          context,
          title: '${segment.fromCity} → ${segment.toCity}',
          from: segment.fromAirportCode,
          to: segment.toAirportCode,
          departure: segment.departureTime,
          arrival: segment.arrivalTime,
          date: segment.departDate,
          colors: colors,
        ),
        const SizedBox(height: 12),
        // Пасажири і класи
        ...segment.passengerClassLabels.entries.map((e) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                children: [
                  Icon(Icons.person_outline,
                      size: 14, color: colors.onSurfaceVariant),
                  const SizedBox(width: 6),
                  Text(
                    '${e.key} — ${e.value}',
                    style: TextStyle(
                      fontSize: 13,
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            )),
      ],
    );
  }

  Widget _buildFlightRoute(
    BuildContext context, {
    required String title,
    required String from,
    required String to,
    required String departure,
    required String arrival,
    required DateTime date,
    required ColorScheme colors,
    bool isReturn = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: colors.primary,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    departure,
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  Text(from,
                      style: TextStyle(color: colors.onSurfaceVariant)),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  Transform.rotate(
                    angle: isReturn ? 4.71239 : 1.5708,
                    child: Icon(
                      Icons.flight,
                      color: colors.primary.withValues(alpha: 0.5),
                      size: 22,
                    ),
                  ),
                  Container(
                      width: 40, height: 1, color: colors.outlineVariant),
                ],
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    arrival,
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  Text(to,
                      style: TextStyle(color: colors.onSurfaceVariant)),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          DateFormat('EEE, d MMM yyyy').format(date),
          style: TextStyle(fontSize: 12, color: colors.onSurfaceVariant),
        ),
      ],
    );
  }

  Widget _buildPriceRow(String label, String value, ColorScheme colors,
      {bool isSecondary = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: isSecondary ? colors.onSurfaceVariant : colors.onSurface,
                fontSize: isSecondary ? 13 : 14,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: isSecondary ? FontWeight.normal : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildBaggageRows(ColorScheme colors) {
    final List<Widget> rows = [];
    baggageSelections.forEach((passengerIdx, selections) {
      selections.forEach((baggageId, count) {
        if (count > 0) {
          rows.add(_buildPriceRow(
            'Extra Baggage (Pass. ${passengerIdx + 1})',
            'x$count',
            colors,
            isSecondary: true,
          ));
        }
      });
    });
    return rows;
  }

  List<Widget> _buildSegmentBaggageRows(
    ColorScheme colors,
    Map<int, Map<int, int>> segmentBaggage,
    String legLabel,
  ) {
    final List<Widget> rows = [];
    segmentBaggage.forEach((passengerIdx, selections) {
      selections.forEach((baggageId, count) {
        if (count > 0) {
          rows.add(_buildPriceRow(
            'Baggage $legLabel (Pass. ${passengerIdx + 1})',
            'x$count',
            colors,
            isSecondary: true,
          ));
        }
      });
    });
    return rows;
  }
}