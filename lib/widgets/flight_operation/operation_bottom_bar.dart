import 'package:flutter/material.dart';

class OperationBottomBar extends StatelessWidget {
  final bool weatherVisible;
  final bool timelineVisible;
  final bool crewVisible;
  final bool hasAlerts;
  final bool hasCritical;
  final VoidCallback onWeatherToggle;
  final VoidCallback onTimelineToggle;
  final VoidCallback onCrewToggle;

  const OperationBottomBar({
    super.key,
    required this.weatherVisible,
    required this.timelineVisible,
    required this.crewVisible,
    required this.hasAlerts,
    required this.hasCritical,
    required this.onWeatherToggle,
    required this.onTimelineToggle,
    required this.onCrewToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E).withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(40),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          BarItem(
            icon: weatherVisible ? Icons.cloud : Icons.cloud_outlined,
            label: 'Weather',
            isActive: weatherVisible,
            badgeColor: hasAlerts
                ? (hasCritical ? Colors.red : Colors.orange)
                : null,
            onTap: onWeatherToggle,
          ),
          const SizedBox(width: 8),
          BarItem(
            icon: timelineVisible
                ? Icons.timeline
                : Icons.timeline_outlined,
            label: 'Timeline',
            isActive: timelineVisible,
            onTap: onTimelineToggle,
          ),
          const SizedBox(width: 8),
          BarItem(
            icon: crewVisible ? Icons.people : Icons.people_outline,
            label: 'Crew',
            isActive: crewVisible,
            onTap: onCrewToggle,
          ),
        ],
      ),
    );
  }
}

class BarItem extends StatefulWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final Color? badgeColor;
  final VoidCallback onTap;

  const BarItem({
    super.key,
    required this.icon,
    required this.label,
    required this.isActive,
    required this.onTap,
    this.badgeColor,
  });

  @override
  State<BarItem> createState() => _BarItemState();
}

class _BarItemState extends State<BarItem> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final activeColor = Colors.white;
    final inactiveColor = Colors.white.withValues(alpha: 0.5);
    final color =
        widget.isActive || _hovered ? activeColor : inactiveColor;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: widget.isActive
                ? Colors.white.withValues(alpha: 0.12)
                : _hovered
                    ? Colors.white.withValues(alpha: 0.06)
                    : Colors.transparent,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(widget.icon, size: 22, color: color),
                  const SizedBox(height: 4),
                  Text(
                    widget.label,
                    style: TextStyle(
                      fontSize: 11,
                      color: color,
                      fontWeight: widget.isActive
                          ? FontWeight.w600
                          : FontWeight.normal,
                    ),
                  ),
                ],
              ),
              if (widget.badgeColor != null)
                Positioned(
                  top: -2,
                  right: -2,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: widget.badgeColor,
                      shape: BoxShape.circle,
                      border: Border.all(
                          color: const Color(0xFF1E1E1E), width: 1.5),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}