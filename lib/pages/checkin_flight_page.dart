import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../services/auth_service.dart';
import '../services/checkin_api_service.dart';
import '../services/checkin_service.dart';
import '../widgets/responsive_layout.dart';
import '../widgets/custom/custom_button.dart';
import '../widgets/checkin/stat_card.dart';
import '../widgets/checkin/flight_list_body.dart';
import '../widgets/checkin/active_boarding_body.dart';
import '../widgets/checkin/checkin_boarding_pass_step.dart';
import '../widgets/checkin/checkin_seat_map_step.dart';

class CheckInFlightsPage extends StatefulWidget {
  const CheckInFlightsPage({super.key});

  @override
  State<CheckInFlightsPage> createState() => _CheckInFlightsPageState();
}

class _CheckInFlightsPageState extends State<CheckInFlightsPage> {
  late final CheckInApiService _apiService;
  late final AuthService _authService;

  List<Map<String, dynamic>> _flights = [];
  bool _isLoading = true;
  String? _error;

  Timer? _ticker;
  DateTime _now = DateTime.now();
  bool _isActioning = false;
  int _checkedIn = 0;
  int _totalPassengers = 0;
  int _remaining = 0;
  String _searchQuery = '';

  List<Map<String, dynamic>>? _recentPassengers;

  GoRouter? _router;

  @override
  void initState() {
    super.initState();
    _authService = context.read<AuthService>();
    _apiService = CheckInApiService(_authService);
    _load();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _router = GoRouter.of(context);
      _router!.routerDelegate.addListener(_onRouteChanged);
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _router?.routerDelegate.removeListener(_onRouteChanged);
    super.dispose();
  }

  void _onRouteChanged() {
    if (!mounted) return;
    final location = GoRouterState.of(context).uri.path;
    if (location == '/checkin' && mounted) _load();
  }

  Future<void> _loadStats(int flightOperationId) async {
    final results = await Future.wait([
      _apiService.getBoardingStats(flightOperationId),
      _apiService.getRecentlyCheckedIn(flightOperationId),
    ]);
    if (!mounted) return;
    final stats = results[0] as Map<String, dynamic>;
    setState(() {
      _totalPassengers = stats['total_passengers'] as int? ?? 0;
      _checkedIn = stats['checked_in'] as int? ?? 0;
      _remaining = stats['remaining'] as int? ?? 0;
      _recentPassengers = (results[1] as List?)
              ?.map((e) => Map<String, dynamic>.from(e as Map))
              .toList() ??
          [];
    });
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final flights = await _apiService.getActiveFlights();
      if (mounted) setState(() {
        _flights = flights;
        _isLoading = false;
      });
      _startTickerIfNeeded();

      final activeFlight = context.read<CheckInService>().activeFlight;
      if (activeFlight != null) {
        await _loadStats(activeFlight['flight_operation_id'] as int);
      }
    } catch (e) {
      if (mounted) setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  void _startTickerIfNeeded() {
    final activeFlight = context.read<CheckInService>().activeFlight;
    if (activeFlight != null &&
        activeFlight['boarding_start_time'] != null) {
      _ticker?.cancel();
      _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
        if (mounted) setState(() => _now = DateTime.now());
      });
    }
  }

  Future<void> _startBoarding(Map<String, dynamic> flight) async {
    setState(() => _isActioning = true);
    final ok =
        await _apiService.startBoarding(flight['flight_operation_id'] as int);
    if (!mounted) return;
    if (ok) {
      final userId = context.read<AuthService>().currentUser?.id ?? '';
      final updated = Map<String, dynamic>.from(flight);
      updated['boarding_start_time'] = DateTime.now().toString();
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
    final ok =
        await _apiService.endBoarding(flight['flight_operation_id'] as int);
    if (!mounted) return;
    if (ok) {
      final userId = context.read<AuthService>().currentUser?.id ?? '';
      await context.read<CheckInService>().clearActiveFlight(userId);
      _ticker?.cancel();
      await _load();
    }
    if (mounted) setState(() => _isActioning = false);
  }

  Future<void> _showBoardingPassModal(int boardingPassId) async {
    try {
      final data = await _apiService.getBoardingPassDetails(boardingPassId);
      if (!mounted) return;
      showDialog(
        context: context,
        builder: (ctx) {
          final colors = Theme.of(ctx).colorScheme;
          return Dialog(
            backgroundColor: Colors.transparent,
            insetPadding:
                const EdgeInsets.symmetric(horizontal: 40, vertical: 40),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1040),
              child: Stack(
                children: [
                  SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CheckInBoardingPassStep(
                          ticketNumber:   data['ticket_number']   ?? '—',
                          passengerName:  data['passenger_name']  ?? '—',
                          flightNumber:   data['flight_number']   ?? '—',
                          flightClass:    data['flight_class']    ?? '—',
                          seat:           data['seat']            ?? '—',
                          departDate:     DateTime.tryParse(data['departs_time'] ?? '') ?? DateTime.now(),
                          departsAirport: data['departs_airport'] ?? '—',
                          arrivesAirport: data['arrives_airport'] ?? '—',
                          departsTime:    data['departs_time']    ?? '—',
                          arrivesTime:    data['arrives_time']    ?? '—',
                          gate:           data['gate']            ?? '—',
                          onNewPassenger: () {},
                          showActions:    false,
                        ),
                      ],
                    ),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: IconButton(
                      icon: Icon(Icons.close, color: colors.onSurfaceVariant),
                      onPressed: () => Navigator.of(ctx).pop(),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to load boarding pass')),
      );
    }
  }

  Future<void> _showContextMenu(
    BuildContext context,
    Offset position,
    int boardingPassId,
    int flightOperationId,
    String currentSeat,
    int classId,
  ) async {
    final result = await showMenu<String>(
      context: context,
      position: RelativeRect.fromLTRB(
        position.dx,
        position.dy,
        position.dx + 1,
        position.dy + 1,
      ),
      items: [
        const PopupMenuItem(
          value: 'reprint',
          child: Row(
            children: [
              Icon(Icons.print_outlined, size: 16),
              SizedBox(width: 8),
              Text('Reprint boarding pass',
                  style: TextStyle(fontSize: 13)),
            ],
          ),
        ),
        const PopupMenuItem(
          value: 'change_seat',
          child: Row(
            children: [
              Icon(Icons.airline_seat_recline_normal_outlined, size: 16),
              SizedBox(width: 8),
              Text('Change seat', style: TextStyle(fontSize: 13)),
            ],
          ),
        ),
      ],
    );

    if (!mounted) return;

    if (result == 'reprint') {
      await _reprintBoardingPass(boardingPassId);
    } else if (result == 'change_seat') {
      await _changeSeat(
          boardingPassId, flightOperationId, currentSeat, classId);
    }
  }

  Future<void> _reprintBoardingPass(int boardingPassId) async {
    try {
      await _apiService.reprintBoardingPass(boardingPassId);
      if (!mounted) return;
      await _showBoardingPassModal(boardingPassId);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to reprint boarding pass')),
      );
    }
  }

  Future<void> _changeSeat(int boardingPassId, int flightOperationId,
      String currentSeat, int classId) async {
    final result = await showDialog<int>(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: Container(
            decoration: BoxDecoration(
              color: Theme.of(ctx).colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                  child: Row(
                    children: [
                      Icon(Icons.airline_seat_recline_normal_outlined,
                          size: 16,
                          color: Theme.of(ctx).colorScheme.primary),
                      const SizedBox(width: 8),
                      Text(
                        'Current seat: $currentSeat',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Theme.of(ctx).colorScheme.primary,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.close, size: 18),
                        onPressed: () => Navigator.of(ctx).pop(),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                CheckInSeatMapStep(
                  authService: _authService,
                  flightOperationId: flightOperationId,
                  passengerClassId: classId,
                  passengerDateOfBirth: null,
                  onSeatSelected: (seatPosition, seatLayoutId) {
                    Navigator.of(ctx).pop(seatLayoutId);
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );

    if (result == null || !mounted) return;

    try {
      await _apiService.updateBoardingPassSeat(boardingPassId, result);
      if (!mounted) return;
      await _showBoardingPassModal(boardingPassId);
      _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to update seat')),
      );
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
                ? ActiveBoardingBody(
                    totalPassengers: _totalPassengers,
                    checkedIn: _checkedIn,
                    remaining: _remaining,
                    recentPassengers: _recentPassengers ?? [],
                    searchQuery: _searchQuery,
                    onSearchChanged: (v) => setState(() => _searchQuery = v),
                    onPassengerTap: _showBoardingPassModal,
                    onPassengerSecondaryTap: (position, boardingPassId,
                        flightOperationId, currentSeat, classId) {
                      _showContextMenu(context, position, boardingPassId,
                          flightOperationId, currentSeat, classId);
                    },
                  )
                : FlightListBody(
                    flights: _flights,
                    isLoading: _isLoading,
                    error: _error,
                    isActioning: _isActioning,
                    onRetry: _load,
                    onStartBoarding: _startBoarding,
                    onJoinBoarding: _joinBoarding,
                  ),
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
                  ? '${activeFlight['flight_number'] ?? '—'} · ${activeFlight['departs_airport'] ?? '—'} → ${activeFlight['arrives_airport'] ?? '—'}'
                  : 'Select a flight to manage boarding',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
            ),
          ],
        ),
        const Spacer(),
        if (activeFlight != null) ...[
          CustomButton(
            label: 'Register Passenger',
            icon: Icons.person_add_outlined,
            isIconAfterLabel: false,
            verticalPadding: 8,
            horizontalPadding: 14,
            onPressed: () async {
              context.go('/checkin/register', extra: activeFlight);
              if (mounted) await _load();
            },
          ),
          const SizedBox(width: 8),
          OutlinedButton(
            onPressed: _isActioning ? null : _leaveBoarding,
            style: OutlinedButton.styleFrom(
              foregroundColor: colors.onSurfaceVariant,
              side: BorderSide(color: colors.outlineVariant),
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            ),
            child: const Text('Leave', style: TextStyle(fontSize: 13)),
          ),
          const SizedBox(width: 8),
          OutlinedButton(
            onPressed:
                _isActioning ? null : () => _endBoarding(activeFlight),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.red,
              side: const BorderSide(color: Colors.red),
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            ),
            child:
                const Text('End Boarding', style: TextStyle(fontSize: 13)),
          ),
        ] else ...[
          IconButton(
            icon: const Icon(Icons.refresh_rounded, size: 20),
            onPressed: _load,
            tooltip: 'Refresh',
          ),
        ],
      ],
    );
  }
}