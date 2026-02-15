import 'package:flutter/material.dart';
import '../models/baggage_models.dart';

class BaggageOptionCard extends StatefulWidget {
  final BaggagePricingInFlight option;
  final int quantity;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;
  final VoidCallback onCardTap;
  final bool isDisabled;

  const BaggageOptionCard({
    super.key,
    required this.option,
    required this.quantity,
    required this.onIncrement,
    required this.onDecrement,
    required this.onCardTap,
    this.isDisabled = false,
  });

  @override
  State<BaggageOptionCard> createState() => _BaggageOptionCardState();
}

class _BaggageOptionCardState extends State<BaggageOptionCard> {
  bool _isHovered = false;

  IconData _getIconForType(int typeId) {
    switch (typeId) {
      case 1: return Icons.luggage;
      case 2: return Icons.inventory_2_outlined;
      case 3: return Icons.privacy_tip_outlined;
      case 4: return Icons.sports_basketball_outlined;
      case 5: return Icons.category_outlined;
      default: return Icons.shopping_bag_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isSelected = widget.quantity > 0;
    
    return MouseRegion(
      cursor: widget.isDisabled ? SystemMouseCursors.forbidden : SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.isDisabled ? null : widget.onCardTap,
        child: AnimatedScale(
          scale: _isHovered && !widget.isDisabled ? 1.03 : 1.0,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          child: Container(
            width: 200,
            margin: const EdgeInsets.only(right: 12, bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isSelected 
                  ? Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.3)
                  : Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
                width: isSelected ? 2 : 1,
              ),
              boxShadow: _isHovered && !widget.isDisabled
                  ? [
                      BoxShadow(
                        color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : null,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // ICON & TYPE
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        _getIconForType(widget.option.type.id),
                        color: Theme.of(context).colorScheme.primary,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        widget.option.type.name,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 16),
                
                // DIMENSIONS
                Row(
                  children: [
                    Icon(
                      Icons.straighten,
                      size: 16,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        widget.option.rule.dimension,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 8),
                
                // WEIGHT
                Row(
                  children: [
                    Icon(
                      Icons.scale,
                      size: 16,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Max ${widget.option.rule.maxWeight.toStringAsFixed(0)} kg',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 16),
                
                // PRICE
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '\$${widget.option.price.toStringAsFixed(2)}',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'per item',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 16),
                
                // QUANTITY SELECTOR - показується тільки якщо обрано
                if (isSelected)
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          icon: Icon(
                            Icons.remove_circle_outline,
                            color: widget.quantity > 0 && !widget.isDisabled
                                ? Theme.of(context).colorScheme.primary
                                : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3),
                          ),
                          onPressed: widget.quantity > 0 && !widget.isDisabled ? widget.onDecrement : null,
                          iconSize: 24,
                        ),
                        Text(
                          widget.quantity.toString(),
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        IconButton(
                          icon: Icon(
                            Icons.add_circle_outline,
                            color: !widget.isDisabled && widget.quantity < 3
                                ? Theme.of(context).colorScheme.primary
                                : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3),
                          ),
                          onPressed: !widget.isDisabled && widget.quantity < 3 ? widget.onIncrement : null,
                          iconSize: 24,
                        ),
                      ],
                    ),
                  ),
                
                // LIMIT INFO
                if (isSelected) ...[
                  const SizedBox(height: 8),
                  Center(
                    child: Text(
                      '${ widget.quantity}/3 selected',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}