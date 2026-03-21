import 'package:flutter/material.dart';

class BulkActionsBar extends StatelessWidget {
  final int selectedCount;
  final VoidCallback onDelete;
  final VoidCallback onLock;

  const BulkActionsBar({
    super.key,
    required this.selectedCount,
    required this.onDelete,
    required this.onLock,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context)
            .colorScheme
            .primaryContainer
            .withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Text(
            '$selectedCount selected',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(width: 16),
          TextButton.icon(
            icon: const Icon(Icons.delete, size: 18),
            label: const Text('Delete'),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            onPressed: onDelete,
          ),
          TextButton.icon(
            icon: const Icon(Icons.lock, size: 18),
            label: const Text('Lock'),
            onPressed: onLock,
          ),
        ],
      ),
    );
  }
}