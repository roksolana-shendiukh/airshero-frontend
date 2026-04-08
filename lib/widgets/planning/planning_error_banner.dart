import 'package:flutter/material.dart';
import '../custom/custom_button.dart';

class PlanningErrorBanner extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const PlanningErrorBanner({
    super.key,
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: Theme.of(context).colorScheme.error),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                  color: Theme.of(context).colorScheme.onErrorContainer),
            ),
          ),
          const SizedBox(width: 8),
          CustomButton(
            label: 'Retry',
            verticalPadding: 10,
            horizontalPadding: 14,
            onPressed: onRetry,
          ),
        ],
      ),
    );
  }
}