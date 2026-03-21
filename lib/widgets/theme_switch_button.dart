import 'package:flutter/material.dart';

class ThemeSwitchButton extends StatelessWidget {
  final bool isLightTheme;
  final VoidCallback onThemeChanged;

  const ThemeSwitchButton({
    super.key,
    required this.isLightTheme,
    required this.onThemeChanged,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(isLightTheme ? Icons.light_mode : Icons.dark_mode),
      tooltip: isLightTheme ? 'Light Theme' : 'Dark Theme',
      onPressed: onThemeChanged,
    );
  }
}