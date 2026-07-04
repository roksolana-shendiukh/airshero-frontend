import 'package:flutter/material.dart';
import 'flight_card.dart';

class FlightListBody extends StatelessWidget {
  final List<Map<String, dynamic>> flights;
  final bool isLoading;
  final String? error;
  final bool isActioning;
  final void Function() onRetry;
  final void Function(Map<String, dynamic>) onStartBoarding;
  final void Function(Map<String, dynamic>) onJoinBoarding;

  const FlightListBody({
    super.key,
    required this.flights,
    required this.isLoading,
    required this.error,
    required this.isActioning,
    required this.onRetry,
    required this.onStartBoarding,
    required this.onJoinBoarding,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) return const Center(child: CircularProgressIndicator());

    if (error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline_rounded,
                size: 48, color: Theme.of(context).colorScheme.error),
            const SizedBox(height: 12),
            Text(error!,
                style:
                    TextStyle(color: Theme.of(context).colorScheme.error)),
            const SizedBox(height: 16),
            TextButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      );
    }

    if (flights.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.flight_outlined,
                size: 56,
                color: Theme.of(context)
                    .colorScheme
                    .outline
                    .withValues(alpha: 0.3)),
            const SizedBox(height: 12),
            Text('No active flights',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(
              'There are no flights waiting for boarding at your airport',
              style: TextStyle(
                  color:
                      Theme.of(context).colorScheme.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      itemCount: flights.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (_, i) => FlightCard(
        flight: flights[i],
        isActioning: isActioning,
        onStartBoarding: onStartBoarding,
        onJoinBoarding: onJoinBoarding,
      ),
    );
  }
}