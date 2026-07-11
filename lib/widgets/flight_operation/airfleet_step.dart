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
      child: NotificationListener<ScrollNotification>(
        onNotification: (_) {
          FocusScope.of(context).unfocus();
          return false;
        },
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
      ),
    );
  
  }
}

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
    debugPrint('>>> loading photos for airfleet ${widget.airfleet.airfleetId}');
    final photos = await widget.apiService.getAirfleetPhotos(widget.airfleet.airfleetId);
    debugPrint('>>> photos count: ${photos.length}');
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
          if (_loadedPhotos && _photos.isNotEmpty)
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(11)),
              child: SizedBox(
                height: 160,
                child: Stack(
                  children: [
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
                          widget.airfleet.aircraftModel ?? '—',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: widget.isSelected
                                ? colors.primary
                                : colors.onSurface,
                          ),
                        ),
                        if (widget.airfleet.airfleetManufacturerName != null)
                          Text(
                            widget.airfleet.airfleetManufacturerName!,
                            style: TextStyle(fontSize: 12, color: colors.onSurfaceVariant),
                          ),
                      ],
                    ),
                  ),

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

          AnimatedSize(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeInOut,
            child: _expanded
                ? Container(
                    decoration: BoxDecoration(
                      border: Border(
                          top: BorderSide(color: colors.outlineVariant)),
                    ),
                    child: _SpecTable(airfleet: widget.airfleet),
                  )
                : const SizedBox.shrink(),
          ),
        ],
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

class _SpecTable extends StatelessWidget {
  final AirfleetModel airfleet;

  const _SpecTable({required this.airfleet});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    final specs = <({IconData icon, String label, String value})>[
      if (airfleet.seatCapacity != null)
        (icon: Icons.airline_seat_recline_normal_outlined, label: 'Seats',   value: '${airfleet.seatCapacity}'),
      if (airfleet.aircraftRangeKm != null)
        (icon: Icons.route_outlined,                       label: 'Range',   value: '${airfleet.aircraftRangeKm!.round()} km'),
      if (airfleet.aircraftSpeed != null)
        (icon: Icons.speed_outlined,                       label: 'Speed',   value: '${airfleet.aircraftSpeed!.round()} km/h'),
      if (airfleet.baggageCapacity != null)
        (icon: Icons.luggage_outlined,                     label: 'Baggage', value: '${airfleet.baggageCapacity!.round()} kg'),
      if (airfleet.aircraftFuelConsumption != null)
        (icon: Icons.local_gas_station_outlined,           label: 'Fuel',    value: '${airfleet.aircraftFuelConsumption} L/h'),
    ];

    final rows = <List<({IconData icon, String label, String value})?>>[];
    for (var i = 0; i < specs.length; i += 2) {
      rows.add([
        specs[i],
        i + 1 < specs.length ? specs[i + 1] : null,
      ]);
    }

    return Column(
      children: rows.map((row) {
        return Row(
          children: [
            _SpecCell(
              icon: row[0]!.icon,
              label: row[0]!.label,
              value: row[0]!.value,
              colors: colors,
              borderRight: true,
            ),
            if (row[1] != null)
              _SpecCell(
                icon: row[1]!.icon,
                label: row[1]!.label,
                value: row[1]!.value,
                colors: colors,
                borderRight: false,
              )
            else
              const Expanded(child: SizedBox()),
          ],
        );
      }).toList(),
    );
  }
}

class _SpecCell extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final ColorScheme colors;
  final bool borderRight;

  const _SpecCell({
    required this.icon,
    required this.label,
    required this.value,
    required this.colors,
    required this.borderRight,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(color: colors.outlineVariant),
            right: borderRight
                ? BorderSide(color: colors.outlineVariant)
                : BorderSide.none,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, size: 13, color: colors.onSurfaceVariant),
            const SizedBox(width: 6),
            Text(label,
                style: TextStyle(
                    fontSize: 12, color: colors.onSurfaceVariant)),
            const Spacer(),
            Text(value,
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: colors.onSurface)),
          ],
        ),
      ),
    );
  }
}