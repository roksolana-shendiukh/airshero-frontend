import 'package:flutter/material.dart';
import '../../models/user_model.dart';

class UserSearchField extends StatefulWidget {
  final List<UserModel> allUsers;
  final String value;
  final ValueChanged<String> onChanged;

  const UserSearchField({
    super.key,
    required this.allUsers,
    required this.value,
    required this.onChanged,
  });

  @override
  State<UserSearchField> createState() => _UserSearchFieldState();
}

class _UserSearchFieldState extends State<UserSearchField> {
  late final TextEditingController _ctrl;
  final FocusNode _focusNode = FocusNode();
  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _overlay;

  List<UserModel> get _suggestions {
    if (_ctrl.text.isEmpty) return [];
    final q = _ctrl.text.toLowerCase();
    return widget.allUsers
        .where((u) =>
            u.fullName.toLowerCase().contains(q) ||
            u.email.toLowerCase().contains(q))
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

  void _select(UserModel user) {
    _ctrl.text = user.fullName;
    widget.onChanged(user.fullName);
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
                constraints: const BoxConstraints(maxHeight: 300),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: _suggestions
                        .map((u) => _UserSuggestionTile(
                              user: u,
                              query: _ctrl.text,
                              onTap: () => _select(u),
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
  void didUpdateWidget(UserSearchField old) {
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
            prefixIcon: Icon(Icons.person_search_outlined, color: colors.primary),
            suffixIcon: _ctrl.text.isNotEmpty
                ? IconButton(
                    icon: Icon(Icons.close, color: colors.primary),
                    onPressed: _clear,
                  )
                : null,
            labelText: 'Search by name or email',
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

class _UserSuggestionTile extends StatefulWidget {
  final UserModel user;
  final String query;
  final VoidCallback onTap;

  const _UserSuggestionTile({
    required this.user,
    required this.query,
    required this.onTap,
  });

  @override
  State<_UserSuggestionTile> createState() => _UserSuggestionTileState();
}

class _UserSuggestionTileState extends State<_UserSuggestionTile> {
  bool _hovered = false;

  Widget _highlightedText(String text, String query, TextStyle baseStyle, Color highlightColor) {
    if (query.isEmpty) return Text(text, style: baseStyle);
    final q = query.toLowerCase();
    final idx = text.toLowerCase().indexOf(q);
    if (idx == -1) return Text(text, style: baseStyle);

    return RichText(
      text: TextSpan(
        style: baseStyle,
        children: [
          TextSpan(text: text.substring(0, idx)),
          TextSpan(
            text: text.substring(idx, idx + query.length),
            style: TextStyle(
              color: highlightColor,
              fontWeight: FontWeight.w700,
            ),
          ),
          TextSpan(text: text.substring(idx + query.length)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

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
                  Icon(Icons.person_outline,
                      size: 18, color: colors.primary),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _highlightedText(
                          widget.user.fullName,
                          widget.query,
                          TextStyle(color: colors.onSurface, fontWeight: FontWeight.w500),
                          colors.primary,
                        ),
                        _highlightedText(
                          widget.user.email,
                          widget.query,
                          TextStyle(color: colors.onSurfaceVariant, fontSize: 12),
                          colors.primary,
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