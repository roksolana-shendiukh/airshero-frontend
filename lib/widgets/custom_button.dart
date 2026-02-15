import 'package:flutter/material.dart';

class CustomButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final double verticalPadding;
  final double borderRadius;
  final IconData? icon;
  final bool isIconAfterLabel;

  const CustomButton({
    super.key,
    required this.label,
    this.onPressed,
    this.verticalPadding = 20,
    this.borderRadius = 6,
    this.icon,
    this.isIconAfterLabel = true,
  });

  @override
  Widget build(BuildContext context) {
    Widget buttonChild;
    
    if (icon != null) {
      buttonChild = Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (!isIconAfterLabel) ...[
            Icon(icon, size: 20),
            const SizedBox(width: 8),
          ],
          Text(
            label,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (isIconAfterLabel) ...[
            const SizedBox(width: 8),
            Icon(icon, size: 20),
          ],
        ],
      );
    } else {
      buttonChild = Text(
        label,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      );
    }

    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        padding: EdgeInsets.symmetric(vertical: verticalPadding),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadius),
        ),
      ),
      child: buttonChild,
    );
  }
}