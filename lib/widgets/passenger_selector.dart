import 'package:flutter/material.dart';
import 'custom_button.dart';

class PassengerSelector extends StatefulWidget {
  final Map<String, int> initialPassengers;
  final String initialClass;
  final ValueChanged<Map<String, dynamic>> onChanged;
  final VoidCallback onClose;

  const PassengerSelector({
    super.key,
    required this.initialPassengers,
    required this.initialClass,
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
  late String flightClass;

  @override
  void initState() {
    super.initState();
    adults = widget.initialPassengers['adults'] ?? 1;
    children = widget.initialPassengers['children'] ?? 0;
    infants = widget.initialPassengers['infants'] ?? 0;
    flightClass = widget.initialClass;
  }

  int get totalPassengers => adults + children + infants;

  void _update() {
    widget.onChanged({
      'adults': adults,
      'children': children,
      'infants': infants,
      'class': flightClass,
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {}, // Блокує клік поза контейнером
      child: Container(
        width: 400,
        padding: const EdgeInsets.all(20),
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // HEADER З КНОПКОЮ ЗАКРИТТЯ
            Row(
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
            const SizedBox(height: 8),
            Text(
              'Maximum 6 passengers per booking',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),

            _buildCounterRow(
              label: 'Adults (12+ years)',
              count: adults,
              onIncrement: totalPassengers < 6 ? () => setState(() { adults++; _update(); }) : null,
              onDecrement: adults > 1 ? () => setState(() { adults--; _update(); }) : null,
            ),
            const SizedBox(height: 12),

            _buildCounterRow(
              label: 'Children (2-12 years)',
              count: children,
              onIncrement: totalPassengers < 6 ? () => setState(() { children++; _update(); }) : null,
              onDecrement: children > 0 ? () => setState(() { children--; _update(); }) : null,
            ),
            const SizedBox(height: 12),

            _buildCounterRow(
              label: 'Infants (0-2 years)',
              count: infants,
              onIncrement: totalPassengers < 6 ? () => setState(() { infants++; _update(); }) : null,
              onDecrement: infants > 0 ? () => setState(() { infants--; _update(); }) : null,
            ),

            const SizedBox(height: 20),
            Text(
              'Class',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 12),

            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: ['Economy', 'Premium Economy', 'Business', 'First'].map((cls) {
                final selected = cls == flightClass;
                return ChoiceChip(
                  label: Text(cls),
                  selected: selected,
                  selectedColor: Theme.of(context).colorScheme.primaryContainer,
                  backgroundColor: Theme.of(context).colorScheme.surfaceContainerHigh,
                  labelStyle: TextStyle(
                    color: selected
                        ? Theme.of(context).colorScheme.onPrimaryContainer
                        : Theme.of(context).colorScheme.onSurfaceVariant,
                    fontWeight: selected ? FontWeight.w500 : FontWeight.normal,
                  ),
                  onSelected: (_) => setState(() { flightClass = cls; _update(); }),
                );
              }).toList(),
            ),

            const SizedBox(height: 16),
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
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
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