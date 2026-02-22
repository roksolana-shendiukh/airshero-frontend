import 'package:flutter/material.dart';
import '/models/city_model.dart';

class CustomDropdownOverlay extends StatelessWidget {
  final LayerLink layerLink;
  final double width;
  final bool isActive;
  final String selectedValue;
  final List<Map<String, String>>? previousSearches;
  final List<String>? recentCities;
  final List<CityModel>? searchResults;
  final bool isSearching;
  final bool isFromField;
  final ValueChanged<String> onSelect;
  final Function(CityModel)? onCitySelected;
  final Function(String from, String to)? onPairSelect;

  const CustomDropdownOverlay({
    super.key,
    required this.layerLink,
    required this.width,
    required this.isActive,
    required this.selectedValue,
    this.previousSearches,
    this.recentCities,
    this.searchResults,
    this.isSearching = false,
    this.isFromField = true,
    required this.onSelect,
    this.onCitySelected,
    this.onPairSelect,
  });

  @override
  Widget build(BuildContext context) {
    Widget buildHoverableTile({
      required Widget leading,
      required Widget title,
      required VoidCallback onTap,
    }) {
      return HoverableTile(leading: leading, title: title, onTap: onTap);
    }

    final isEmpty = selectedValue.trim().isEmpty;
    final hasRecentCities = recentCities != null && recentCities!.isNotEmpty;
    final hasRoutes = previousSearches != null && previousSearches!.isNotEmpty;

    return CompositedTransformFollower(
      link: layerLink,
      showWhenUnlinked: false,
      offset: const Offset(0, 56),
      child: Align(
        alignment: Alignment.topLeft,
        child: SizedBox(
          width: width,
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
                    if (isSearching) ...[
                      const Padding(
                        padding: EdgeInsets.all(16),
                        child: Center(child: CircularProgressIndicator()),
                      ),

                    ] else if (searchResults != null && searchResults!.isNotEmpty) ...[
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: Text('Cities', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                      ...searchResults!.map((city) {
                        return buildHoverableTile(
                          leading: Icon(Icons.location_city, color: Theme.of(context).colorScheme.primary),
                          title: Text(city.displayName, style: const TextStyle(fontWeight: FontWeight.w500)),
                          onTap: () {
                            onSelect(city.cityName); 
                            onCitySelected?.call(city); 
                          },
                        );
                      }),

                    ] else if (searchResults != null &&
                        searchResults!.isEmpty &&
                        selectedValue.length > 1) ...[
                      const Padding(
                        padding: EdgeInsets.all(16),
                        child: Text('No cities found'),
                      ),

                    ] else if (isEmpty) ...[
                      if (hasRecentCities) ...[
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          child: Text('Recent cities',
                              style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                        ...recentCities!.map((city) {
                          return buildHoverableTile(
                            leading: Icon(Icons.history,
                                color: Theme.of(context).colorScheme.primary),
                            title: Text(city),
                            onTap: () => onSelect(city),
                          );
                        }),
                      ],
                      if (hasRoutes) ...[
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          child: Text('Popular routes',
                              style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                        ...previousSearches!.map((route) {
                          final from = route['from'] ?? '';
                          final to = route['to'] ?? '';
                          return buildHoverableTile(
                            leading: Icon(
                              isFromField ? Icons.arrow_forward : Icons.swap_horiz,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                            title: Row(
                              children: [
                                Text(from,
                                    style: const TextStyle(fontWeight: FontWeight.w500)),
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 6),
                                  child: Icon(Icons.arrow_forward,
                                      size: 14,
                                      color: Theme.of(context).colorScheme.onSurfaceVariant),
                                ),
                                Text(to),
                              ],
                            ),
                            onTap: () => onPairSelect?.call(from, to),
                          );
                        }),
                      ],
                      if (!hasRecentCities && !hasRoutes) ...[
                        const Padding(
                          padding: EdgeInsets.all(16),
                          child: Text('Start typing to search cities...'),
                        ),
                      ],
                    ],
                  ],
                ),
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
    final color = Theme.of(context)
        .colorScheme
        .primaryContainer
        .withValues(alpha: _isHovered ? 0.3 : 0.1);

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
          child: InkWell(
            onTap: widget.onTap,
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  widget.leading,
                  const SizedBox(width: 16),
                  Expanded(child: widget.title),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}