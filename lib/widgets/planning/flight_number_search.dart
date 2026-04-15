import 'package:flutter/material.dart';

class FlightNumberSearch extends StatefulWidget {
  final List<String> allFlightNumbers;
  final String value;
  final ValueChanged<String> onChanged;

  const FlightNumberSearch({
    super.key,
    required this.allFlightNumbers,
    required this.value,
    required this.onChanged,
  });

  @override
  State<FlightNumberSearch> createState() => _FlightNumberSearchState();
}

class _FlightNumberSearchState extends State<FlightNumberSearch> {
  late final TextEditingController _ctrl;
  final FocusNode _focusNode = FocusNode();
  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _overlay;

  List<String> get _suggestions {
    if (_ctrl.text.isEmpty) return [];
    final q = _ctrl.text.toLowerCase();
    return widget.allFlightNumbers
        .where((n) => n.toLowerCase().contains(q))
        .take(8)
        .toList();
  }

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.value);
    _focusNode.addListener(_onFocusChanged);
  }

  void _onFocusChanged() {
    setState(() {});
    if (_focusNode.hasFocus) {
      _updateOverlay();
    } else {
      Future.delayed(const Duration(milliseconds: 150), _hideOverlay);
    }
  }

  void _onChanged(String v) {
    widget.onChanged(v);
    _updateOverlay();
  }

  void _select(String number) {
    _ctrl.text = number;
    widget.onChanged(number);
    _focusNode.unfocus();
    _hideOverlay();
  }

  void _clear() {
    _ctrl.clear();
    widget.onChanged('');
    _hideOverlay();
  }

  void _updateOverlay() {
    if (_suggestions.isEmpty) {
      _hideOverlay();
      return;
    }
    if (_overlay != null) {
      _overlay!.markNeedsBuild();
      return;
    }
    _showOverlay();
  }

  void _showOverlay() {
    final renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox == null) return;
    final width = renderBox.size.width;

    _overlay = OverlayEntry(
      builder: (ctx) => CompositedTransformFollower(
        link: _layerLink,
        showWhenUnlinked: false,
        offset: const Offset(0, 56),
        child: Align(
          alignment: Alignment.topLeft,
          child: SizedBox(
            width: width,
            child: Material(
              color: Theme.of(ctx).colorScheme.surface,
              borderRadius: BorderRadius.circular(8),
              elevation: 4,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 260),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: _suggestions
                        .map((n) => _SuggestionTile(
                              number: n,
                              query: _ctrl.text,
                              onTap: () => _select(n),
                            ))
                        .toList(),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    Overlay.of(context).insert(_overlay!);
  }

  void _hideOverlay() {
    _overlay?.remove();
    _overlay = null;
  }

  @override
  void didUpdateWidget(FlightNumberSearch old) {
    super.didUpdateWidget(old);
    if (widget.value != old.value && _ctrl.text != widget.value) {
      _ctrl.text = widget.value;
    }
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChanged);
    _hideOverlay();
    _ctrl.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final isActive = _focusNode.hasFocus;

    return CompositedTransformTarget(
      link: _layerLink,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        decoration: BoxDecoration(
          color: colors.primaryContainer
              .withValues(alpha: isActive ? 0.3 : 0.1),
          borderRadius: BorderRadius.circular(6),
        ),
        child: TextField(
          controller: _ctrl,
          focusNode: _focusNode,
          onChanged: _onChanged,
          onEditingComplete: () => _focusNode.unfocus(),
          style: TextStyle(color: colors.onSurface),
          cursorColor: colors.primary,
          decoration: InputDecoration(
            prefixIcon: Icon(Icons.search, color: colors.primary),
            suffixIcon: _ctrl.text.isNotEmpty
                ? IconButton(
                    icon: Icon(Icons.close, color: colors.primary),
                    onPressed: _clear,
                  )
                : null,
            labelText: 'Search by flight number',
            labelStyle: TextStyle(color: colors.onSurfaceVariant),
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            fillColor: Colors.transparent,
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(
                horizontal: 16, vertical: 16),
          ),
        ),
      ),
    );
  }
}

class _SuggestionTile extends StatefulWidget {
  final String number;
  final String query;
  final VoidCallback onTap;

  const _SuggestionTile({
    required this.number,
    required this.query,
    required this.onTap,
  });

  @override
  State<_SuggestionTile> createState() => _SuggestionTileState();
}

class _SuggestionTileState extends State<_SuggestionTile> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final q = widget.query.toLowerCase();
    final idx = widget.number.toLowerCase().indexOf(q);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 100),
          decoration: BoxDecoration(
            color: colors.primaryContainer
                .withValues(alpha: _hovered ? 0.3 : 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: InkWell(
            onTap: widget.onTap,
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 10),
              child: Row(
                children: [
                  Icon(Icons.flight_takeoff_outlined,
                      size: 18, color: colors.primary),
                  const SizedBox(width: 12),
                  idx >= 0
                      ? RichText(
                          text: TextSpan(
                            children: [
                              TextSpan(
                                text: widget.number.substring(0, idx),
                                style: TextStyle(color: colors.onSurface),
                              ),
                              TextSpan(
                                text: widget.number.substring(
                                    idx, idx + widget.query.length),
                                style: TextStyle(
                                  color: colors.primary,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              TextSpan(
                                text: widget.number
                                    .substring(idx + widget.query.length),
                                style: TextStyle(color: colors.onSurface),
                              ),
                            ],
                          ),
                        )
                      : Text(widget.number,
                          style: TextStyle(color: colors.onSurface)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}