import 'package:flutter/material.dart';
import '../../models/passenger_model.dart';
import '../../services/passenger_api_service.dart';
import '../../services/auth_service.dart';

class PassengerSearchBar extends StatefulWidget {
  final AuthService authService;
  final void Function(PassengerModel passenger) onPassengerFound;
  final void Function() onClear;
  final String? initialDocumentNumber;
  final Set<String> usedDocumentNumbers;
  final ValueChanged<String>? onTextChanged;

  const PassengerSearchBar({
    super.key,
    required this.authService,
    required this.onPassengerFound,
    required this.onClear,
    this.initialDocumentNumber,
    this.usedDocumentNumbers = const {},
    this.onTextChanged,
  });

  @override
  State<PassengerSearchBar> createState() => _PassengerSearchBarState();
}

class _PassengerSearchBarState extends State<PassengerSearchBar> {
  late TextEditingController _controller;
  final _focusNode = FocusNode();
  final _layerLink = LayerLink();

  final ValueNotifier<List<Map<String, dynamic>>> _suggestionsNotifier =
      ValueNotifier([]);
  final ValueNotifier<bool> _isSearchingNotifier = ValueNotifier(false);

  bool _isLoadingPassenger = false;
  bool _notFound = false;
  bool _duplicateError = false;
  OverlayEntry? _overlayEntry;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialDocumentNumber ?? '');
    _focusNode.addListener(_onFocusChanged);
  }

  void _onFocusChanged() {
    setState(() {});
    if (_focusNode.hasFocus) {
      if (_suggestionsNotifier.value.isNotEmpty || _isSearchingNotifier.value) {
        _showOverlay();
      }
    } else {
      Future.delayed(const Duration(milliseconds: 200), _hideOverlay);
    }
  }

  Future<void> _onChanged(String value) async {
    widget.onTextChanged?.call(value); 
    setState(() {
      _notFound = false;
      _duplicateError = false;
    });
    widget.onClear();

    if (value.trim().length < 2) {
      _suggestionsNotifier.value = [];
      _isSearchingNotifier.value = false;
      _hideOverlay();
      return;
    }

    _isSearchingNotifier.value = true;
    _showOverlay();

    final api = PassengerApiService(widget.authService);
    final results = await api.getDocumentSuggestions(value.trim());

    if (!mounted) return;

    _suggestionsNotifier.value = results;
    _isSearchingNotifier.value = false;

    if (results.isEmpty) _hideOverlay();
  }

  Future<void> _selectSuggestion(Map<String, dynamic> suggestion) async {
    final docNumber = (suggestion['document_number'] as String?) ?? '';
    if (docNumber.isEmpty) return;
    _controller.text = docNumber;
    _hideOverlay();
    _focusNode.unfocus();
    await _fetchPassenger(docNumber);
  }

  Future<void> _onSubmitted(String value) async {
    final query = value.trim();
    if (query.isEmpty) return;

    if (_suggestionsNotifier.value.isNotEmpty) {
      _selectSuggestion(_suggestionsNotifier.value.first);
    } else {
      _hideOverlay();
      _focusNode.unfocus();
      await _fetchPassenger(query);
    }
  }

  Future<void> _fetchPassenger(String docNumber) async {
    if (widget.usedDocumentNumbers.contains(docNumber)) {
      setState(() {
        _isLoadingPassenger = false;
        _notFound = false;
        _duplicateError = true;
      });
      widget.onClear();
      return;
    }

    setState(() {
      _isLoadingPassenger = true;
      _notFound = false;
      _duplicateError = false;
    });

    widget.onClear();

    final api = PassengerApiService(widget.authService);
    final passenger = await api.searchPassengerByDocument(docNumber);

    if (!mounted) return;
    setState(() {
      _isLoadingPassenger = false;
      _notFound = passenger == null;
    });

    if (passenger != null) {
      widget.onPassengerFound(passenger);
    }
  }

  void _clear() {
    _controller.clear();
    widget.onTextChanged?.call('');
    _suggestionsNotifier.value = [];
    _isSearchingNotifier.value = false;
    setState(() {
      _notFound = false;
      _duplicateError = false;
    });
    _hideOverlay();
    widget.onClear();
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
    _suggestionsNotifier.dispose();
    _isSearchingNotifier.dispose();
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final isActive = _focusNode.hasFocus;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CompositedTransformTarget(
          link: _layerLink,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            decoration: BoxDecoration(
              color: colors.primaryContainer
                  .withValues(alpha: isActive ? 0.3 : 0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: TextField(
              controller: _controller,
              focusNode: _focusNode,
              onChanged: _onChanged,
              onSubmitted: _onSubmitted,
              textInputAction: TextInputAction.search,
              style: TextStyle(color: colors.onSurface),
              cursorColor: colors.primary,
              decoration: InputDecoration(
                prefixIcon: Icon(Icons.contact_page_outlined, color: colors.primary),
                suffixIcon: _isLoadingPassenger
                    ? Padding(
                        padding: const EdgeInsets.all(12),
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: colors.primary),
                        ),
                      )
                    : _controller.text.isNotEmpty
                        ? IconButton(
                            icon: Icon(Icons.close, color: colors.primary),
                            onPressed: _clear,
                          )
                        : null,
                labelText: 'Search passenger by document number',
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
        ),

        if (_notFound) ...[
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.only(left: 16),
            child: Row(
              children: [
                Icon(Icons.info_outline, size: 14, color: colors.error),
                const SizedBox(width: 6),
                Text(
                  'No passenger found with this document number',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colors.error,
                      ),
                ),
              ],
            ),
          ),
        ],

        if (_duplicateError) ...[
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.only(left: 16),
            child: Row(
              children: [
                Icon(Icons.warning_outlined, size: 14, color: colors.error),
                const SizedBox(width: 6),
                Text(
                  'This document is already used by another passenger',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colors.error,
                      ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _SuggestionTile extends StatefulWidget {
  final String documentNumber;
  final String firstName;
  final String lastName;
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
        onExit: (_) => setState(() => _isHovered = false),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          decoration: BoxDecoration(
            color: colors.primaryContainer
                .withValues(alpha: _isHovered ? 0.3 : 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: InkWell(
            onTap: widget.onTap,
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
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
                            color: colors.onSurface,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '- ${widget.firstName} ${widget.lastName}',
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