import 'package:flutter/material.dart';
import '../../models/hub_selection_model.dart';
import '../../widgets/booking/segment_date_form.dart';
import '../../widgets/custom/custom_input_field.dart';
import '../../widgets/custom/custom_button.dart';
import '../../widgets/booking/flight_search_form.dart';

class MultiSegmentSection extends StatelessWidget {
  final HubSelection hub;
  final MainFormData mainData;
  final DateTime? leg1Date;
  final DateTime? leg2Date;
  final List<String> leg2Dates;
  final bool isLoadingLeg2;
  final bool isCalendarOpen;
  final bool isPassengerOpen;
  final bool canSearch;
  final Map<String, int> passengers;
  final GlobalKey passengerFieldKey;
  final void Function(DateTime?) onLeg1DateChanged;
  final void Function(DateTime?) onLeg2DateSelected;
  final void Function() onClearHub;
  final void Function() onSearch;
  final void Function() onOpenPassenger;
  final void Function() onClosePassenger;
  final void Function(Map<String, int>) onPassengersChanged;
  final void Function(
    GlobalKey fieldKey,
    List<String> availableDates,
    DateTime? current,
    void Function(DateTime?) onSelected,
  ) onOpenCalendar;

  const MultiSegmentSection({
    super.key,
    required this.hub,
    required this.mainData,
    required this.leg1Date,
    required this.leg2Date,
    required this.leg2Dates,
    required this.isLoadingLeg2,
    required this.isCalendarOpen,
    required this.isPassengerOpen,
    required this.canSearch,
    required this.passengers,
    required this.passengerFieldKey,
    required this.onLeg1DateChanged,
    required this.onLeg2DateSelected,
    required this.onClearHub,
    required this.onSearch,
    required this.onOpenPassenger,
    required this.onClosePassenger,
    required this.onPassengersChanged,
    required this.onOpenCalendar,
  });

  String _formatPassengers() {
    final total = passengers.values.reduce((a, b) => a + b);
    return '$total passenger${total > 1 ? 's' : ''}';
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: colors.surfaceContainerLow,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(4),
              topRight: Radius.circular(4),
            ),
            border: Border(
              left:   BorderSide(color: colors.primary, width: 3),
              top:    BorderSide(color: colors.outlineVariant.withValues(alpha: 0.5)),
              right:  BorderSide(color: colors.outlineVariant.withValues(alpha: 0.5)),
              bottom: BorderSide(color: colors.outlineVariant.withValues(alpha: 0.5)),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'CONNECTING ROUTE',
                      style: textTheme.labelSmall?.copyWith(
                        color: colors.primary,
                        letterSpacing: 1.2,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${mainData.fromCity}  →  ${hub.cityName}  →  ${mainData.toCity}',
                      style: textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                        letterSpacing: -0.2,
                      ),
                    ),
                  ],
                ),
              ),
              TextButton(
                onPressed: onClearHub,
                style: TextButton.styleFrom(
                  foregroundColor: colors.onSurfaceVariant,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(
                  'Change route',
                  style: textTheme.labelSmall?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 12),

        SegmentDateForm(
          fromCityId: mainData.fromCityId,
          fromCity: mainData.fromCity,
          toCityId: hub.cityId,
          toCity: hub.cityName,
          finalDestinationCityId: mainData.toCityId,
          isCalendarOpen: isCalendarOpen,
          onDateChanged: onLeg1DateChanged,
          onRemove: onClearHub,
          onOpenCalendar: onOpenCalendar,
        ),

        const SizedBox(height: 8),

        Row(
          children: [
            const SizedBox(width: 16),
            Container(width: 1, height: 16, color: colors.outlineVariant),
          ],
        ),

        const SizedBox(height: 8),

        _buildLeg2Result(context, colors, textTheme),

        const SizedBox(height: 16),

        CustomInputField(
          key: passengerFieldKey,
          label: 'Passengers',
          value: _formatPassengers(),
          icon: Icons.person_outline,
          readOnly: true,
          isSelected: isPassengerOpen,
          onTap: () => isPassengerOpen ? onClosePassenger() : onOpenPassenger(),
        ),

        const SizedBox(height: 16),

        SizedBox(
          width: double.infinity,
          child: CustomButton(
            label: 'Search',
            onPressed: canSearch ? onSearch : null,
          ),
        ),
      ],
    );
  }

  Widget _buildLeg2Result(
    BuildContext context,
    ColorScheme colors,
    TextTheme textTheme,
  ) {
    if (leg1Date == null) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: colors.surfaceContainerLow.withValues(alpha: 0.5),
          border: Border.all(color: colors.outlineVariant.withValues(alpha: 0.3)),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Row(
          children: [
            Icon(Icons.arrow_forward, size: 14, color: colors.onSurfaceVariant),
            const SizedBox(width: 8),
            Text(
              '${hub.cityName}  →  ${mainData.toCity}',
              style: textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: colors.onSurfaceVariant,
              ),
            ),
            const Spacer(),
            Text(
              'Select first leg date to see options',
              style: textTheme.bodySmall
                  ?.copyWith(color: colors.onSurfaceVariant),
            ),
          ],
        ),
      );
    }

    if (isLoadingLeg2) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: colors.surfaceContainerLow,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: colors.outlineVariant.withValues(alpha: 0.6)),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                  strokeWidth: 2, color: colors.primary),
            ),
            const SizedBox(width: 12),
            Text(
              'Looking for connecting flights...',
              style: textTheme.bodySmall
                  ?.copyWith(color: colors.onSurfaceVariant),
            ),
          ],
        ),
      );
    }

    if (leg2Date != null) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: colors.surfaceContainerLow,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: colors.primary.withValues(alpha: 0.4)),
        ),
        child: Row(
          children: [
            Icon(Icons.check_circle_outline, size: 16, color: colors.primary),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${hub.cityName}  →  ${mainData.toCity}',
                    style: textTheme.bodyMedium
                        ?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  Text(
                    _formatDate(leg2Date!),
                    style: textTheme.bodySmall?.copyWith(
                      color: colors.primary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            if (leg2Dates.length > 1)
              TextButton(
                onPressed: () => onLeg2DateSelected(null),
                style: TextButton.styleFrom(
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                ),
                child: Text(
                  'Change',
                  style: textTheme.labelSmall
                      ?.copyWith(color: colors.onSurfaceVariant),
                ),
              ),
          ],
        ),
      );
    }

    if (leg2Dates.length > 1) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: colors.surfaceContainerLow,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: colors.outlineVariant.withValues(alpha: 0.6)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${hub.cityName}  →  ${mainData.toCity}',
              style:
                  textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              'Select connecting flight date:',
              style: textTheme.bodySmall
                  ?.copyWith(color: colors.onSurfaceVariant),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: leg2Dates.map((dateStr) {
                final date = DateTime.parse(dateStr);
                return InkWell(
                  onTap: () => onLeg2DateSelected(date),
                  borderRadius: BorderRadius.circular(4),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: colors.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: colors.outlineVariant),
                    ),
                    child: Text(
                      _formatDate(date),
                      style: textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w500,
                        color: colors.primary,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      );
    }

    return const SizedBox.shrink();
  }
}