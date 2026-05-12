import 'package:flutter/material.dart';
import '../../services/flight_operation_api_service.dart';

class AirfleetCard extends StatefulWidget {
  final Map<String, dynamic> airfleet;
  final FlightOperationApiService apiService;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const AirfleetCard({
    super.key,
    required this.airfleet,
    required this.apiService,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  State<AirfleetCard> createState() => _AirfleetCardState();
}

class _AirfleetCardState extends State<AirfleetCard> {
  List<String> _photos = [];
  int _photoIndex = 0;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadPhotos();
  }

  Future<void> _loadPhotos() async {
    final id = widget.airfleet['airfleetId'] as int?;
    if (id == null) {
      if (mounted) setState(() => _loading = false);
      return;
    }
    final photos = await widget.apiService.getAirfleetPhotos(id);
    if (mounted) setState(() {
      _photos = photos;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final a = widget.airfleet;
    final manufacturer = a['manufacturerName'] as String? ?? '';

    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: colors.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: 180,
            child: Stack(
              fit: StackFit.expand,
              children: [
                _buildPhoto(colors),

                Positioned(
                  bottom: 0, left: 0, right: 0,
                  child: Container(
                    height: 50,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [
                          Colors.black.withValues(alpha: 0.55),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),

                // Manufacturer badge
                if (manufacturer.isNotEmpty)
                  Positioned(
                    bottom: 8, left: 10,
                    child: Text(
                      manufacturer,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w500),
                    ),
                  ),

                // Nav arrows
                if (_photos.length > 1) ...[
                  Positioned(
                    left: 4, top: 0, bottom: 0,
                    child: Center(child: _NavBtn(
                      icon: Icons.chevron_left,
                      onTap: () => setState(() =>
                          _photoIndex = (_photoIndex - 1 + _photos.length) % _photos.length),
                    )),
                  ),
                  Positioned(
                    right: 4, top: 0, bottom: 0,
                    child: Center(child: _NavBtn(
                      icon: Icons.chevron_right,
                      onTap: () => setState(() =>
                          _photoIndex = (_photoIndex + 1) % _photos.length),
                    )),
                  ),
                  Positioned(
                    bottom: 6, left: 0, right: 0,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(_photos.length, (i) =>
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          margin: const EdgeInsets.symmetric(horizontal: 2),
                          width: i == _photoIndex ? 14 : 5,
                          height: 5,
                          decoration: BoxDecoration(
                            color: i == _photoIndex
                                ? Colors.white
                                : Colors.white.withValues(alpha: 0.45),
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],

                // Edit / Delete
                Positioned(
                  top: 8, right: 8,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _CircleBtn(icon: Icons.edit_outlined, onTap: widget.onEdit),
                      const SizedBox(width: 5),
                      _CircleBtn(icon: Icons.delete_outline, onTap: widget.onDelete, isError: true),
                    ],
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    a['aircraftModel'] ?? '—',
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 10),

                  _SpecsGrid(airfleet: a, colors: colors),

                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhoto(ColorScheme colors) {
  if (_loading) {
    return ColoredBox(
      color: colors.surfaceContainerHigh,
      child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
    );
  }
  if (_photos.isEmpty) {
    return ColoredBox(
      color: colors.surfaceContainerHigh,
      child: Center(
        child: Icon(Icons.airplanemode_active,
            size: 36, color: colors.outline.withValues(alpha: 0.18)),
      ),
    );
  }
  return Image.network(
    _photos[_photoIndex],
    fit: BoxFit.cover,
    headers: const {
      'Access-Control-Allow-Origin': '*',
    },
    loadingBuilder: (_, child, progress) => progress == null
        ? child
        : ColoredBox(
            color: colors.surfaceContainerHigh,
            child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
          ),
    errorBuilder: (_, __, ___) => ColoredBox(
      color: colors.surfaceContainerHigh,
      child: Center(
        child: Icon(Icons.broken_image_outlined,
            size: 28, color: colors.onSurfaceVariant),
      ),
    ),
  );
}

}

class _SpecsGrid extends StatelessWidget {
  final Map<String, dynamic> airfleet;
  final ColorScheme colors;

  const _SpecsGrid({required this.airfleet, required this.colors});

  @override
  Widget build(BuildContext context) {
    final specs = [
      (Icons.airline_seat_recline_normal_outlined, 'Seats',   '${airfleet['seatCapacity'] ?? '—'}'),
      (Icons.route_outlined,                        'Range',   '${airfleet['aircraftRangeKm'] ?? '—'} km'),
      (Icons.speed_outlined,                        'Speed',   '${airfleet['aircraftSpeed'] ?? '—'} km/h'),
      (Icons.luggage_outlined,                      'Baggage', '${airfleet['baggageCapacity'] ?? '—'} kg'),
      (Icons.local_gas_station_outlined,            'Fuel',    '${airfleet['aircraftFuelConsumption'] ?? '—'} L/h'),
    ];

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Expanded(child: _SpecTile(icon: specs[0].$1, label: specs[0].$2, value: specs[0].$3, colors: colors)),
            const SizedBox(width: 4),
            Expanded(child: _SpecTile(icon: specs[1].$1, label: specs[1].$2, value: specs[1].$3, colors: colors)),
            const SizedBox(width: 4),
            Expanded(child: _SpecTile(icon: specs[2].$1, label: specs[2].$2, value: specs[2].$3, colors: colors)),
          ],
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            Expanded(child: _SpecTile(icon: specs[3].$1, label: specs[3].$2, value: specs[3].$3, colors: colors)),
            const SizedBox(width: 4),
            Expanded(child: _SpecTile(icon: specs[4].$1, label: specs[4].$2, value: specs[4].$3, colors: colors)),
          ],
        ),
      ],
    );
  }
}

  class _SpecTile extends StatelessWidget {
    final IconData icon;
    final String label;
    final String value;
    final ColorScheme colors;

    const _SpecTile({
      required this.icon,
      required this.label,
      required this.value,
      required this.colors,
    });

    @override
    Widget build(BuildContext context) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        decoration: BoxDecoration(
          color: colors.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: colors.outlineVariant.withValues(alpha: 0.5),
            width: 0.8,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, size: 13, color: colors.onSurfaceVariant),
            const SizedBox(width: 6),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(label,
                      style: TextStyle(
                          fontSize: 9,
                          color: colors.onSurfaceVariant,
                          letterSpacing: 0.2)),
                  Text(value,
                      style: const TextStyle(
                          fontSize: 11, fontWeight: FontWeight.w600),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
          ],
        ),
      );
    }
  }
  
class _NavBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _NavBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 24, height: 24,
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.35),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: Colors.white, size: 16),
      ),
    );
  }
}

class _CircleBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool isError;

  const _CircleBtn({
    required this.icon,
    required this.onTap,
    this.isError = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 27, height: 27,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 4),
          ],
        ),
        child: Icon(icon,
            size: 13,
            color: isError ? const Color(0xFFE24B4A) : Colors.grey[700]),
      ),
    );
  }
}