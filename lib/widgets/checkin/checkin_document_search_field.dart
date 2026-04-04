import 'package:flutter/material.dart';
import '../../services/checkin_api_service.dart';
import '../../services/auth_service.dart';

class CheckInDocumentSearchField extends StatefulWidget {
  final AuthService authService;
  final String flightNumber;
  final DateTime departsDate;
  final Function(String) onDocumentSelected;
  final TextEditingController controller;
  

  const CheckInDocumentSearchField({
    super.key,
    required this.authService,
    required this.flightNumber,
    required this.departsDate,
    required this.onDocumentSelected,
    required this.controller,
  });

  @override
  State<CheckInDocumentSearchField> createState() =>
      _CheckInDocumentSearchFieldState();
}

class _CheckInDocumentSearchFieldState
    extends State<CheckInDocumentSearchField> {
  final _focusNode = FocusNode();
  final _layerLink = LayerLink();

  final _fieldKey = GlobalKey();
  final ValueNotifier<List<Map<String, dynamic>>> _suggestionsNotifier =
      ValueNotifier([]);
  final ValueNotifier<bool> _isSearchingNotifier = ValueNotifier(false);

  OverlayEntry? _overlayEntry;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_onFocusChanged);
  }

  void _onFocusChanged() {
    setState(() {});
    if (_focusNode.hasFocus) {
      if (_suggestionsNotifier.value.isNotEmpty ||
          _isSearchingNotifier.value) {
        _showOverlay();
      }
    } else {
      Future.delayed(const Duration(milliseconds: 200), _hideOverlay);
    }
  }

  Future<void> _onChanged(String value) async {
    widget.controller.text = value.toUpperCase();

    if (value.trim().length < 2) {
      _suggestionsNotifier.value = [];
      _isSearchingNotifier.value = false;
      _hideOverlay();
      return;
    }

    _isSearchingNotifier.value = true;
    _showOverlay();

    try {
      final api = CheckInApiService(widget.authService);
      final results = await api.getFlightPassengerSuggestions(
        query:        value.trim().toUpperCase(),
        flightNumber: widget.flightNumber,
        departsDate:  widget.departsDate,
      );

      if (!mounted) return;

      _suggestionsNotifier.value = results;
      _isSearchingNotifier.value = false;

      if (results.isEmpty) {
        _hideOverlay();
      } else {
        _showOverlay();
      }
    } catch (_) {
      if (!mounted) return;
      _isSearchingNotifier.value = false;
      _hideOverlay();
    }
  }

  void _selectSuggestion(Map<String, dynamic> suggestion) {
    final doc = (suggestion['document_number'] as String? ?? '').toUpperCase();
    widget.controller.text = doc;
    widget.onDocumentSelected(doc);
    _hideOverlay();
    _focusNode.unfocus();
  }

  void _clear() {
    widget.controller.clear();
    _suggestionsNotifier.value = [];
    _isSearchingNotifier.value = false;
    _hideOverlay();
    setState(() {});
  }

  void _showOverlay() {
    if (_overlayEntry != null) return;

    final renderBox =
        _fieldKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return;

    _overlayEntry = OverlayEntry(
      builder: (ctx) {
        final box =
            _fieldKey.currentContext?.findRenderObject() as RenderBox?;
        final w = box?.size.width ?? 300;

        return CompositedTransformFollower(
          link: _layerLink,
          showWhenUnlinked: false,
          targetAnchor: Alignment.bottomLeft,   
          followerAnchor: Alignment.topLeft,  
          offset: Offset.zero,               
          child: Align(
            alignment: Alignment.topLeft,
            child: SizedBox(
              width: w,
              child: Material(
                color: Theme.of(ctx).colorScheme.surface,
                borderRadius: BorderRadius.circular(8),
                elevation: 4,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 280),
                  child: SingleChildScrollView(
                    child: ValueListenableBuilder<bool>(
                      valueListenable: _isSearchingNotifier,
                      builder: (_, isSearching, __) {
                        return ValueListenableBuilder<List<Map<String, dynamic>>>(
                          valueListenable: _suggestionsNotifier,
                          builder: (_, suggestions, __) {
                            if (isSearching) {
                              return const Padding(
                                padding: EdgeInsets.all(16),
                                child: Center(child: CircularProgressIndicator()),
                              );
                            }

                            final filtered = suggestions
                                .where((s) =>
                                    s['document_number'] != null &&
                                    (s['document_number'] as String).isNotEmpty)
                                .toList();

                            if (filtered.isEmpty) return const SizedBox.shrink();

                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: filtered
                                  .map((s) => _SuggestionTile(
                                        documentNumber:
                                            s['document_number'] as String,
                                        firstName:
                                            s['first_name'] as String? ?? '',
                                        lastName:
                                            s['last_name'] as String? ?? '',
                                        onTap: () => _selectSuggestion(s),
                                      ))
                                  .toList(),
                            );
                          },
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );

    Overlay.of(context).insert(_overlayEntry!);
  }


  void _hideOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChanged);
    _hideOverlay();
    _suggestionsNotifier.dispose();
    _isSearchingNotifier.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors   = Theme.of(context).colorScheme;
    final isActive = _focusNode.hasFocus;

    return CompositedTransformTarget(
      link: _layerLink,
      child: AnimatedContainer(
        key: _fieldKey,
        duration: const Duration(milliseconds: 150),
        decoration: BoxDecoration(
          color: colors.primaryContainer
              .withValues(alpha: isActive ? 0.3 : 0.1),
          borderRadius: BorderRadius.circular(6),
        ),
        child: TextField(
          controller:      widget.controller,
          focusNode:       _focusNode,
          onChanged:       _onChanged,
          textInputAction: TextInputAction.search,
          style:           TextStyle(color: colors.onSurface),
          cursorColor:     colors.primary,
          decoration: InputDecoration(
            prefixIcon: Icon(
              Icons.contact_page_outlined,
              color: colors.primary,
            ),
            suffixIcon: widget.controller.text.isNotEmpty
                ? IconButton(
                    icon: Icon(Icons.close, color: colors.primary),
                    onPressed: _clear,
                  )
                : null,
            labelText:  'Document Number',
            labelStyle: TextStyle(color: colors.onSurfaceVariant),
            border:        InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            fillColor:     Colors.transparent,
            isDense:       true,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical:   16,
            ),
          ),
        ),
      ),
    );
  }
}

class _SuggestionTile extends StatefulWidget {
  final String       documentNumber;
  final String       firstName;
  final String       lastName;
  final VoidCallback onTap;

  const _SuggestionTile({
    required this.documentNumber,
    required this.firstName,
    required this.lastName,
    required this.onTap,
  });

  @override
  State<_SuggestionTile> createState() => _SuggestionTileState();
}

class _SuggestionTileState extends State<_SuggestionTile> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit:  (_) => setState(() => _isHovered = false),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          decoration: BoxDecoration(
            color: colors.primaryContainer
                .withValues(alpha: _isHovered ? 0.3 : 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: InkWell(
            onTap:        widget.onTap,
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 10),
              child: Row(
                children: [
                  Icon(Icons.contact_page_outlined,
                      color: colors.primary, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Row(
                      children: [
                        Text(
                          widget.documentNumber,
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color:      colors.onSurface,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '— ${widget.firstName} ${widget.lastName}',
                          style: TextStyle(
                            color:    colors.onSurfaceVariant,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}