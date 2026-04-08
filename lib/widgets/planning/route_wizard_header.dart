import 'package:flutter/material.dart';

class RouteWizardHeader extends StatelessWidget {
  final String currentStep;
  final VoidCallback? onBack;

  static const _steps = [
    ('routeInfo', 'Route info'),
    ('schedule', 'Schedule'),
    ('confirm', 'Confirm'),
  ];

  const RouteWizardHeader({
    super.key,
    required this.currentStep,
    this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final currentIndex =
        _steps.indexWhere((s) => s.$1 == currentStep);

    return Container(
      padding: const EdgeInsets.fromLTRB(8, 16, 16, 16),
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border(
          bottom: BorderSide(
            color: colors.outline.withValues(alpha: 0.15),
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back, size: 20),
                onPressed: onBack,
                tooltip: currentIndex == 0 ? 'Cancel' : 'Back',
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'New route',
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      'Step ${currentIndex + 1} of ${_steps.length}',
                      style: textTheme.bodySmall?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _steps.asMap().entries.map((entry) {
              final index = entry.key;
              final step = entry.value;
              final isCurrent = index == currentIndex;
              final isDone = index < currentIndex;

              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: isCurrent
                          ? colors.primaryContainer
                          : colors.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isCurrent
                            ? colors.primary
                            : colors.outline.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (isDone) ...[
                          Icon(Icons.check_circle,
                              size: 16, color: colors.primary),
                          const SizedBox(width: 4),
                        ],
                        Text(
                          step.$2,
                          style: textTheme.bodySmall?.copyWith(
                            fontWeight: isCurrent
                                ? FontWeight.bold
                                : FontWeight.normal,
                            color: isCurrent
                                ? colors.onPrimaryContainer
                                : isDone
                                    ? colors.onSurface
                                    : colors.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (index < _steps.length - 1)
                    Icon(
                      Icons.arrow_forward_ios,
                      size: 12,
                      color: colors.onSurfaceVariant,
                    ),
                ],
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}