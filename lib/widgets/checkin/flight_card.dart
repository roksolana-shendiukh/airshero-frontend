import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../custom/custom_button.dart';

class FlightCard extends StatelessWidget {
  final Map<String, dynamic> flight;
  final bool isActioning;
  final void Function(Map<String, dynamic>) onStartBoarding;
  final void Function(Map<String, dynamic>) onJoinBoarding;

  const FlightCard({
    super.key,
    required this.flight,
    required this.isActioning,
    required this.onStartBoarding,
    required this.onJoinBoarding,
  });

  String _formatTime(String? datetime) {
    if (datetime == null) return '—';
    try {
      return DateFormat('HH:mm').format(DateTime.parse(datetime));
    } catch (_) {
      return '—';
    }
  }

  String _formatDate(String? datetime) {
    if (datetime == null) return '—';
    try {
      return DateFormat('MMM d').format(DateTime.parse(datetime));
    } catch (_) {
      return '—';
    }
  }

  Color _statusColor(String? status, ColorScheme colors) {
    switch (status) {
      case 'Waiting':   return colors.onSurfaceVariant;
      case 'Boarding':  return const Color(0xFF2196F3);
      case 'Scheduled': return colors.primary;
      default:          return colors.onSurfaceVariant;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors        = Theme.of(context).colorScheme;
    final status        = flight['status']             as String?;
    final flightNumber  = flight['flight_number']      as String? ?? '—';
    final gate          = flight['gate_code']          as String? ?? '—';
    final departs       = flight['departs_datetime']   as String?;
    final arrives       = flight['arrives_datetime']   as String?;
    final depAirport    = flight['departs_airport']    as String? ?? '—';
    final arrAirport    = flight['arrives_airport']    as String? ?? '—';
    final arrName       = flight['arrives_airport_name'] as String? ?? '—';
    final boardingStart = flight['boarding_start_time'] as String?;
    final boardingEnd   = flight['boarding_end_time']   as String?;
    final statusColor   = _statusColor(status, colors);
    final isBoarding    = status == 'Boarding';
    final isBoardingDone = boardingStart != null && boardingEnd != null;

    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isBoarding && boardingEnd == null
              ? const Color(0xFF2196F3).withValues(alpha: 0.4)
              : colors.outlineVariant.withValues(alpha: 0.4),
          width: isBoarding && boardingEnd == null ? 1.5 : 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  flightNumber,
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(width: 10),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                    border:
                        Border.all(color: statusColor.withValues(alpha: 0.3)),
                  ),
                  child: Text(
                    status ?? '—',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: statusColor,
                    ),
                  ),
                ),
                const Spacer(),
                Icon(Icons.door_sliding_outlined,
                    size: 14, color: colors.onSurfaceVariant),
                const SizedBox(width: 5),
                Text(
                  'Gate $gate',
                  style:
                      TextStyle(fontSize: 13, color: colors.onSurfaceVariant),
                ),
              ],
            ),

            const SizedBox(height: 16),

            Row(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _formatTime(departs),
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontWeight: FontWeight.w600),
                    ),
                    Text(depAirport,
                        style: TextStyle(
                            fontSize: 12, color: colors.onSurfaceVariant)),
                    Text(_formatDate(departs),
                        style: TextStyle(
                            fontSize: 11, color: colors.onSurfaceVariant)),
                  ],
                ),
                Expanded(
                  child: Row(
                    children: [
                      Expanded(
                        child: Container(
                            height: 1,
                            color: colors.outline.withValues(alpha: 0.3)),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Icon(Icons.flight,
                            size: 16, color: colors.onSurfaceVariant),
                      ),
                      Expanded(
                        child: Container(
                            height: 1,
                            color: colors.outline.withValues(alpha: 0.3)),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      _formatTime(arrives),
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontWeight: FontWeight.w600),
                    ),
                    Text(arrAirport,
                        style: TextStyle(
                            fontSize: 12, color: colors.onSurfaceVariant)),
                    Text(arrName,
                        style: TextStyle(
                            fontSize: 11, color: colors.onSurfaceVariant),
                        overflow: TextOverflow.ellipsis),
                  ],
                ),
              ],
            ),

            if (isBoardingDone) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(Icons.check_circle_outline,
                      size: 13, color: Colors.green),
                  const SizedBox(width: 5),
                  Text(
                    'Boarding completed · ${boardingStart!.substring(0, 5)} — ${boardingEnd!.substring(0, 5)}',
                    style:
                        const TextStyle(fontSize: 11, color: Colors.green),
                  ),
                ],
              ),
            ],

            const SizedBox(height: 16),

            Align(
              alignment: Alignment.centerRight,
              child: isActioning
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : isBoardingDone
                      ? const SizedBox.shrink()
                      : status == 'Waiting'
                          ? CustomButton(
                              label: 'Start Boarding',
                              icon: Icons.play_arrow_rounded,
                              isIconAfterLabel: false,
                              verticalPadding: 8,
                              horizontalPadding: 14,
                              onPressed: () => onStartBoarding(flight),
                            )
                          : status == 'Boarding'
                              ? CustomButton(
                                  label: 'Join Boarding',
                                  icon: Icons.login_rounded,
                                  isIconAfterLabel: false,
                                  verticalPadding: 8,
                                  horizontalPadding: 14,
                                  onPressed: () => onJoinBoarding(flight),
                                )
                              : const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }
}