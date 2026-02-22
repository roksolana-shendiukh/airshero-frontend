import 'package:flutter/material.dart';
import 'custom/custom_button.dart';
import '../models/class.dart';

class PassengerSelector extends StatefulWidget {
  final Map<String, int> initialPassengers;
  final Map<int, String> initialPassengerClasses;
  final ValueChanged<Map<String, dynamic>> onChanged;
  final VoidCallback onClose;

  const PassengerSelector({
    super.key,
    required this.initialPassengers,
    required this.initialPassengerClasses,
    required this.onChanged,
    required this.onClose,
  });

  @override
  State<PassengerSelector> createState() => _PassengerSelectorState();
}

class _PassengerSelectorState extends State<PassengerSelector> {
  late int adults;
  late int children;
  late int infants;
  late Map<int, String> passengerClasses;

  static final List<String> _classes =
      Class.values.map((c) => c.label).toList();

  @override
  void initState() {
    super.initState();
    adults = widget.initialPassengers['adults'] ?? 1;
    children = widget.initialPassengers['children'] ?? 0;
    infants = widget.initialPassengers['infants'] ?? 0;
    passengerClasses = Map<int, String>.from(widget.initialPassengerClasses);
    _syncClasses();
  }

  int get totalPassengers => adults + children + infants;

  void _syncClasses() {
    for (int i = 0; i < totalPassengers; i++) {
      passengerClasses[i] ??= Class.economy.label;
    }
    passengerClasses.removeWhere((key, _) => key >= totalPassengers);
  }

  String _getPassengerLabel(int index) {
    if (index < adults) return 'Adult ${index + 1}';
    if (index < adults + children) return 'Child ${index - adults + 1}';
    return 'Infant ${index - adults - children + 1}';
  }

  void _update() {
    widget.onChanged({
      'adults': adults,
      'children': children,
      'infants': infants,
      'passengerClasses': Map<int, String>.from(passengerClasses),
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {},
      child: Container(
        width: 420,
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.5,
        ),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Фіксований заголовок
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 8, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Passengers & Class',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: widget.onClose,
                    iconSize: 20,
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
              child: Text(
                'Maximum 6 passengers per booking',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
            ),

            const Divider(height: 1),

            // Скролований вміст
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Лічильники
                    _buildCounterRow(
                      label: 'Adults (12+ years)',
                      count: adults,
                      onIncrement: totalPassengers < 6
                          ? () => setState(() { adults++; _syncClasses(); _update(); })
                          : null,
                      onDecrement: adults > 1
                          ? () => setState(() { adults--; _syncClasses(); _update(); })
                          : null,
                    ),
                    const SizedBox(height: 12),
                    _buildCounterRow(
                      label: 'Children (2-12 years)',
                      count: children,
                      onIncrement: totalPassengers < 6
                          ? () => setState(() { children++; _syncClasses(); _update(); })
                          : null,
                      onDecrement: children > 0
                          ? () => setState(() { children--; _syncClasses(); _update(); })
                          : null,
                    ),
                    const SizedBox(height: 12),
                    _buildCounterRow(
                      label: 'Infants (0-2 years)',
                      count: infants,
                      onIncrement: totalPassengers < 6
                          ? () => setState(() { infants++; _syncClasses(); _update(); })
                          : null,
                      onDecrement: infants > 0
                          ? () => setState(() { infants--; _syncClasses(); _update(); })
                          : null,
                    ),

                    const SizedBox(height: 20),
                    const Divider(),
                    const SizedBox(height: 12),

                    // Класи для кожного пасажира
                    Text(
                      'Flight class per passenger',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    const SizedBox(height: 12),

                    ...List.generate(totalPassengers, (index) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _getPassengerLabel(index),
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.w500,
                                  ),
                            ),
                            const SizedBox(height: 6),
                            Wrap(
                              spacing: 6,
                              runSpacing: 6,
                              children: _classes.map((cls) {
                                final isSelected = passengerClasses[index] == cls;
                                return ChoiceChip(
                                  label: Text(cls, style: const TextStyle(fontSize: 12)),
                                  selected: isSelected,
                                  selectedColor: Theme.of(context).colorScheme.primaryContainer,
                                  backgroundColor: Theme.of(context).colorScheme.surfaceContainerHigh,
                                  labelStyle: TextStyle(
                                    color: isSelected
                                        ? Theme.of(context).colorScheme.onPrimaryContainer
                                        : Theme.of(context).colorScheme.onSurfaceVariant,
                                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                                  ),
                                  onSelected: (_) => setState(() {
                                    passengerClasses[index] = cls;
                                    _update();
                                  }),
                                );
                              }).toList(),
                            ),
                          ],
                        ),
                      );
                    }),

                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: CustomButton(
                        label: 'Done',
                        onPressed: widget.onClose,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCounterRow({
    required String label,
    required int count,
    VoidCallback? onIncrement,
    VoidCallback? onDecrement,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(label, style: Theme.of(context).textTheme.bodyMedium),
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.remove_circle_outline),
              color: onDecrement != null
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3),
              onPressed: onDecrement,
              splashRadius: 20,
            ),
            SizedBox(
              width: 40,
              child: Center(
                child: Text(
                  count.toString(),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.add_circle_outline),
              color: onIncrement != null
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3),
              onPressed: onIncrement,
              splashRadius: 20,
            ),
          ],
        ),
      ],
    );
  }
}