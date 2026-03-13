import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../services/passenger_api_service.dart';
import '../../services/auth_service.dart';

class CheckInDocumentSearchField extends StatefulWidget {
  final AuthService authService;
  final ValueChanged<String> onChanged;
  final String value;

  const CheckInDocumentSearchField({
    super.key,
    required this.authService,
    required this.onChanged,
    required this.value,
  });

  @override
  State<CheckInDocumentSearchField> createState() =>
      _CheckInDocumentSearchFieldState();
}

class _CheckInDocumentSearchFieldState
    extends State<CheckInDocumentSearchField> {
  late TextEditingController _controller;
  final _focusNode = FocusNode();
  final _layerLink = LayerLink();

  final ValueNotifier<List<Map<String, dynamic>>> _suggestions = ValueNotifier([]);
  final ValueNotifier<bool> _isSearching = ValueNotifier(false);

  OverlayEntry? _overlayEntry;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.value);
    _focusNode.addListener(_onFocusChanged);
  }

  void _onFocusChanged() {
    setState(() {});
    if (_focusNode.hasFocus) {
      if (_suggestions.value.isNotEmpty || _isSearching.value) _showOverlay();
    } else {
      Future.delayed(const Duration(milliseconds: 200), _hideOverlay);
    }
  }

  Future<void> _onChanged(String value) async {
    final upper = value.toUpperCase();
    _controller.value = TextEditingValue(
      text: upper,
      selection: TextSelection.collapsed(offset: upper.length),
    );
    widget.onChanged(upper);

    if (upper.trim().length < 2) {
      _suggestions.value = [];
      _isSearching.value = false;
      _hideOverlay();
      return;
    }

    _isSearching.value = true;
    _showOverlay();

    final api = PassengerApiService(widget.authService);
    final results = await api.getDocumentSuggestions(upper.trim());

    if (!mounted) return;
    _suggestions.value = results;
    _isSearching.value = false;
    if (results.isEmpty) _hideOverlay();
  }

  void _selectSuggestion(Map<String, dynamic> suggestion) {
    final docNumber = (suggestion['document_number'] as String? ?? '').toUpperCase();
    _controller.value = TextEditingValue(
      text: docNumber,
      selection: TextSelection.collapsed(offset: docNumber.length),
    );
    widget.onChanged(docNumber);
    _hideOverlay();
    _focusNode.unfocus();
  }

  void _clear() {
    _controller.clear();
    widget.onChanged('');
    _suggestions.value = [];
    _isSearching.value = false;
    _hideOverlay();
  }

  void _showOverlay() {
    if (_overlayEntry != null) return;

    final renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox == null) return;
    final width = renderBox.size.width;

    _overlayEntry = OverlayEntry(
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
                constraints: const BoxConstraints(maxHeight: 280),
                child: SingleChildScrollView(
                  child: ValueListenableBuilder<bool>(
                    valueListenable: _isSearching,
                    builder: (_, isSearching, __) {
                      return ValueListenableBuilder<List<Map<String, dynamic>>>(
                        valueListenable: _suggestions,
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
                                .map((s) => _CheckInSuggestionTile(
                                      documentNumber: s['document_number'] as String,
                                      firstName: s['first_name'] as String? ?? '',
                                      lastName: s['last_name'] as String? ?? '',
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
    _focusNode.removeListener(_onFocusChanged);
    _hideOverlay();
    _suggestions.dispose();
    _isSearching.dispose();
    _controller.dispose();
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
          color: colors.primaryContainer.withValues(alpha: isActive ? 0.3 : 0.1),
          borderRadius: BorderRadius.circular(6),
        ),
        child: TextField(
          controller: _controller,
          focusNode: _focusNode,
          onChanged: _onChanged,
          textInputAction: TextInputAction.search,
          style: TextStyle(color: colors.onSurface),
          cursorColor: colors.primary,
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9]')),
            LengthLimitingTextInputFormatter(10),
          ],
          decoration: InputDecoration(
            prefixIcon: Icon(Icons.contact_page_outlined, color: colors.primary),
            suffixIcon: _controller.text.isNotEmpty
                ? IconButton(
                    icon: Icon(Icons.close, color: colors.primary),
                    onPressed: _clear,
                  )
                : null,
            labelText: 'Document Number',
            labelStyle: TextStyle(color: colors.onSurfaceVariant),
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
    );
  }
}

class _CheckInSuggestionTile extends StatefulWidget {
  final String documentNumber;
  final String firstName;
  final String lastName;
  final VoidCallback onTap;

  const _CheckInSuggestionTile({
    required this.documentNumber,
    required this.firstName,
    required this.lastName,
    required this.onTap,
  });

  @override
  State<_CheckInSuggestionTile> createState() => _CheckInSuggestionTileState();
}

class _CheckInSuggestionTileState extends State<_CheckInSuggestionTile> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          decoration: BoxDecoration(
            color: colors.primaryContainer.withValues(alpha: _isHovered ? 0.3 : 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: InkWell(
            onTap: widget.onTap,
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                children: [
                  Icon(Icons.contact_page_outlined, color: colors.primary, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Row(
                      children: [
                        Text(
                          widget.documentNumber,
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: colors.onSurface,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '— ${widget.firstName} ${widget.lastName}',
                          style: TextStyle(
                            color: colors.onSurfaceVariant,
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