import 'package:flutter/material.dart';

class AllowanceBanner extends StatelessWidget {
  final Map<String, dynamic>? allowance;
  const AllowanceBanner({super.key, required this.allowance});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final qty    = allowance?['baggageQuantity'] ?? 0;
    final weight = allowance?['baggageMaxWeight'] ?? 0;
    final type   = allowance?['baggageTypeName']  ?? '—';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color:        colors.primaryContainer.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(6),
        border:       Border.all(color: colors.outline.withValues(alpha: 0.15)),
      ),
      child: Row(
        children: [
          Icon(Icons.luggage_outlined, size: 16, color: colors.primary),
          const SizedBox(width: 10),
          Text(
            'Allowance:',
            style: TextStyle(
              fontSize:   12,
              color:      colors.onSurfaceVariant,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              '$qty × $type · max ${weight}kg/bag',
              style: TextStyle(
                fontSize:   13,
                fontWeight: FontWeight.w600,
                color:      colors.onSurface,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class FlightWeightBanner extends StatelessWidget {
  final double flightCheckedWeight;
  final double currentPassengerWeight;
  final double baggageCapacity;

  const FlightWeightBanner({
    super.key,
    required this.flightCheckedWeight,
    required this.currentPassengerWeight,
    required this.baggageCapacity,
  });

  @override
  Widget build(BuildContext context) {
    final colors      = Theme.of(context).colorScheme;
    final total       = flightCheckedWeight + currentPassengerWeight;
    final progress    = baggageCapacity > 0
        ? (total / baggageCapacity).clamp(0.0, 1.0)
        : 0.0;
    final percent     = (progress * 100).toStringAsFixed(1);
    final isNearFull  = progress > 0.85;
    final isFull      = progress >= 1.0;
    final accentColor = isFull
        ? colors.error
        : isNearFull
            ? const Color(0xFFE65100)
            : colors.primary;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color:        colors.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(8),
        border:       Border.all(color: colors.outline.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.flight_outlined, size: 14, color: colors.onSurfaceVariant),
              const SizedBox(width: 6),
              Text(
                'Baggage hold',
                style: TextStyle(
                  fontSize:   12,
                  color:      colors.onSurfaceVariant,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Spacer(),
              Text(
                '$percent%',
                style: TextStyle(
                  fontSize:   13,
                  fontWeight: FontWeight.w700,
                  color:      accentColor,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                '${total.toStringAsFixed(1)} / ${baggageCapacity.toStringAsFixed(0)} kg',
                style: TextStyle(fontSize: 12, color: colors.onSurfaceVariant),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value:           progress,
              minHeight:       6,
              backgroundColor: colors.outline.withValues(alpha: 0.15),
              valueColor:      AlwaysStoppedAnimation<Color>(accentColor),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              WeightChip(
                label:  'Already checked',
                value:  '${flightCheckedWeight.toStringAsFixed(1)} kg',
                colors: colors,
              ),
              const SizedBox(width: 8),
              if (currentPassengerWeight > 0)
                WeightChip(
                  label:  'This passenger',
                  value:  '+${currentPassengerWeight.toStringAsFixed(1)} kg',
                  colors: colors,
                  accent: accentColor,
                ),
              const Spacer(),
              WeightChip(
                label:  'Remaining',
                value:  '${(baggageCapacity - total).clamp(0, baggageCapacity).toStringAsFixed(1)} kg',
                colors: colors,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class WeightChip extends StatelessWidget {
  final String      label;
  final String      value;
  final ColorScheme colors;
  final Color?      accent;

  const WeightChip({
    super.key,
    required this.label,
    required this.value,
    required this.colors,
    this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 10, color: colors.onSurfaceVariant)),
        Text(
          value,
          style: TextStyle(
            fontSize:   12,
            fontWeight: FontWeight.w600,
            color:      accent ?? colors.onSurface,
          ),
        ),
      ],
    );
  }
}

class SurchargeSummary extends StatelessWidget {
  final double amount;
  const SurchargeSummary({super.key, required this.amount});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color:        const Color(0xFFE65100).withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(6),
        border:       Border.all(color: const Color(0xFFE65100).withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Excess baggage surcharge',
            style: TextStyle(
              fontSize:   13,
              color:      colors.onSurface,
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            '\$${amount.toStringAsFixed(2)}',
            style: const TextStyle(
              fontSize:   14,
              fontWeight: FontWeight.w700,
              color:      Color(0xFFE65100),
            ),
          ),
        ],
      ),
    );
  }
}