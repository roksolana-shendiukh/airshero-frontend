import 'package:flutter/material.dart';
import '../../models/flight_alternatives_model.dart';
import '../../models/hub_selection_model.dart';
import 'connecting_hub_button.dart';

class AlternativesSection extends StatelessWidget {
  final FlightAlternatives? alternatives;
  final void Function(HubSelection hub) onHubSelected;
  final void Function(int cityId, String cityName) onNearbyAirportSelected;

  const AlternativesSection({
    super.key,
    required this.alternatives,
    required this.onHubSelected,
    required this.onNearbyAirportSelected,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      decoration: BoxDecoration(
        color: colors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(4),
        border: Border(
          left: BorderSide(color: colors.primary, width: 3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'No direct flights available',
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'The following routing options are available for this route.',
                  style: textTheme.bodySmall?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          if (alternatives == null ||
              (alternatives!.nearbyCities.isEmpty &&
                  alternatives!.connectingHubs.isEmpty))
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: Text(
                'No alternative routes found. Please select different cities.',
                style: textTheme.bodySmall?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
              ),
            )
          else ...[
            if (alternatives!.connectingHubs.isNotEmpty) ...[
              _buildSectionDivider(context),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
                child: Row(
                  children: [
                    Text(
                      'VIA CONNECTING CITY',
                      style: textTheme.labelSmall?.copyWith(
                        color: colors.onSurfaceVariant,
                        letterSpacing: 1.2,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: colors.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(3),
                      ),
                      child: Text(
                        '2 bookings required',
                        style: textTheme.labelSmall?.copyWith(
                          color: colors.onSurfaceVariant,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: alternatives!.connectingHubs.map((hub) {
                    return ConnectingHubButton(
                      cityName: hub.cityName,
                      onTap: () => onHubSelected(
                        HubSelection(
                          cityId: hub.cityId,
                          cityName: hub.cityName,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
            if (alternatives!.nearbyCities.isNotEmpty) ...[
              _buildSectionDivider(context),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
                child: Text(
                  'NEARBY AIRPORTS',
                  style: textTheme.labelSmall?.copyWith(
                    color: colors.onSurfaceVariant,
                    letterSpacing: 1.2,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: alternatives!.nearbyCities.map((city) {
                    return NearbyAirportButton(
                      cityName: city.cityName,
                      distanceKm: city.distanceKm,
                      onTap: () => onNearbyAirportSelected(
                        city.cityId,
                        city.cityName,
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }

  Widget _buildSectionDivider(BuildContext context) {
    return Divider(
      height: 1,
      thickness: 1,
      color: Theme.of(context).colorScheme.outlineVariant.withOpacity(0.5),
    );
  }
}