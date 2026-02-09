import 'package:flutter/material.dart';

class ThemeNotifier extends InheritedWidget {
  final bool isLightTheme;
  final VoidCallback toggleTheme;

  const ThemeNotifier({
    super.key,
    required this.isLightTheme,
    required this.toggleTheme,
    required super.child,
  });

  static ThemeNotifier? of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<ThemeNotifier>();
  }

  @override
  bool updateShouldNotify(ThemeNotifier oldWidget) {
    return isLightTheme != oldWidget.isLightTheme;
  }
}