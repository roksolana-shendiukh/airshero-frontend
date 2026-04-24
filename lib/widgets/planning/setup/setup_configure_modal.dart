import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../services/planning_service.dart';
import '../../custom/custom_button.dart';
import '../../custom/custom_input_field.dart';
import '../create_flight_steps/step2_seat_map.dart';

class SetupConfigureModal extends StatefulWidget {
  final List<Map<String, dynamic>> flights;
  final PlanningService service;
  final int airfleetId;
  final void Function(List<int> confirmedIds) onDone;
  final VoidCallback onClose;

  const SetupConfigureModal({
    super.key,
    required this.flights,
    required this.service,
    required this.airfleetId,
    required this.onDone,
    required this.onClose,
  });

  @override
  State<SetupConfigureModal> createState() => _SetupConfigureModalState();
}

class _SetupConfigureModalState extends State<SetupConfigureModal>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  // Classes
  Map<int, int> _classSeats = {};
  Map<int, String> _classNames = {};

  // Prices
  Map<int, double> _prices = {};

  // Baggage
  List<Map<String, dynamic>> _baggageRules = [];
  bool _loadingBaggage = true;
  Map<int, Set<int>> _enabledBaggageRules = {};
  Map<int, Map<int, double>> _baggagePrices = {};

  bool _saving = false;
  bool _hasExistingClasses = false;
  Map<int, double> _originalPrices = {};

  bool get _hasChanges {
    if (_originalPrices.isEmpty && _prices.isNotEmpty) return true;
    if (_originalPrices.length != _prices.length) return true;
    for (final e in _prices.entries) {
      if (_originalPrices[e.key] != e.value) return true;
    }
    if (_enabledBaggageRules.values.any((s) => s.isNotEmpty)) return true;
    return false;
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this, initialIndex: 1);
    _initFromFlight();
    _loadBaggage();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _initFromFlight() {
    final prices =
        (widget.flights.first['prices'] as List<dynamic>? ?? [])
            .cast<Map<String, dynamic>>();

    if (prices.isNotEmpty) {
      _hasExistingClasses = true;
      for (final p in prices) {
        final classId = p['classId'] as int;
        _classNames[classId] = p['className'] as String;
        _prices[classId] = (p['price'] as num).toDouble();
        _classSeats[classId] = 0;
        _originalPrices[classId] = (p['price'] as num).toDouble();
      }
    }
  }

  Future<void> _loadBaggage() async {
    try {
      final rules = await widget.service.getBaggageRules();
      if (!mounted) return;
      setState(() {
        _baggageRules = rules
            .where((r) => r['baggageTypeName'] != 'Carry-on baggage')
            .toList();
        _loadingBaggage = false;
        _initBaggageForClasses();
      });
    } catch (e) {
      if (mounted) setState(() => _loadingBaggage = false);
    }
  }

  void _initBaggageForClasses() {
    for (final classId in _classNames.keys) {
      _enabledBaggageRules.putIfAbsent(classId, () => {});
      _baggagePrices.putIfAbsent(classId, () => {});
      for (final rule in _baggageRules) {
        final ruleId = rule['baggagePricingRuleId'] as int;
        _baggagePrices[classId]!.putIfAbsent(ruleId, () => 0.0);
      }
    }
  }

  void _onClassesChanged(
      Map<int, int> classSeats, Map<int, String> classNames) {
    setState(() {
      _classSeats = classSeats;
      _classNames = classNames;

      // Додаємо нові класи в prices
      for (final classId in classNames.keys) {
        _prices.putIfAbsent(classId, () => 0.0);
      }
      // Видаляємо класи яких більше немає
      _prices.removeWhere((k, _) => !classNames.containsKey(k));

      // Оновлюємо багаж
      for (final classId in classNames.keys) {
        _enabledBaggageRules.putIfAbsent(classId, () => {});
        _baggagePrices.putIfAbsent(classId, () => {});
        for (final rule in _baggageRules) {
          final ruleId = rule['baggagePricingRuleId'] as int;
          _baggagePrices[classId]!.putIfAbsent(ruleId, () => 0.0);
        }
      }
      _enabledBaggageRules.removeWhere((k, _) => !classNames.containsKey(k));
      _baggagePrices.removeWhere((k, _) => !classNames.containsKey(k));
    });
  }

  bool get _hasUnpricedBaggage =>
      _enabledBaggageRules.entries.any((entry) => entry.value.any(
          (ruleId) => (_baggagePrices[entry.key]?[ruleId] ?? 0.0) == 0));

  bool get _canSave =>
      _classNames.isNotEmpty &&
      _prices.isNotEmpty &&
      _prices.values.every((p) => p > 0) &&
      !_hasUnpricedBaggage;

  Future<void> _confirm() async {
    setState(() => _saving = true);
    try {
      if (_hasChanges) {
        // Є зміни — зберігаємо і підтверджуємо
        final classPrices = _prices.entries
            .map((e) => {'class_id': e.key, 'price': e.value})
            .toList();

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

        for (final flight in widget.flights) {
          final flightId = flight['flightId'] as int;
          final existingPrices =
              (flight['prices'] as List<dynamic>? ?? [])
                  .cast<Map<String, dynamic>>();

          if (existingPrices.isEmpty) {
            await widget.service.configureFlight(
              flightId: flightId,
              classPrices: classPrices,
            );
          } else {
            await widget.service.updateFlightPrices(
              flightId: flightId,
              classPrices: classPrices,
            );
            final existingClassIds =
                existingPrices.map((p) => p['classId'] as int).toList();
            final newClassIds = _classNames.keys.toList();
            if (existingClassIds.toSet().difference(newClassIds.toSet()).isNotEmpty ||
                newClassIds.toSet().difference(existingClassIds.toSet()).isNotEmpty) {
              await widget.service.updateFlightClasses(
                flightId: flightId,
                classIds: newClassIds,
              );
            }
          }

          if (baggageOptions.isNotEmpty) {
            await widget.service.addBaggageToFlight(
              flightId: flightId,
              options: baggageOptions,
            );
          }
        }
      } else {
        // Немає змін — просто підтверджуємо
        final flightIds =
            widget.flights.map((f) => f['flightId'] as int).toList();
        await widget.service.confirmFlights(flightIds);
      }

      final confirmedIds =
          widget.flights.map((f) => f['flightId'] as int).toList();
      widget.onDone(confirmedIds);
      widget.onClose();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8)),
        ));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  String _fmtDate(String iso) {
    final dt = DateTime.parse(iso);
    return '${dt.day.toString().padLeft(2, '0')}.${dt.month.toString().padLeft(2, '0')}.${dt.year}';
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final first = widget.flights.first;

    return SizedBox(
      width: 960,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildHeader(colors, first),
          ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.65,
            ),
            child: TabBarView(
              controller: _tabController,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _buildClassesTab(colors),
                _buildPricesTab(colors),
                _buildBaggageTab(colors),
              ],
            ),
          ),
          _buildBottomBar(colors),
        ],
      ),
    );
  }

  Widget _buildHeader(ColorScheme colors, Map<String, dynamic> first) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 20, 20, 0),
      decoration: BoxDecoration(
        border: Border(
            bottom: BorderSide(
                color: colors.outline.withValues(alpha: 0.15))),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: colors.primaryContainer.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.tune_outlined,
                    size: 18, color: colors.primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${first['flightNumber']}  ·  '
                      '${first['departsCode']} → ${first['arrivesCode']}',
                      style: const TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w600),
                    ),
                    Text(
                      '${widget.flights.length} flights  ·  '
                      '${_fmtDate(first['departsDatetime'] as String)}'
                      '${widget.flights.length > 1 ? ' – ${_fmtDate(widget.flights.last['departsDatetime'] as String)}' : ''}',
                      style: TextStyle(
                          fontSize: 12, color: colors.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: widget.onClose,
                icon: const Icon(Icons.close, size: 18),
                style: IconButton.styleFrom(
                    foregroundColor: colors.onSurfaceVariant),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TabBar(
            controller: _tabController,
            tabs: [
              Tab(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('Classes'),
                    if (_classNames.isNotEmpty) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 1),
                        decoration: BoxDecoration(
                          color: colors.primaryContainer,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '${_classNames.length}',
                          style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: colors.primary),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const Tab(text: 'Prices'),
              const Tab(text: 'Baggage'),
            ],
            labelStyle: const TextStyle(
                fontSize: 13, fontWeight: FontWeight.w600),
            unselectedLabelStyle: const TextStyle(fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildClassesTab(ColorScheme colors) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Step2SeatMap(
        service: widget.service,
        airfleetId: widget.airfleetId,
        onChanged: (classSeats, classNames, _) {
          _onClassesChanged(classSeats, classNames);
        },
        onClassesConfirmed: (_) {
          _tabController.animateTo(1);
        },
      ),
    );
  }

  static const _palette = [
    Color(0xFF2196F3),
    Color(0xFFFF6B9D),
    Color(0xFF00BCD4),
    Color(0xFFFFD700),
    Color(0xFF4CAF50),
    Color(0xFFFF9800),
  ];

  Color _classColor(int classId) {
    final ids = _classNames.keys.toList()..sort();
    final index = ids.indexOf(classId);
    if (index == -1) return const Color(0xFF9E9E9E);
    return _palette[index % _palette.length];
  }

  Widget _buildPricesTab(ColorScheme colors) {
    if (_classNames.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.airline_seat_recline_normal_outlined,
                size: 40, color: colors.onSurfaceVariant),
            const SizedBox(height: 12),
            Text('Select classes first',
                style: TextStyle(color: colors.onSurfaceVariant)),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => _tabController.animateTo(0),
              child: const Text('Go to Classes'),
            ),
          ],
        ),
      );
    }

    final currentDate =
        '${DateTime.now().day.toString().padLeft(2, '0')}.${DateTime.now().month.toString().padLeft(2, '0')}.${DateTime.now().year}';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Wrap(
        spacing: 16,
        runSpacing: 16,
        children: _prices.entries.map((entry) {
          final classId = entry.key;
          final className = _classNames[classId] ?? 'Class $classId';
          final price = entry.value;
          final color = _classColor(classId);
          final seats = _classSeats[classId] ?? 0;
          final priceDisplay = price > 0 ? price.toStringAsFixed(0) : '0';

          return Container(
            width: 240,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: colors.surfaceContainerHighest.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                  color: colors.outline.withValues(alpha: 0.2)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(className.toUpperCase(),
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: color)),
                const SizedBox(height: 4),
                if (seats > 0)
                  Text('$seats seats available',
                      style: TextStyle(
                          fontSize: 12, color: colors.onSurfaceVariant)),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Text('\$',
                        style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w300,
                            color: colors.onSurface)),
                    const SizedBox(width: 8),
                    Expanded(
                        child: Text('base\nprice',
                            style: TextStyle(
                                fontSize: 11,
                                height: 1.1,
                                color: colors.onSurfaceVariant))),
                    Text(priceDisplay,
                        style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: colors.onSurface)),
                  ],
                ),
                const SizedBox(height: 20),
                CustomInputField(
                  label: 'Ticket price',
                  value: price > 0 ? price.toStringAsFixed(0) : '',
                  icon: Icons.confirmation_number_outlined,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(6),
                  ],
                  onChanged: (val) {
                    setState(() {
                      _prices[classId] = double.tryParse(val) ?? 0.0;
                    });
                  },
                ),
                const SizedBox(height: 12),
                Text('Publ. date: $currentDate',
                    style: TextStyle(
                        fontSize: 11, color: colors.onSurfaceVariant)),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildBaggageTab(ColorScheme colors) {
    if (_classNames.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.luggage_outlined,
                size: 40, color: colors.onSurfaceVariant),
            const SizedBox(height: 12),
            Text('Select classes first',
                style: TextStyle(color: colors.onSurfaceVariant)),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => _tabController.animateTo(0),
              child: const Text('Go to Classes'),
            ),
          ],
        ),
      );
    }

    if (_loadingBaggage) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_baggageRules.isEmpty) {
      return Center(
        child: Text('No baggage rules available',
            style: TextStyle(color: colors.onSurfaceVariant)),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Wrap(
        spacing: 16,
        runSpacing: 16,
        children: _classNames.keys.map((classId) {
          final className = _classNames[classId] ?? 'Class $classId';
          final enabledCount =
              _enabledBaggageRules[classId]?.length ?? 0;

          return Container(
            width: 280,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colors.surfaceContainerHighest.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                  color: colors.outline.withValues(alpha: 0.2)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(className.toUpperCase(),
                          style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: colors.primary,
                              letterSpacing: 0.5)),
                    ),
                    if (enabledCount > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: colors.primaryContainer,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text('$enabledCount active',
                            style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: colors.primary)),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                Divider(
                    color: colors.outline.withValues(alpha: 0.2),
                    height: 1),
                const SizedBox(height: 12),
                ..._baggageRules.map((rule) {
                  final ruleId = rule['baggagePricingRuleId'] as int;
                  final typeName =
                      rule['baggageTypeName'] as String? ?? '';
                  final maxWeight = rule['baggage_max_weight'] as num?;
                  final isEnabled =
                      _enabledBaggageRules[classId]?.contains(ruleId) ??
                          false;
                  final currentPrice =
                      _baggagePrices[classId]?[ruleId] ?? 0.0;

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            SizedBox(
                              width: 28,
                              height: 28,
                              child: Checkbox(
                                value: isEnabled,
                                materialTapTargetSize:
                                    MaterialTapTargetSize.shrinkWrap,
                                onChanged: (val) {
                                  setState(() {
                                    if (val == true) {
                                      _enabledBaggageRules[classId]!
                                          .add(ruleId);
                                    } else {
                                      _enabledBaggageRules[classId]!
                                          .remove(ruleId);
                                      _baggagePrices[classId]![ruleId] =
                                          0.0;
                                    }
                                  });
                                },
                              ),
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Text(typeName,
                                      style: const TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w500)),
                                  if (maxWeight != null)
                                    Text(
                                        '${maxWeight.toStringAsFixed(0)} kg',
                                        style: TextStyle(
                                            fontSize: 11,
                                            color:
                                                colors.onSurfaceVariant)),
                                ],
                              ),
                            ),
                          ],
                        ),
                        if (isEnabled)
                          Padding(
                            padding:
                                const EdgeInsets.only(left: 32, top: 6),
                            child: CustomInputField(
                              label: 'Price (\$)',
                              value: currentPrice > 0
                                  ? currentPrice.toStringAsFixed(0)
                                  : '',
                              icon: Icons.attach_money_outlined,
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                                LengthLimitingTextInputFormatter(5),
                              ],
                              onChanged: (val) {
                                setState(() {
                                  _baggagePrices[classId]![ruleId] =
                                      double.tryParse(val) ?? 0.0;
                                });
                              },
                            ),
                          ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildBottomBar(ColorScheme colors) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 20),
      decoration: BoxDecoration(
        border: Border(
            top: BorderSide(
                color: colors.outline.withValues(alpha: 0.15))),
      ),
      child: Row(
        children: [
          if (_hasUnpricedBaggage)
            Row(
              children: [
                Icon(Icons.warning_outlined, size: 14, color: colors.error),
                const SizedBox(width: 6),
                Text(
                  'All selected baggage options must have a price',
                  style: TextStyle(fontSize: 12, color: colors.error),
                ),
              ],
            )
          else if (_classNames.isEmpty)
            Text('Select classes to continue',
                style: TextStyle(
                    fontSize: 12, color: colors.onSurfaceVariant))
          else if (_prices.values.any((p) => p == 0))
            Text('Set prices for all classes',
                style: TextStyle(
                    fontSize: 12, color: colors.onSurfaceVariant))
          else if (_hasChanges)
            Row(
              children: [
                Icon(Icons.edit_outlined,
                    size: 14, color: colors.primary),
                const SizedBox(width: 6),
                Text('Changes will be saved',
                    style: TextStyle(
                        fontSize: 12, color: colors.primary)),
              ],
            ),
          const Spacer(),
          TextButton(
            onPressed: widget.onClose,
            style: TextButton.styleFrom(
              foregroundColor: colors.onSurfaceVariant,
              padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 10),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6)),
            ),
            child: const Text('Cancel'),
          ),
          const SizedBox(width: 8),
          _saving
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2))
              : CustomButton(
                  label: 'Confirm',
                  icon: Icons.check_circle_outline,
                  isIconAfterLabel: false,
                  onPressed: _canSave ? _confirm : null,
                  verticalPadding: 10,
                  horizontalPadding: 20,
                ),
        ],
      ),
    );
  }
}