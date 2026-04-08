import 'package:flutter/material.dart';

Future<void> showMonthPicker({
  required BuildContext context,
  required DateTime selectedDate,
  required List<String> availableMonths,
  required void Function(DateTime) onMonthSelected,
}) async {
  int tempYear = selectedDate.year;

  await showDialog(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setModalState) {
        final colors = Theme.of(context).colorScheme;

        bool isMonthAvailable(int year, int month) {
          final key = '$year-${month.toString().padLeft(2, '0')}';
          return availableMonths.isEmpty || availableMonths.contains(key);
        }

        return Dialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 320),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Text('Select month',
                          style: Theme.of(context).textTheme.titleMedium),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.close, size: 20),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.chevron_left),
                        onPressed: () => setModalState(() => tempYear--),
                      ),
                      Text(
                        '$tempYear',
                        style: Theme.of(context)
                            .textTheme
                            .titleSmall
                            ?.copyWith(fontWeight: FontWeight.w500),
                      ),
                      IconButton(
                        icon: const Icon(Icons.chevron_right),
                        onPressed: () => setModalState(() => tempYear++),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 3,
                    childAspectRatio: 2.2,
                    mainAxisSpacing: 8,
                    crossAxisSpacing: 8,
                    children: List.generate(12, (i) {
                      final m = i + 1;
                      final isSelected = m == selectedDate.month &&
                          tempYear == selectedDate.year;
                      final isAvail = isMonthAvailable(tempYear, m);

                      return GestureDetector(
                        onTap: isAvail
                            ? () {
                                Navigator.of(context).pop();
                                onMonthSelected(DateTime(tempYear, m));
                              }
                            : null,
                        child: Container(
                          decoration: BoxDecoration(
                            color: isSelected
                                ? colors.primary
                                : colors.surfaceContainerHighest
                                    .withValues(alpha: 0.5),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Center(
                            child: Text(
                              _shortMonth(m),
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: isSelected
                                    ? FontWeight.w600
                                    : FontWeight.normal,
                                color: isSelected
                                    ? colors.onPrimary
                                    : isAvail
                                        ? colors.onSurface
                                        : colors.onSurfaceVariant
                                            .withValues(alpha: 0.4),
                                decoration: !isAvail
                                    ? TextDecoration.lineThrough
                                    : null,
                                decorationColor: colors.onSurfaceVariant
                                    .withValues(alpha: 0.4),
                              ),
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    ),
  );
}

String _shortMonth(int m) => const [
      '',
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ][m];