import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'custom_dropdown_overlay.dart';

class CustomInputField extends StatefulWidget {
  final String label;
  final String value;
  final IconData icon;
  final VoidCallback? onTap;
  final VoidCallback? onIconTap;
  final bool isSelected;
  final List<Map<String, String>>? nearestAirports;
  final List<Map<String, String>>? previousSearches;
  final ValueChanged<String>? onChanged;
  final bool readOnly;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;

  const CustomInputField({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    this.onTap,
    this.onIconTap,
    this.isSelected = false,
    this.nearestAirports,
    this.previousSearches,
    this.onChanged,
    this.readOnly = false,
    this.keyboardType,
    this.inputFormatters,
  });

  @override
  State<CustomInputField> createState() => _CustomInputFieldState();
}

class _CustomInputFieldState extends State<CustomInputField> {
  late TextEditingController _controller;
  final FocusNode _focusNode = FocusNode();
  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.value);

    _focusNode.addListener(() {
      if (_focusNode.hasFocus) {
        widget.onTap?.call(); 
        if (!widget.readOnly && widget.onIconTap == null) {
          _showOverlay();
        }
      } else {
        Future.delayed(const Duration(milliseconds: 200), _hideOverlay);
      }
      setState(() {});
    });
  }

  @override
  void didUpdateWidget(covariant CustomInputField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value != oldWidget.value && _controller.text != widget.value) {
      _controller.value = TextEditingValue(
        text: widget.value,
        selection: TextSelection.collapsed(offset: widget.value.length),
      );
    }
  }

  void _showOverlay() {
    if (_overlayEntry != null) return;
    final RenderBox? renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox == null) return;

    final size = renderBox.size;

    if ((widget.nearestAirports?.isNotEmpty ?? false) ||
        (widget.previousSearches?.isNotEmpty ?? false)) {
      _overlayEntry = OverlayEntry(
        builder: (context) => CustomDropdownOverlay(
          layerLink: _layerLink,
          width: size.width,
          isActive: true,
          selectedValue: _controller.text,
          nearestAirports: widget.nearestAirports,
          previousSearches: widget.previousSearches,
          onSelect: (value) {
            _controller.text = value;
            widget.onChanged?.call(value);
            _focusNode.unfocus();
          },
        ),
      );
      Overlay.of(context).insert(_overlayEntry!);
    }
  }

  void _hideOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  @override
  void dispose() {
    _hideOverlay();
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isActive = _focusNode.hasFocus || widget.isSelected || _isHovered;
    final bool hasIconTap = widget.onIconTap != null;

    final hoverColor = Theme.of(context)
        .colorScheme
        .primaryContainer
        .withValues(alpha: isActive ? 0.3 : 0.1);

    return CompositedTransformTarget(
      link: _layerLink,
      child: MouseRegion(
        cursor: (widget.readOnly && !hasIconTap)
            ? SystemMouseCursors.click 
            : SystemMouseCursors.text,
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: GestureDetector(
          onTap: (widget.readOnly && !hasIconTap) ? widget.onTap : null,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            decoration: BoxDecoration(
              color: hoverColor,
              borderRadius: BorderRadius.circular(6),
            ),
            child: TextField(
              controller: _controller,
              focusNode: _focusNode,
              readOnly: widget.readOnly && !hasIconTap,
              enableInteractiveSelection: true,
              keyboardType: widget.keyboardType,
              inputFormatters: widget.inputFormatters,
              onChanged: (value) => widget.onChanged?.call(value),
              onTap: () {
                if (widget.readOnly && !hasIconTap) {
                  widget.onTap?.call();
                } else {
                  widget.onTap?.call();
                  if (widget.onIconTap == null) {
                    _showOverlay();
                  }
                  _controller.selection = TextSelection.collapsed(
                    offset: _controller.text.length,
                  );
                }
              },
              style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
              cursorColor: Theme.of(context).colorScheme.primary,
              decoration: InputDecoration(
                prefixIcon: hasIconTap
                    ? IconButton(
                        icon: Icon(
                          widget.icon,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        onPressed: widget.onIconTap,
                      )
                    : Icon(
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
            ),
          ),
        ),
      ),
    );
  }
}