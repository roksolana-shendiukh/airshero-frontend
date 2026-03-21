import 'package:flutter/material.dart';
import 'custom/custom_button.dart';

class PassengerSelector extends StatefulWidget {
  final Map<String, int> initialPassengers;
  final ValueChanged<Map<String, int>> onChanged;
  final VoidCallback onClose;

  const PassengerSelector({
    super.key,
    required this.initialPassengers,
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

  @override
  void initState() {
    super.initState();
    adults = widget.initialPassengers['adults'] ?? 1;
    children = widget.initialPassengers['children'] ?? 0;
    infants = widget.initialPassengers['infants'] ?? 0;
  }

  int get totalPassengers => adults + children + infants;

  void _update() {
    widget.onChanged({
      'adults': adults,
      'children': children,
      'infants': infants,
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {},
      child: Container(
        width: 380,
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
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 8, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Passengers',
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
              padding: const EdgeInsets.fromLTRB(20, 2, 20, 12),
              child: Text(
                'Maximum 6 passengers per booking',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
            ),

            const Divider(height: 1),

            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildCounterRow(
                      label: 'Adults',
                      subtitle: '12+ years',
                      count: adults,
                      onIncrement: totalPassengers < 6
                          ? () => setState(() { adults++; _update(); })
                          : null,
                      onDecrement: adults > 1
                          ? () => setState(() { adults--; _update(); })
                          : null,
                    ),
                    const Divider(height: 24),
                    _buildCounterRow(
                      label: 'Children',
                      subtitle: '2–12 years',
                      count: children,
                      onIncrement: totalPassengers < 6
                          ? () => setState(() { children++; _update(); })
                          : null,
                      onDecrement: children > 0
                          ? () => setState(() { children--; _update(); })
                          : null,
                    ),
                    const Divider(height: 24),
                    _buildCounterRow(
                      label: 'Infants',
                      subtitle: '0–2 years',
                      count: infants,
                      onIncrement: totalPassengers < 6
                          ? () => setState(() { infants++; _update(); })
                          : null,
                      onDecrement: infants > 0
                          ? () => setState(() { infants--; _update(); })
                          : null,
                    ),
                    const SizedBox(height: 20),
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
    required String subtitle,
    required int count,
    VoidCallback? onIncrement,
    VoidCallback? onDecrement,
  }) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
              ),
              Text(
                subtitle,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
            ],
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
              width: 32,
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