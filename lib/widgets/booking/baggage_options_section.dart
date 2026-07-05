import 'package:flutter/material.dart';
import '../../models/baggage_model.dart';
import 'baggage_option_card.dart';
import 'segment_label.dart';

class BaggageOptionsSection extends StatelessWidget {
  final List<BaggagePricingInFlight> baggageOptions;
  final List<BaggagePricingInFlight> leg2BaggageOptions;
  final bool isLoading;
  final String? error;
  final bool isMultiSegment;
  final int currentPassengerIndex;
  final Map<int, Map<int, int>> passengerBaggageSelections;
  final Map<int, Map<int, int>> passengerLeg2BaggageSelections;
  final String? fromCity;
  final String? toCity;
  final String? leg2FromCity;
  final String? leg2ToCity;
  final void Function() onRetry;
  final void Function(int optionId, int qty, bool isLeg2) onQuantityChanged;

  const BaggageOptionsSection({
    super.key,
    required this.baggageOptions,
    required this.leg2BaggageOptions,
    required this.isLoading,
    required this.error,
    required this.isMultiSegment,
    required this.currentPassengerIndex,
    required this.passengerBaggageSelections,
    required this.passengerLeg2BaggageSelections,
    required this.onRetry,
    required this.onQuantityChanged,
    this.fromCity,
    this.toCity,
    this.leg2FromCity,
    this.leg2ToCity,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 32),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (error != null) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          children: [
            Text(error!,
                style: TextStyle(
                    color: Theme.of(context).colorScheme.error)),
            const SizedBox(height: 8),
            TextButton(
                onPressed: onRetry, child: const Text('Try again')),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isMultiSegment) ...[
            SegmentLabel(label: 'LEG 1  $fromCity → $toCity'),
            const SizedBox(height: 12),
          ],
          if (baggageOptions.isEmpty)
            Text(
              'No baggage options available.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            )
          else
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: baggageOptions.map((option) {
                final qty = passengerBaggageSelections[currentPassengerIndex]
                        ?[option.baggagePricingInFlightId] ??
                    0;
                return BaggageOptionCard(
                  option: option,
                  quantity: qty,
                  isDisabled: false,
                  onCardTap: () {
                    if (qty > 0) return;
                    onQuantityChanged(
                        option.baggagePricingInFlightId, 1, false);
                  },
                  onIncrement: () {
                    if (qty > 0 && qty < 3) {
                      onQuantityChanged(
                          option.baggagePricingInFlightId, qty + 1, false);
                    }
                  },
                  onDecrement: () {
                    if (qty > 0) {
                      onQuantityChanged(
                          option.baggagePricingInFlightId, qty - 1, false);
                    }
                  },
                );
              }).toList(),
            ),

          if (isMultiSegment) ...[
            const SizedBox(height: 24),
            SegmentLabel(label: 'LEG 2  $leg2FromCity → $leg2ToCity'),
            const SizedBox(height: 12),
            if (leg2BaggageOptions.isEmpty)
              Text(
                'No baggage options available.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color:
                          Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              )
            else
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: leg2BaggageOptions.map((option) {
                  final qty = passengerLeg2BaggageSelections[
                              currentPassengerIndex]
                          ?[option.baggagePricingInFlightId] ??
                      0;
                  return BaggageOptionCard(
                    option: option,
                    quantity: qty,
                    isDisabled: false,
                    onCardTap: () {
                      if (qty > 0) return;
                      onQuantityChanged(
                          option.baggagePricingInFlightId, 1, true);
                    },
                    onIncrement: () {
                      if (qty > 0 && qty < 3) {
                        onQuantityChanged(
                            option.baggagePricingInFlightId, qty + 1, true);
                      }
                    },
                    onDecrement: () {
                      if (qty > 0) {
                        onQuantityChanged(
                            option.baggagePricingInFlightId, qty - 1, true);
                      }
                    },
                  );
                }).toList(),
              ),
          ],
        ],
      ),
    );
  }
}