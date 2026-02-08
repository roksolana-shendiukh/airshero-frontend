import 'package:flutter/material.dart';
import '../config/theme.dart'; 

class Avatar extends StatelessWidget {
  final double radius;
  final String? imageUrl;

  const Avatar({super.key, this.radius = 30, this.imageUrl});

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? DarkColors.surfaceContainerLow : LightColors.surfaceContainerLow;
    final iconColor = isDark ? DarkColors.onSurfaceVariant : LightColors.onSurfaceVariant;

    return CircleAvatar(
      radius: radius,
      backgroundColor: bgColor,
      backgroundImage: imageUrl != null ? NetworkImage(imageUrl!) : null,
      child: imageUrl == null
          ? Icon(Icons.person, size: radius, color: iconColor)
          : null,
    );
  }
}
