import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'custom_dropdown_overlay.dart';
import '/models/city_model.dart';
import '/services/booking_api_service.dart';
import '/services/auth_service.dart';

class CustomInputField extends StatefulWidget {
  final String label;
  final String value;
  final IconData icon;
  final String? errorText;
  final String? hint;
  final VoidCallback? onTap;
  final VoidCallback? onIconTap;
  final bool isSelected;
  final List<Map<String, String>>? previousSearches;
  final List<String>? recentCities;
  final ValueChanged<String>? onChanged;
  final bool readOnly;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final bool obscureText;
  final bool searchAirports;
  final bool isFromField;
  final Function(String from, String to)? onPairSelect;
  final Function(CityModel)? onCitySelected;

  const CustomInputField({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    this.errorText,
    this.hint,
    this.onTap,
    this.onIconTap,
    this.isSelected = false,
    this.previousSearches,
    this.recentCities,
    this.onChanged,
    this.readOnly = false,
    this.keyboardType,
    this.inputFormatters,
    this.obscureText = false,
    this.searchAirports = false,
    this.isFromField = true,
    this.onPairSelect,
    this.onCitySelected,
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

  List<CityModel> _searchResults = [];
  bool _isSearching = false;

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
        Future.delayed(const Duration(milliseconds: 300), _hideOverlay);
      }
      setState(() {});
    });
  }

  @override
  void didUpdateWidget(covariant CustomInputField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value != oldWidget.value &&
        _controller.text != widget.value) {
      _controller.value = TextEditingValue(
        text: widget.value,
        selection: TextSelection.collapsed(offset: widget.value.length),
      );
    }
  }

  Future<void> _onTextChanged(String value) async {
    widget.onChanged?.call(value);

    if (!widget.searchAirports) return;

    if (_overlayEntry == null) _showOverlay();

    if (value.trim().length < 1) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
      _overlayEntry?.markNeedsBuild();
      return;
    }

    setState(() => _isSearching = true);
    _overlayEntry?.markNeedsBuild();

    try {
      final authService = context.read<AuthService>();
      final service = BookingApiService(authService);
      final results = await service.searchCities(value.trim());
      if (mounted) {
        setState(() {
          _searchResults = results;
          _isSearching = false;
        });
        _overlayEntry?.markNeedsBuild();
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isSearching = false);
        _overlayEntry?.markNeedsBuild();
      }
    }
  }

  void _showOverlay() {
    if (_overlayEntry != null) {
      return;
    }
    final RenderBox? renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox == null) {
      return;
    }

    if (!widget.searchAirports &&
        (widget.previousSearches?.isEmpty ?? true) &&
        (widget.recentCities?.isEmpty ?? true)) {
      return;
    }

    final size = renderBox.size;

    _overlayEntry = OverlayEntry(
      builder: (context) => CustomDropdownOverlay(
        layerLink: _layerLink,
        width: size.width,
        isActive: true,
        selectedValue: _controller.text,
        previousSearches: widget.previousSearches,
        recentCities: widget.recentCities,
        searchResults: widget.searchAirports ? _searchResults : null,
        isSearching: _isSearching,
        isFromField: widget.isFromField,
        onCitySelected: widget.onCitySelected,
        onSelect: (value) {
          _controller.text = value;
          widget.onChanged?.call(value);
          _focusNode.unfocus();
        },
        onPairSelect: widget.onPairSelect != null
            ? (from, to) {
                widget.onPairSelect!(from, to);
                _controller.text = widget.isFromField ? from : to;
                _focusNode.unfocus();
              }
            : null,
      ),
    );
    Overlay.of(context).insert(_overlayEntry!);
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
    final bool isActive =
        _focusNode.hasFocus || widget.isSelected || _isHovered;
    final bool hasIconTap = widget.onIconTap != null;

    final hoverColor = Theme.of(context)
        .colorScheme
        .primaryContainer
        .withValues(alpha: isActive ? 0.3 : 0.1);

    return CompositedTransformTarget(
      link: _layerLink,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Tooltip(
            message: widget.hint ?? '',
            preferBelow: true,
            waitDuration: const Duration(milliseconds: 300),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(6),
            ),
            textStyle: TextStyle(
              color: Theme.of(context).colorScheme.onSurface,
              fontSize: 12,
            ),
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
                    obscureText: widget.obscureText,
                    enableInteractiveSelection: true,
                    keyboardType: widget.keyboardType,
                    inputFormatters: widget.inputFormatters,
                    onChanged: _onTextChanged,
                    onTap: () {
                      if (widget.readOnly && !hasIconTap) {
                        widget.onTap?.call();
                      } else {
                        widget.onTap?.call();
                        if (widget.onIconTap == null) {
                          _showOverlay();
                        }
                      }
                    },
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
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
      ),
    );
  }
}