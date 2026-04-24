import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../services/planning_service.dart';
import '../../widgets/responsive_layout.dart';
import '../../widgets/custom/custom_button.dart';
import '../../widgets/planning/create_flight_steps/step2_seat_map.dart';
import '../../widgets/planning/create_flight_steps/step3_prices.dart';
import '../../widgets/planning/create_flight_steps/step4_confirm.dart';

enum _ConfigStep { seatMap, prices, confirm }

class FlightConfigPage extends StatefulWidget {
  final List<Map<String, dynamic>> flights;

  const FlightConfigPage({
    super.key,
    required this.flights,
  });

  @override
  State<FlightConfigPage> createState() => _FlightConfigPageState();
}

class _FlightConfigPageState extends State<FlightConfigPage> {
  late final PlanningService _service;
  _ConfigStep _step = _ConfigStep.seatMap;

  Map<int, int> _classSeats = {};
  Map<int, String> _classNames = {};
  Map<int, double> _classPrices = {};
  Map<int, Map<int, double>> _baggagePrices = {};
  Map<int, Set<int>> _enabledBaggageRules = {};

  bool _isSubmitting = false;

  static const _stepLabels = ['Seat map', 'Prices', 'Confirm'];

  @override
  void initState() {
    super.initState();
    _service = PlanningService(context.read<AuthService>());
    debugPrint('FLIGHT DATA: ${widget.flights.first}');
  }
    int get _airfleetId =>
        widget.flights.first['airfleetId'] as int;
        

    int get _currentIndex => _ConfigStep.values.indexOf(_step);

    bool get _canGoNext {
      switch (_step) {
        case _ConfigStep.seatMap:
          return _classSeats.isNotEmpty;
        case _ConfigStep.prices:
          final ticketsOk = _classPrices.length == _classSeats.length &&
              _classPrices.values.every((p) => p > 0);
          final baggageOk = _enabledBaggageRules.entries.every((entry) =>
              entry.value.every((ruleId) =>
                  (_baggagePrices[entry.key]?[ruleId] ?? 0.0) > 0));
          return ticketsOk && baggageOk;
        case _ConfigStep.confirm:
          return true;
      }
    }

    void _next() {
      setState(() {
        switch (_step) {
          case _ConfigStep.seatMap:
            _step = _ConfigStep.prices;
          case _ConfigStep.prices:
            _step = _ConfigStep.confirm;
          case _ConfigStep.confirm:
            break;
        }
      });
    }

    void _back() {
      switch (_step) {
        case _ConfigStep.seatMap:
          context.go('/planning/setup');
        case _ConfigStep.prices:
          setState(() => _step = _ConfigStep.seatMap);
        case _ConfigStep.confirm:
          setState(() => _step = _ConfigStep.prices);
      }
    }

    Future<void> _submit() async {
    setState(() => _isSubmitting = true);
    try {
      final classPrices = _classPrices.entries
          .map((e) => {'class_id': e.key, 'price': e.value})
          .toList();

      for (final flight in widget.flights) {
        final flightId = flight['flightId'] as int;

        await _service.configureFlight(
          flightId: flightId,
          classPrices: classPrices,
        );

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
      }

      if (mounted) {        
        context.go('/planning/setup');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceFirst('Exception: ', '')),
            backgroundColor: Colors.red.shade700,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8)),
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
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildStepIndicator(),
                  const SizedBox(height: 24),
                  _buildStepContent(),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              border: Border(
                top: BorderSide(
                  color: Theme.of(context)
                      .colorScheme
                      .outline
                      .withValues(alpha: 0.1),
                ),
              ),
            ),
            child: _buildBottomBar(),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    final colors = Theme.of(context).colorScheme;
    final first = widget.flights.first;

    return Padding(
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
                Text('Configure flights',
                    style: Theme.of(context).textTheme.titleLarge),
                Text(
                  '${first['flightNumber']}  ·  '
                  '${first['departsCode']} → ${first['arrivesCode']}  ·  '
                  '${widget.flights.length} flights',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: colors.onSurfaceVariant),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepIndicator() {
    final colors = Theme.of(context).colorScheme;

    return Row(
      children: List.generate(_ConfigStep.values.length * 2 - 1, (i) {
        if (i.isOdd) {
          final stepIndex = i ~/ 2;
          final isDone = _currentIndex > stepIndex;
          return Expanded(
            child: Container(
              height: 2,
              color: isDone
                  ? colors.primary
                  : colors.outline.withValues(alpha: 0.2),
            ),
          );
        }

        final stepIndex = i ~/ 2;
        final step = _ConfigStep.values[stepIndex];
        final isActive = _currentIndex == stepIndex;
        final isDone = _currentIndex > stepIndex;

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isDone
                    ? colors.primary
                    : isActive
                        ? colors.primaryContainer
                        : colors.surfaceContainerHighest,
                border: Border.all(
                  color: isActive || isDone
                      ? colors.primary
                      : colors.outline.withValues(alpha: 0.3),
                  width: isActive ? 2 : 1,
                ),
              ),
              child: Center(
                child: isDone
                    ? Icon(Icons.check, size: 16, color: colors.onPrimary)
                    : Text(
                        '${stepIndex + 1}',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: isActive
                              ? colors.primary
                              : colors.onSurfaceVariant,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              _stepLabels[stepIndex],
              style: TextStyle(
                fontSize: 11,
                fontWeight:
                    isActive ? FontWeight.w600 : FontWeight.normal,
                color: isActive
                    ? colors.primary
                    : colors.onSurfaceVariant,
              ),
            ),
          ],
        );
      }),
    );
  }

  Widget _buildStepContent() {
    final colors = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: colors.outline.withValues(alpha: 0.15)),
      ),
      clipBehavior: Clip.antiAlias,
      padding: const EdgeInsets.all(28),
      child: switch (_step) {
        _ConfigStep.seatMap => Step2SeatMap(
            service: _service,
            airfleetId: _airfleetId,
            onChanged: (classSeats, classNames, _) {
              setState(() {
                _classSeats = classSeats;
                _classNames = classNames;
              });
            },
            onClassesConfirmed: (_) => _next(),
          ),
        _ConfigStep.prices => Step3Prices(
            classSeats: _classSeats,
            classNames: _classNames,
            initialTicketPrices: _classPrices,
            initialBaggagePrices: _baggagePrices,
            onTicketPricesChanged: (p) =>
                setState(() => _classPrices = p),
            onBaggagePricesChanged: (p) =>
                setState(() => _baggagePrices = p),
            onBaggageEnabledChanged: (e) =>
                setState(() => _enabledBaggageRules = e),
            planningService: _service,
          ),
        _ConfigStep.confirm => FlightConfigConfirm(
            flights: widget.flights,
            classSeats: _classSeats,
            classNames: _classNames,
            classPrices: _classPrices,
            baggagePrices: _baggagePrices,
            enabledBaggageRules: _enabledBaggageRules,
          ),
      },
    );
  }

  Widget _buildBottomBar() {
    final colors = Theme.of(context).colorScheme;
    final isLast = _step == _ConfigStep.confirm;

    return Row(
      children: [
        TextButton.icon(
          onPressed: _back,
          icon: const Icon(Icons.arrow_back, size: 15),
          label: Text(_step == _ConfigStep.seatMap ? 'Cancel' : 'Back'),
          style: TextButton.styleFrom(
            foregroundColor: colors.onSurfaceVariant,
            padding: const EdgeInsets.symmetric(
                horizontal: 16, vertical: 12),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(6)),
          ),
        ),
        const Spacer(),
        if (!isLast)
          CustomButton(
            label: _step == _ConfigStep.seatMap
                ? 'Continue to Prices'
                : 'Review & Confirm',
            icon: Icons.arrow_forward,
            isIconAfterLabel: true,
            onPressed: _canGoNext ? _next : null,
            verticalPadding: 12,
            horizontalPadding: 24,
          )
        else
          _isSubmitting
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : CustomButton(
                  label: 'Apply to ${widget.flights.length} flights',
                  icon: Icons.check_circle_outline,
                  isIconAfterLabel: false,
                  onPressed: _submit,
                  verticalPadding: 12,
                  horizontalPadding: 24,
                ),
      ],
    );
  }



}