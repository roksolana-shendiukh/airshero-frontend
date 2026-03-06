import 'package:flutter/material.dart';

class CustomSelectField extends StatefulWidget {
  final String label;
  final String value;
  final IconData icon;
  final List<String> items;
  final List<String>? itemLabels;
  final ValueChanged<String?> onChanged;
  final String? errorText;
  final bool searchable;

  const CustomSelectField({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    required this.items,
    required this.onChanged,
    this.itemLabels,
    this.errorText,
    this.searchable = false,
  });

  @override
  State<CustomSelectField> createState() => _CustomSelectFieldState();
}

class _CustomSelectFieldState extends State<CustomSelectField> {
  final LayerLink _layerLink = LayerLink();
  final FocusNode _focusNode = FocusNode();
  late TextEditingController _controller;
  OverlayEntry? _overlayEntry;
  OverlayEntry? _barrierEntry;

  bool _isOpen = false;
  bool _isHovered = false;
  List<int> _filteredIndices = [];

  static const double _itemHeight = 44.0;
  static const int _maxVisible = 5;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: _currentLabel);
    _filteredIndices = List.generate(widget.items.length, (i) => i);

    _focusNode.addListener(() {
      if (!_focusNode.hasFocus) {
        Future.delayed(const Duration(milliseconds: 150), () {
          if (mounted) _closeOverlay();
        });
      }
      if (mounted) setState(() {});
    });

    _controller.addListener(() {
      final sel = _controller.selection;
      if (sel.start != sel.end && sel.isValid) {
        final offset = sel.baseOffset.clamp(0, _controller.text.length);
        _controller.selection = TextSelection.collapsed(offset: offset);
      }
    });
  }

  @override
  void didUpdateWidget(CustomSelectField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value ||
        oldWidget.items != widget.items ||
        oldWidget.itemLabels != widget.itemLabels) {
      _filteredIndices = List.generate(widget.items.length, (i) => i);
      if (!_focusNode.hasFocus) {
        _controller.text = _currentLabel;
      }
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _overlayEntry?.markNeedsBuild();
      });
    }
  }

  String get _currentLabel {
    final idx = widget.items.indexOf(widget.value);
    if (idx == -1) return '';
    return widget.itemLabels != null && idx < widget.itemLabels!.length
        ? widget.itemLabels![idx]
        : widget.items[idx];
  }

  String _labelForIndex(int index) {
    return widget.itemLabels != null && index < widget.itemLabels!.length
        ? widget.itemLabels![index]
        : widget.items[index];
  }

  void _onTextChanged(String text) {
    final query = text.toLowerCase();
    setState(() {
      _filteredIndices = List.generate(widget.items.length, (i) => i)
          .where((i) => _labelForIndex(i).toLowerCase().contains(query))
          .toList();
    });
    if (!_isOpen) _openOverlay();
    _overlayEntry?.markNeedsBuild();
  }

  void _selectIndex(int index) {
    final value = widget.items[index];
    final label = _labelForIndex(index);
    _controller.text = label;
    _filteredIndices = List.generate(widget.items.length, (i) => i);
    _closeOverlay();
    _focusNode.unfocus();
    widget.onChanged(value);
  }

  void _openOverlay() {
    if (_overlayEntry != null) return;

    final renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox == null) return;
    final width = renderBox.size.width;

    _barrierEntry = OverlayEntry(
      builder: (_) => GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: _closeOverlay,
        child: const SizedBox.expand(),
      ),
    );

    _overlayEntry = OverlayEntry(
      builder: (ctx) {
        final colors = Theme.of(ctx).colorScheme;
        final indices = _filteredIndices;
        final visibleCount = indices.length.clamp(0, _maxVisible);
        final listHeight = visibleCount * _itemHeight;

        return CompositedTransformFollower(
          link: _layerLink,
          showWhenUnlinked: false,
          offset: const Offset(0, 56),
          child: Align(
            alignment: Alignment.topLeft,
            child: SizedBox(
              width: width,
              child: Material(
                color: colors.surface,
                borderRadius: BorderRadius.circular(8),
                elevation: 4,
                child: indices.isEmpty
                    ? Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text(
                          'No results',
                          style: TextStyle(
                            color: colors.onSurfaceVariant,
                            fontSize: 13,
                          ),
                        ),
                      )
                    : SizedBox(
                        height: listHeight,
                        child: ListView.builder(
                          padding: EdgeInsets.zero,
                          itemCount: indices.length,
                          itemExtent: _itemHeight,
                          itemBuilder: (_, i) {
                            final idx = indices[i];
                            final label = _labelForIndex(idx);
                            final isSelected =
                                widget.items[idx] == widget.value;
                            return _OverlayOption(
                              label: label,
                              isSelected: isSelected,
                              onTap: () => _selectIndex(idx),
                            );
                          },
                        ),
                      ),
              ),
            ),
          ),
        );
      },
    );

    final overlay = Overlay.of(context);
    overlay.insert(_barrierEntry!);
    overlay.insert(_overlayEntry!);
    setState(() => _isOpen = true);
  }

  void _closeOverlay() {
    _barrierEntry?.remove();
    _barrierEntry = null;
    _overlayEntry?.remove();
    _overlayEntry = null;
    if (mounted) {
      setState(() => _isOpen = false);
      if (widget.searchable) {
        _controller.text = _currentLabel;
        _filteredIndices = List.generate(widget.items.length, (i) => i);
      }
    }
  }

  void _toggle() {
    if (_isOpen) {
      _closeOverlay();
      _focusNode.unfocus();
    } else {
      if (widget.searchable) {
        _filteredIndices = List.generate(widget.items.length, (i) => i);
        _focusNode.requestFocus();
      }
      _openOverlay();
    }
  }

  @override
  void dispose() {
    _barrierEntry?.remove();
    _barrierEntry = null;
    _overlayEntry?.remove();
    _overlayEntry = null;
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final isActive = _isOpen || _isHovered || _focusNode.hasFocus;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CompositedTransformTarget(
          link: _layerLink,
          child: MouseRegion(
            onEnter: (_) => setState(() => _isHovered = true),
            onExit: (_) => setState(() => _isHovered = false),
            child: GestureDetector(
              onTap: widget.searchable ? null : _toggle,
              child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              decoration: BoxDecoration(
                color: isActive
                  ? colors.primaryContainer.withValues(alpha: 0.3)
                  : Colors.transparent,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                children: [
                  const SizedBox(width: 12),
                  Icon(widget.icon, color: colors.primary, size: 22),
                  const SizedBox(width: 4),
                  Expanded(
                    child: widget.searchable
                        ? TextField(
                            controller: _controller,
                            focusNode: _focusNode,
                            onChanged: _onTextChanged,
                            onTap: () {
                              if (!_isOpen) {
                                _filteredIndices = List.generate(
                                    widget.items.length, (i) => i);
                                _openOverlay();
                              }
                            },
                            style: TextStyle(color: colors.onSurface),
                            cursorColor: colors.primary,
                            decoration: InputDecoration(
                              labelText: widget.label,
                              labelStyle:
                                  TextStyle(color: colors.onSurfaceVariant),
                              border: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              focusedBorder: InputBorder.none,
                              filled: true,                       
                              fillColor: Colors.transparent, 
                              isDense: true,
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 4, vertical: 16),
                            ),
                          )
                        : _currentLabel.isEmpty
                            ? Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 4, vertical: 18),
                                child: Text(
                                  widget.label,
                                  style: TextStyle(
                                      color: colors.onSurfaceVariant,
                                      fontSize: 16),
                                ),
                              )
                            : Padding(
                                padding: const EdgeInsets.only(
                                    left: 4, top: 8, bottom: 8),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      widget.label,
                                      style: TextStyle(
                                          color: colors.onSurfaceVariant,
                                          fontSize: 12),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      _currentLabel,
                                      style: TextStyle(
                                          color: colors.onSurface,
                                          fontSize: 16),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: AnimatedRotation(
                      turns: _isOpen ? 0.5 : 0,
                      duration: const Duration(milliseconds: 150),
                      child: Icon(Icons.arrow_drop_down,
                          color: colors.onSurfaceVariant),
                    ),
                  ),
                ],
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
    );
  }
}

class _OverlayOption extends StatefulWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _OverlayOption({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<_OverlayOption> createState() => _OverlayOptionState();
}

class _OverlayOptionState extends State<_OverlayOption> {
  bool _isHovered = false;
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() {
          _isHovered = false;
          _isPressed = false;
        }),
        child: GestureDetector(
          onTapDown: (_) {
            setState(() => _isPressed = true);
            widget.onTap();
          },
          onTapUp: (_) => setState(() => _isPressed = false),
          onTapCancel: () => setState(() => _isPressed = false),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 120),
            decoration: BoxDecoration(
              color: widget.isSelected
                  ? colors.primaryContainer.withValues(alpha: 0.4)
                  : colors.primaryContainer.withValues(
                      alpha: _isPressed
                          ? 0.4
                          : _isHovered
                              ? 0.3
                              : 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.label,
                      style: TextStyle(
                        color: colors.onSurface,
                        fontWeight: widget.isSelected
                            ? FontWeight.w600
                            : FontWeight.normal,
                      ),
                    ),
                  ),
                  if (widget.isSelected)
                    Icon(Icons.check, size: 16, color: colors.primary),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}