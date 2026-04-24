import 'package:flutter/material.dart';

class BookingSearchBar extends StatefulWidget {
  final ValueChanged<String> onChanged;
  final String value;

  const BookingSearchBar({
    super.key,
    required this.onChanged,
    this.value = '',
  });

  @override
  State<BookingSearchBar> createState() => _BookingSearchBarState();
}

class _BookingSearchBarState extends State<BookingSearchBar> {
  late final TextEditingController _ctrl;
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.value);
    _focusNode.addListener(() => setState(() {}));
  }

  @override
  void didUpdateWidget(BookingSearchBar old) {
    super.didUpdateWidget(old);
    if (widget.value != old.value && _ctrl.text != widget.value) {
      _ctrl.text = widget.value;
    }
  }

  void _clear() {
    _ctrl.clear();
    widget.onChanged('');
  }

  @override
  void dispose() {
    _focusNode.dispose();
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final isActive = _focusNode.hasFocus;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      decoration: BoxDecoration(
        color: colors.primaryContainer.withValues(alpha: isActive ? 0.3 : 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: TextField(
        controller: _ctrl,
        focusNode: _focusNode,
        onChanged: widget.onChanged,
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
          labelText: 'Search by booking #, city or passenger name',
          labelStyle: TextStyle(color: colors.onSurfaceVariant),
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          fillColor: Colors.transparent,
          isDense: true,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
      ),
    );
  }
}