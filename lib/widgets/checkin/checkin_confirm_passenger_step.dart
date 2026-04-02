import 'package:flutter/material.dart';
import '../custom/custom_button.dart';

class CheckInConfirmPassengerStep extends StatelessWidget {
  final Map<String, dynamic> bookingData;
  final VoidCallback onConfirm;

  const CheckInConfirmPassengerStep({
    super.key,
    required this.bookingData,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    final passengerName    = bookingData['passengerName']           as String? ?? '—';
    final passengerSurname = bookingData['passengerSurname']        as String? ?? '—';
    final documentNumber   = bookingData['passengerDocumentNumber'] as String? ?? '—';
    final className        = bookingData['className']               as String? ?? '—';
    final bookingNumber    = bookingData['bookingNumber']           as String? ?? '—';
    final bookingStatus    = bookingData['bookingStatus']           as String? ?? '—';
    final baggageQuantity  = bookingData['baggageQuantity']         as int?    ?? 0;
    final baggagePrice     = bookingData['baggagePrice']            as double?;

    return Container(
      margin:  const EdgeInsets.fromLTRB(16, 12, 16, 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color:        colors.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          Row(
            children: [
              Icon(Icons.person_outline, color: colors.primary, size: 18),
              const SizedBox(width: 8),
              Text(
                'Confirm passenger',
                style: Theme.of(context)
                    .textTheme
                    .titleSmall
                    ?.copyWith(fontWeight: FontWeight.w600),
              ),
            ],
          ),

          const SizedBox(height: 12),

          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colors.primaryContainer.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: colors.primary.withValues(alpha: 0.25),
                width: 0.5,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$passengerName $passengerSurname',
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                Text(
                  documentNumber,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: colors.onSurfaceVariant,
                        letterSpacing: 1.5,
                      ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 10),

          Row(
            children: [
              Expanded(
                child: _InfoTile(
                  icon:  Icons.confirmation_number_outlined,
                  label: 'Booking',
                  value: bookingNumber,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _InfoTile(
                  icon:  Icons.airline_seat_recline_normal_outlined,
                  label: 'Class',
                  value: className,
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          Row(
            children: [
              Expanded(
                child: _InfoTile(
                  icon:       Icons.check_circle_outline,
                  label:      'Status',
                  value:      bookingStatus,
                  valueColor: colors.primary,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _InfoTile(
                  icon:  Icons.luggage_outlined,
                  label: 'Baggage',
                  value: baggageQuantity == 0
                      ? 'No baggage'
                      : '$baggageQuantity pc${baggageQuantity > 1 ? 's' : ''}'
                        '${baggagePrice != null ? ' · \$${baggagePrice.toStringAsFixed(0)}' : ''}',
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          SizedBox(
            width: double.infinity,
            child: CustomButton(
              label:     'Confirm & select seat',
              onPressed: onConfirm,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String   label;
  final String   value;
  final Color?   valueColor;

  const _InfoTile({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color:        colors.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: colors.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colors.onSurfaceVariant,
                        fontSize: 11,
                      ),
                ),
                Text(
                  value,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: valueColor ?? colors.onSurface,
                      ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}