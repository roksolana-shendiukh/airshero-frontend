import 'package:flutter/material.dart';

class CustomDropdownOverlay extends StatelessWidget {
  final LayerLink layerLink;
  final double width;
  final bool isActive;
  final String selectedValue;
  final List<Map<String, String>>? nearestAirports;
  final List<Map<String, String>>? previousSearches;
  final ValueChanged<String> onSelect;

  const CustomDropdownOverlay({
    super.key,
    required this.layerLink,
    required this.width,
    required this.isActive,
    required this.selectedValue,
    this.nearestAirports,
    this.previousSearches,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    Widget buildHoverableTile({required Widget leading, required Widget title, required VoidCallback onTap}) {
      return HoverableTile(
        leading: leading,
        title: title,
        onTap: onTap,
      );
    }

    return Positioned(
      width: width,
      child: CompositedTransformFollower(
        link: layerLink,
        showWhenUnlinked: false,
        offset: const Offset(0, 56),
        child: Material(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(6),
          elevation: 4,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 300),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (selectedValue.isNotEmpty) ...[
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Text('Selected city', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                    buildHoverableTile(
                      leading: Icon(Icons.location_on, color: Theme.of(context).colorScheme.primary),
                      title: Text(selectedValue),
                      onTap: () => onSelect(selectedValue),
                    ),
                  ],

                  if (nearestAirports != null && nearestAirports!.isNotEmpty) ...[
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Text('Nearest airports', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                    ...nearestAirports!.map((airport) {
                      final name = airport['name'] ?? '';
                      final iata = airport['iata'] ?? '';
                      return buildHoverableTile(
                        leading: Icon(Icons.place, color: Theme.of(context).colorScheme.primary),
                        title: Text('$name ($iata)'),
                        onTap: () => onSelect('$name ($iata)'),
                      );
                    }),
                  ],

                  if (previousSearches != null && previousSearches!.isNotEmpty) ...[
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Text('Previous searches', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                    ...previousSearches!.map((search) {
                      final from = search['from'] ?? '';
                      final to = search['to'] ?? '';
                      final direction = search['direction'] ?? 'one';

                      IconData iconDirection =
                          direction == 'both' ? Icons.swap_horiz : Icons.arrow_forward;

                      return buildHoverableTile(
                        leading: Icon(Icons.history, color: Theme.of(context).colorScheme.primary),
                        title: Row(
                          children: [
                            Text(from),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 4),
                              child: Icon(
                                iconDirection,
                                size: 16,
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                            ),
                            Text(to),
                          ],
                        ),
                        onTap: () => onSelect('$from -> $to'),
                      );
                    }),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class HoverableTile extends StatefulWidget {
  final Widget leading;
  final Widget title;
  final VoidCallback onTap;

  const HoverableTile({
    required this.leading,
    required this.title,
    required this.onTap,
    super.key,
  });

  @override
  State<HoverableTile> createState() => _HoverableTileState();
}

class _HoverableTileState extends State<HoverableTile> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.primaryContainer.withValues(
      alpha: _isHovered ? 0.3 : 0.1,
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(8),
          ),
          child: ListTile(
            leading: widget.leading,
            title: widget.title,
            onTap: widget.onTap,
          ),
        ),
      ),
    );
  }
}
