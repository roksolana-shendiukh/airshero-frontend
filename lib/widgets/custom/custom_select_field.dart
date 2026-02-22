import 'package:flutter/material.dart';

class CustomSelectField extends StatefulWidget {
  final String label;
  final String value;
  final IconData icon;
  final List<String> items;
  final ValueChanged<String?> onChanged;
  final String? errorText;

  const CustomSelectField({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    required this.items,
    required this.onChanged,
    this.errorText,
  });

  @override
  State<CustomSelectField> createState() => _CustomSelectFieldState();
}

class _CustomSelectFieldState extends State<CustomSelectField> {
  bool _isHovered = false;
  bool _isFocused = false;

  @override
  Widget build(BuildContext context) {
    final bool isActive = _isFocused || _isHovered;

    final hoverColor = Theme.of(context)
        .colorScheme
        .primaryContainer
        .withValues(alpha: isActive ? 0.3 : 0.1);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        MouseRegion(
          onEnter: (_) => setState(() => _isHovered = true),
          onExit: (_) => setState(() => _isHovered = false),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            decoration: BoxDecoration(
              color: hoverColor,
              borderRadius: BorderRadius.circular(6),
            ),
            child: DropdownButtonFormField<String>(
              isExpanded: true,
              onTap: () => setState(() => _isFocused = true),
              decoration: InputDecoration(
                prefixIcon: Icon(
                  widget.icon,
                  color: Theme.of(context).colorScheme.primary,
                ),
                labelText: widget.label,
                labelStyle: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                fillColor: Colors.transparent,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 16,
                ),
              ),
              icon: Icon(
                Icons.arrow_drop_down,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              dropdownColor: Theme.of(context).colorScheme.surface,
              items: widget.items.map((String item) {
                return DropdownMenuItem<String>(
                  value: item,
                  child: Text(
                    item,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                );
              }).toList(),
              onChanged: (value) {
                setState(() => _isFocused = false);
                widget.onChanged(value);
              },
            ),
          ),
        ),
        if (widget.errorText != null)
          Padding(
            padding: const EdgeInsets.only(left: 16, top: 4),
            child: Text(
              widget.errorText!,
              style: const TextStyle(color: Colors.red, fontSize: 12),
            ),
          ),
      ],
    );
  }
}