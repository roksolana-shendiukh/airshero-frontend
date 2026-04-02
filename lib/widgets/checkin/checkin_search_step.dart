import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../../services/auth_service.dart';
import '../../services/checkin_api_service.dart';
import '../custom/custom_button.dart';

part 'checkin_validators.dart';

class CheckInSearchStep extends StatefulWidget {
  final AuthService authService;
  final String      flightNumber;
  final DateTime    departDate;
  final void Function({
    required String documentNumber,
    required String flightNumber,
    required DateTime departDate,
    required Map<String, dynamic> booking,
  }) onSearch;

  const CheckInSearchStep({
    super.key,
    required this.authService,
    required this.flightNumber,
    required this.departDate,
    required this.onSearch,
  });

  @override
  State<CheckInSearchStep> createState() => _CheckInSearchStepState();
}

class _CheckInSearchStepState extends State<CheckInSearchStep> {
  late TextEditingController _controller;
  final _focusNode = FocusNode();
  final _layerLink = LayerLink();

  final ValueNotifier<List<Map<String, dynamic>>> _suggestionsNotifier =
      ValueNotifier([]);
  final ValueNotifier<bool> _isSearchingNotifier = ValueNotifier(false);

  bool    _documentNumberTouched = false;
  bool    _isLoading             = false;
  String? _apiError;

  OverlayEntry? _overlayEntry;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
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

  // ── Suggestions ───────────────────────────────────────────────────────────

  Future<void> _onChanged(String value) async {
    final upper = value.toUpperCase();
    _controller.value = TextEditingValue(
      text:      upper,
      selection: TextSelection.collapsed(offset: upper.length),
    );

    setState(() {
      _documentNumberTouched = upper.isNotEmpty;
      _apiError              = null;
    });

    if (upper.trim().length < 2) {
      _suggestionsNotifier.value = [];
      _isSearchingNotifier.value = false;
      _hideOverlay();
      return;
    }

    _isSearchingNotifier.value = true;
    _showOverlay();

    try {
      final api     = CheckInApiService(widget.authService);
      final results = await api.getFlightPassengerSuggestions(
        query:        upper.trim(),
        flightNumber: widget.flightNumber,
        departsDate:  widget.departDate,
      );
      if (!mounted) return;
      _suggestionsNotifier.value = results;
      _isSearchingNotifier.value = false;
      if (results.isEmpty) _hideOverlay();
    } catch (_) {
      if (!mounted) return;
      _isSearchingNotifier.value = false;
      _hideOverlay();
    }
  }

  Future<void> _selectSuggestion(Map<String, dynamic> suggestion) async {
    final doc = (suggestion['document_number'] as String? ?? '').toUpperCase();
    if (doc.isEmpty) return;
    _controller.text = doc;
    _hideOverlay();
    _focusNode.unfocus();
    await _handleSearch(docNumber: doc);
  }

  Future<void> _onSubmitted(String value) async {
    final query = value.trim().toUpperCase();
    if (query.isEmpty) return;

    if (_suggestionsNotifier.value.isNotEmpty) {
      await _selectSuggestion(_suggestionsNotifier.value.first);
    } else {
      _hideOverlay();
      _focusNode.unfocus();
      await _handleSearch(docNumber: query);
    }
  }

  // ── Search ────────────────────────────────────────────────────────────────

  Future<void> _handleSearch({String? docNumber}) async {
    final doc = (docNumber ?? _controller.text).trim().toUpperCase();

    setState(() {
      _documentNumberTouched = true;
      _apiError              = null;
    });

    if (doc.isEmpty) return;

    setState(() => _isLoading = true);

    try {
      final api     = CheckInApiService(widget.authService);
      final results = await api.searchBooking(
        documentNumber: doc,
        flightNumber:   widget.flightNumber,
        departsDate:    widget.departDate,
      );

      if (!mounted) return;

      if (results.isEmpty) {
        setState(() =>
            _apiError = 'Booking not found. Check the document number.');
        return;
      }

      widget.onSearch(
        documentNumber: doc,
        flightNumber:   widget.flightNumber,
        departDate:     widget.departDate,
        booking:        results.first,
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _apiError = 'Connection error. Please try again.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _clear() {
    _controller.clear();
    _suggestionsNotifier.value = [];
    _isSearchingNotifier.value = false;
    setState(() {
      _documentNumberTouched = false;
      _apiError              = null;
    });
    _hideOverlay();
  }

  // ── Overlay ───────────────────────────────────────────────────────────────

  void _showOverlay() {
    if (_overlayEntry != null) return;

    final renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox == null) return;
    final width = renderBox.size.width;

    _overlayEntry = OverlayEntry(
      builder: (ctx) => CompositedTransformFollower(
        link:             _layerLink,
        showWhenUnlinked: false,
        offset:           const Offset(0, 56),
        child: Align(
          alignment: Alignment.topLeft,
          child: SizedBox(
            width: width,
            child: Material(
              color:        Theme.of(ctx).colorScheme.surface,
              borderRadius: BorderRadius.circular(8),
              elevation:    4,
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
                              child: Center(
                                  child: CircularProgressIndicator()),
                            );
                          }

                          final filtered = suggestions
                              .where((s) =>
                                  (s['document_number'] as String?)
                                      ?.isNotEmpty ??
                                  false)
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

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final colors   = Theme.of(context).colorScheme;
    final isActive = _focusNode.hasFocus;

    return Container(
      margin:  const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color:        colors.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          // ── Рейс і дата ─────────────────────────────────────
          Row(
            children: [
              Expanded(
                child: _InfoChip(
                  icon:  Icons.flight_outlined,
                  label: 'Flight',
                  value: widget.flightNumber,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _InfoChip(
                  icon:  Icons.calendar_today_outlined,
                  label: 'Date',
                  value: DateFormat('MMM d, yyyy').format(widget.departDate),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // ── Поле документа з overlay ─────────────────────────
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
                controller:      _controller,
                focusNode:       _focusNode,
                onChanged:       _onChanged,
                onSubmitted:     _onSubmitted,
                textInputAction: TextInputAction.search,
                style:           TextStyle(color: colors.onSurface),
                cursorColor:     colors.primary,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9]')),
                  LengthLimitingTextInputFormatter(10),
                ],
                decoration: InputDecoration(
                  prefixIcon: Icon(
                    Icons.contact_page_outlined,
                    color: colors.primary,
                  ),
                  suffixIcon: _isLoading
                      ? Padding(
                          padding: const EdgeInsets.all(12),
                          child: SizedBox(
                            width:  20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: colors.primary,
                            ),
                          ),
                        )
                      : _controller.text.isNotEmpty
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
          ),

          // ── API error ────────────────────────────────────────
          if (_apiError != null) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color:        colors.errorContainer.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: colors.error.withValues(alpha: 0.3),
                  width: 0.5,
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, size: 16, color: colors.error),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _apiError!,
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(color: colors.error),
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 16),

          // ── Submit ───────────────────────────────────────────
          SizedBox(
            width: double.infinity,
            child: CustomButton(
              label: _isLoading ? 'Searching...' : 'Find Booking',
              onPressed: (_isFormValid && !_isLoading)
                  ? () => _handleSearch()
                  : null,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Info chip ─────────────────────────────────────────────────────────────────

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String   label;
  final String   value;

  const _InfoChip({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color:        colors.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: colors.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color:    colors.onSurfaceVariant,
                        fontSize: 11,
                      ),
                ),
                Text(
                  value,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color:      colors.onSurface,
                      ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Suggestion tile ───────────────────────────────────────────────────────────

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