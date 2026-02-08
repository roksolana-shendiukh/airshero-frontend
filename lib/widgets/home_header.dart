import 'package:flutter/material.dart';
import 'theme_switch_button.dart';
import 'avatar.dart';

class HomeHeader extends StatelessWidget implements PreferredSizeWidget {
  final bool isLightTheme;
  final VoidCallback onThemeChanged;

  const HomeHeader({
    super.key,
    required this.isLightTheme,
    required this.onThemeChanged,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Text(
        'AirShero',
        style: Theme.of(context).textTheme.titleLarge,
      ),
      actions: [
        ThemeSwitchButton(
          isLightTheme: isLightTheme,
          onThemeChanged: onThemeChanged,
        ),
        const SizedBox(width: 12),
        const Avatar(radius: 20),
        const SizedBox(width: 12),
        Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () => Scaffold.of(context).openEndDrawer(),
          ),
        ),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}