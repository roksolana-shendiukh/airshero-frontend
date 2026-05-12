import 'package:flutter/material.dart';

class UserTablePagination extends StatelessWidget {
  final int currentPage;
  final int totalPages;
  final int totalUsers;
  final int itemsPerPage;
  final VoidCallback onPrevious;
  final VoidCallback onNext;

  const UserTablePagination({
    super.key,
    required this.currentPage,
    required this.totalPages,
    required this.totalUsers,
    required this.itemsPerPage,
    required this.onPrevious,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    final start = (currentPage - 1) * itemsPerPage + 1;
    final end = (currentPage * itemsPerPage > totalUsers)
        ? totalUsers
        : currentPage * itemsPerPage;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color:
                Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Showing $start-$end of $totalUsers',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left),
                onPressed: currentPage > 1 ? onPrevious : null,
              ),
              Text(
                'Page $currentPage of $totalPages',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right),
                onPressed: currentPage < totalPages ? onNext : null,
              ),
            ],
          ),
        ],
      ),
    );
  }
}