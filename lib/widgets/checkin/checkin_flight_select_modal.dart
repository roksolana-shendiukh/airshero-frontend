import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/auth_service.dart';
import '../../services/checkin_api_service.dart';
import '../../widgets/custom/custom_button.dart';

class CheckInFlightSelectModal extends StatefulWidget {
  final AuthService authService;
  final void Function(Map<String, dynamic> flight) onFlightSelected;

  const CheckInFlightSelectModal({
    super.key,
    required this.authService,
    required this.onFlightSelected,
  });

  @override
  State<CheckInFlightSelectModal> createState() =>
      _CheckInFlightSelectModalState();
}

class _CheckInFlightSelectModalState extends State<CheckInFlightSelectModal> {
  List<Map<String, dynamic>> _flights   = [];
  bool                       _isLoading = true;
  String?                    _error;

  @override
  void initState() {
    super.initState();
    _loadFlights();
  }

  Future<void> _loadFlights() async {
    try {
      final api     = CheckInApiService(widget.authService);
      final flights = await api.getActiveFlights();
      if (!mounted) return;
      setState(() {
        _flights   = flights;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error     = 'Failed to load flights. Please try again.';
        _isLoading = false;
      });
    }
  }

  String _formatTime(String? datetime) {
    if (datetime == null) return '—';
    try {
      return DateFormat('HH:mm').format(DateTime.parse(datetime));
    } catch (_) {
      return '—';
    }
  }

  String _formatDate(String? datetime) {
    if (datetime == null) return '—';
    try {
      return DateFormat('MMM d').format(DateTime.parse(datetime));
    } catch (_) {
      return '—';
    }
  }

  Color _statusColor(String? status, ColorScheme colors) {
    switch (status) {
      case 'Boarding':  return const Color(0xFF4CAF50);
      case 'Delayed':   return colors.error;
      case 'Scheduled': return colors.primary;
      default:          return colors.onSurfaceVariant;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Dialog(
      backgroundColor: colors.surfaceContainerHigh,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560, maxHeight: 600),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              Row(
                children: [
                  Icon(Icons.flight_takeoff, color: colors.primary, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Select flight',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ],
              ),

              const SizedBox(height: 6),

              Text(
                'Select the flight you are checking in for',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
              ),

              const SizedBox(height: 20),

              // ── Content ──────────────────────────────────────
              if (_isLoading)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: CircularProgressIndicator(),
                  ),
                )
              else if (_error != null)
                _buildError()
              else if (_flights.isEmpty)
                _buildEmpty()
              else
                Flexible(
                  child: ListView.separated(
                    shrinkWrap:     true,
                    itemCount:      _flights.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) =>
                        _buildFlightCard(_flights[index]),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFlightCard(Map<String, dynamic> flight) {
    final colors        = Theme.of(context).colorScheme;
    final status        = flight['status']            as String?;
    final flightNumber  = flight['flightNumber']      as String? ?? '—';
    final gate          = flight['gateCode']          as String? ?? '—';
    final departs       = flight['departsDatetime']   as String?;
    final arrives       = flight['arrivesDatetime']   as String?;
    final depAirport    = flight['departsAirport']    as String? ?? '—';
    final arrAirport    = flight['arrivesAirport']    as String? ?? '—';
    final arrName       = flight['arrivesAirportName'] as String? ?? '—';
    final boardingStart = flight['boardingStartTime'] as String?;
    final boardingEnd   = flight['boardingEndTime']   as String?;

    return Material(
      color:        colors.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: boardingStart != null
            ? () => widget.onFlightSelected(flight)
            : null,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    flightNumber,
                    style: Theme.of(context)
                        .textTheme
                        .titleSmall
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: _statusColor(status, colors)
                          .withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      status ?? '—',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color:      _statusColor(status, colors),
                            fontWeight: FontWeight.w600,
                            fontSize:   11,
                          ),
                    ),
                  ),
                  const Spacer(),
                  Icon(Icons.door_sliding_outlined,
                      size: 14, color: colors.onSurfaceVariant),
                  const SizedBox(width: 4),
                  Text(
                    'Gate $gate',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: colors.onSurfaceVariant,
                        ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              Row(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _formatTime(departs),
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(fontWeight: FontWeight.w600),
                      ),
                      Text(
                        depAirport,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: colors.onSurfaceVariant,
                            ),
                      ),
                      Text(
                        _formatDate(departs),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color:    colors.onSurfaceVariant,
                              fontSize: 11,
                            ),
                      ),
                    ],
                  ),
                  Expanded(
                    child: Row(
                      children: [
                        Expanded(
                          child: Container(
                            height: 1,
                            color: colors.outline.withValues(alpha: 0.3),
                          ),
                        ),
                        Padding(
                          padding:
                              const EdgeInsets.symmetric(horizontal: 8),
                          child: Icon(Icons.flight,
                              size: 16, color: colors.onSurfaceVariant),
                        ),
                        Expanded(
                          child: Container(
                            height: 1,
                            color: colors.outline.withValues(alpha: 0.3),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        _formatTime(arrives),
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(fontWeight: FontWeight.w600),
                      ),
                      Text(
                        arrAirport,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: colors.onSurfaceVariant,
                            ),
                      ),
                      Text(
                        arrName,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color:    colors.onSurfaceVariant,
                              fontSize: 11,
                            ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ],
              ),

              if (boardingStart != null && boardingEnd != null) ...[
                const SizedBox(height: 10),
                Row(
                  children: [
                    Icon(Icons.person_outline,
                        size: 13, color: colors.onSurfaceVariant),
                    const SizedBox(width: 4),
                    Text(
                      'Boarding: ${boardingStart.substring(0, 5)} — ${boardingEnd.substring(0, 5)}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color:    colors.onSurfaceVariant,
                            fontSize: 11,
                          ),
                    ),
                  ],
                ),
              ],

              const SizedBox(height: 10),

             if (boardingStart == null)
              Align(
                alignment: Alignment.centerRight,
                child: CustomButton(
                  label:             'Start Boarding',
                  icon:              Icons.play_arrow_rounded,
                  isIconAfterLabel:  false,
                  verticalPadding:   8,
                  horizontalPadding: 14,
                  onPressed: () async {
                    final api = CheckInApiService(widget.authService);
                    final ok  = await api.startBoarding(
                        flight['flightOperationId'] as int);
                    if (ok && mounted) {
                      widget.onFlightSelected(flight);
                    }
                  },
                ),
              )
            else if (boardingEnd == null)
              Align(
                alignment: Alignment.centerRight,
                child: CustomButton(
                  label:             'End Boarding',
                  icon:              Icons.stop_rounded,
                  isIconAfterLabel:  false,
                  verticalPadding:   8,
                  horizontalPadding: 14,
                  backgroundColor:   Colors.orange,
                  onPressed: () async {
                    final api = CheckInApiService(widget.authService);
                    await api.endBoarding(
                        flight['flightOperationId'] as int);
                    if (mounted) _loadFlights();
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildError() {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color:        colors.errorContainer.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, size: 16, color: colors.error),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _error!,
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: colors.error),
            ),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                _isLoading = true;
                _error     = null;
              });
              _loadFlights();
            },
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty() {
    final colors = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            Icon(Icons.flight_land, size: 48, color: colors.onSurfaceVariant),
            const SizedBox(height: 12),
            Text(
              'No active flights',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              'There are no flights currently boarding at your airport',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}