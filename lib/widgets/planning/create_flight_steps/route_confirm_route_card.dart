import 'package:flutter/material.dart';

class RouteConfirmRouteCard extends StatelessWidget {
  final Map<String, dynamic> departsAirport;
  final Map<String, dynamic> arrivesAirport;

  const RouteConfirmRouteCard({
    super.key,
    required this.departsAirport,
    required this.arrivesAirport,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final isInternational =
        departsAirport['countryName'] != arrivesAirport['countryName'];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surfaceContainerHighest.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: colors.outline.withValues(alpha: 0.15)),
      ),
      child: Row(
        children: [
          Expanded(child: _AirportBlock(airport: departsAirport)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                Icon(Icons.arrow_forward,
                    size: 20, color: colors.onSurfaceVariant),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: isInternational
                        ? colors.primaryContainer.withValues(alpha: 0.5)
                        : colors.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    isInternational ? 'International' : 'Domestic',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: isInternational
                          ? colors.primary
                          : colors.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(child: _AirportBlock(airport: arrivesAirport, alignEnd: true)),
        ],
      ),
    );
  }
}

class _AirportBlock extends StatelessWidget {
  final Map<String, dynamic> airport;
  final bool alignEnd;

  const _AirportBlock({required this.airport, this.alignEnd = false});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment:
          alignEnd ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Text(
          airport['airportCode'] as String,
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
        ),
        Text(
          airport['cityName'] as String,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
        ),
        Text(
          airport['countryName'] as String,
          style: TextStyle(fontSize: 11, color: colors.onSurfaceVariant),
        ),
        const SizedBox(height: 4),
        Text(
          airport['airportName'] as String? ?? '',
          style: TextStyle(fontSize: 11, color: colors.onSurfaceVariant),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}