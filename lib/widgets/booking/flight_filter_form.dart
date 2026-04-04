import 'package:flutter/material.dart';
import '../../models/class.dart';
import '../../models/flight_filter_state.dart';

class FlightFilterForm extends StatefulWidget {
  final FlightFilterState filterState;
  final Map<String, int> passengers;
  final bool isRoundTrip;
  final ValueChanged<FlightFilterState> onChanged;
  final bool isMultiSegment;

  const FlightFilterForm({
    super.key,
    required this.filterState,
    required this.passengers,
    required this.isRoundTrip,
    required this.onChanged,
    this.isMultiSegment = false,
  });

  @override
  State<FlightFilterForm> createState() => _FlightFilterFormState();
}

class _FlightFilterFormState extends State<FlightFilterForm>
    with SingleTickerProviderStateMixin {
  late TabController _classTabController;

  @override
  void initState() {
    super.initState();
    _classTabController = TabController(
      length: (widget.isRoundTrip || widget.isMultiSegment) ? 2 : 1,
      vsync: this,
    );
  }

  @override
  void dispose() {
    _classTabController.dispose();
    super.dispose();
  }

  int get _total => widget.passengers.values.reduce((a, b) => a + b);
  int get _adults => widget.passengers['adults'] ?? 0;
  int get _children => widget.passengers['children'] ?? 0;

  String _passengerLabel(int i) {
    if (i < _adults) return 'Adult ${i + 1}';
    if (i < _adults + _children) return 'Child ${i - _adults + 1}';
    return 'Infant ${i - _adults - _children + 1}';
  }

  FlightFilterState _reset() => FlightFilterState(
        passengerClasses: {
          for (final e in widget.filterState.passengerClasses.entries)
            e.key: Class.any
        },
        returnPassengerClasses: {
          for (final e in widget.filterState.returnPassengerClasses.entries)
            e.key: Class.any
        },
        minPrice: widget.filterState.minPrice,
        maxPrice: widget.filterState.maxPrice,
        selectedMinPrice: widget.filterState.minPrice,
        selectedMaxPrice: widget.filterState.maxPrice,
        selectedAirlines: {},
        availableAirlines: widget.filterState.availableAirlines,
        minDurationMinutes: widget.filterState.minDurationMinutes,
        maxDurationMinutes: widget.filterState.maxDurationMinutes,
        selectedMinDuration: widget.filterState.minDurationMinutes,
        selectedMaxDuration: widget.filterState.maxDurationMinutes,
        departureSlots: {},
        returnSlots: {},
        availableOutboundClasses: widget.filterState.availableOutboundClasses,
        availableReturnClasses: widget.filterState.availableReturnClasses,
        availableDepartureSlots: widget.filterState.availableDepartureSlots,
        availableReturnSlots: widget.filterState.availableReturnSlots,
        sortOrder: SortOrder.priceAsc,
      );

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final hasActive = !widget.filterState.isDefault;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Text('Filters',
                    style: tt.titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold)),
                if (hasActive) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: cs.primary,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text('Active',
                        style: tt.labelSmall
                            ?.copyWith(color: cs.onPrimary)),
                  ),
                ],
              ],
            ),
            TextButton(
              onPressed: hasActive ? () => widget.onChanged(_reset()) : null,
              child: const Text('Reset all'),
            ),
          ],
        ),

        const Divider(),

        _SectionTitle('Sort by'),
        const SizedBox(height: 8),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: SortOrder.values.map((order) {
            final selected = widget.filterState.sortOrder == order;
            return _Chip(
              label: order.label,
              icon: order.icon,
              selected: selected,
              onTap: () => widget.onChanged(
                  widget.filterState.copyWith(sortOrder: order)),
            );
          }).toList(),
        ),

        const Divider(),

        _SectionTitle('Flight class'),
        const SizedBox(height: 8),

        if (widget.isRoundTrip || widget.isMultiSegment) ...[
          TabBar(
            controller: _classTabController,
            tabs: [
              Tab(text: widget.isMultiSegment ? 'Leg 1' : 'Outbound'),
              Tab(text: widget.isMultiSegment ? 'Leg 2' : 'Return'),
            ],
          ),

          const SizedBox(height: 12),
          AnimatedBuilder(
            animation: _classTabController,
            builder: (context, _) {
              final isReturn = _classTabController.index == 1;
              final classes = isReturn
                  ? widget.filterState.returnPassengerClasses
                  : widget.filterState.passengerClasses;
              final availableClasses = isReturn
                  ? widget.filterState.availableReturnClasses
                  : widget.filterState.availableOutboundClasses;
              return _buildClassChips(
                classes: classes,
                isReturn: isReturn,
                availableClasses: availableClasses,
                cs: cs,
                tt: tt,
              );
            },
          ),
        ] else
          _buildClassChips(
            classes: widget.filterState.passengerClasses,
            isReturn: false,
            availableClasses: widget.filterState.availableOutboundClasses,
            cs: cs,
            tt: tt,
          ),

        const Divider(),

        _SectionTitle('Price range'),
        const SizedBox(height: 4),
        if (widget.filterState.minPrice == widget.filterState.maxPrice)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(
              'All flights: \$${widget.filterState.minPrice.toStringAsFixed(0)}',
              style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
            ),
          )
        else ...[
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '\$${widget.filterState.selectedMinPrice.toStringAsFixed(0)}',
                style: tt.bodySmall?.copyWith(
                    color: cs.primary, fontWeight: FontWeight.w600),
              ),
              Text(
                '\$${widget.filterState.selectedMaxPrice.toStringAsFixed(0)}',
                style: tt.bodySmall?.copyWith(
                    color: cs.primary, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          RangeSlider(
            min: widget.filterState.minPrice,
            max: widget.filterState.maxPrice,
            values: RangeValues(widget.filterState.selectedMinPrice,
                widget.filterState.selectedMaxPrice),
            onChanged: (v) => widget.onChanged(widget.filterState.copyWith(
              selectedMinPrice: v.start,
              selectedMaxPrice: v.end,
            )),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('\$${widget.filterState.minPrice.toStringAsFixed(0)}',
                  style: tt.labelSmall
                      ?.copyWith(color: cs.onSurfaceVariant)),
              Text('\$${widget.filterState.maxPrice.toStringAsFixed(0)}',
                  style: tt.labelSmall
                      ?.copyWith(color: cs.onSurfaceVariant)),
            ],
          ),
        ],

        const Divider(),

        _SectionTitle('Airline'),
        const SizedBox(height: 8),
        if (widget.filterState.availableAirlines.isEmpty)
          Text(
            'No airline info available',
            style: tt.bodySmall?.copyWith(
                color: cs.onSurfaceVariant, fontStyle: FontStyle.italic),
          )
        else
          ...widget.filterState.availableAirlines.map((airline) {
            final selected =
                widget.filterState.selectedAirlines.contains(airline);
            return InkWell(
              onTap: () {
                final updated =
                    Set<String>.from(widget.filterState.selectedAirlines);
                selected ? updated.remove(airline) : updated.add(airline);
                widget.onChanged(widget.filterState
                    .copyWith(selectedAirlines: updated));
              },
              borderRadius: BorderRadius.circular(6),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    SizedBox(
                      width: 20,
                      height: 20,
                      child: Checkbox(
                        value: selected,
                        onChanged: (_) {
                          final updated = Set<String>.from(
                              widget.filterState.selectedAirlines);
                          selected
                              ? updated.remove(airline)
                              : updated.add(airline);
                          widget.onChanged(widget.filterState
                              .copyWith(selectedAirlines: updated));
                        },
                        materialTapTargetSize:
                            MaterialTapTargetSize.shrinkWrap,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(child: Text(airline, style: tt.bodyMedium)),
                  ],
                ),
              ),
            );
          }),

        if (widget.filterState.hasDurationRange) ...[
          const Divider(),
          _SectionTitle('Flight duration'),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                formatDuration(widget.filterState.selectedMinDuration),
                style: tt.bodySmall?.copyWith(
                    color: cs.primary, fontWeight: FontWeight.w600),
              ),
              Text(
                formatDuration(widget.filterState.selectedMaxDuration),
                style: tt.bodySmall?.copyWith(
                    color: cs.primary, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          RangeSlider(
            min: widget.filterState.minDurationMinutes.toDouble(),
            max: widget.filterState.maxDurationMinutes.toDouble(),
            values: RangeValues(
              widget.filterState.selectedMinDuration.toDouble(),
              widget.filterState.selectedMaxDuration.toDouble(),
            ),
            onChanged: (v) => widget.onChanged(widget.filterState.copyWith(
              selectedMinDuration: v.start.round(),
              selectedMaxDuration: v.end.round(),
            )),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(formatDuration(widget.filterState.minDurationMinutes),
                  style: tt.labelSmall
                      ?.copyWith(color: cs.onSurfaceVariant)),
              Text(formatDuration(widget.filterState.maxDurationMinutes),
                  style: tt.labelSmall
                      ?.copyWith(color: cs.onSurfaceVariant)),
            ],
          ),
        ],

        const Divider(),

        _SectionTitle('Departure time'),
        const SizedBox(height: 8),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: TimeSlot.values.map((slot) {
            final selected =
                widget.filterState.departureSlots.contains(slot);
            final available =
                widget.filterState.availableDepartureSlots.contains(slot);
            return _Chip(
              label: slot.label,
              icon: slot.icon,
              selected: selected,
              disabled: !available,
              onTap: !available
                  ? null
                  : () {
                      final updated = Set<TimeSlot>.from(
                          widget.filterState.departureSlots);
                      selected ? updated.remove(slot) : updated.add(slot);
                      widget.onChanged(widget.filterState
                          .copyWith(departureSlots: updated));
                    },
            );
          }).toList(),
        ),

        if (widget.isRoundTrip) ...[
          const SizedBox(height: 12),
          const Divider(),
          _SectionTitle('Return departure time'),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: TimeSlot.values.map((slot) {
              final selected =
                  widget.filterState.returnSlots.contains(slot);
              final available =
                  widget.filterState.availableReturnSlots.contains(slot);
              return _Chip(
                label: slot.label,
                icon: slot.icon,
                selected: selected,
                disabled: !available,
                onTap: !available
                    ? null
                    : () {
                        final updated = Set<TimeSlot>.from(
                            widget.filterState.returnSlots);
                        selected ? updated.remove(slot) : updated.add(slot);
                        widget.onChanged(widget.filterState
                            .copyWith(returnSlots: updated));
                      },
              );
            }).toList(),
          ),
        ],

        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildClassChips({
    required Map<int, Class> classes,
    required bool isReturn,
    required Set<String> availableClasses,
    required ColorScheme cs,
    required TextTheme tt,
  }) {
    return Column(
      children: List.generate(_total, (i) {
        final current = classes[i] ?? Class.any;
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(_passengerLabel(i),
                  style: tt.bodySmall
                      ?.copyWith(color: cs.onSurfaceVariant)),
              const SizedBox(height: 6),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: Class.values.map((cls) {
                  final selected = current == cls;
                  final available = cls == Class.any ||
                      availableClasses.contains(cls.label);
                  return _Chip(
                    label: cls.label,
                    selected: selected,
                    disabled: !available,
                    onTap: !available
                        ? null
                        : () {
                            final updated = Map<int, Class>.from(classes);
                            updated[i] = cls;
                            if (isReturn) {
                              widget.onChanged(widget.filterState.copyWith(
                                  returnPassengerClasses: updated));
                            } else {
                              widget.onChanged(widget.filterState
                                  .copyWith(passengerClasses: updated));
                            }
                          },
                  );
                }).toList(),
              ),
            ],
          ),
        );
      }),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 12, bottom: 4),
      child: Text(
        text,
        style: Theme.of(context)
            .textTheme
            .titleSmall
            ?.copyWith(fontWeight: FontWeight.w600),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final IconData? icon;
  final bool selected;
  final bool disabled;
  final VoidCallback? onTap;

  const _Chip({
    required this.label,
    this.icon,
    required this.selected,
    this.disabled = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    final Color bgColor;
    final Color borderColor;
    final Color textColor;
    final Color iconColor;

    if (disabled) {
      bgColor = cs.surfaceContainerLowest;
      borderColor = cs.outlineVariant.withValues(alpha: 0.4);
      textColor = cs.onSurface.withValues(alpha: 0.3);
      iconColor = cs.onSurface.withValues(alpha: 0.3);
    } else if (selected) {
      bgColor = cs.primary;
      borderColor = cs.primary;
      textColor = cs.onPrimary;
      iconColor = cs.onPrimary;
    } else {
      bgColor = cs.surfaceContainerHigh;
      borderColor = cs.outlineVariant;
      textColor = cs.onSurface;
      iconColor = cs.onSurfaceVariant;
    }

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: borderColor),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 14, color: iconColor),
              const SizedBox(width: 4),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                color: textColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}