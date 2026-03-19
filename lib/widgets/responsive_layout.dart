import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../config/theme_notifier.dart';
import '../services/auth_service.dart';
import '../models/user_model.dart';

class ResponsiveLayout extends StatefulWidget {
  final Widget? header;
  final Widget body;

  const ResponsiveLayout({
    super.key,
    this.header,
    required this.body,
  });

  @override
  State<ResponsiveLayout> createState() => _ResponsiveLayoutState();
}

class _ResponsiveLayoutState extends State<ResponsiveLayout>
    with SingleTickerProviderStateMixin {
  bool _sidebarCollapsed = false;

  static const double _expandedWidth  = 260;
  static const double _collapsedWidth = 60;

  void _toggleSidebar() => setState(() => _sidebarCollapsed = !_sidebarCollapsed);

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
              _buildAppBar(context, authService, currentUser, isLargeScreen, isLightTheme, themeNotifier),
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (isLargeScreen)
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 220),
                        curve: Curves.easeInOut,
                        width: _sidebarCollapsed ? _collapsedWidth : _expandedWidth,
                        child: _buildSidebar(context, currentUser),
                      ),
                    Expanded(
                      child: Column(
                        children: [
                          if (widget.header != null) widget.header!,
                          Expanded(child: widget.body),
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

  PreferredSizeWidget _buildAppBar(
    BuildContext context,
    AuthService authService,
    UserModel? currentUser,
    bool isLargeScreen,
    bool isLightTheme,
    ThemeNotifier? themeNotifier,
  ) {
    final colors = Theme.of(context).colorScheme;

    return AppBar(
      elevation: 0,
      leading: isLargeScreen
          ? Padding(
              padding: const EdgeInsets.all(8),
              child: Icon(Icons.flight, color: colors.primary, size: 32),
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
          icon: Icon(isLightTheme ? Icons.dark_mode : Icons.light_mode),
          onPressed: () => themeNotifier?.toggleTheme(),
        ),
        const SizedBox(width: 8),
        if (currentUser != null)
          PopupMenuButton<String>(
            icon: CircleAvatar(
              radius: 18,
              backgroundColor: colors.primary,
              child: Text(
                currentUser.firstName.isNotEmpty
                    ? currentUser.firstName[0].toUpperCase()
                    : currentUser.email[0].toUpperCase(),
                style: TextStyle(
                  color: colors.onPrimary,
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
                    Text(currentUser.fullName,
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                    Text(
                      currentUser.role.displayName,
                      style: TextStyle(
                          fontSize: 12, color: colors.onSurfaceVariant),
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
                    Text('Logout', style: TextStyle(color: Colors.red)),
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
    );
  }

  Widget _buildDrawer(BuildContext context, UserModel? currentUser) {
    return Drawer(
      child: _buildMenuContent(
        context,
        currentUser,
        collapsed: false,
        onClose: () => Navigator.of(context).pop(),
      ),
    );
  }

  Widget _buildSidebar(BuildContext context, UserModel? currentUser) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      color: colors.surfaceContainerHigh,
      child: SingleChildScrollView(
        physics: const NeverScrollableScrollPhysics(),
        child: _buildMenuContent(
          context,
          currentUser,
          collapsed: _sidebarCollapsed,
          onClose: _toggleSidebar,
        ),
      ),
    );
  }

  Widget _buildMenuContent(
    BuildContext context,
    UserModel? currentUser, {
    required bool collapsed,
    VoidCallback? onClose,
  }) {
    if (currentUser == null) return _buildGuestMenu(context, collapsed: collapsed);

    final currentPath = GoRouterState.of(context).uri.path;
    final menuItems = currentUser.role.menuItems;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (!collapsed) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 8, 12),
              child: Row(
                children: [
                  Expanded(
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
                        const SizedBox(height: 3),
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
                  Tooltip(
                    message: 'Collapse sidebar',
                    // onClose handles both drawer close and sidebar collapse
                    child: InkWell(
                      onTap: onClose,
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          color: Theme.of(context).colorScheme.surfaceContainerHighest,
                        ),
                        child: Icon(
                          Icons.chevron_left,
                          size: 18,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Divider(
              height: 1,
              thickness: 1,
              color: Theme.of(context).colorScheme.outlineVariant.withOpacity(0.5),
            ),
            const SizedBox(height: 8),
          ] else ...[
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Center(
                child: Tooltip(
                  message: 'Expand sidebar',
                  child: InkWell(
                    onTap: onClose,
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        color: Theme.of(context).colorScheme.surfaceContainerHighest,
                      ),
                      child: Icon(
                        Icons.chevron_right,
                        size: 18,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
          ...menuItems.map((item) => _SidebarItem(
                icon: item.icon,
                title: item.title,
                isActive: currentPath == item.route,
                collapsed: collapsed,
                onTap: () {
                  if (Navigator.canPop(context)) Navigator.pop(context);
                  context.go(item.route);
                },
              )),
        ],
      ),
    );
  }

  Widget _buildGuestMenu(BuildContext context, {required bool collapsed}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _SidebarItem(
            icon: Icons.search,
            title: 'Search Flights',
            collapsed: collapsed,
            onTap: () {
              if (Navigator.canPop(context)) Navigator.pop(context);
              context.go('/');
            },
          ),
        ],
      ),
    );
  }

  String _getAppBarTitle(UserRole? role) {
    if (role == null) return 'AirShero';
    switch (role) {
      case UserRole.salesAgent:      return 'AirShero Sales';
      case UserRole.checkInAgent:    return 'AirShero Check-In';
      case UserRole.flightOperator:  return 'AirShero Operations';
      case UserRole.planningManager: return 'AirShero Planning';
      case UserRole.systemAdmin:     return 'AirShero Admin';
    }
  }
}

// ─────────────────────────────────────────────
// Sidebar item — Linear/Notion style
// ─────────────────────────────────────────────
class _SidebarItem extends StatefulWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final bool isActive;
  final bool collapsed;

  const _SidebarItem({
    required this.icon,
    required this.title,
    required this.onTap,
    this.isActive = false,
    this.collapsed = false,
  });

  @override
  State<_SidebarItem> createState() => _SidebarItemState();
}

class _SidebarItemState extends State<_SidebarItem> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final active  = widget.isActive;
    final collapsed = widget.collapsed;

    final bgColor = active
        ? colors.primary.withOpacity(0.08)
        : _hovered
            ? colors.onSurface.withOpacity(0.05)
            : Colors.transparent;

    final iconColor  = active ? colors.primary : colors.onSurfaceVariant;
    final textColor  = active ? colors.primary : colors.onSurface;
    final fontWeight = active ? FontWeight.w600 : FontWeight.w400;

    final child = MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit:  (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          margin: EdgeInsets.symmetric(
            horizontal: collapsed ? 6 : 8,
            vertical:   2,
          ),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(6),
            border: Border(
              left: BorderSide(
                color: active ? colors.primary : Colors.transparent,
                width: 2,
              ),
            ),
          ),
          child: collapsed
              ? Tooltip(
                  message: widget.title,
                  preferBelow: false,
                  child: SizedBox(
                    height: 40,
                    child: Center(
                      child: Icon(widget.icon, size: 20, color: iconColor),
                    ),
                  ),
                )
              : Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 10),
                  child: Row(
                    children: [
                      Icon(widget.icon, size: 18, color: iconColor),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          widget.title,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: fontWeight,
                            color: textColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
        ),
      ),
    );

    return child;
  }
}