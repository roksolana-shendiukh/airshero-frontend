import 'dart:async';
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
  final ValueChanged<String>? onSearch;

  static final List<VoidCallback> _openInstances = [];

  static void closeAll() {
    for (final close in List.of(_openInstances)) {
      close();
    }
  }

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
    this.onSearch,
  });

  @override
  State<CustomSelectField> createState() => _CustomSelectFieldState();
}

class _CustomSelectFieldState extends State<CustomSelectField> {
  final FocusNode _focusNode = FocusNode();
  final LayerLink _layerLink = LayerLink();
  late TextEditingController _controller;
  OverlayEntry? _overlayEntry;
  OverlayEntry? _barrierEntry;
  ScrollPosition? _scrollPosition;
  bool _isOpen      = false;
  bool _isHovered   = false;
  bool _pendingOpen = false;
  bool _isSearching = false;
  List<int> _filteredIndices = [];
  Timer? _debounce;

  static const double _itemHeight = 44.0;
  static const int    _maxVisible = 5;

  void _onFocusChanged() {
    if (!_focusNode.hasFocus) {
      Future.delayed(const Duration(milliseconds: 150), () {
        if (mounted) _closeOverlay();
      });
    }
    if (mounted) setState(() {});
  }

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: _currentLabel);
    _filteredIndices = List.generate(widget.items.length, (i) => i);
    _focusNode.addListener(_onFocusChanged);
  }

  @override
  void didUpdateWidget(CustomSelectField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value ||
        oldWidget.items != widget.items ||
        oldWidget.itemLabels != widget.itemLabels) {
      _filteredIndices = List.generate(widget.items.length, (i) => i);
      _isSearching = false;
      if (!_focusNode.hasFocus) {
        _controller.text = _currentLabel;
      }
      if (_overlayEntry != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _overlayEntry?.markNeedsBuild();
        });
      }
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
    if (widget.onSearch != null) {
      _debounce?.cancel();
      setState(() => _isSearching = true);
      _debounce = Timer(const Duration(milliseconds: 350), () {
        widget.onSearch!(text);
      });
      if (!_isOpen) _openOverlay();
    } else {
      final query = text.toLowerCase();
      setState(() {
        _filteredIndices = List.generate(widget.items.length, (i) => i)
            .where((i) => _labelForIndex(i).toLowerCase().contains(query))
            .toList();
      });
      if (!_isOpen) _openOverlay();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _overlayEntry?.markNeedsBuild();
      });
    }
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
    if (_isOpen || _pendingOpen) return;
    if (!mounted) return;
    _pendingOpen = true;
    _scrollPosition = Scrollable.maybeOf(context)?.position;
    _scrollPosition?.addListener(_closeOverlay);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_pendingOpen) return;
      _pendingOpen = false;

      final renderBox = context.findRenderObject() as RenderBox?;
      if (renderBox == null || !renderBox.hasSize || !renderBox.attached) return;

      final fieldSize  = renderBox.size;
      final fieldPos   = renderBox.localToGlobal(Offset.zero);
      final screenH    = MediaQuery.of(context).size.height;
      final spaceBelow = screenH - fieldPos.dy - fieldSize.height - 8;
      final maxH       = spaceBelow.clamp(_itemHeight, _itemHeight * _maxVisible);

      _barrierEntry = OverlayEntry(
        builder: (_) => Listener(
          behavior: HitTestBehavior.translucent,
          onPointerDown: (_) => _closeOverlay(),
          child: const SizedBox.expand(),
        ),
      );

      _overlayEntry = OverlayEntry(
        builder: (ctx) {
          final colors  = Theme.of(ctx).colorScheme;
          final indices = _filteredIndices;
          final count   = indices.length.clamp(0, _maxVisible);
          final listH   = (count * _itemHeight).clamp(0.0, maxH);

          return CompositedTransformFollower(
            link: _layerLink,
            showWhenUnlinked: false,
            offset: Offset(0, fieldSize.height + 4),
            child: Align(
              alignment: Alignment.topLeft,
              child: Material(
                color:        colors.surface,
                borderRadius: BorderRadius.circular(8),
                elevation:    4,
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth:  fieldSize.width,
                    maxHeight: maxH,
                  ),
                  child: _isSearching
                      ? const Padding(
                          padding: EdgeInsets.all(16),
                          child: Center(
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        )
                      : indices.isEmpty
                          ? Padding(
                              padding: const EdgeInsets.all(16),
                              child: Text(
                                'No results',
                                style: TextStyle(
                                    color: colors.onSurfaceVariant,
                                    fontSize: 13),
                              ),
                            )
                          : SizedBox(
                              height: listH,
                              child: ListView.builder(
                                padding:    EdgeInsets.zero,
                                itemCount:  indices.length,
                                itemExtent: _itemHeight,
                                itemBuilder: (_, i) {
                                  final idx        = indices[i];
                                  final label      = _labelForIndex(idx);
                                  final isSelected =
                                      widget.items[idx] == widget.value;
                                  return _OverlayOption(
                                    label:      label,
                                    isSelected: isSelected,
                                    onTap:      () => _selectIndex(idx),
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
      CustomSelectField._openInstances.add(_closeOverlay);
      if (mounted) setState(() => _isOpen = true);
    });
  }

  void _closeOverlay() {
    _pendingOpen = false;
    _scrollPosition?.removeListener(_closeOverlay);
    _scrollPosition = null;
    _barrierEntry?.remove();
    _barrierEntry = null;
    _overlayEntry?.remove();
    _overlayEntry = null;
    CustomSelectField._openInstances.remove(_closeOverlay);
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
    _debounce?.cancel();
    _pendingOpen = false;
    _scrollPosition?.removeListener(_closeOverlay);
    _scrollPosition = null;
    CustomSelectField._openInstances.remove(_closeOverlay);
    _barrierEntry?.remove();
    _barrierEntry = null;
    _overlayEntry?.remove();
    _overlayEntry = null;
    _focusNode.removeListener(_onFocusChanged);
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors   = Theme.of(context).colorScheme;
    final isActive = _isOpen || _isHovered || _focusNode.hasFocus;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CompositedTransformTarget(
          link: _layerLink,
          child: MouseRegion(
            onEnter: (_) => setState(() => _isHovered = true),
            onExit:  (_) => setState(() => _isHovered = false),
            child: widget.searchable
                ? AnimatedContainer(
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
                          child: TextField(
                            controller: _controller,
                            focusNode:  _focusNode,
                            onChanged:  _onTextChanged,
                            onTap: () {
                              _filteredIndices = List.generate(
                                  widget.items.length, (i) => i);
                              if (!_isOpen) _openOverlay();
                            },
                            onTapAlwaysCalled: true,
                            style:       TextStyle(color: colors.onSurface),
                            cursorColor: colors.primary,
                            decoration: InputDecoration(
                              labelText:  widget.label,
                              labelStyle:
                                  TextStyle(color: colors.onSurfaceVariant),
                              border:         InputBorder.none,
                              enabledBorder:  InputBorder.none,
                              focusedBorder:  InputBorder.none,
                              filled:         true,
                              fillColor:      Colors.transparent,
                              isDense:        true,
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 4, vertical: 16),
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: AnimatedRotation(
                            turns:    _isOpen ? 0.5 : 0,
                            duration: const Duration(milliseconds: 150),
                            child: Icon(Icons.arrow_drop_down,
                                color: colors.onSurfaceVariant),
                          ),
                        ),
                      ],
                    ),
                  )
                : InkWell(
                    onTap: _toggle,
                    borderRadius: BorderRadius.circular(6),
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
                            child: _currentLabel.isEmpty
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
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
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
                              turns:    _isOpen ? 0.5 : 0,
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
  final String       label;
  final bool         isSelected;
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

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit:  (_) => setState(() => _isHovered = false),
        child: GestureDetector(
          onTapDown: (_) => widget.onTap(),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 120),
            decoration: BoxDecoration(
              color: widget.isSelected
                  ? colors.primaryContainer.withValues(alpha: 0.4)
                  : colors.primaryContainer
                      .withValues(alpha: _isHovered ? 0.3 : 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.label,
                      style: TextStyle(
                          color: colors.onSurface,
                          fontWeight: widget.isSelected
                              ? FontWeight.w600
                              : FontWeight.normal),
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