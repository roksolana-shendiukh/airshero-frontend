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

class _ResponsiveLayoutState extends State<ResponsiveLayout> {
  bool _sidebarCollapsed = false;

  static const double _expandedWidth = 260;
  static const double _collapsedWidth = 75;

  void _toggleSidebar() => setState(() => _sidebarCollapsed = !_sidebarCollapsed);

  @override
  Widget build(BuildContext context) {
    final bool isLargeScreen = MediaQuery.of(context).size.width >= 1024;
    final themeNotifier = ThemeNotifier.of(context);
    final isLightTheme = themeNotifier?.isLightTheme ?? true;
    final colors = Theme.of(context).colorScheme;

    return Consumer<AuthService>(
      builder: (context, authService, _) {
        final currentUser = authService.currentUser;

        return Scaffold(
          drawer: isLargeScreen ? null : _buildDrawer(context, currentUser),
          body: Column(
            children: [
              Container(
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: colors.outlineVariant.withValues(alpha: 0.5),
                      width: 1,
                    ),
                  ),
                ),
                child: _buildAppBar(context, authService, currentUser, isLargeScreen, isLightTheme, themeNotifier),
              ),
              
              Expanded(
                child: Row(
                  children: [
                    if (isLargeScreen)
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        curve: Curves.easeInOut,
                        width: _sidebarCollapsed ? _collapsedWidth : _expandedWidth,
                        decoration: BoxDecoration(
                          color: colors.surfaceContainerLow,
                          border: Border(
                            right: BorderSide(
                              color: colors.outlineVariant.withValues(alpha: 0.5),
                            ),
                          ),
                        ),
                        child: ClipRect(
                          child: _buildSidebarContent(context, currentUser, collapsed: _sidebarCollapsed),
                        ),
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
      scrolledUnderElevation: 0,
      backgroundColor: Colors.transparent,
      leading: isLargeScreen
          ? Center(
              child: Icon(Icons.flight_takeoff, color: colors.primary, size: 28),
            )
          : null,
      titleSpacing: isLargeScreen ? 0 : null,
      title: GestureDetector(
        onTap: () => context.go('/'),
        child: Text(
          _getAppBarTitle(currentUser?.role),
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
      ),
      actions: [
        IconButton(
          icon: Icon(isLightTheme ? Icons.dark_mode_outlined : Icons.light_mode_outlined),
          onPressed: () => themeNotifier?.toggleTheme(),
        ),
        if (currentUser != null) _buildUserAvatar(context, currentUser, authService),
        const SizedBox(width: 16),
      ],
    );
  }

  Widget _buildSidebarContent(
    BuildContext context,
    UserModel? currentUser, {
    required bool collapsed,
  }) {
    if (currentUser == null) return const SizedBox.shrink();

    final colors = Theme.of(context).colorScheme;
    final currentPath = GoRouterState.of(context).uri.path;
    final menuItems = currentUser.role.menuItems;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 16, 8, 16),
          child: collapsed
              ? Center(
                  child: InkWell(
                    onTap: _toggleSidebar,
                    child: _buildAirlineLogo(currentUser, size: 36),
                  ),
                )
              : SingleChildScrollView( 
                  scrollDirection: Axis.horizontal,
                  physics: const NeverScrollableScrollPhysics(),
                  child: SizedBox(
                    width: _expandedWidth - 20, 
                    child: Row(
                      children: [
                        _buildAirlineLogo(currentUser, size: 36),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            currentUser.airlineName?.toUpperCase() ?? "AIRLINE",
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w900,
                              color: colors.primary,
                              letterSpacing: 0.5,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.fade,
                            softWrap: false,
                          ),
                        ),
                        IconButton(
                          visualDensity: VisualDensity.compact,
                          icon: const Icon(Icons.menu_open, size: 20),
                          onPressed: _toggleSidebar,
                        ),
                      ],
                    ),
                  ),
                ),
        ),
        
        const Divider(height: 1, indent: 12, endIndent: 12),
        const SizedBox(height: 8),

        // MENU ITEMS - ТЕЖ ЗАХИЩЕНІ ВІД OVERFLOW
        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            children: menuItems.map((item) => _SidebarItem(
              icon: item.icon,
              title: item.title,
              isActive: currentPath == item.route,
              collapsed: collapsed,
              onTap: () {
                if (Navigator.canPop(context)) Navigator.pop(context);
                context.go(item.route);
              },
            )).toList(),
          ),
        ),

        if (collapsed)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: IconButton(
              icon: const Icon(Icons.chevron_right),
              onPressed: _toggleSidebar,
            ),
          ),
      ],
    );
  }

  Widget _buildAirlineLogo(UserModel user, {required double size}) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white,
        border: Border.all(color: Colors.grey.withValues(alpha: 0.15)),
      ),
      child: ClipOval(
        child: Padding(
          padding: const EdgeInsets.all(5.0),
          child: user.airlineLogoUrl != null
              ? Image.network(
                  user.airlineLogoUrl!,
                  fit: BoxFit.contain,
                  errorBuilder: (c, e, s) => const Icon(Icons.flight_takeoff, size: 16),
                )
              : const Icon(Icons.flight_takeoff, size: 16, color: Colors.grey),
        ),
      ),
    );
  }

  Widget _buildUserAvatar(BuildContext context, UserModel user, AuthService authService) {
    final colors = Theme.of(context).colorScheme;
    return PopupMenuButton<String>(
      offset: const Offset(0, 45),
      child: CircleAvatar(
        radius: 16,
        backgroundColor: colors.primary,
        child: Text(
          user.firstName.isNotEmpty 
              ? user.firstName[0].toUpperCase() 
              : (user.email.isNotEmpty ? user.email[0].toUpperCase() : '?'),
          style: TextStyle(
            color: colors.onPrimary, 
            fontSize: 13, 
            fontWeight: FontWeight.bold
          ),
        ),
      ),
      itemBuilder: (context) => [
        PopupMenuItem(
          enabled: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(user.fullName, style: const TextStyle(fontWeight: FontWeight.bold)),
              Text(user.role.displayName, style: TextStyle(fontSize: 12, color: colors.outline)),
            ],
          ),
        ),
        const PopupMenuDivider(),
        const PopupMenuItem(
          value: 'logout',
          child: Row(
            children: [
              Icon(Icons.logout, size: 18, color: Colors.red),
              SizedBox(width: 8),
              Text('Logout', style: TextStyle(color: Colors.red)),
            ],
          ),
        ),
      ],
      onSelected: (val) {
        if (val == 'logout') {
          authService.logout();
          context.go('/');
        }
      },
    );
  }

  Widget _buildDrawer(BuildContext context, UserModel? currentUser) {
    return Drawer(
      width: _expandedWidth,
      child: SafeArea(
        child: _buildSidebarContent(context, currentUser, collapsed: false),
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

class _SidebarItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final bool isActive;
  final bool collapsed;
  final VoidCallback onTap;

  const _SidebarItem({
    required this.icon,
    required this.title,
    required this.isActive,
    required this.collapsed,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 10, horizontal: collapsed ? 0 : 12),
          decoration: BoxDecoration(
            color: isActive ? colors.primary.withValues(alpha: 0.08) : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: collapsed
              ? Tooltip(
                  message: title, 
                  child: Center(child: Icon(icon, color: isActive ? colors.primary : colors.onSurfaceVariant, size: 22))
                )
              : SingleChildScrollView( 
                  scrollDirection: Axis.horizontal,
                  physics: const NeverScrollableScrollPhysics(),
                  child: SizedBox(
                    width: 200, 
                    child: Row(
                      children: [
                        Icon(icon, size: 20, color: isActive ? colors.primary : colors.onSurfaceVariant),
                        const SizedBox(width: 12),
                        Text(
                          title,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                            color: isActive ? colors.primary : colors.onSurface,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
        ),
      ),
    );
  }
}