import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../services/planning_service.dart';
import '../../widgets/responsive_layout.dart';
import '../../widgets/planning/create_flight_steps/step1_route_date.dart';
import '../../widgets/planning/create_flight_steps/step2_seat_map.dart';
import '../../widgets/planning/create_flight_steps/step3_prices.dart';
import '../../widgets/planning/create_flight_steps/step4_confirm.dart';

enum _CreateFlightStep { routeDate, seatMap, prices, confirm }

class CreateFlightPage extends StatefulWidget {
  const CreateFlightPage({super.key});

  @override
  State<CreateFlightPage> createState() => _CreateFlightPageState();
}

class _CreateFlightPageState extends State<CreateFlightPage>
    with SingleTickerProviderStateMixin {
  late final PlanningService _service;
  late final AnimationController _animController;
  late Animation<double> _fadeAnim;

  _CreateFlightStep _step = _CreateFlightStep.routeDate;

  Map<String, dynamic>? _selectedRoute;
  int? _flightScheduleId;
  DateTime? _selectedDate;
  String? _departsTime;
  String? _arrivesTime;

  Map<int, int> _classSeats = {};
  Map<int, String> _classNames = {};
  Map<int, double> _classPrices = {};
  Map<int, Map<int, double>> _baggagePrices = {};
  Map<int, Set<int>> _enabledBaggageRules = {};

  bool _isSubmitting = false;

  static const _stepLabels = ['Route & date', 'Seat map', 'Prices', 'Confirm'];

  @override
  void initState() {
    super.initState();
    _service = PlanningService(context.read<AuthService>());
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  int get _currentIndex => _CreateFlightStep.values.indexOf(_step);

  bool get _canGoNext {
    switch (_step) {
      case _CreateFlightStep.routeDate:
        return _selectedRoute != null &&
            _flightScheduleId != null &&
            _selectedDate != null &&
            _departsTime != null &&
            _arrivesTime != null;
      case _CreateFlightStep.seatMap:
        return _classSeats.isNotEmpty;
      case _CreateFlightStep.prices:
        return _classPrices.length == _classSeats.length &&
            _classPrices.values.every((p) => p > 0);
      case _CreateFlightStep.confirm:
        return true;
    }
  }

  void _goToStep(_CreateFlightStep step) {
    final targetIndex = _CreateFlightStep.values.indexOf(step);
    if (targetIndex >= _currentIndex) return;
    _animController.forward(from: 0);
    setState(() => _step = step);
  }

  void _next() {
    _animController.forward(from: 0);
    setState(() {
      switch (_step) {
        case _CreateFlightStep.routeDate:
          _step = _CreateFlightStep.seatMap;
        case _CreateFlightStep.seatMap:
          _step = _CreateFlightStep.prices;
        case _CreateFlightStep.prices:
          _step = _CreateFlightStep.confirm;
        case _CreateFlightStep.confirm:
          break;
      }
    });
  }

  void _back() {
    switch (_step) {
      case _CreateFlightStep.routeDate:
        context.go('/planning/flights');
      case _CreateFlightStep.seatMap:
        _animController.forward(from: 0);
        setState(() => _step = _CreateFlightStep.routeDate);
      case _CreateFlightStep.prices:
        _animController.forward(from: 0);
        setState(() => _step = _CreateFlightStep.seatMap);
      case _CreateFlightStep.confirm:
        _animController.forward(from: 0);
        setState(() => _step = _CreateFlightStep.prices);
    }
  }

  String _buildDatetime(DateTime date, String time,
      {bool nextDayIfLess = false, String? compareTo}) {
    if (nextDayIfLess && compareTo != null) {
      final tp = time.split(':');
      final cp = compareTo.split(':');
      final tMins = int.parse(tp[0]) * 60 + int.parse(tp[1]);
      final cMins = int.parse(cp[0]) * 60 + int.parse(cp[1]);
      if (tMins < cMins) date = date.add(const Duration(days: 1));
    }
    return '${date.year}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}'
        'T$time:00';
  }

  Future<void> _submit() async {
    setState(() => _isSubmitting = true);
    try {
      final depDt = _buildDatetime(_selectedDate!, _departsTime!);
      final arrDt = _buildDatetime(_selectedDate!, _arrivesTime!,
          nextDayIfLess: true, compareTo: _departsTime!);

      final classPrices = _classPrices.entries
          .map((e) => {'class_id': e.key, 'price': e.value})
          .toList();

      final result = await _service.createFlight(
        flightScheduleId: _flightScheduleId!,
        departsDatetime: depDt,
        arrivesDatetime: arrDt,
        classPrices: classPrices,
      );

      final flightId = result['flightId'] as int;

      final baggageOptions = <Map<String, dynamic>>[];
      for (final entry in _enabledBaggageRules.entries) {
        for (final ruleId in entry.value) {
          baggageOptions.add({
            'classId': entry.key,
            'baggagePricingRuleId': ruleId,
            'price': _baggagePrices[entry.key]?[ruleId] ?? 0.0,
          });
        }
      }

      if (baggageOptions.isNotEmpty) {
        await _service.addBaggageToFlight(
          flightId: flightId,
          options: baggageOptions,
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(children: [
              Icon(Icons.check_circle_outline, color: Colors.white, size: 16),
              SizedBox(width: 8),
              Text('Flight created successfully'),
            ]),
            backgroundColor: Colors.green.shade700,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        );
        context.go('/planning/flights');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceFirst('Exception: ', '')),
            backgroundColor: Colors.red.shade700,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ResponsiveLayout(
      header: _buildHeader(),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        child: _buildBody(),
      ),
    );
  }

  Widget _buildHeader() {
    final colors = Theme.of(context).colorScheme;
    final route = _selectedRoute;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
          child: Row(
            children: [
              InkWell(
                onTap: _back,
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                        color: colors.outline.withValues(alpha: 0.2)),
                  ),
                  child: Icon(Icons.arrow_back,
                      size: 18, color: colors.onSurface),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Create flight',
                        style: Theme.of(context).textTheme.titleLarge),
                    if (route != null)
                      Text(
                        '${route['flightNumber']}  ·  '
                        '${route['departsCode']} → ${route['arrivesCode']}  ·  '
                        '${route['aircraftModel']}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: colors.onSurfaceVariant),
                      )
                    else
                      Text('New flight',
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(color: colors.onSurfaceVariant)),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: colors.surfaceContainerHighest.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${_currentIndex + 1} / ${_CreateFlightStep.values.length}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _buildTabBar(),
      ],
    );
  }

  Widget _buildTabBar() {
    final colors = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        border: Border(
          bottom:
              BorderSide(color: colors.outline.withValues(alpha: 0.15)),
        ),
      ),
      child: Row(
        children: List.generate(_CreateFlightStep.values.length, (i) {
          final step = _CreateFlightStep.values[i];
          final isActive = _currentIndex == i;
          final isDone = _currentIndex > i;
          final isReachable = i < _currentIndex;

          return GestureDetector(
            onTap: isReachable ? () => _goToStep(step) : null,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 0),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: isActive ? colors.primary : Colors.transparent,
                    width: 2,
                  ),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 14),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (isDone)
                      Padding(
                        padding: const EdgeInsets.only(right: 5),
                        child: Icon(Icons.check_circle,
                            size: 13, color: colors.primary),
                      ),
                    Text(
                      _stepLabels[i],
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight:
                            isActive ? FontWeight.w600 : FontWeight.normal,
                        color: isActive
                            ? colors.primary
                            : isDone
                                ? colors.onSurface
                                : colors.onSurfaceVariant
                                    .withValues(alpha: 0.5),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildBody() {
    final colors = Theme.of(context).colorScheme;
    final isLast = _step == _CreateFlightStep.confirm;

    return Column(
      children: [
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                  color: colors.outline.withValues(alpha: 0.15)),
            ),
            clipBehavior: Clip.antiAlias,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(28),
              child: FadeTransition(
                opacity: _fadeAnim,
                child: _buildStep(),
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            TextButton.icon(
              onPressed: _back,
              icon: const Icon(Icons.arrow_back, size: 15),
              label: Text(_step == _CreateFlightStep.routeDate
                  ? 'Cancel'
                  : 'Back'),
              style: TextButton.styleFrom(
                foregroundColor: colors.onSurfaceVariant,
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
            ),
            const Spacer(),
            if (!isLast)
              FilledButton(
                onPressed: _canGoNext ? _next : null,
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Continue to ${_stepLabels[_currentIndex + 1]}'),
                    const SizedBox(width: 6),
                    const Icon(Icons.arrow_forward, size: 15),
                  ],
                ),
              )
            else
              _isSubmitting
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : FilledButton.icon(
                      onPressed: _submit,
                      icon: const Icon(Icons.flight_takeoff, size: 16),
                      label: const Text('Create flight'),
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 12),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
          ],
        ),
      ],
    );
  }

  Widget _buildStep() {
    switch (_step) {
      case _CreateFlightStep.routeDate:
        return Step1RouteDate(
          service: _service,
          selectedRoute: _selectedRoute,
          selectedFlightScheduleId: _flightScheduleId,
          selectedDate: _selectedDate,
          departsTime: _departsTime,
          arrivesTime: _arrivesTime,
          onChanged: ({
            required route,
            required flightScheduleId,
            required date,
            required departsTime,
            required arrivesTime,
          }) {
            setState(() {
              _selectedRoute = route;
              _flightScheduleId = flightScheduleId;
              _selectedDate = date;
              _departsTime = departsTime;
              _arrivesTime = arrivesTime;
              _classSeats = {};
              _classPrices = {};
              _baggagePrices = {};
              _enabledBaggageRules = {};
            });
          },
        );

      case _CreateFlightStep.seatMap:
        return Step2SeatMap(
          service: _service,
          airfleetId: _selectedRoute!['airfleetId'] as int,
          onChanged: (classSeats, classNames, blockedSeatLayoutIds) {
            setState(() {
              _classSeats = classSeats;
              _classNames = classNames;
            });
          },
          onClassesConfirmed: (_) => _next(),
        );

      case _CreateFlightStep.prices:
        return Step3Prices(
          classSeats: _classSeats,
          classNames: _classNames,
          initialTicketPrices: _classPrices,
          initialBaggagePrices: _baggagePrices,
          onTicketPricesChanged: (p) => setState(() => _classPrices = p),
          onBaggagePricesChanged: (p) => setState(() => _baggagePrices = p),
          onBaggageEnabledChanged: (e) =>
              setState(() => _enabledBaggageRules = e),
          planningService: _service,
        );

      case _CreateFlightStep.confirm:
        return Step4Confirm(
          route: _selectedRoute!,
          date: _selectedDate!,
          departsTime: _departsTime!,
          arrivesTime: _arrivesTime!,
          classSeats: _classSeats,
          classNames: _classNames,
          classPrices: _classPrices,
          baggagePrices: _baggagePrices,
          enabledBaggageRules: _enabledBaggageRules,
        );
    }
  }
}