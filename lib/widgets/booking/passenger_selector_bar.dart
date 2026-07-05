import 'package:flutter/material.dart';

class PassengerSelectorBar extends StatefulWidget {
  final int totalPassengers;
  final int currentPassengerIndex;
  final Set<int> removedPassengerIndices;
  final Map<int, Map<String, dynamic>> passengerData;
  final Map<int, Map<int, int>> passengerBaggageSelections;
  final Map<String, String> passengerClassLabels;
  final Map<String, int> passengers;
  final void Function(int index) onPassengerSelected;
  final void Function(int index) onPassengerRemoved;

  const PassengerSelectorBar({
    super.key,
    required this.totalPassengers,
    required this.currentPassengerIndex,
    required this.removedPassengerIndices,
    required this.passengerData,
    required this.passengerBaggageSelections,
    required this.passengerClassLabels,
    required this.passengers,
    required this.onPassengerSelected,
    required this.onPassengerRemoved,
  });

  @override
  State<PassengerSelectorBar> createState() => _PassengerSelectorBarState();
}

class _PassengerSelectorBarState extends State<PassengerSelectorBar> {
  int? _hoveredPassengerIndex;

  String _getPassengerLabel(int index) {
    final adultsCount = widget.passengers['adults'] ?? 0;
    final childrenCount = widget.passengers['children'] ?? 0;
    if (index < adultsCount) return 'Adult ${index + 1}';
    if (index < adultsCount + childrenCount)
      return 'Child ${index - adultsCount + 1}';
    return 'Infant ${index - adultsCount - childrenCount + 1}';
  }

  String _getPassengerType(int index) {
    final adultsCount = widget.passengers['adults'] ?? 0;
    final childrenCount = widget.passengers['children'] ?? 0;
    if (index < adultsCount) return 'Adult';
    if (index < adultsCount + childrenCount) return 'Child';
    return 'Infant';
  }

  int _getTotalBaggageForPassenger(int passengerIndex) =>
      widget.passengerBaggageSelections[passengerIndex]
          ?.values
          .fold<int>(0, (sum, qty) => sum + qty) ??
      0;

  String _getPassengerDisplayName(int index) {
    final data = widget.passengerData[index];
    if (data == null ||
        data.isEmpty ||
        data['first_name'] == null ||
        data['first_name'].toString().isEmpty) {
      return _getPassengerLabel(index);
    }
    final firstName = data['first_name'].toString();
    bool hasDuplicate = false;
    for (int i = 0; i < widget.totalPassengers; i++) {
      if (i != index) {
        final otherData = widget.passengerData[i];
        if (otherData != null &&
            otherData['first_name']?.toString().toLowerCase() ==
                firstName.toLowerCase()) {
          hasDuplicate = true;
          break;
        }
      }
    }
    if (hasDuplicate &&
        data['last_name'] != null &&
        data['last_name'].toString().isNotEmpty) {
      return '$firstName ${data['last_name']}';
    }
    return firstName;
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 88,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: widget.totalPassengers,
        itemBuilder: (context, index) {
          if (widget.removedPassengerIndices.contains(index)) {
            return const SizedBox.shrink();
          }

          final isSelected = index == widget.currentPassengerIndex;
          final isHovered = _hoveredPassengerIndex == index;
          final baggageCount = _getTotalBaggageForPassenger(index);
          final hasPassengerData =
              widget.passengerData[index]?.isNotEmpty ?? false;

          final label = _getPassengerLabel(index);
          final type = _getPassengerType(index);
          final classLabel = widget.passengerClassLabels[label] ?? '';

          final passengerName = hasPassengerData &&
                  widget.passengerData[index]!['first_name']
                          ?.toString()
                          .isNotEmpty ==
                      true
              ? widget.passengerData[index]!['first_name'].toString()
              : label;

          final subtitleText =
              classLabel.isNotEmpty ? '$type • $classLabel' : type;
          final passengerIcon =
              hasPassengerData ? Icons.person : Icons.person_outline;

          return Padding(
            padding: const EdgeInsets.only(right: 12),
            child: MouseRegion(
              onEnter: (_) =>
                  setState(() => _hoveredPassengerIndex = index),
              onExit: (_) =>
                  setState(() => _hoveredPassengerIndex = null),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  InkWell(
                    onTap: () => widget.onPassengerSelected(index),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 6),
                      constraints: const BoxConstraints(maxHeight: 84),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? Theme.of(context)
                                .colorScheme
                                .primaryContainer
                            : Theme.of(context)
                                .colorScheme
                                .surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected
                              ? Theme.of(context).colorScheme.primary
                              : Colors.transparent,
                          width: 2,
                        ),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            passengerIcon,
                            size: 20,
                            color: isSelected
                                ? Theme.of(context)
                                    .colorScheme
                                    .onPrimaryContainer
                                : Theme.of(context).colorScheme.onSurface,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            passengerName,
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(
                                  fontWeight: isSelected
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                  color: isSelected
                                      ? Theme.of(context)
                                          .colorScheme
                                          .onPrimaryContainer
                                      : Theme.of(context)
                                          .colorScheme
                                          .onSurface,
                                ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            subtitleText,
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(
                                  fontSize: 10,
                                  color: isSelected
                                      ? Theme.of(context)
                                          .colorScheme
                                          .onPrimaryContainer
                                      : Theme.of(context)
                                          .colorScheme
                                          .primary,
                                  fontWeight: FontWeight.w500,
                                ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (baggageCount > 0) ...[
                            const SizedBox(height: 2),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.luggage,
                                    size: 10,
                                    color: Theme.of(context)
                                        .colorScheme
                                        .primary),
                                const SizedBox(width: 2),
                                Text(
                                  '$baggageCount',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(
                                        fontSize: 10,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .primary,
                                        fontWeight: FontWeight.bold,
                                      ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  if (isHovered)
                    Positioned(
                      top: -6,
                      right: 6,
                      child: GestureDetector(
                        onTap: () => widget.onPassengerRemoved(index),
                        child: Container(
                          width: 18,
                          height: 18,
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.error,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.close,
                            size: 12,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}