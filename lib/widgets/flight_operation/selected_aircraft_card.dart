import 'package:flutter/material.dart';
import '../../models/airfleet_model.dart';
import '../../services/flight_operation_api_service.dart';

class SelectedAircraftCard extends StatefulWidget {
  final AirfleetModel airfleet;
  final FlightOperationApiService apiService;

  const SelectedAircraftCard({
    super.key,
    required this.airfleet,
    required this.apiService,
  });

  @override
  State<SelectedAircraftCard> createState() => _SelectedAircraftCardState();
}

class _SelectedAircraftCardState extends State<SelectedAircraftCard> {
  List<String> _photos = [];
  int _photoIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadPhotos();
  }

  Future<void> _loadPhotos() async {
    final photos = await widget.apiService
        .getAirfleetPhotos(widget.airfleet.airfleetId);
    if (mounted) setState(() => _photos = photos);
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final a = widget.airfleet;

    return Container(
      decoration: BoxDecoration(
        color: colors.primary.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.primary.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_photos.isNotEmpty)
            ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(11)),
              child: SizedBox(
                height: 200,
                child: Stack(
                  children: [
                    Image.network(
                      _photos[_photoIndex],
                      width: double.infinity,
                      height: 200,
                      fit: BoxFit.cover,
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
                          child: NavButton(
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
                          child: NavButton(
                            icon: Icons.chevron_right,
                            onTap: () => setState(() => _photoIndex =
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
                  ],
                ),
              ),
            )
          else
            ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(11)),
              child: Container(
                height: 80,
                color: colors.surfaceContainerHigh,
                child: Center(
                  child: Icon(Icons.airplanemode_active_outlined,
                      size: 32,
                      color:
                          colors.onSurfaceVariant.withValues(alpha: 0.4)),
                ),
              ),
            ),

          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
            child: Row(
              children: [
                Icon(Icons.airplanemode_active_rounded,
                    color: colors.primary, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        a.aircraftModel ?? '',
                        style: const TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 16),
                      ),
                      if (a.airfleetManufacturerName != null)
                        Text(
                          a.airfleetManufacturerName!,
                          style: TextStyle(
                              color: colors.onSurfaceVariant, fontSize: 12),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          Divider(
              height: 1,
              color: colors.outlineVariant.withValues(alpha: 0.5)),

          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  children: [
                    if (a.seatCapacity != null) ...[
                      _buildSpecCell(colors,
                          Icons.airline_seat_recline_normal_outlined,
                          'Seats', '${a.seatCapacity}',
                          borderRight: true),
                      Divider(
                          height: 1,
                          color:
                              colors.outlineVariant.withValues(alpha: 0.5)),
                    ],
                    if (a.aircraftSpeed != null) ...[
                      _buildSpecCell(colors, Icons.speed_outlined, 'Speed',
                          '${a.aircraftSpeed!.round()} km/h',
                          borderRight: true),
                      Divider(
                          height: 1,
                          color:
                              colors.outlineVariant.withValues(alpha: 0.5)),
                    ],
                    if (a.aircraftFuelConsumption != null)
                      _buildSpecCell(
                          colors,
                          Icons.local_gas_station_outlined,
                          'Fuel',
                          '${a.aircraftFuelConsumption} L/h',
                          borderRight: true),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  children: [
                    if (a.aircraftRangeKm != null) ...[
                      _buildSpecCell(colors, Icons.route_outlined, 'Range',
                          '${a.aircraftRangeKm!.round()} km',
                          borderRight: false),
                      Divider(
                          height: 1,
                          color:
                              colors.outlineVariant.withValues(alpha: 0.5)),
                    ],
                    if (a.baggageCapacity != null)
                      _buildSpecCell(colors, Icons.luggage_outlined,
                          'Baggage', '${a.baggageCapacity!.round()} kg',
                          borderRight: false),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSpecCell(
    ColorScheme colors,
    IconData icon,
    String label,
    String value, {
    required bool borderRight,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: borderRight
          ? BoxDecoration(
              border: Border(
                right: BorderSide(
                    color: colors.outlineVariant.withValues(alpha: 0.5)),
              ),
            )
          : null,
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
    );
  }
}

class NavButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const NavButton({
    super.key,
    required this.icon,
    required this.onTap,
  });

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