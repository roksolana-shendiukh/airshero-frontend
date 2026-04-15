import 'package:flutter/material.dart';

class StatusBadge extends StatelessWidget {
  final String label;
  final Color  color;

  const StatusBadge({super.key, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color:        color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border:       Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize:   11,
          fontWeight: FontWeight.w600,
          color:      color,
        ),
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}

class ActiveChip extends StatelessWidget {
  final String       label;
  final VoidCallback onClear;
  final ColorScheme  colors;

  const ActiveChip({
    super.key,
    required this.label,
    required this.onClear,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color:        colors.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colors.primary.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label,
              style: TextStyle(
                fontSize:   11,
                fontWeight: FontWeight.w500,
                color:      colors.primary,
              )),
          const SizedBox(width: 5),
          GestureDetector(
            onTap: onClear,
            child: Icon(Icons.close_rounded, size: 13, color: colors.primary),
          ),
        ],
      ),
    );
  }
}

class ActionBtn extends StatefulWidget {
  final String       label;
  final IconData     icon;
  final bool         primary;
  final VoidCallback onTap;
  final ColorScheme  colors;

  const ActionBtn({
    super.key,
    required this.label,
    required this.icon,
    required this.primary,
    required this.onTap,
    required this.colors,
  });

  @override
  State<ActionBtn> createState() => _ActionBtnState();
}

class _ActionBtnState extends State<ActionBtn> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final color = widget.primary
        ? widget.colors.primary
        : widget.colors.onSurfaceVariant;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit:  (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 130),
          padding:  const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: widget.primary
                ? (_hovered
                    ? color.withValues(alpha: 0.18)
                    : color.withValues(alpha: 0.1))
                : (_hovered
                    ? widget.colors.surfaceContainerHighest
                    : Colors.transparent),
            borderRadius: BorderRadius.circular(7),
            border: Border.all(
              color: widget.primary
                  ? color.withValues(alpha: _hovered ? 0.5 : 0.3)
                  : widget.colors.outlineVariant,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(widget.icon, size: 13, color: color),
              const SizedBox(width: 5),
              Text(widget.label,
                  style: TextStyle(
                    fontSize:   12,
                    fontWeight: FontWeight.w500,
                    color:      color,
                  )),
            ],
          ),
        ),
      ),
    );
  }
}


class IconBtn extends StatelessWidget {
  final IconData     icon;
  final String       tooltip;
  final VoidCallback onTap;
  final ColorScheme  colors;

  const IconBtn({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onTap,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width:  36,
          height: 36,
          decoration: BoxDecoration(
            color: colors.surfaceContainerHighest.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: colors.outlineVariant),
          ),
          child: Icon(icon, size: 17, color: colors.onSurfaceVariant),
        ),
      ),
    );
  }
}

class PageBtn extends StatelessWidget {
  final IconData     icon;
  final bool         enabled;
  final VoidCallback onTap;
  final ColorScheme  colors;

  const PageBtn({
    super.key,
    required this.icon,
    required this.enabled,
    required this.onTap,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        width:  28,
        height: 28,
        decoration: BoxDecoration(
          color: colors.surfaceContainerHighest.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: colors.outlineVariant),
        ),
        child: Icon(icon,
            size:  16,
            color: enabled
                ? colors.onSurface
                : colors.onSurfaceVariant.withValues(alpha: 0.3)),
      ),
    );
  }
}