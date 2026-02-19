import 'package:flutter/material.dart';
import '../../widgets/responsive_layout.dart';
import '../../models/user_model.dart';
import '../../widgets/table_header.dart';
import '../../widgets/table_row.dart' as admin_table;
import '../../widgets/admin/users_table_columns.dart';
import '../../widgets/table_columns.dart';
import '../../widgets/admin/user_table_pagination.dart';
import '../../widgets/admin/user_management_header.dart';
import '../../widgets/admin/bulk_actions_bar.dart';
import '../../widgets/admin/create_user_dialog.dart';
import '../../widgets/custom_select_field.dart';

class AdminUsersPage extends StatefulWidget {
  const AdminUsersPage({super.key});

  @override
  State<AdminUsersPage> createState() => _AdminUsersPageState();
}

class _AdminUsersPageState extends State<AdminUsersPage> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _horizontalScroll = ScrollController();

  UserRole? _selectedRoleFilter;
  UserStatus? _selectedStatusFilter;

  int _currentPage = 1;
  final int _itemsPerPage = 10;

  final Set<String> _selectedUserIds = {};
  bool _selectAll = false;

  @override
  void dispose() {
    _searchController.dispose();
    _horizontalScroll.dispose();
    super.dispose();
  }

  List<UserModel> _getMockUsers() {
    return [
      UserModel(id: '1', email: 'john.doe@airshero.com', firstName: 'John', lastName: 'Doe', role: UserRole.salesAgent, status: UserStatus.active, createdAt: DateTime(2025, 1, 15), lastLoginAt: DateTime.now().subtract(const Duration(hours: 2)), airlineName: 'Ukraine International', airlineLogoUrl: 'https://upload.wikimedia.org/wikipedia/commons/thumb/8/80/Ukraine-International-Airlines-Logo.svg/200px-Ukraine-International-Airlines-Logo.svg.png'),
      UserModel(id: '2', email: 'jane.smith@airshero.com', firstName: 'Jane', lastName: 'Smith', role: UserRole.checkInAgent, status: UserStatus.active, createdAt: DateTime(2025, 1, 20), lastLoginAt: DateTime.now().subtract(const Duration(hours: 5)), airlineName: 'Wizz Air', airlineLogoUrl: 'https://upload.wikimedia.org/wikipedia/commons/thumb/5/5e/Wizz_Air_logo.svg/200px-Wizz_Air_logo.svg.png'),
      UserModel(id: '3', email: 'bob.wilson@airshero.com', firstName: 'Bob', lastName: 'Wilson', role: UserRole.flightOperator, status: UserStatus.locked, createdAt: DateTime(2025, 2, 1), lastLoginAt: DateTime.now().subtract(const Duration(days: 3)), airlineName: 'SkyUp Airlines', airlineLogoUrl: 'https://upload.wikimedia.org/wikipedia/commons/thumb/0/0f/SkyUp_Airlines_logo.svg/200px-SkyUp_Airlines_logo.svg.png'),
      UserModel(id: '4', email: 'alice.brown@airshero.com', firstName: 'Alice', lastName: 'Brown', role: UserRole.planningManager, status: UserStatus.active, createdAt: DateTime(2025, 2, 10), lastLoginAt: DateTime.now().subtract(const Duration(minutes: 30)), airlineName: 'Ukraine International', airlineLogoUrl: 'https://upload.wikimedia.org/wikipedia/commons/thumb/8/80/Ukraine-International-Airlines-Logo.svg/200px-Ukraine-International-Airlines-Logo.svg.png'),
      UserModel(id: '5', email: 'admin@airshero.com', firstName: 'System', lastName: 'Admin', role: UserRole.systemAdmin, status: UserStatus.active, createdAt: DateTime(2024, 12, 1), lastLoginAt: DateTime.now(), airlineName: 'AirShero System', airlineLogoUrl: null),
    ];
  }

  List<UserModel> get _filteredUsers {
    var users = _getMockUsers();
    if (_searchController.text.isNotEmpty) {
      final query = _searchController.text.toLowerCase();
      users = users.where((u) => u.email.toLowerCase().contains(query) || u.fullName.toLowerCase().contains(query)).toList();
    }
    if (_selectedRoleFilter != null) users = users.where((u) => u.role == _selectedRoleFilter).toList();
    if (_selectedStatusFilter != null) users = users.where((u) => u.status == _selectedStatusFilter).toList();
    return users;
  }

  int get _totalPages => (_filteredUsers.length / _itemsPerPage).ceil();

  List<UserModel> get _paginatedUsers {
    final start = (_currentPage - 1) * _itemsPerPage;
    final end = start + _itemsPerPage;
    return _filteredUsers.sublist(start, end > _filteredUsers.length ? _filteredUsers.length : end);
  }

  void _showCreateUserDialog() {
    showDialog(
      context: context,
      builder: (context) => CreateUserDialog(
        onUserCreated: (userData) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('User ${userData['email']} created successfully')));
          setState(() {});
        },
      ),
    );
  }

  void _toggleSelectAll() {
    setState(() {
      if (_selectAll) {
        _selectedUserIds.clear();
      } else {
        _selectedUserIds.addAll(_paginatedUsers.map((u) => u.id));
      }
      _selectAll = !_selectAll;
    });
  }

  void _toggleUserSelection(String userId) {
    setState(() {
      if (_selectedUserIds.contains(userId)) {
        _selectedUserIds.remove(userId);
        _selectAll = false;
      } else {
        _selectedUserIds.add(userId);
        if (_selectedUserIds.length == _paginatedUsers.length) _selectAll = true;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isLargeScreen = MediaQuery.of(context).size.width >= 1024;
    final tableHeight = MediaQuery.of(context).size.height - 56 - 24;
    final totalWidth = UsersTableColumns.all.totalWidth;

    return ResponsiveLayout(
      header: Padding(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            UserManagementHeader(userCount: _filteredUsers.length, onCreateUser: _showCreateUserDialog),
            const SizedBox(height: 24),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                SizedBox(
                  width: isLargeScreen ? 300 : double.infinity,
                  child: TextField(
                    controller: _searchController,
                    onChanged: (_) => setState(() {}),
                    decoration: InputDecoration(
                      hintText: 'Search by name or email...',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(icon: const Icon(Icons.clear), onPressed: () { _searchController.clear(); setState(() {}); })
                          : null,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                  ),
                ),
                SizedBox(
                  width: 220,
                  child: CustomSelectField(
                    label: 'Role', icon: Icons.badge_outlined,
                    value: _selectedRoleFilter?.displayName ?? 'All Roles',
                    items: ['All Roles', ...UserRole.values.map((r) => r.displayName)],
                    onChanged: (value) => setState(() {
                      _selectedRoleFilter = value == 'All Roles' ? null : UserRole.values.firstWhere((r) => r.displayName == value);
                      _currentPage = 1;
                    }),
                  ),
                ),
                SizedBox(
                  width: 180,
                  child: CustomSelectField(
                    label: 'Status', icon: Icons.circle_outlined,
                    value: _selectedStatusFilter?.displayName ?? 'All',
                    items: ['All', ...UserStatus.values.map((s) => s.displayName)],
                    onChanged: (value) => setState(() {
                      _selectedStatusFilter = value == 'All' ? null : UserStatus.values.firstWhere((s) => s.displayName == value);
                      _currentPage = 1;
                    }),
                  ),
                ),
              ],
            ),
            if (_selectedUserIds.isNotEmpty) ...[
              const SizedBox(height: 16),
              BulkActionsBar(
                selectedCount: _selectedUserIds.length,
                onDelete: () => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Delete ${_selectedUserIds.length} users'))),
                onLock: () => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lock ${_selectedUserIds.length} users'))),
              ),
            ],
            const SizedBox(height: 16),
          ],
        ),
      ),

      body: Padding(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        child: SizedBox(
          height: tableHeight,
          child: Container(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2)),
            ),
            child: Column(
              children: [
                // ══════════════════════════════════════════════════
                // Хедер + рядки загорнуті в ОДИН горизонтальний скрол.
                // Завдяки цьому хедер і всі рядки скроляться синхронно.
                // ══════════════════════════════════════════════════
                Expanded(
                  child: _paginatedUsers.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.search_off, size: 64, color: Theme.of(context).colorScheme.onSurfaceVariant),
                              const SizedBox(height: 16),
                              Text('No users found', style: Theme.of(context).textTheme.titleMedium),
                            ],
                          ),
                        )
                      : SingleChildScrollView(
                          // Горизонтальний скрол — один на хедер І рядки
                          scrollDirection: Axis.horizontal,
                          controller: _horizontalScroll,
                          child: SizedBox(
                            width: totalWidth,
                            child: Column(
                              children: [
                                // Хедер всередині горизонтального скролу
                                TableHeader(
                                  selectAll: _selectAll,
                                  onToggleSelectAll: _toggleSelectAll,
                                ),
                                // Рядки — вертикальний скрол всередині горизонтального
                                Expanded(
                                  child: ListView.builder(
                                    itemCount: _paginatedUsers.length,
                                    itemBuilder: (context, index) {
                                      final user = _paginatedUsers[index];
                                      return admin_table.TableRow(
                                        user: user,
                                        isSelected: _selectedUserIds.contains(user.id),
                                        onToggle: () => _toggleUserSelection(user.id),
                                        onEdit: () => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Edit ${user.email}'))),
                                        onDelete: () => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Delete ${user.email}'))),
                                        onToggleLock: () => setState(() {}),
                                      );
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                ),

                // Пагінація — поза горизонтальним скролом
                if (_filteredUsers.isNotEmpty)
                  UserTablePagination(
                    currentPage: _currentPage,
                    totalPages: _totalPages,
                    totalUsers: _filteredUsers.length,
                    itemsPerPage: _itemsPerPage,
                    onPrevious: () => setState(() => _currentPage--),
                    onNext: () => setState(() => _currentPage++),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}