import 'package:flutter/material.dart';

class SearchResultsHeader extends StatelessWidget {
  final String fromCity;
  final String toCity;
  final DateTime departDate;
  final DateTime? returnDate;
  final int totalPassengers;
  final String flightClass;
  final int flightsCount;
  final VoidCallback onBack;

  const SearchResultsHeader({
    super.key,
    required this.fromCity,
    required this.toCity,
    required this.departDate,
    this.returnDate,
    required this.totalPassengers,
    required this.flightClass,
    required this.flightsCount,
    required this.onBack,
  });

  String _formatDate(DateTime date) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[date.month - 1]} ${date.day}';
  }

  @override
  Widget build(BuildContext context) {
    final isRoundTrip = returnDate != null;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHigh,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: onBack,
            tooltip: 'Back to search',
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$fromCity → $toCity',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${_formatDate(departDate)}${isRoundTrip ? ' - ${_formatDate(returnDate!)}' : ''} • $totalPassengers passenger${totalPassengers > 1 ? 's' : ''} • $flightClass',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '$flightsCount flight${flightsCount != 1 ? 's' : ''}',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}