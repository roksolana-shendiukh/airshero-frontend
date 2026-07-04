import 'package:flutter/material.dart';

class ConnectingHubButton extends StatefulWidget {
  final String cityName;
  final VoidCallback onTap;

  const ConnectingHubButton({
    super.key,
    required this.cityName,
    required this.onTap,
  });

  @override
  State<ConnectingHubButton> createState() => _ConnectingHubButtonState();
}

class _ConnectingHubButtonState extends State<ConnectingHubButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: _hovered
                ? colors.primary.withOpacity(0.08)
                : colors.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(
              color: _hovered ? colors.primary : colors.outlineVariant,
              width: _hovered ? 1.5 : 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'via',
                style: textTheme.bodySmall?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                widget.cityName,
                style: textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: _hovered ? colors.primary : colors.onSurface,
                  letterSpacing: -0.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class NearbyAirportButton extends StatefulWidget {
  final String cityName;
  final int distanceKm;
  final VoidCallback onTap;

  const NearbyAirportButton({
    super.key,
    required this.cityName,
    required this.distanceKm,
    required this.onTap,
  });

  @override
  State<NearbyAirportButton> createState() => _NearbyAirportButtonState();
}

class _NearbyAirportButtonState extends State<NearbyAirportButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: _hovered
                ? colors.primary.withOpacity(0.06)
                : colors.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(
              color: _hovered ? colors.primary : colors.outlineVariant,
              width: _hovered ? 1.5 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                widget.cityName,
                style: textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: _hovered ? colors.primary : colors.onSurface,
                  letterSpacing: -0.2,
                ),
              ),
              Text(
                '${widget.distanceKm} km from destination',
                style: textTheme.labelSmall?.copyWith(
                  color: colors.onSurfaceVariant,
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}