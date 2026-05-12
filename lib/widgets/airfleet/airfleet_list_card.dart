import 'package:flutter/material.dart';
import '../../services/flight_operation_api_service.dart';

class AirfleetListCard extends StatefulWidget {
  final Map<String, dynamic> airfleet;
  final bool isSelected;
  final FlightOperationApiService flightApi;
  final VoidCallback onConfigure;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const AirfleetListCard({
    super.key,
    required this.airfleet,
    required this.isSelected,
    required this.flightApi,
    required this.onConfigure,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  State<AirfleetListCard> createState() => _AirfleetListCardState();
}

class _AirfleetListCardState extends State<AirfleetListCard> {
  List<String> _photos = [];
  int _photoIndex = 0;
  bool _loadingPhotos = true;

  @override
  void initState() {
    super.initState();
    _loadPhotos();
  }

  Future<void> _loadPhotos() async {
    final id = widget.airfleet['airfleetId'] as int?;
    if (id == null) {
      if (mounted) setState(() => _loadingPhotos = false);
      return;
    }
    final photos = await widget.flightApi.getAirfleetPhotos(id);
    if (mounted) setState(() { _photos = photos; _loadingPhotos = false; });
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final a = widget.airfleet;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: widget.isSelected
              ? const Color(0xFF7F77DD)
              : colors.outlineVariant.withValues(alpha: 0.6),
          width: widget.isSelected ? 1.5 : 0.8,
        ),
        color: widget.isSelected
            ? const Color(0xFF7F77DD).withValues(alpha: 0.05)
            : colors.surface,
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Photo
          SizedBox(
            height: 90,
            child: Stack(
              fit: StackFit.expand,
              children: [
                _buildPhoto(colors),
                // Gradient
                Positioned(
                  bottom: 0, left: 0, right: 0,
                  child: Container(
                    height: 36,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [
                          Colors.black.withValues(alpha: 0.5),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
                // Manufacturer
                if ((a['manufacturerName'] as String?) != null)
                  Positioned(
                    bottom: 6, left: 8,
                    child: Text(
                      a['manufacturerName'] as String,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.w500),
                    ),
                  ),
                // Edit/Delete buttons
                Positioned(
                  top: 6, right: 6,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _MiniBtn(
                          icon: Icons.edit_outlined,
                          onTap: widget.onEdit),
                      const SizedBox(width: 4),
                      _MiniBtn(
                          icon: Icons.delete_outline,
                          onTap: widget.onDelete,
                          isError: true),
                    ],
                  ),
                ),
                // Nav arrows
                if (_photos.length > 1) ...[
                  Positioned(
                    left: 3, top: 0, bottom: 0,
                    child: Center(
                      child: _NavBtn(
                        icon: Icons.chevron_left,
                        onTap: () => setState(() =>
                            _photoIndex = (_photoIndex - 1 + _photos.length) %
                                _photos.length),
                      ),
                    ),
                  ),
                  Positioned(
                    right: 3, top: 0, bottom: 0,
                    child: Center(
                      child: _NavBtn(
                        icon: Icons.chevron_right,
                        onTap: () => setState(() =>
                            _photoIndex = (_photoIndex + 1) % _photos.length),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          // Body
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 8, 10, 6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  a['aircraftModel'] ?? '—',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: widget.isSelected
                        ? const Color(0xFF7F77DD)
                        : colors.onSurface,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 5),
                _SpecRow(airfleet: a, colors: colors),
                const SizedBox(height: 8),
                // Configure button
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: widget.onConfigure,
                    icon: Icon(
                      Icons.grid_view_rounded,
                      size: 13,
                      color: widget.isSelected
                          ? const Color(0xFF7F77DD)
                          : colors.onSurfaceVariant,
                    ),
                    label: Text(
                      widget.isSelected
                          ? 'Configuring...'
                          : 'Configure seats',
                      style: TextStyle(
                        fontSize: 11,
                        color: widget.isSelected
                            ? const Color(0xFF7F77DD)
                            : colors.onSurfaceVariant,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 5),
                      side: BorderSide(
                        color: widget.isSelected
                            ? const Color(0xFF7F77DD)
                            : colors.outlineVariant,
                        width: 0.8,
                      ),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhoto(ColorScheme colors) {
    if (_loadingPhotos) {
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
              size: 28, color: colors.outline.withValues(alpha: 0.2)),
        ),
      );
    }
    return Image.network(
      _photos[_photoIndex],
      width: double.infinity,
      height: 90,
      fit: BoxFit.cover,
      loadingBuilder: (_, child, progress) => progress == null
          ? child
          : ColoredBox(
              color: colors.surfaceContainerHigh,
              child: const Center(
                  child: CircularProgressIndicator(strokeWidth: 2)),
            ),
      errorBuilder: (_, __, ___) => ColoredBox(
        color: colors.surfaceContainerHigh,
        child: Center(
            child: Icon(Icons.broken_image_outlined,
                color: colors.onSurfaceVariant)),
      ),
    );
  }
}

class _SpecRow extends StatelessWidget {
  final Map<String, dynamic> airfleet;
  final ColorScheme colors;
  const _SpecRow({required this.airfleet, required this.colors});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 4,
      runSpacing: 4,
      children: [
        if (airfleet['seatCapacity'] != null)
          _pill('${airfleet['seatCapacity']} seats', colors),
        if (airfleet['aircraftSpeed'] != null)
          _pill('${airfleet['aircraftSpeed']} km/h', colors),
        if (airfleet['aircraftRangeKm'] != null)
          _pill('${airfleet['aircraftRangeKm']} km', colors),
      ],
    );
  }

  Widget _pill(String text, ColorScheme colors) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: colors.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(20),
          border:
              Border.all(color: colors.outlineVariant.withValues(alpha: 0.5)),
        ),
        child: Text(text,
            style:
                TextStyle(fontSize: 10, color: colors.onSurfaceVariant)),
      );
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
        width: 20, height: 20,
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.35),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: Colors.white, size: 14),
      ),
    );
  }
}

class _MiniBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool isError;
  const _MiniBtn(
      {required this.icon, required this.onTap, this.isError = false});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 24, height: 24,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.15), blurRadius: 3)
          ],
        ),
        child: Icon(icon,
            size: 12,
            color: isError ? const Color(0xFFE24B4A) : Colors.grey[700]),
      ),
    );
  }
}