import 'package:flutter/material.dart';
import 'stat_card.dart';
import '../checkin/checkin_passenger_bar.dart';

class ActiveBoardingBody extends StatelessWidget {
  final int totalPassengers;
  final int checkedIn;
  final int remaining;
  final List<Map<String, dynamic>> recentPassengers;
  final String searchQuery;
  final void Function(String) onSearchChanged;
  final void Function(int boardingPassId) onPassengerTap;
  final void Function(
    Offset position,
    int boardingPassId,
    int flightOperationId,
    String currentSeat,
    int classId,
  ) onPassengerSecondaryTap;

  const ActiveBoardingBody({
    super.key,
    required this.totalPassengers,
    required this.checkedIn,
    required this.remaining,
    required this.recentPassengers,
    required this.searchQuery,
    required this.onSearchChanged,
    required this.onPassengerTap,
    required this.onPassengerSecondaryTap,
  });

  String _fmtIssuedAt(String? issuedAt) {
    if (issuedAt == null) return '—';
    try {
      final dt = DateTime.parse(issuedAt);
      final diff = DateTime.now().difference(dt);
      if (diff.inMinutes < 1) return 'just now';
      if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
      return '${diff.inHours}h ago';
    } catch (_) {
      return '—';
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    final filtered = recentPassengers.where((p) {
      if (searchQuery.isEmpty) return true;
      final name = (p['passenger_name'] as String? ?? '').toLowerCase();
      final seat = (p['seat'] as String? ?? '').toLowerCase();
      final q = searchQuery.toLowerCase();
      return name.contains(q) || seat.contains(q);
    }).toList();

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: StatCard(
                  label: 'Total passengers',
                  value: '$totalPassengers',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: StatCard(
                  label: 'Checked in',
                  value: '$checkedIn',
                  valueColor: Colors.green,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: StatCard(
                  label: 'Remaining',
                  value: '$remaining',
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          CheckInPassengerSearchBar(
            onChanged: onSearchChanged,
            onClear: () => onSearchChanged(''),
          ),

          const SizedBox(height: 12),

          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                  color: colors.outlineVariant.withValues(alpha: 0.4)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                  child: Text(
                    'CHECKED IN PASSENGERS',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.8,
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                ),
                Divider(
                    height: 1,
                    color: colors.outlineVariant.withValues(alpha: 0.4)),
                filtered.isEmpty
                    ? Padding(
                        padding: const EdgeInsets.all(32),
                        child: Center(
                          child: Text(
                            searchQuery.isEmpty
                                ? 'No passengers registered yet'
                                : 'No results for "$searchQuery"',
                            style:
                                TextStyle(color: colors.onSurfaceVariant),
                          ),
                        ),
                      )
                    : ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: filtered.length,
                        separatorBuilder: (_, __) => Divider(
                            height: 1,
                            color: colors.outlineVariant
                                .withValues(alpha: 0.3)),
                        itemBuilder: (_, i) {
                          final p = filtered[i];
                          return GestureDetector(
                            onTap: () => onPassengerTap(
                                p['boarding_pass_id'] as int),
                            onSecondaryTapUp: (details) =>
                                onPassengerSecondaryTap(
                              details.globalPosition,
                              p['boarding_pass_id'] as int,
                              p['flight_operation_id'] as int? ?? 0,
                              p['seat'] as String? ?? '—',
                              p['class_id'] as int? ?? 1,
                            ),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 10),
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    radius: 16,
                                    backgroundColor: colors.primaryContainer
                                        .withValues(alpha: 0.5),
                                    child: Text(
                                      (p['passenger_name'] as String? ??
                                          '?')[0],
                                      style: TextStyle(
                                          fontSize: 12,
                                          color: colors.primary),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          p['passenger_name'] as String? ??
                                              '—',
                                          style: const TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w600),
                                        ),
                                        Text(
                                          'Seat ${p['seat'] ?? '—'} · ${p['class_name'] ?? '—'}',
                                          style: TextStyle(
                                              fontSize: 11,
                                              color:
                                                  colors.onSurfaceVariant),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Row(
                                    children: [
                                      Text(
                                        _fmtIssuedAt(
                                            p['issued_at'] as String?),
                                        style: TextStyle(
                                            fontSize: 11,
                                            color: colors.onSurfaceVariant),
                                      ),
                                      const SizedBox(width: 8),
                                      Icon(
                                        Icons.chevron_right,
                                        size: 16,
                                        color: colors.onSurfaceVariant
                                            .withValues(alpha: 0.5),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}