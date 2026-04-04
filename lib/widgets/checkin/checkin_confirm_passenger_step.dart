import 'package:flutter/material.dart';
import '../custom/custom_button.dart';
import '../../services/auth_service.dart';
import '../../services/checkin_api_service.dart';

class CheckInConfirmPassengerStep extends StatelessWidget {
  final Map<String, dynamic> bookingData;
  final AuthService          authService;
  final VoidCallback         onConfirm;

  const CheckInConfirmPassengerStep({
    super.key,
    required this.bookingData,
    required this.authService,
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
    final bookingItemId    = bookingData['bookingItemId']           as int?    ?? 0;

    return Container(
      margin:  const EdgeInsets.fromLTRB(16, 0, 16, 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color:        colors.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width:  36,
                height: 36,
                decoration: BoxDecoration(
                  color:        colors.primaryContainer.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Center(
                  child: Text(
                    '${passengerName.isNotEmpty ? passengerName[0] : ''}${passengerSurname.isNotEmpty ? passengerSurname[0] : ''}',
                    style: TextStyle(
                      fontSize:   14,
                      fontWeight: FontWeight.w600,
                      color:      colors.primary,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$passengerName $passengerSurname',
                      style: TextStyle(
                        fontSize:   16,
                        fontWeight: FontWeight.w600,
                        color:      colors.onSurface,
                      ),
                    ),
                    Text(
                      documentNumber,
                      style: TextStyle(
                        fontSize:      13,
                        color:         colors.onSurfaceVariant,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color:        colors.primaryContainer.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  bookingStatus,
                  style: TextStyle(
                    fontSize:   11,
                    fontWeight: FontWeight.w600,
                    color:      colors.primary,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),
          Divider(height: 1, color: colors.outline.withValues(alpha: 0.15)),
          const SizedBox(height: 16),

          Row(
            children: [
              Expanded(
                child: _InfoRow(
                  icon:   Icons.confirmation_number_outlined,
                  label:  'Booking',
                  value:  bookingNumber,
                  colors: colors,
                ),
              ),
              const SizedBox(width: 24),
              Expanded(
                child: _InfoRow(
                  icon:   Icons.airline_seat_recline_normal_outlined,
                  label:  'Class',
                  value:  className,
                  colors: colors,
                ),
              ),
              const SizedBox(width: 24),
              Expanded(
                child: _InfoRow(
                  icon:   Icons.luggage_outlined,
                  label:  'Baggage',
                  value:  baggageQuantity == 0
                      ? 'No baggage'
                      : '$baggageQuantity pc${baggageQuantity > 1 ? 's' : ''}'
                        '${baggagePrice != null ? ' · \$${baggagePrice.toStringAsFixed(0)}' : ''}',
                  colors: colors,
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          SizedBox(
            width: double.infinity,
            child: CustomButton(
              label:     'Confirm and select seat',
              onPressed: () async {
                final api    = CheckInApiService(authService);
                final result = await api.checkAlreadyCheckedIn(bookingItemId);

                if (!context.mounted) return;

                if (result['alreadyCheckedIn'] == true) {
                  showDialog(
                    context: context,
                    builder: (ctx) {
                      final c = Theme.of(ctx).colorScheme;
                      return AlertDialog(
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        title: Row(
                          children: [
                            Icon(Icons.warning_amber_outlined, color: c.error),
                            const SizedBox(width: 8),
                            const Text('Already Checked In'),
                          ],
                        ),
                        content: Text(
                          'This passenger is already checked in.\nTicket: ${result['ticketNumber'] ?? '—'}',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(ctx).pop(),
                            child: const Text('OK'),
                          ),
                        ],
                      );
                    },
                  );
                } else {
                  onConfirm();
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData    icon;
  final String      label;
  final String      value;
  final ColorScheme colors;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 14, color: colors.onSurfaceVariant),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(fontSize: 11, color: colors.onSurfaceVariant),
              ),
              Text(
                value,
                style: TextStyle(
                  fontSize:   13,
                  fontWeight: FontWeight.w600,
                  color:      colors.onSurface,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }
}