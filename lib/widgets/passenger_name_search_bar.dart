import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:async';
import '../../models/passenger_model.dart';
import '../../services/passenger_api_service.dart';
import '../../services/auth_service.dart';

class PassengerNameSearchBar extends StatefulWidget {
  final AuthService authService;
  final void Function(PassengerModel passenger) onPassengerFound;
  final void Function() onClear;
  final void Function()? onNotFound;
  final String? passengerType;
  final DateTime? departDate;

  const PassengerNameSearchBar({
    super.key,
    required this.authService,
    required this.onPassengerFound,
    required this.onClear,
    this.onNotFound,
    this.passengerType,
    this.departDate,
  });

  @override
  State<PassengerNameSearchBar> createState() => _PassengerNameSearchBarState();
}

class _PassengerNameSearchBarState extends State<PassengerNameSearchBar> {
  final _controller = TextEditingController();
  final _focusNode  = FocusNode();
  final _layerLink  = LayerLink();

  final ValueNotifier<List<PassengerModel>> _suggestionsNotifier = ValueNotifier([]);
  final ValueNotifier<bool> _isSearchingNotifier = ValueNotifier(false);

  OverlayEntry? _overlayEntry;
  Timer? _debounce;
  bool _notFound = false;

  @override
  void initState() {
    super.initState();
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
    _debounce?.cancel();
    setState(() => _notFound = false);

    if (value.trim().length < 2) {
      _suggestionsNotifier.value = [];
      _isSearchingNotifier.value = false;
      _hideOverlay();
      return;
    }

    _isSearchingNotifier.value = true;
    _showOverlay();

    _debounce = Timer(const Duration(milliseconds: 350), () async {
      final api     = PassengerApiService(widget.authService);
      final results = await api.searchPassengers(
        value.trim(),
        passengerType: widget.passengerType,
        departDate:    widget.departDate,
      );

      if (!mounted) return;
      _suggestionsNotifier.value = results;
      _isSearchingNotifier.value = false;

      if (results.isEmpty) {
        _hideOverlay();
        setState(() => _notFound = true);
        widget.onNotFound?.call();
      }
    });
  }

  void _selectPassenger(PassengerModel p) {
    _controller.text = '${p.firstName} ${p.lastName}';
    _hideOverlay();
    _focusNode.unfocus();
    setState(() => _notFound = false);
    widget.onPassengerFound(p);
  }

  void _clear() {
    _controller.clear();
    _suggestionsNotifier.value = [];
    _isSearchingNotifier.value = false;
    setState(() => _notFound = false);
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
                      if (isSearching) {
                        return const Padding(
                          padding: EdgeInsets.all(16),
                          child: Center(child: CircularProgressIndicator()),
                        );
                      }
                      return ValueListenableBuilder<List<PassengerModel>>(
                        valueListenable: _suggestionsNotifier,
                        builder: (_, suggestions, __) {
                          if (suggestions.isEmpty) return const SizedBox.shrink();
                          return Column(
                            children: suggestions.map((p) {
                              final dob = p.dateOfBirth != null
                                  ? DateFormat('dd.MM.yyyy').format(
                                      p.dateOfBirth is DateTime
                                          ? p.dateOfBirth as DateTime
                                          : DateTime.parse(p.dateOfBirth.toString()),
                                    )
                                  : '—';
                              return _PassengerTile(
                                firstName: p.firstName,
                                lastName:  p.lastName,
                                dob:       dob,
                                onTap:     () => _selectPassenger(p),
                              );
                            }).toList(),
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
    _debounce?.cancel();
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
    final colors   = Theme.of(context).colorScheme;
    final isActive = _focusNode.hasFocus;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CompositedTransformTarget(
          link: _layerLink,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            decoration: BoxDecoration(
              color: colors.primaryContainer.withValues(alpha: isActive ? 0.3 : 0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: TextField(
              controller: _controller,
              focusNode:  _focusNode,
              onChanged:  _onChanged,
              style:       TextStyle(color: colors.onSurface),
              cursorColor: colors.primary,
              decoration: InputDecoration(
                prefixIcon: Icon(Icons.person_search_outlined, color: colors.primary),
                suffixIcon: _controller.text.isNotEmpty
                    ? IconButton(
                        icon: Icon(Icons.close, color: colors.primary),
                        onPressed: _clear,
                      )
                    : null,
                labelText:  'Search passenger by name',
                labelStyle: TextStyle(color: colors.onSurfaceVariant),
                border:        InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                fillColor:     Colors.transparent,
                isDense:       true,
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 16),
              ),
            ),
          ),
        ),

        if (_notFound) ...[
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.only(left: 4),
            child: Row(
              children: [
                Icon(Icons.info_outline, size: 14, color: colors.onSurfaceVariant),
                const SizedBox(width: 6),
                Text(
                  'Passenger not found — form is ready for manual input',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colors.onSurfaceVariant,
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

class _PassengerTile extends StatefulWidget {
  final String firstName;
  final String lastName;
  final String dob;
  final VoidCallback onTap;

  const _PassengerTile({
    required this.firstName,
    required this.lastName,
    required this.dob,
    required this.onTap,
  });

  @override
  State<_PassengerTile> createState() => _PassengerTileState();
}

class _PassengerTileState extends State<_PassengerTile> {
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
            color: colors.primaryContainer.withValues(
                alpha: _isHovered ? 0.3 : 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: InkWell(
            onTap: widget.onTap,
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                children: [
                  Icon(Icons.person_outline, color: colors.primary, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      '${widget.firstName} ${widget.lastName}',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: colors.onSurface,
                      ),
                    ),
                  ),
                  Text(
                    widget.dob,
                    style: TextStyle(
                        fontSize: 12, color: colors.onSurfaceVariant),
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