import 'package:flutter/material.dart';

class CheckInPassengerSearchBar extends StatefulWidget {
  final ValueChanged<String> onChanged;
  final VoidCallback? onClear;

  const CheckInPassengerSearchBar({
    super.key,
    required this.onChanged,
    this.onClear,
  });

  @override
  State<CheckInPassengerSearchBar> createState() =>
      _CheckInPassengerSearchBarState();
}

class _CheckInPassengerSearchBarState
    extends State<CheckInPassengerSearchBar> {
  final _controller = TextEditingController();
  final _focusNode  = FocusNode();

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _clear() {
    _controller.clear();
    widget.onChanged('');
    widget.onClear?.call();
  }

  @override
  Widget build(BuildContext context) {
    final colors   = Theme.of(context).colorScheme;
    final isActive = _focusNode.hasFocus;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      width: 400,
      decoration: BoxDecoration(
        color: colors.primaryContainer
            .withValues(alpha: isActive ? 0.3 : 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: TextField(
        controller:      _controller,
        focusNode:       _focusNode,
        onChanged:       widget.onChanged,
        style:           TextStyle(fontSize: 13, color: colors.onSurface),
        cursorColor:     colors.primary,
        textInputAction: TextInputAction.search,
        decoration: InputDecoration(
          prefixIcon: Icon(Icons.search,
              size: 18, color: colors.onSurfaceVariant),
          suffixIcon: _controller.text.isNotEmpty
              ? IconButton(
                  icon: Icon(Icons.close,
                      size: 16, color: colors.onSurfaceVariant),
                  onPressed: _clear,
                )
              : null,
          hintText:  'Search by name',
          hintStyle: TextStyle(
              fontSize: 13, color: colors.onSurfaceVariant),
          border:        InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          fillColor:     Colors.transparent,
          isDense:       true,
          contentPadding: const EdgeInsets.symmetric(
              horizontal: 12, vertical: 10),
        ),
        onTap: () => setState(() {}),
      ),
    );
  }
}