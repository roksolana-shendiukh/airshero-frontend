import 'package:flutter/material.dart';
import '../../models/airfleet_model.dart';
import '../../services/flight_operation_api_service.dart';

class AirfleetStep extends StatelessWidget {
  final List<AirfleetModel> airfleets;
  final AirfleetModel? selected;
  final ValueChanged<AirfleetModel?> onChanged;
  final FlightOperationApiService apiService;

  const AirfleetStep({
    super.key,
    required this.airfleets,
    required this.selected,
    required this.onChanged,
    required this.apiService,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    if (airfleets.isEmpty) {
      return Center(
        child: Text('No aircraft available for this route',
            style: TextStyle(color: colors.onSurfaceVariant)),
      );
    }

    return ConstrainedBox(
      constraints: const BoxConstraints(maxHeight: 380),
      child: ListView.separated(
        shrinkWrap: true,
        itemCount: airfleets.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (_, i) => _AirfleetCard(
          airfleet:   airfleets[i],
          isSelected: selected?.airfleetId == airfleets[i].airfleetId,
          apiService: apiService,
          onTap: () => onChanged(
            selected?.airfleetId == airfleets[i].airfleetId
                ? null
                : airfleets[i],
          ),
        ),
      ),
    );
  }
}


// ── Картка літака ──────────────────────────────────────────────────────────────

class _AirfleetCard extends StatefulWidget {
  final AirfleetModel airfleet;
  final bool isSelected;
  final FlightOperationApiService apiService;
  final VoidCallback onTap;

  const _AirfleetCard({
    required this.airfleet,
    required this.isSelected,
    required this.apiService,
    required this.onTap,
  });

  @override
  State<_AirfleetCard> createState() => _AirfleetCardState();
}

class _AirfleetCardState extends State<_AirfleetCard> {
  List<String> _photos     = [];
  bool         _loadedPhotos = false;
  bool         _expanded   = false;
  int          _photoIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadPhotos();
  }

  Future<void> _loadPhotos() async {
    final photos = await widget.apiService.getAirfleetPhotos(widget.airfleet.airfleetId);
    if (mounted) setState(() {
      _photos      = photos;
      _loadedPhotos = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: widget.isSelected
            ? colors.primaryContainer.withValues(alpha: 0.25)
            : colors.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: widget.isSelected ? colors.primary : colors.outlineVariant,
          width: widget.isSelected ? 1.5 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Фото слайдер ────────────────────────────────────────────
          if (_loadedPhotos && _photos.isNotEmpty)
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(11)),
              child: SizedBox(
                height: 160,
                child: Stack(
                  children: [
                    // Фото
                    Image.network(
                      _photos[_photoIndex],
                      width: double.infinity,
                      height: 160,
                      fit: BoxFit.cover,
                      loadingBuilder: (_, child, progress) => progress == null
                          ? child
                          : Container(
                              color: colors.surfaceContainerHigh,
                              child: const Center(
                                  child: CircularProgressIndicator()),
                            ),
                      errorBuilder: (_, __, ___) => Container(
                        color: colors.surfaceContainerHigh,
                        child: Icon(Icons.broken_image_outlined,
                            color: colors.onSurfaceVariant),
                      ),
                    ),

                    // Стрілки навігації
                    if (_photos.length > 1) ...[
                      Positioned(
                        left: 6,
                        top: 0,
                        bottom: 0,
                        child: Center(
                          child: _NavButton(
                            icon: Icons.chevron_left,
                            onTap: () => setState(() =>
                                _photoIndex =
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

                      // Dots
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
                              width:  i == _photoIndex ? 16 : 6,
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

                    // Чекбокс вибору
                    Positioned(
                      top: 8,
                      right: 8,
                      child: GestureDetector(
                        onTap: widget.onTap,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: widget.isSelected
                                ? colors.primary
                                : Colors.black.withValues(alpha: 0.3),
                            border: Border.all(
                                color: Colors.white, width: 1.5),
                          ),
                          child: widget.isSelected
                              ? const Icon(Icons.check,
                                  size: 14, color: Colors.white)
                              : null,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            )
          else if (!_loadedPhotos)
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(11)),
              child: Container(
                height: 80,
                color: colors.surfaceContainerHigh,
                child: const Center(child: CircularProgressIndicator()),
              ),
            )
          else
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(11)),
              child: Container(
                height: 60,
                color: colors.surfaceContainerHigh,
                child: Center(
                  child: Icon(Icons.airplanemode_active_outlined,
                      size: 28, color: colors.onSurfaceVariant.withValues(alpha: 0.4)),
                ),
              ),
            ),

          // ── Інфо рядок ──────────────────────────────────────────────
          InkWell(
            onTap: widget.onTap,
            borderRadius: _expanded
                ? BorderRadius.zero
                : const BorderRadius.vertical(bottom: Radius.circular(11)),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.airfleet.aircraftModel,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: widget.isSelected
                                ? colors.primary
                                : colors.onSurface,
                          ),
                        ),
                        if (widget.airfleet.manufacturerName != null)
                          Text(
                            widget.airfleet.manufacturerName!,
                            style: TextStyle(
                                fontSize: 12,
                                color: colors.onSurfaceVariant),
                          ),
                      ],
                    ),
                  ),

                  // Пілюлі seats / range
                  if (widget.airfleet.seatCapacity != null)
                    _Pill(
                      icon: Icons.airline_seat_recline_normal_outlined,
                      label: '${widget.airfleet.seatCapacity}',
                      colors: colors,
                      active: widget.isSelected,
                    ),
                  const SizedBox(width: 6),
                  if (widget.airfleet.aircraftRangeKm != null)
                    _Pill(
                      icon: Icons.route_outlined,
                      label: '${widget.airfleet.aircraftRangeKm!.round()} km',
                      colors: colors,
                      active: widget.isSelected,
                    ),
                  const SizedBox(width: 8),

                  // Кнопка розгортання деталей
                  GestureDetector(
                    onTap: () => setState(() => _expanded = !_expanded),
                    child: AnimatedRotation(
                      turns: _expanded ? 0.5 : 0,
                      duration: const Duration(milliseconds: 150),
                      child: Icon(Icons.keyboard_arrow_down,
                          size: 20, color: colors.onSurfaceVariant),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Розгорнуті характеристики ────────────────────────────────
          AnimatedSize(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeInOut,
            child: _expanded
                ? Container(
                    padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
                    decoration: BoxDecoration(
                      border: Border(
                          top: BorderSide(color: colors.outlineVariant)),
                    ),
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        if (widget.airfleet.seatCapacity != null)
                          _SpecTile(
                              icon: Icons.airline_seat_recline_normal_outlined,
                              label: 'Seats',
                              value: '${widget.airfleet.seatCapacity}'),
                        if (widget.airfleet.aircraftRangeKm != null)
                          _SpecTile(
                              icon: Icons.route_outlined,
                              label: 'Range',
                              value:
                                  '${widget.airfleet.aircraftRangeKm!.round()} km'),
                        if (widget.airfleet.aircraftSpeed != null)
                          _SpecTile(
                              icon: Icons.speed_outlined,
                              label: 'Speed',
                              value:
                                  '${widget.airfleet.aircraftSpeed!.round()} km/h'),
                        if (widget.airfleet.baggageCapacity != null)
                          _SpecTile(
                              icon: Icons.luggage_outlined,
                              label: 'Baggage',
                              value:
                                  '${widget.airfleet.baggageCapacity!.round()} kg'),
                        if (widget.airfleet.aircraftFuelConsumption != null)
                          _SpecTile(
                              icon: Icons.local_gas_station_outlined,
                              label: 'Fuel',
                              value:
                                  '${widget.airfleet.aircraftFuelConsumption} L/h'),
                      ],
                    ),
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}


// ── Навігаційна кнопка ─────────────────────────────────────────────────────────

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


// ── Spec tile ──────────────────────────────────────────────────────────────────

class _SpecTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _SpecTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: colors.onSurfaceVariant),
          const SizedBox(width: 5),
          Text(label,
              style: TextStyle(fontSize: 11, color: colors.onSurfaceVariant)),
          const SizedBox(width: 4),
          Text(value,
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: colors.onSurface)),
        ],
      ),
    );
  }
}


// ── Pill ───────────────────────────────────────────────────────────────────────

class _Pill extends StatelessWidget {
  final IconData icon;
  final String label;
  final ColorScheme colors;
  final bool active;

  const _Pill({
    required this.icon,
    required this.label,
    required this.colors,
    required this.active,
  });

  @override
  Widget build(BuildContext context) {
    final color = active ? colors.primary : colors.onSurfaceVariant;
    final bg    = active
        ? colors.primary.withValues(alpha: 0.1)
        : colors.surfaceContainerHigh;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 3),
          Text(label,
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: color)),
        ],
      ),
    );
  }
}