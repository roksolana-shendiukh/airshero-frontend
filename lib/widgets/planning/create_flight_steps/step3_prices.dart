import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../widgets/custom/custom_input_field.dart';
import '../../../services/planning_service.dart';

class Step3Prices extends StatefulWidget {
  final Map<int, int> classSeats;
  final Map<int, String> classNames;

  final Map<int, double> initialTicketPrices;
  final Map<int, Map<int, double>> initialBaggagePrices;

  final ValueChanged<Map<int, double>> onTicketPricesChanged;
  final ValueChanged<Map<int, Map<int, double>>> onBaggagePricesChanged;
  final ValueChanged<Map<int, Set<int>>> onBaggageEnabledChanged;

  final PlanningService planningService;

  const Step3Prices({
    super.key,
    required this.classSeats,
    required this.classNames,
    required this.initialTicketPrices,
    required this.initialBaggagePrices,
    required this.onTicketPricesChanged,
    required this.onBaggagePricesChanged,
    required this.onBaggageEnabledChanged,
    required this.planningService,
  });

  @override
  State<Step3Prices> createState() => _Step3PricesState();
}

class _Step3PricesState extends State<Step3Prices> {
  final Map<int, double> _currentTicketPrices = {};
  final Map<int, Map<int, double>> _currentBaggagePrices = {};

  final Map<int, Set<int>> _enabledBaggageRules = {};

  // Правила багажу завантажені з API
  List<Map<String, dynamic>> _baggageRules = [];
  bool _isLoadingRules = true;
  String? _rulesError;

  int _activeTabIndex = 0;

  static const _palette = [
    Color(0xFF2196F3),
    Color(0xFFFF6B9D),
    Color(0xFF00BCD4),
    Color(0xFFFFD700),
    Color(0xFF4CAF50),
    Color(0xFFFF9800),
  ];

  @override
  void initState() {
    super.initState();
    _currentTicketPrices.addAll(widget.initialTicketPrices);

    for (final classId in widget.classSeats.keys) {
      _currentBaggagePrices[classId] = {};
      _enabledBaggageRules[classId] = {};

      final initialForClass = widget.initialBaggagePrices[classId] ?? {};
      _currentBaggagePrices[classId]!.addAll(initialForClass);
    }

    _loadBaggageRules();
  }

  Future<void> _loadBaggageRules() async {
    try {
      setState(() {
        _isLoadingRules = true;
        _rulesError = null;
      });

      final rules = await widget.planningService.getBaggageRules();

      setState(() {
        _baggageRules = rules;
        _isLoadingRules = false;

        for (final classId in widget.classSeats.keys) {
          for (final rule in rules) {
            final ruleId = rule['baggagePricingRuleId'] as int;
            _currentBaggagePrices[classId]!.putIfAbsent(ruleId, () => 0.0);

            final initialPrice =
                widget.initialBaggagePrices[classId]?[ruleId] ?? 0.0;
            if (initialPrice > 0) {
              _enabledBaggageRules[classId]!.add(ruleId);
            }
          }
        }
      });
    } catch (e) {
      setState(() {
        _isLoadingRules = false;
        _rulesError = e.toString();
      });
    }
  }

  void _notifyTickets() {
    final validPrices = <int, double>{};
    for (final entry in _currentTicketPrices.entries) {
      if (entry.value > 0) validPrices[entry.key] = entry.value;
    }
    widget.onTicketPricesChanged(validPrices);
  }

  void _notifyBaggage() {
    widget.onBaggagePricesChanged(_currentBaggagePrices);
  }

  void _notifyEnabled() {
    widget.onBaggageEnabledChanged(_enabledBaggageRules);
  }

  
  Color _classColor(int classId) {
    final ids = widget.classSeats.keys.toList()..sort();
    final index = ids.indexOf(classId);
    if (index == -1) return const Color(0xFF9E9E9E);
    return _palette[index % _palette.length];
  }

  String get _currentDateString {
    final now = DateTime.now();
    return '${now.day.toString().padLeft(2, '0')}'
        '.${now.month.toString().padLeft(2, '0')}'
        '.${now.year}';
  }

  int _enabledCountForClass(int classId) =>
      _enabledBaggageRules[classId]?.length ?? 0;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.payments_outlined, color: colors.primary, size: 24),
            const SizedBox(width: 8),
            Text(
              'Step 3: Set Prices',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.w600),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'Define base ticket prices and baggage tariffs for each enabled class.',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 24),

        Container(
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                  color: colors.outline.withValues(alpha: 0.2), width: 1),
            ),
          ),
          child: Row(
            children: [
              _buildTabButton('Ticket Tariffs', 0, colors),
              const SizedBox(width: 24),
              _buildTabButton('Baggage Tariffs', 1, colors),
            ],
          ),
        ),
        const SizedBox(height: 24),

        if (_activeTabIndex == 0) _buildTicketPricesTab(colors),
        if (_activeTabIndex == 1) _buildBaggagePricesTab(colors),
      ],
    );
  }

  Widget _buildTabButton(String title, int index, ColorScheme colors) {
    final isActive = _activeTabIndex == index;

    final totalEnabled = index == 1
        ? _enabledBaggageRules.values
            .fold<int>(0, (sum, set) => sum + set.length)
        : 0;

    return GestureDetector(
      onTap: () => setState(() => _activeTabIndex = index),
      child: Container(
        padding: const EdgeInsets.only(bottom: 12, left: 4, right: 4),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: isActive ? colors.primary : Colors.transparent,
              width: 2,
            ),
          ),
        ),
        child: Row(
          children: [
            Text(
              title,
              style: TextStyle(
                color: isActive ? colors.primary : colors.onSurfaceVariant,
                fontWeight:
                    isActive ? FontWeight.w600 : FontWeight.normal,
                fontSize: 14,
              ),
            ),
            if (index == 1 && totalEnabled > 0) ...[
              const SizedBox(width: 6),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                decoration: BoxDecoration(
                  color: colors.primaryContainer,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$totalEnabled',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: colors.onPrimaryContainer,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTicketPricesTab(ColorScheme colors) {
    return Wrap(
      spacing: 16,
      runSpacing: 16,
      children: widget.classSeats.entries.map((entry) {
        final classId = entry.key;
        final name = widget.classNames[classId] ?? 'Class $classId';
        final color = _classColor(classId);
        final currentVal = _currentTicketPrices[classId] ?? 0.0;
        final priceDisplay =
            currentVal > 0 ? currentVal.toStringAsFixed(0) : '0';

        return Container(
          width: 240,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: colors.surfaceContainerHighest.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(16),
            border:
                Border.all(color: colors.outline.withValues(alpha: 0.2)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(name.toUpperCase(),
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: color)),
              const SizedBox(height: 8),
              Text('${entry.value} seats available',
                  style: TextStyle(
                      fontSize: 12, color: colors.onSurfaceVariant)),
              const SizedBox(height: 24),

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
              const SizedBox(height: 24),

              CustomInputField(
                label: 'Ticket Price',
                value:
                    _currentTicketPrices[classId]?.toStringAsFixed(0) ??
                        '',
                icon: Icons.confirmation_number_outlined,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(6),
                ],
                onChanged: (val) {
                  final parsed = double.tryParse(val);
                  setState(() {
                    if (parsed != null && parsed > 0) {
                      _currentTicketPrices[classId] = parsed;
                    } else {
                      _currentTicketPrices.remove(classId);
                    }
                  });
                  _notifyTickets();
                },
              ),
              const SizedBox(height: 16),
              Text('Publ. date: $_currentDateString',
                  style: TextStyle(
                      fontSize: 11, color: colors.onSurfaceVariant)),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildBaggagePricesTab(ColorScheme colors) {
    if (_isLoadingRules) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(40),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_rulesError != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Icon(Icons.error_outline,
                  color: colors.error, size: 40),
              const SizedBox(height: 12),
              Text('Failed to load baggage rules',
                  style: TextStyle(
                      color: colors.error, fontWeight: FontWeight.w600)),
              const SizedBox(height: 4),
              Text(_rulesError!,
                  style: TextStyle(
                      fontSize: 12, color: colors.onSurfaceVariant)),
              const SizedBox(height: 16),
              FilledButton.tonal(
                onPressed: _loadBaggageRules,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    // Немає правил
    if (_baggageRules.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Column(
            children: [
              Icon(Icons.luggage_outlined,
                  size: 40, color: colors.onSurfaceVariant),
              const SizedBox(height: 12),
              Text('No baggage rules available',
                  style:
                      TextStyle(color: colors.onSurfaceVariant)),
            ],
          ),
        ),
      );
    }

    return Wrap(
      spacing: 16,
      runSpacing: 16,
      children: widget.classSeats.keys.map((classId) {
        final name = widget.classNames[classId] ?? 'Class $classId';
        final color = _classColor(classId);
        final enabledCount = _enabledCountForClass(classId);

        return Container(
          width: 300,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: colors.surfaceContainerHighest.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(16),
            border:
                Border.all(color: colors.outline.withValues(alpha: 0.2)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(name.toUpperCase(),
                            style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: color)),
                        const SizedBox(height: 2),
                        Text('Select available baggage options',
                            style: TextStyle(
                                fontSize: 11,
                                color: colors.onSurfaceVariant)),
                      ],
                    ),
                  ),
                  if (enabledCount > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '$enabledCount active',
                        style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: color),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Divider(
                  color: colors.outline.withValues(alpha: 0.2), height: 1),
              const SizedBox(height: 12),

              ..._baggageRules.map(
                  (rule) => _buildBaggageRuleRow(classId, rule, colors)),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildBaggageRuleRow(
      int classId, Map<String, dynamic> rule, ColorScheme colors) {
    final ruleId = rule['baggagePricingRuleId'] as int;
    final typeName = rule['baggageTypeName'] as String? ?? 'Baggage';
    final dimensions = rule['dimensions'] as String?;
    final maxWeight = rule['maxWeightKg'] as double?;
    final overweightFee = rule['overweightFeePerKg'] as double?;

    final isEnabled = _enabledBaggageRules[classId]?.contains(ruleId) ?? false;
    final currentPrice = _currentBaggagePrices[classId]?[ruleId] ?? 0.0;

    final weightLabel = maxWeight != null
        ? '${maxWeight.toStringAsFixed(0)} kg'
        : '';
    final fieldLabel = [typeName, weightLabel]
        .where((s) => s.isNotEmpty)
        .join(' · ');

    return AnimatedOpacity(
      duration: const Duration(milliseconds: 200),
      opacity: isEnabled ? 1.0 : 0.5,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(
                  width: 32,
                  height: 32,
                  child: Checkbox(
                    value: isEnabled,
                    materialTapTargetSize:
                        MaterialTapTargetSize.shrinkWrap,
                    onChanged: (val) {
                      setState(() {
                        if (val == true) {
                          _enabledBaggageRules[classId]!.add(ruleId);
                        } else {
                          _enabledBaggageRules[classId]!.remove(ruleId);
                          _currentBaggagePrices[classId]![ruleId] = 0.0;
                        }
                      });
                      _notifyBaggage();
                      _notifyEnabled();
                    },
                  ),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        typeName,
                        style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: colors.onSurface),
                      ),
                      if (dimensions != null || maxWeight != null)
                        Text(
                          [
                            if (maxWeight != null) '${maxWeight.toStringAsFixed(0)} kg',
                            if (dimensions != null) dimensions,
                          ].join(' · '),
                          style: TextStyle(
                              fontSize: 11,
                              color: colors.onSurfaceVariant),
                        ),
                    ],
                  ),
                ),
              ],
            ),

            AnimatedSize(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeInOut,
              child: isEnabled
                  ? Padding(
                      padding: const EdgeInsets.only(left: 36, top: 6),
                      child: Row(
                        children: [
                          Expanded(
                            child: CustomInputField(
                              label: fieldLabel,
                              hint: overweightFee != null
                                  ? 'Overweight: \$${overweightFee.toStringAsFixed(0)}/kg'
                                  : 'Enter price',
                              value: currentPrice > 0
                                  ? currentPrice.toStringAsFixed(0)
                                  : '',
                              icon: Icons.luggage_outlined,
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                                LengthLimitingTextInputFormatter(5),
                              ],
                              onChanged: (val) {
                                final parsed = double.tryParse(val);
                                setState(() {
                                  _currentBaggagePrices[classId]![ruleId] =
                                      parsed ?? 0.0;
                                });
                                _notifyBaggage();
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Позначка "free" якщо ціна = 0
                          if (currentPrice == 0.0)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.green.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text(
                                'Free',
                                style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.green),
                              ),
                            ),
                        ],
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }
}