import 'package:flutter/material.dart';
import '../config/theme_notifier.dart';

class ResponsiveLayout extends StatelessWidget {
  final Widget? header; // ← ДОДАНО: Опціональний фіксований header
  final Widget body;

  const ResponsiveLayout({
    super.key,
    this.header,
    required this.body,
  });

  @override
  Widget build(BuildContext context) {
    final bool isLargeScreen = MediaQuery.of(context).size.width >= 1024;
    final themeNotifier = ThemeNotifier.of(context);
    final isLightTheme = themeNotifier?.isLightTheme ?? true;

    return Scaffold(
      drawer: isLargeScreen ? null : _buildDrawer(context),
      body: Column(
        children: [
          /// ===== APP BAR =====
          AppBar(
            elevation: 0,
            leading: isLargeScreen
                ? Padding(
                    padding: const EdgeInsets.all(8),
                    child: Icon(
                      Icons.flight,
                      color: Theme.of(context).colorScheme.primary,
                      size: 32,
                    ),
                  )
                : Builder(
                    builder: (context) => IconButton(
                      icon: const Icon(Icons.menu),
                      onPressed: () => Scaffold.of(context).openDrawer(),
                    ),
                  ),
            title: const Text('AirShero'),
            actions: [
              IconButton(
                icon: Icon(
                  isLightTheme ? Icons.dark_mode : Icons.light_mode,
                ),
                onPressed: () {
                  themeNotifier?.toggleTheme();
                },
              ),
              const SizedBox(width: 8),
              Padding(
                padding: const EdgeInsets.only(right: 16),
                child: CircleAvatar(
                  radius: 18,
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  child: Icon(
                    Icons.person,
                    color: Theme.of(context).colorScheme.onPrimary,
                  ),
                ),
              ),
            ],
          ),

          /// ===== MAIN CONTENT =====
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (isLargeScreen) _buildSidebar(context),
                Expanded(
                  child: Column(
                    children: [
                      // ФІКСОВАНИЙ HEADER (якщо є)
                      if (header != null) header!,
                      
                      // СКРОЛЮВАНИЙ КОНТЕНТ
                      Expanded(
                        child: SingleChildScrollView(
                          child: body,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawer(BuildContext context) {
    return Drawer(
      child: _buildMenuContent(context),
    );
  }

  Widget _buildSidebar(BuildContext context) {
    return Container(
      width: 280,
      color: Theme.of(context).colorScheme.surfaceContainerHigh,
      child: _buildMenuContent(context),
    );
  }

  Widget _buildMenuContent(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 16),
      children: [
        HoverableMenuItem(
          icon: Icons.book_online,
          title: 'My Bookings',
          onTap: () {
            if (Navigator.canPop(context)) Navigator.pop(context);
          },
        ),
        HoverableMenuItem(
          icon: Icons.flight,
          title: 'Flights',
          onTap: () {},
        ),
        HoverableMenuItem(
          icon: Icons.settings,
          title: 'Settings',
          onTap: () {},
        ),
      ],
    );
  }
}

class HoverableMenuItem extends StatefulWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  const HoverableMenuItem({
    required this.icon,
    required this.title,
    required this.onTap,
    super.key,
  });

  @override
  State<HoverableMenuItem> createState() => _HoverableMenuItemState();
}

class _HoverableMenuItemState extends State<HoverableMenuItem> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: InkWell(
          onTap: widget.onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            decoration: BoxDecoration(
              color: _isHovered
                  ? Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.3)
                  : Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.1),
            ),
            child: Row(
              children: [
                Icon(widget.icon, size: 24, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 16),
                Text(
                  widget.title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}