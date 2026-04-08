import 'package:flutter/material.dart';
import '../../../services/planning_service.dart';

class PlanningAirfleetSelector extends StatefulWidget {
  final PlanningService service;
  final List<Map<String, dynamic>> airfleets;
  final Map<String, dynamic>? selected;
  final ValueChanged<Map<String, dynamic>?> onChanged;

  const PlanningAirfleetSelector({
    super.key,
    required this.service,
    required this.airfleets,
    required this.selected,
    required this.onChanged,
  });

  @override
  State<PlanningAirfleetSelector> createState() =>
      _PlanningAirfleetSelectorState();
}

class _PlanningAirfleetSelectorState
    extends State<PlanningAirfleetSelector> {
  @override
  Widget build(BuildContext context) {
    if (widget.airfleets.isEmpty) {
      return Center(
        child: Text(
          'No aircraft available',
          style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant),
        ),
      );
    }

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: widget.airfleets.map((af) {
        final isSelected =
            widget.selected?['airfleetId'] == af['airfleetId'];
        return SizedBox(
          width: 280,
          child: _AirfleetCard(
            service: widget.service,
            airfleet: af,
            isSelected: isSelected,
            onTap: () => widget.onChanged(isSelected ? null : af),
          ),
        );
      }).toList(),
    );
  }
}

class _AirfleetCard extends StatefulWidget {
  final PlanningService service;
  final Map<String, dynamic> airfleet;
  final bool isSelected;
  final VoidCallback onTap;

  const _AirfleetCard({
    required this.service,
    required this.airfleet,
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<_AirfleetCard> createState() => _AirfleetCardState();
}

class _AirfleetCardState extends State<_AirfleetCard> {
  List<String> _photos = [];
  bool _loadedPhotos = false;
  int _photoIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadPhotos();
  }

  Future<void> _loadPhotos() async {
    final airfleetId = widget.airfleet['airfleetId'] as int;
    final photos = await widget.service.getAirfleetPhotos(airfleetId);
    if (mounted) {
      setState(() {
        _photos = photos;
        _loadedPhotos = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: widget.onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: widget.isSelected
              ? colors.primaryContainer.withValues(alpha: 0.25)
              : colors.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: widget.isSelected
                ? colors.primary
                : colors.outlineVariant,
            width: widget.isSelected ? 1.5 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildPhoto(colors),
            _buildInfo(colors),
            _buildSpecs(colors),
          ],
        ),
      ),
    );
  }

  Widget _buildPhoto(ColorScheme colors) {
    return ClipRRect(
      borderRadius:
          const BorderRadius.vertical(top: Radius.circular(11)),
      child: SizedBox(
        height: 150,
        child: Stack(
          children: [
            if (!_loadedPhotos)
              Container(
                color: colors.surfaceContainerHigh,
                child: const Center(
                    child: CircularProgressIndicator(strokeWidth: 2)),
              )
            else if (_photos.isEmpty)
              Container(
                color: colors.surfaceContainerHigh,
                child: Center(
                  child: Icon(
                    Icons.airplanemode_active_outlined,
                    size: 36,
                    color: colors.onSurfaceVariant.withValues(alpha: 0.4),
                  ),
                ),
              )
            else
              Image.network(
                _photos[_photoIndex],
                width: double.infinity,
                height: 150,
                fit: BoxFit.cover,
                loadingBuilder: (_, child, progress) =>
                    progress == null
                        ? child
                        : Container(
                            color: colors.surfaceContainerHigh,
                            child: const Center(
                                child: CircularProgressIndicator(
                                    strokeWidth: 2)),
                          ),
                errorBuilder: (_, __, ___) => Container(
                  color: colors.surfaceContainerHigh,
                  child: Icon(Icons.broken_image_outlined,
                      color: colors.onSurfaceVariant),
                ),
              ),

            if (_photos.length > 1) ...[
              Positioned(
                left: 6,
                top: 0,
                bottom: 0,
                child: Center(
                  child: _NavButton(
                    icon: Icons.chevron_left,
                    onTap: () => setState(() => _photoIndex =
                        (_photoIndex - 1 + _photos.length) %
                            _photos.length),
                  ),
                ),
              ),
              Positioned(
                right: 6,
                top: 0,
                bottom: 0,
                child: Center(
                  child: _NavButton(
                    icon: Icons.chevron_right,
                    onTap: () => setState(() =>
                        _photoIndex =
                            (_photoIndex + 1) % _photos.length),
                  ),
                ),
              ),
              Positioned(
                bottom: 8,
                left: 0,
                right: 0,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    _photos.length,
                    (i) => AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      margin:
                          const EdgeInsets.symmetric(horizontal: 3),
                      width: i == _photoIndex ? 16 : 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: i == _photoIndex
                            ? Colors.white
                            : Colors.white.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  ),
                ),
              ),
            ],

            Positioned(
              top: 8,
              right: 8,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: widget.isSelected
                      ? colors.primary
                      : Colors.black.withValues(alpha: 0.3),
                  border:
                      Border.all(color: Colors.white, width: 1.5),
                ),
                child: widget.isSelected
                    ? const Icon(Icons.check,
                        size: 14, color: Colors.white)
                    : null,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfo(ColorScheme colors) {
    final af = widget.airfleet;
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            af['aircraftModel'] as String,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: widget.isSelected
                  ? colors.primary
                  : colors.onSurface,
            ),
          ),
          if (af['manufacturerName'] != null)
            Text(
              af['manufacturerName'] as String,
              style: TextStyle(
                  fontSize: 12, color: colors.onSurfaceVariant),
            ),
        ],
      ),
    );
  }

  Widget _buildSpecs(ColorScheme colors) {
    final af = widget.airfleet;

    final specs = <({IconData icon, String label, String value})>[
      if (af['seatCapacity'] != null)
        (
          icon: Icons.airline_seat_recline_normal_outlined,
          label: 'Seats',
          value: '${af['seatCapacity']}',
        ),
      if (af['aircraftRangeKm'] != null)
        (
          icon: Icons.route_outlined,
          label: 'Range',
          value: '${(af['aircraftRangeKm'] as num).round()} km',
        ),
      if (af['aircraftSpeed'] != null)
        (
          icon: Icons.speed_outlined,
          label: 'Speed',
          value: '${(af['aircraftSpeed'] as num).round()} km/h',
        ),
      if (af['baggageCapacity'] != null)
        (
          icon: Icons.luggage_outlined,
          label: 'Baggage',
          value: '${(af['baggageCapacity'] as num).round()} kg',
        ),
    ];

    if (specs.isEmpty) return const SizedBox.shrink();

    final rows = <List<({IconData icon, String label, String value})?>>[];
    for (var i = 0; i < specs.length; i += 2) {
      rows.add([
        specs[i],
        i + 1 < specs.length ? specs[i + 1] : null,
      ]);
    }

    return Container(
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: colors.outlineVariant),
        ),
        borderRadius: const BorderRadius.vertical(
            bottom: Radius.circular(11)),
      ),
      child: Column(
        children: rows.asMap().entries.map((entry) {
          final isLast = entry.key == rows.length - 1;
          final row = entry.value;
          return Row(
            children: [
              _SpecCell(
                icon: row[0]!.icon,
                label: row[0]!.label,
                value: row[0]!.value,
                colors: colors,
                borderRight: true,
                borderBottom: !isLast,
                isLeft: true,
                isLast: isLast,
              ),
              if (row[1] != null)
                _SpecCell(
                  icon: row[1]!.icon,
                  label: row[1]!.label,
                  value: row[1]!.value,
                  colors: colors,
                  borderRight: false,
                  borderBottom: !isLast,
                  isLeft: false,
                  isLast: isLast,
                )
              else
                const Expanded(child: SizedBox()),
            ],
          );
        }).toList(),
      ),
    );
  }
}

class _NavButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _NavButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.35),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: Colors.white, size: 20),
      ),
    );
  }
}

class _SpecCell extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final ColorScheme colors;
  final bool borderRight;
  final bool borderBottom;
  final bool isLeft;
  final bool isLast;

  const _SpecCell({
    required this.icon,
    required this.label,
    required this.value,
    required this.colors,
    required this.borderRight,
    required this.borderBottom,
    required this.isLeft,
    required this.isLast,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(
            horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          border: Border(
            right: borderRight
                ? BorderSide(color: colors.outlineVariant)
                : BorderSide.none,
            bottom: borderBottom
                ? BorderSide(color: colors.outlineVariant)
                : BorderSide.none,
          ),
          borderRadius: isLast
              ? BorderRadius.only(
                  bottomLeft:
                      isLeft ? const Radius.circular(11) : Radius.zero,
                  bottomRight:
                      !isLeft ? const Radius.circular(11) : Radius.zero,
                )
              : null,
        ),
        child: Row(
          children: [
            Icon(icon, size: 13, color: colors.onSurfaceVariant),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                label,
                style: TextStyle(
                    fontSize: 11, color: colors.onSurfaceVariant),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                value,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: colors.onSurface,
                ),
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.end,
              ),
            ),
          ],
        ),
      ),
    );
  }
}