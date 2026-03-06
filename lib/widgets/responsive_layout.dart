import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../config/theme_notifier.dart';
import '../services/auth_service.dart';
import '../models/user_model.dart';

class ResponsiveLayout extends StatelessWidget {
  final Widget? header;
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

    return Consumer<AuthService>(
      builder: (context, authService, _) {
        final currentUser = authService.currentUser;

        return Scaffold(
          drawer: isLargeScreen ? null : _buildDrawer(context, currentUser),
          body: Column(
            children: [
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
                title: GestureDetector(
                  onTap: () => context.go('/sales/bookings'),
                  child: MouseRegion(
                    cursor: SystemMouseCursors.click,
                    child: Text(_getAppBarTitle(currentUser?.role)),
                  ),
                ),
                actions: [
                  IconButton(
                    icon: Icon(
                      isLightTheme ? Icons.dark_mode : Icons.light_mode,
                    ),
                    onPressed: () => themeNotifier?.toggleTheme(),
                  ),
                  const SizedBox(width: 8),
                  if (currentUser != null)
                    PopupMenuButton<String>(
                      icon: CircleAvatar(
                        radius: 18,
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        child: Text(
                          currentUser.firstName.isNotEmpty
                              ? currentUser.firstName[0].toUpperCase()
                              : currentUser.email[0].toUpperCase(),
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onPrimary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      itemBuilder: (context) => [
                        PopupMenuItem(
                          enabled: false,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                currentUser.fullName,
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              Text(
                                currentUser.role.displayName,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const PopupMenuDivider(),
                        const PopupMenuItem(
                          value: 'logout',
                          child: Row(
                            children: [
                              Icon(Icons.logout, size: 20, color: Colors.red),
                              SizedBox(width: 12),
                              Text('Logout',
                                  style: TextStyle(color: Colors.red)),
                            ],
                          ),
                        ),
                      ],
                      onSelected: (value) {
                        if (value == 'logout') {
                          authService.logout();
                          context.go('/');
                        }
                      },
                    ),
                  const SizedBox(width: 16),
                ],
              ),

              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (isLargeScreen) _buildSidebar(context, currentUser),
                    Expanded(
                      child: Column(
                        children: [
                          if (header != null) header!,
                          Expanded(child: body),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  String _getAppBarTitle(UserRole? role) {
    if (role == null) return 'AirShero';
    switch (role) {
      case UserRole.salesAgent:
        return 'AirShero Sales';
      case UserRole.checkInAgent:
        return 'AirShero Check-In';
      case UserRole.flightOperator:
        return 'AirShero Operations';
      case UserRole.planningManager:
        return 'AirShero Planning';
      case UserRole.systemAdmin:
        return 'AirShero Admin';
    }
  }

  Widget _buildDrawer(BuildContext context, UserModel? currentUser) {
    return Drawer(
      child: _buildMenuContent(context, currentUser),
    );
  }

  Widget _buildSidebar(BuildContext context, UserModel? currentUser) {
    return Container(
      width: 280,
      color: Theme.of(context).colorScheme.surfaceContainerHigh,
      child: SingleChildScrollView(
        physics: const NeverScrollableScrollPhysics(),
        child: _buildMenuContent(context, currentUser),
      ),
    );
  }

  Widget _buildMenuContent(BuildContext context, UserModel? currentUser) {
    if (currentUser == null) {
      return _buildGuestMenu(context);
    }

    final currentPath = GoRouterState.of(context).uri.path;
    final menuItems = currentUser.role.menuItems;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  currentUser.role.displayName.toUpperCase(),
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  currentUser.fullName,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface,
                        fontWeight: FontWeight.w500,
                      ),
                ),
              ],
            ),
          ),
          const Divider(height: 24),
          ...menuItems.map((item) => HoverableMenuItem(
                icon: item.icon,
                title: item.title,
                isActive: currentPath == item.route,
                onTap: () {
                  if (Navigator.canPop(context)) Navigator.pop(context);
                  context.go(item.route);
                },
              )),
        ],
      ),
    );
  }

  Widget _buildGuestMenu(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          HoverableMenuItem(
            icon: Icons.search,
            title: 'Search Flights',
            onTap: () {
              if (Navigator.canPop(context)) Navigator.pop(context);
              context.go('/');
            },
          ),
        ],
      ),
    );
  }
}

class HoverableMenuItem extends StatefulWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final bool isActive;

  const HoverableMenuItem({
    required this.icon,
    required this.title,
    required this.onTap,
    this.isActive = false,
    super.key,
  });

  @override
  State<HoverableMenuItem> createState() => _HoverableMenuItemState();
}

class _HoverableMenuItemState extends State<HoverableMenuItem> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final isActive = widget.isActive;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: InkWell(
          onTap: widget.onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            decoration: BoxDecoration(
              color: isActive
                  ? Theme.of(context)
                      .colorScheme
                      .primaryContainer
                      .withValues(alpha: 0.5)
                  : _isHovered
                      ? Theme.of(context)
                          .colorScheme
                          .primaryContainer
                          .withValues(alpha: 0.3)
                      : Theme.of(context)
                          .colorScheme
                          .primaryContainer
                          .withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(
                  widget.icon,
                  size: 24,
                  color: isActive
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).colorScheme.onSurface,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    widget.title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight:
                          isActive ? FontWeight.bold : FontWeight.w500,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
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