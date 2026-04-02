import 'package:flutter/material.dart';
import '../../models/planning_overview_model.dart';

class PlanningStatsCards extends StatelessWidget {
  final PlanningOverviewStats stats;

  const PlanningStatsCards({super.key, required this.stats});

  @override
  Widget build(BuildContext context) {
    final items = [
      _StatDef(
        icon: Icons.flight_takeoff_rounded,
        label: 'Active Flights',
        value: stats.activeFlightsCount.toString(),
        sub: 'this month',
      ),
      _StatDef(
        icon: Icons.route_rounded,
        label: 'Routes',
        value: stats.routesCount.toString(),
        sub: 'active',
      ),
      _StatDef(
        icon: Icons.airline_seat_recline_normal_rounded,
        label: 'Avg. Load',
        value: '${stats.averageLoadPercent.toStringAsFixed(1)}%',
        sub: 'across all flights',
      ),
      _StatDef(
        icon: Icons.euro_rounded,
        label: 'Revenue',
        value: _fmtRevenue(stats.monthlyRevenueEur),
        sub: 'current month',
      ),
    ];

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (int i = 0; i < items.length; i++) ...[
            if (i > 0) const SizedBox(width: 16),
            Expanded(child: _StatCard(item: items[i])),
          ],
        ],
      ),
    );
  }

  String _fmtRevenue(double v) {
    if (v >= 1000000) return '€${(v / 1000000).toStringAsFixed(1)}M';
    if (v >= 1000) return '€${(v / 1000).toStringAsFixed(0)}K';
    return '€${v.toStringAsFixed(0)}';
  }
}

class _StatCard extends StatelessWidget {
  final _StatDef item;
  const _StatCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: colors.primaryContainer,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(item.icon, size: 20, color: colors.primary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    item.label,
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.copyWith(fontSize: 12),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    item.value,
                    style: Theme.of(context)
                        .textTheme
                        .titleLarge
                        ?.copyWith(fontSize: 22),
                  ),
                  Text(
                    item.sub,
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.copyWith(fontSize: 11),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatDef {
  final IconData icon;
  final String label;
  final String value;
  final String sub;
  const _StatDef({
    required this.icon,
    required this.label,
    required this.value,
    required this.sub,
  });
}