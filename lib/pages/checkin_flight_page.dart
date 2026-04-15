import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../services/auth_service.dart';
import '../../services/checkin_api_service.dart';
import '../../services/checkin_service.dart';
import '../../widgets/responsive_layout.dart';
import '../../widgets/custom/custom_button.dart';

class CheckInFlightsPage extends StatefulWidget {
  const CheckInFlightsPage({super.key});

  @override
  State<CheckInFlightsPage> createState() => _CheckInFlightsPageState();
}

class _CheckInFlightsPageState extends State<CheckInFlightsPage> {
  late final CheckInApiService _apiService;

  List<Map<String, dynamic>> _flights   = [];
  bool                       _isLoading = true;
  String?                    _error;

  Timer?    _ticker;
  DateTime  _now            = DateTime.now();
  bool      _isActioning    = false;
  int       _checkedIn      = 0;
  int _totalPassengers = 0;
  int _remaining       = 0;

  List<Map<String, dynamic>>? _recentPassengers;

  Future<void> _loadStats(int flightOperationId) async {
    final results = await Future.wait([
      _apiService.getBoardingStats(flightOperationId),
      _apiService.getRecentlyCheckedIn(flightOperationId),
    ]);
    if (!mounted) return;
    final stats  = results[0] as Map<String, dynamic>;
    setState(() {
      _totalPassengers  = stats['totalPassengers'] as int? ?? 0;
      _checkedIn        = stats['checkedIn']       as int? ?? 0;
      _remaining        = stats['remaining']       as int? ?? 0;
      _recentPassengers = (results[1] as List?)
        ?.map((e) => Map<String, dynamic>.from(e as Map))
        .toList() ?? [];
        });
  }

  @override
  void initState() {
    super.initState();
    _apiService = CheckInApiService(context.read<AuthService>());
    _load();
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      final flights = await _apiService.getActiveFlights();
      if (mounted) setState(() { _flights = flights; _isLoading = false; });
      _startTickerIfNeeded();
      
      final activeFlight = context.read<CheckInService>().activeFlight;
      if (activeFlight != null) {
        await _loadStats(activeFlight['flightOperationId'] as int);
      }
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _isLoading = false; });
    }
  }


  void _startTickerIfNeeded() {
    final activeFlight = context.read<CheckInService>().activeFlight;
    if (activeFlight != null && activeFlight['boardingStartTime'] != null) {
      _ticker?.cancel();
      _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
        if (mounted) setState(() => _now = DateTime.now());
      });
    }
  }

  String _elapsedLabel(String? boardingStartTime) {
    if (boardingStartTime == null) return '00:00';
    try {
      DateTime? start;
      
      start = DateTime.tryParse(boardingStartTime);
      
      if (start == null) {
        final parts = boardingStartTime.split(':');
        final now   = DateTime.now();
        start = DateTime(
          now.year, now.month, now.day,
          int.parse(parts[0]),
          int.parse(parts[1]),
          parts.length > 2 ? int.parse(parts[2].split('.').first) : 0,
        );
      }
      
      final diff = _now.difference(start);
      final h    = diff.inHours;
      final m    = diff.inMinutes % 60;
      final s    = diff.inSeconds % 60;
      if (h > 0) {
        return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
      }
      return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
    } catch (_) {
      return '00:00';
    }
  }


  Future<void> _startBoarding(Map<String, dynamic> flight) async {
    setState(() => _isActioning = true);
    final ok = await _apiService.startBoarding(
        flight['flightOperationId'] as int);
    if (!mounted) return;
    if (ok) {
      final userId = context.read<AuthService>().currentUser?.id ?? '';
      final updated = Map<String, dynamic>.from(flight);
      updated['boardingStartTime'] = DateTime.now().toString();
      await context.read<CheckInService>().setActiveFlight(updated, userId);
      await _load();
    }
    if (mounted) setState(() => _isActioning = false);
  }

  Future<void> _joinBoarding(Map<String, dynamic> flight) async {
    final userId = context.read<AuthService>().currentUser?.id ?? '';
    await context.read<CheckInService>().setActiveFlight(flight, userId);
    _startTickerIfNeeded();
    setState(() {});
  }

  Future<void> _leaveBoarding() async {
    final userId = context.read<AuthService>().currentUser?.id ?? '';
    await context.read<CheckInService>().clearActiveFlight(userId);
    _ticker?.cancel();
    setState(() {});
  }

  Future<void> _endBoarding(Map<String, dynamic> flight) async {
    setState(() => _isActioning = true);
    final ok = await _apiService.endBoarding(
        flight['flightOperationId'] as int);
    if (!mounted) return;
    if (ok) {
      final userId = context.read<AuthService>().currentUser?.id ?? '';
      await context.read<CheckInService>().clearActiveFlight(userId);
      _ticker?.cancel();
      await _load();
    }
    if (mounted) setState(() => _isActioning = false);
  }

  String _formatTime(String? datetime) {
    if (datetime == null) return '—';
    try { return DateFormat('HH:mm').format(DateTime.parse(datetime)); }
    catch (_) { return '—'; }
  }

  String _formatDate(String? datetime) {
    if (datetime == null) return '—';
    try { return DateFormat('MMM d').format(DateTime.parse(datetime)); }
    catch (_) { return '—'; }
  }

  Color _statusColor(String? status, ColorScheme colors) {
    switch (status) {
      case 'Waiting':  return colors.onSurfaceVariant;
      case 'Boarding': return const Color(0xFF2196F3);
      default:         return colors.onSurfaceVariant;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<CheckInService>(
      builder: (context, checkinService, _) {
        final activeFlight = checkinService.activeFlight;

        return ResponsiveLayout(
          header: Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
            child: _buildHeader(activeFlight),
          ),
          body: Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
            child: activeFlight != null
                ? _buildActiveBoardingBody(activeFlight)
                : _buildFlightListBody(),
          ),
        );
      },
    );
  }

  Widget _buildHeader(Map<String, dynamic>? activeFlight) {
    final colors = Theme.of(context).colorScheme;
    return Row(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              activeFlight != null ? 'Active Boarding' : 'Flights',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 2),
            Text(
              activeFlight != null
                  ? '${activeFlight['flightNumber'] ?? '—'} · ${activeFlight['departsAirport'] ?? '—'} → ${activeFlight['arrivesAirport'] ?? '—'}'
                  : 'Select a flight to manage boarding',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
            ),
          ],
        ),
        const Spacer(),
        if (activeFlight != null) ...[
          OutlinedButton(
            onPressed: _isActioning ? null : _leaveBoarding,
            style: OutlinedButton.styleFrom(
              foregroundColor: colors.onSurfaceVariant,
              side: BorderSide(color: colors.outlineVariant),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            ),
            child: const Text('Leave', style: TextStyle(fontSize: 13)),
          ),
          const SizedBox(width: 8),
          OutlinedButton(
            onPressed: _isActioning ? null : () => _endBoarding(activeFlight),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.red,
              side: const BorderSide(color: Colors.red),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            ),
            child: const Text('End Boarding', style: TextStyle(fontSize: 13)),
          ),
        ] else ...[
          
          
          IconButton(
            icon:      const Icon(Icons.refresh_rounded, size: 20),
            onPressed: _load,
            tooltip:   'Refresh',
          ),
        ],
      ],
    );
  }

  Widget _buildActiveBoardingBody(Map<String, dynamic> flight) {
    final colors = Theme.of(context).colorScheme;

    return SingleChildScrollView(
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _StatCard(
                    label: 'Total passengers',
                    value: '$_totalPassengers',
                    colors: colors),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StatCard(
                    label:      'Checked in',
                    value:      '$_checkedIn',
                    valueColor: Colors.green,
                    colors:     colors),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StatCard(
                    label: 'Remaining',
                    value: '$_remaining',
                    colors: colors),
              ),
            ],
          ),

          const SizedBox(height: 32),

          CustomButton(
            label:             'Register Passenger',
            icon:              Icons.person_add_outlined,
            isIconAfterLabel:  false,
            verticalPadding:   12,
            horizontalPadding: 28,
            onPressed: () => context.go(
              '/checkin/register',
              extra: flight,
            ),
          ),

          const SizedBox(height: 32),

          Container(
            width:       double.infinity,
            decoration: BoxDecoration(
              color:        colors.surface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                  color: colors.outlineVariant.withValues(alpha: 0.4)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                  child: Text(
                    'RECENTLY CHECKED IN',
                    style: TextStyle(
                      fontSize:      11,
                      fontWeight:    FontWeight.w600,
                      letterSpacing: 0.8,
                      color:         colors.onSurfaceVariant,
                    ),
                  ),
                ),
                Divider(
                    height: 1,
                    color: colors.outlineVariant.withValues(alpha: 0.4)),
                (_recentPassengers ?? []).isEmpty
                    ? Padding(
                        padding: const EdgeInsets.all(32),
                        child: Center(
                          child: Text(
                            'No passengers registered yet',
                            style: TextStyle(color: colors.onSurfaceVariant),
                          ),
                        ),
                      )
                    : ListView.separated(
                        shrinkWrap:       true,
                        physics:          const NeverScrollableScrollPhysics(),
                        itemCount: (_recentPassengers ?? []).length,
                        separatorBuilder: (_, __) => Divider(
                            height: 1,
                            color: colors.outlineVariant
                                .withValues(alpha: 0.3)),
                        itemBuilder: (_, i) {
                          final p = (_recentPassengers ?? [])[i];
                          return Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 10),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 16,
                                  backgroundColor: colors.primaryContainer
                                      .withValues(alpha: 0.5),
                                  child: Text(
                                    (p['passengerName'] as String? ?? '?')[0],
                                    style: TextStyle(
                                        fontSize: 12,
                                        color:    colors.primary),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        p['passengerName'] as String? ?? '—',
                                        style: const TextStyle(
                                            fontSize:   13,
                                            fontWeight: FontWeight.w600),
                                      ),
                                      Text(
                                        'Seat ${p['seat'] ?? '—'} · ${p['className'] ?? '—'}',
                                        style: TextStyle(
                                            fontSize: 11,
                                            color:
                                                colors.onSurfaceVariant),
                                      ),
                                    ],
                                  ),
                                ),
                                Text(
                                  _fmtIssuedAt(p['issuedAt'] as String?),
                                  style: TextStyle(
                                      fontSize: 11,
                                      color:    colors.onSurfaceVariant),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _fmtIssuedAt(String? issuedAt) {
    if (issuedAt == null) return '—';
    try {
      final dt   = DateTime.parse(issuedAt);
      final diff = DateTime.now().difference(dt);
      if (diff.inMinutes < 1) return 'just now';
      if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
      return '${diff.inHours}h ago';
    } catch (_) {
      return '—';
    }
  }
  
  Widget _buildFlightListBody() {
    if (_isLoading) return const Center(child: CircularProgressIndicator());

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline_rounded,
                size: 48,
                color: Theme.of(context).colorScheme.error),
            const SizedBox(height: 12),
            Text(_error!,
                style: TextStyle(
                    color: Theme.of(context).colorScheme.error)),
            const SizedBox(height: 16),
            TextButton(onPressed: _load, child: const Text('Retry')),
          ],
        ),
      );
    }

    if (_flights.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.flight_outlined,
                size: 56,
                color: Theme.of(context)
                    .colorScheme
                    .outline
                    .withValues(alpha: 0.3)),
            const SizedBox(height: 12),
            Text('No active flights',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(
              'There are no flights waiting for boarding at your airport',
              style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      itemCount:        _flights.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder:      (_, i) => _buildFlightCard(_flights[i]),
    );
  }

  Widget _buildFlightCard(Map<String, dynamic> flight) {
    final colors        = Theme.of(context).colorScheme;
    final status        = flight['status']             as String?;
    final flightNumber  = flight['flightNumber']       as String? ?? '—';
    final gate          = flight['gateCode']           as String? ?? '—';
    final departs       = flight['departsDatetime']    as String?;
    final arrives       = flight['arrivesDatetime']    as String?;
    final depAirport    = flight['departsAirport']     as String? ?? '—';
    final arrAirport    = flight['arrivesAirport']     as String? ?? '—';
    final arrName       = flight['arrivesAirportName'] as String? ?? '—';
    final boardingStart = flight['boardingStartTime']  as String?;
    final boardingEnd   = flight['boardingEndTime']    as String?;
    final statusColor   = _statusColor(status, colors);
    final isBoarding    = status == 'Boarding';
    final isBoardingDone = boardingStart != null && boardingEnd != null;

    return Container(
      decoration: BoxDecoration(
        color:        colors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isBoarding && boardingEnd == null
              ? const Color(0xFF2196F3).withValues(alpha: 0.4)
              : colors.outlineVariant.withValues(alpha: 0.4),
          width: isBoarding && boardingEnd == null ? 1.5 : 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(flightNumber,
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(width: 10),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color:        statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                        color: statusColor.withValues(alpha: 0.3)),
                  ),
                  child: Text(status ?? '—',
                      style: TextStyle(
                        fontSize:   11,
                        fontWeight: FontWeight.w600,
                        color:      statusColor,
                      )),
                ),
                const Spacer(),
                Icon(Icons.door_sliding_outlined,
                    size: 14, color: colors.onSurfaceVariant),
                const SizedBox(width: 5),
                Text('Gate $gate',
                    style: TextStyle(
                        fontSize: 13, color: colors.onSurfaceVariant)),
              ],
            ),

            const SizedBox(height: 16),

            Row(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_formatTime(departs),
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(fontWeight: FontWeight.w600)),
                    Text(depAirport,
                        style: TextStyle(
                            fontSize: 12,
                            color: colors.onSurfaceVariant)),
                    Text(_formatDate(departs),
                        style: TextStyle(
                            fontSize: 11,
                            color: colors.onSurfaceVariant)),
                  ],
                ),
                Expanded(
                  child: Row(
                    children: [
                      Expanded(
                        child: Container(
                            height: 1,
                            color:
                                colors.outline.withValues(alpha: 0.3)),
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
                            color:
                                colors.outline.withValues(alpha: 0.3)),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(_formatTime(arrives),
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(fontWeight: FontWeight.w600)),
                    Text(arrAirport,
                        style: TextStyle(
                            fontSize: 12,
                            color: colors.onSurfaceVariant)),
                    Text(arrName,
                        style: TextStyle(
                            fontSize: 11,
                            color: colors.onSurfaceVariant),
                        overflow: TextOverflow.ellipsis),
                  ],
                ),
              ],
            ),

            if (isBoardingDone) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(Icons.check_circle_outline,
                      size: 13, color: Colors.green),
                  const SizedBox(width: 5),
                  Text(
                    'Boarding completed · ${boardingStart!.substring(0, 5)} — ${boardingEnd!.substring(0, 5)}',
                    style: const TextStyle(
                        fontSize: 11, color: Colors.green),
                  ),
                ],
              ),
            ],

            const SizedBox(height: 16),

            Align(
              alignment: Alignment.centerRight,
              child: _isActioning
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : isBoardingDone
                      ? const SizedBox.shrink()
                      : status == 'Waiting'
                          ? CustomButton(
                              label:             'Start Boarding',
                              icon:              Icons.play_arrow_rounded,
                              isIconAfterLabel:  false,
                              verticalPadding:   8,
                              horizontalPadding: 14,
                              onPressed: () => _startBoarding(flight),
                            )
                          : CustomButton(
                              label:             'Join Boarding',
                              icon:              Icons.login_rounded,
                              isIconAfterLabel:  false,
                              verticalPadding:   8,
                              horizontalPadding: 14,
                              onPressed: () => _joinBoarding(flight),
                            ),
            ),
          ],
        ),
      ),
    );
  }


}

class _StatCard extends StatelessWidget {
  final String      label;
  final String      value;
  final Color?      valueColor;
  final ColorScheme colors;

  const _StatCard({
    required this.label,
    required this.value,
    required this.colors,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color:        colors.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Text(label,
              style: TextStyle(
                  fontSize: 12, color: colors.onSurfaceVariant)),
          const SizedBox(height: 6),
          Text(value,
              style: TextStyle(
                fontSize:   24,
                fontWeight: FontWeight.w500,
                color:      valueColor ?? colors.onSurface,
              )),
        ],
      ),
    );
  }
}