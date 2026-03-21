import 'package:flutter/material.dart';
import '../../models/gate_model.dart';

class GateStep extends StatelessWidget {
  final List<GateModel> gates;
  final GateModel? selected;
  final bool isLoading;
  final ValueChanged<GateModel?> onChanged;

  const GateStep({
    super.key,
    required this.gates,
    required this.selected,
    required this.isLoading,
    required this.onChanged,
  });

  Map<String, List<GateModel>> get _grouped {
    final map = <String, List<GateModel>>{};
    for (final g in gates) {
      final key = g.terminalCode ?? '?';
      map.putIfAbsent(key, () => []).add(g);
    }
    return map;
  }

  Color _terminalTypeColor(String? type, ColorScheme colors) {
    switch (type) {
      case 'Domestic':                 return Colors.green;
      case 'International':            return Colors.blue;
      case 'International Short-Haul': return Colors.blue;
      case 'International Long-Haul':  return Colors.orange;
      default:                         return colors.onSurfaceVariant;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    if (isLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 40),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (gates.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.door_sliding_outlined,
                  size: 36,
                  color: colors.onSurfaceVariant.withValues(alpha: 0.4)),
              const SizedBox(height: 8),
              Text('No gates available for this route',
                  style: TextStyle(color: colors.onSurfaceVariant)),
            ],
          ),
        ),
      );
    }

    final grouped = _grouped;

    return ConstrainedBox(
      constraints: const BoxConstraints(maxHeight: 360),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: grouped.entries.map((entry) {
            final terminalCode = entry.key;
            final terminalGates = entry.value;
            final terminalType = terminalGates.first.terminalType;
            final typeColor = _terminalTypeColor(terminalType, colors);

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(bottom: 10, top: 4),
                  child: Row(
                    children: [
                      Text(
                        'Terminal $terminalCode',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (terminalType != null)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: typeColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                                color: typeColor.withValues(alpha: 0.3)),
                          ),
                          child: Text(
                            terminalType,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                              color: typeColor,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),

                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: terminalGates.map((gate) {
                    final isSelected  = selected?.gateId == gate.gateId;
                    final isAvailable = gate.isAvailable;

                    return GestureDetector(
                      onTap: isAvailable
                          ? () => onChanged(isSelected ? null : gate)
                          : null,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        width: 72,
                        height: 56,
                        decoration: BoxDecoration(
                          color: !isAvailable
                              ? colors.surfaceContainerHighest
                                  .withValues(alpha: 0.5)
                              : isSelected
                                  ? colors.primaryContainer
                                      .withValues(alpha: 0.35)
                                  : colors.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: !isAvailable
                                ? colors.outlineVariant
                                    .withValues(alpha: 0.4)
                                : isSelected
                                    ? colors.primary
                                    : colors.outlineVariant,
                            width: isSelected ? 1.5 : 1,
                          ),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (!isAvailable)
                              Icon(Icons.lock_outline,
                                  size: 14,
                                  color: colors.onSurfaceVariant
                                      .withValues(alpha: 0.4)),
                            Text(
                              gate.gateCode,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: !isAvailable
                                    ? colors.onSurfaceVariant
                                        .withValues(alpha: 0.4)
                                    : isSelected
                                        ? colors.primary
                                        : colors.onSurface,
                              ),
                            ),
                            Text(
                              isAvailable ? 'Gate' : 'Busy',
                              style: TextStyle(
                                fontSize: 10,
                                color: !isAvailable
                                    ? colors.onSurfaceVariant
                                        .withValues(alpha: 0.4)
                                    : isSelected
                                        ? colors.primary.withValues(alpha: 0.7)
                                        : colors.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),

                const SizedBox(height: 16),
                Divider(color: colors.outlineVariant, height: 1),
                const SizedBox(height: 16),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }
}