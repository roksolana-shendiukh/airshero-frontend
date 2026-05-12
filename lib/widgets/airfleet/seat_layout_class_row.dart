import 'package:flutter/material.dart';

class SeatLayoutClassRow extends StatelessWidget {
  final Map<String, dynamic> layout;
  final Color color;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const SeatLayoutClassRow({
    super.key,
    required this.layout,
    required this.color,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final rows = (layout['seatLayoutRows'] as num?)?.toInt() ?? 0;
    final colsRaw = layout['seatLayoutColumns'] as String? ?? '';
    final colParts = colsRaw
        .split(' ')
        .where((s) => s.trim().isNotEmpty)
        .toList();
    final seatsPerRow =
        colParts.fold(0, (s, c) => s + (int.tryParse(c.trim()) ?? 0));
    final total = rows * seatsPerRow;
    final config = colParts.join('+');

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: colors.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 10, height: 10,
                decoration:
                    BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              const SizedBox(width: 8),
              Text(layout['className'] ?? 'Class',
                  style: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w600)),
              const Spacer(),
              IconButton(
                icon: Icon(Icons.edit_outlined,
                    size: 16, color: colors.onSurfaceVariant),
                onPressed: onEdit,
                padding: EdgeInsets.zero,
                constraints:
                    const BoxConstraints(minWidth: 30, minHeight: 30),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline,
                    size: 16, color: Color(0xFFE24B4A)),
                onPressed: onDelete,
                padding: EdgeInsets.zero,
                constraints:
                    const BoxConstraints(minWidth: 30, minHeight: 30),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Stats
          Row(
            children: [
              _stat(Icons.table_rows_outlined, '$rows rows', colors),
              const SizedBox(width: 8),
              _stat(Icons.view_column_outlined, config, colors),
              const SizedBox(width: 8),
              _stat(Icons.airline_seat_recline_normal_outlined,
                  '$total seats', colors),
            ],
          ),
          // Seat map preview
          if (rows > 0 && colParts.isNotEmpty) ...[
            const SizedBox(height: 12),
            _SeatPreview(
                rows: rows, colParts: colParts, color: color),
          ],
        ],
      ),
    );
  }

  Widget _stat(IconData icon, String text, ColorScheme colors) =>
      Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: colors.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
              color: colors.outlineVariant.withValues(alpha: 0.5)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 12, color: colors.onSurfaceVariant),
            const SizedBox(width: 4),
            Text(text,
                style: TextStyle(
                    fontSize: 11, color: colors.onSurfaceVariant)),
          ],
        ),
      );
}

class _SeatPreview extends StatelessWidget {
  final int rows;
  final List<String> colParts;
  final Color color;

  const _SeatPreview({
    required this.rows,
    required this.colParts,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final previewRows = rows.clamp(0, 4);

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ...List.generate(previewRows, (r) => Padding(
            padding: const EdgeInsets.only(bottom: 3),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('${r + 1}',
                    style: TextStyle(
                        fontSize: 9,
                        color: Theme.of(context)
                            .colorScheme
                            .onSurfaceVariant),
                    textAlign: TextAlign.right),
                const SizedBox(width: 6),
                ...colParts.asMap().entries.expand((entry) {
                  final i = entry.key;
                  final count = int.tryParse(entry.value.trim()) ?? 0;
                  return [
                    if (i > 0) const SizedBox(width: 6),
                    ...List.generate(
                      count,
                      (_) => Container(
                        width: 14,
                        height: 14,
                        margin: const EdgeInsets.only(right: 2),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.7),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                  ];
                }),
              ],
            ),
          )),
          if (rows > 4)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                '+ ${rows - 4} more rows',
                style: TextStyle(
                    fontSize: 10,
                    color: Theme.of(context)
                        .colorScheme
                        .onSurfaceVariant),
              ),
            ),
        ],
      ),
    );
  }
}