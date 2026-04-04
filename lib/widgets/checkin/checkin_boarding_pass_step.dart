import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class CheckInBoardingPassStep extends StatelessWidget {
  final String    ticketNumber;
  final String    passengerName;
  final String    flightNumber;
  final String    flightClass;
  final String    seat;
  final DateTime  departDate;
  final int       bagCount;
  final VoidCallback onNewPassenger;

  const CheckInBoardingPassStep({
    super.key,
    required this.ticketNumber,
    required this.passengerName,
    required this.flightNumber,
    required this.flightClass,
    required this.seat,
    required this.departDate,
    required this.bagCount,
    required this.onNewPassenger,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color:        colors.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(12),
              border:       Border.all(color: colors.outline.withValues(alpha: 0.12)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.confirmation_number_outlined, color: colors.primary, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      'Boarding Pass',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: colors.primary),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color:        Colors.green.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'CHECK-IN COMPLETE',
                        style: TextStyle(
                          fontSize:      10,
                          fontWeight:    FontWeight.w700,
                          color:         Colors.green,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                const Divider(height: 1),
                const SizedBox(height: 14),
                _InfoRow(label: 'Ticket №',  value: ticketNumber),
                const SizedBox(height: 8),
                _InfoRow(label: 'Passenger', value: passengerName),
                const SizedBox(height: 8),
                _InfoRow(label: 'Flight',    value: flightNumber),
                const SizedBox(height: 8),
                _InfoRow(label: 'Date',      value: DateFormat('MMM d, yyyy').format(departDate)),
                const SizedBox(height: 8),
                _InfoRow(label: 'Seat',      value: seat),
                const SizedBox(height: 8),
                _InfoRow(label: 'Class',     value: flightClass),
                const SizedBox(height: 8),
                _InfoRow(label: 'Bags',      value: '$bagCount bag${bagCount == 1 ? '' : 's'}'),
              ],
            ),
          ),

          const SizedBox(height: 24),

          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: onNewPassenger,
              icon:  const Icon(Icons.person_add_outlined),
              label: const Text('Check In Next Passenger'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape:   RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(fontSize: 12, color: colors.onSurfaceVariant)),
        Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
      ],
    );
  }
}