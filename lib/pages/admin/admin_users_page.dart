import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../widgets/responsive_layout.dart';
import '../../models/user_model.dart';
import '../../widgets/table_header.dart';
import '../../widgets/table_row.dart' as admin_table;
import '../../widgets/admin/users_table_columns.dart';
import '../../widgets/admin/user_table_pagination.dart';
import '../../widgets/admin/user_management_header.dart';
import '../../widgets/admin/bulk_actions_bar.dart';
import '../../widgets/admin/create_user_dialog.dart';
import '../../widgets/custom/custom_select_field.dart';
import '../../services/admin_api_service.dart';
import '../../services/auth_service.dart';

class AdminUsersPage extends StatefulWidget {
  const AdminUsersPage({super.key});

  @override
  State<AdminUsersPage> createState() => _AdminUsersPageState();
}

class _AdminUsersPageState extends State<AdminUsersPage> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _horizontalScroll = ScrollController();

  late final AdminApiService _adminApi;
  List<UserModel> _users = [];
  bool _isLoading = false;
  String? _error;

  UserRole? _selectedRoleFilter;
  UserStatus? _selectedStatusFilter;

  int _currentPage = 1;
  final int _itemsPerPage = 10;

  final Set<String> _selectedUserIds = {};
  bool _selectAll = false;

  Map<String, double> _columnWidths = {
    'checkbox': UsersTableColumns.checkbox.width,
    'name':     UsersTableColumns.name.width,
    'email':    UsersTableColumns.email.width,
    'airline':  UsersTableColumns.airline.width,
    'role':     UsersTableColumns.role.width,
    'status':   UsersTableColumns.status.width,
    'actions':  UsersTableColumns.actions.width,
  };

  @override
  void initState() {
    super.initState();
    _adminApi = AdminApiService(context.read<AuthService>());
    _loadUsers();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _horizontalScroll.dispose();
    super.dispose();
  }

  void _onColumnResize(String key, double delta) {
    setState(() {
      final current = _columnWidths[key] ?? 100;
      _columnWidths[key] = (current + delta).clamp(60.0, 500.0);
    });
  }

  double get _totalWidth => _columnWidths.values.fold(0, (sum, w) => sum + w);

  Future<void> _loadUsers() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final data = await _adminApi.getUsers();
      setState(() {
        _users = data
            .where((u) => u['role'] != 'systemAdmin')
            .map((u) => UserModel(
                  id: u['uid'],
                  email: u['email'] ?? '',
                  firstName: u['firstName'] ?? '',
                  lastName: u['lastName'] ?? '',
                  role: UserRole.fromId(u['roleId'] as int? ?? 0),
                  status: UserStatus.values.firstWhere(
                    (s) => s.name == u['status'],
                    orElse: () => UserStatus.pendingActivation,
                  ),
                  airlineName: u['airlineName'] ?? '',
                  airlineLogoUrl: null,
                  createdAt: DateTime.now(),
                  lastLoginAt: null,
                ))
            .toList();
      });
    } catch (e) {
      setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  List<UserModel> get _filteredUsers {
    var users = _users;
    if (_searchController.text.isNotEmpty) {
      final query = _searchController.text.toLowerCase();
      users = users
          .where((u) =>
              u.email.toLowerCase().contains(query) ||
              u.fullName.toLowerCase().contains(query))
          .toList();
    }
    if (_selectedRoleFilter != null) {
      users = users.where((u) => u.role == _selectedRoleFilter).toList();
    }
    if (_selectedStatusFilter != null) {
      users = users.where((u) => u.status == _selectedStatusFilter).toList();
    }
    return users;
  }

  int get _totalPages => (_filteredUsers.length / _itemsPerPage).ceil();

  List<UserModel> get _paginatedUsers {
    final start = (_currentPage - 1) * _itemsPerPage;
    final end = (start + _itemsPerPage).clamp(0, _filteredUsers.length);
    return _filteredUsers.sublist(start, end);
  }

  void _showCreateUserDialog() {
    showDialog(
      context: context,
      builder: (context) => CreateUserDialog(onUserCreated: _loadUsers),
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

    return ResponsiveLayout(
      header: Padding(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            UserManagementHeader(
              userCount: _filteredUsers.length,
              onCreateUser: _showCreateUserDialog,
            ),
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
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                _searchController.clear();
                                setState(() {});
                              },
                            )
                          : null,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                  ),
                ),
                SizedBox(
                  width: 220,
                  child: CustomSelectField(
                    label: 'Role',
                    icon: Icons.badge_outlined,
                    value: _selectedRoleFilter?.displayName ?? 'All Roles',
                    items: ['All Roles', ...UserRole.values.map((r) => r.displayName)],
                    onChanged: (value) => setState(() {
                      _selectedRoleFilter = value == 'All Roles'
                          ? null
                          : UserRole.values.firstWhere((r) => r.displayName == value);
                      _currentPage = 1;
                    }),
                  ),
                ),
                SizedBox(
                  width: 200,
                  child: CustomSelectField(
                    label: 'Status',
                    icon: Icons.circle_outlined,
                    value: _selectedStatusFilter?.displayName ?? 'All',
                    items: ['All', ...UserStatus.values.map((s) => s.displayName)],
                    onChanged: (value) => setState(() {
                      _selectedStatusFilter = value == 'All'
                          ? null
                          : UserStatus.values.firstWhere((s) => s.displayName == value);
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
                onDelete: () => ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Delete ${_selectedUserIds.length} users')),
                ),
                onLock: () => ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Lock ${_selectedUserIds.length} users')),
                ),
              ),
            ],
            const SizedBox(height: 16),
          ],
        ),
      ),

      // ── BODY: займає весь залишок висоти (Expanded у ResponsiveLayout) ───
      body: Padding(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.error_outline, size: 48, color: Colors.red),
                        const SizedBox(height: 16),
                        Text(_error!, style: const TextStyle(color: Colors.red)),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _loadUsers,
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  )
                : Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: Theme.of(context)
                            .colorScheme
                            .outline
                            .withValues(alpha: 0.2),
                      ),
                    ),
                    child: Column(
                      children: [
                        // ── Таблиця ───────────────────────────────────────
                        Expanded(
                          child: _paginatedUsers.isEmpty
                              ? Center(
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.search_off,
                                        size: 64,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onSurfaceVariant,
                                      ),
                                      const SizedBox(height: 16),
                                      Text(
                                        'No users found',
                                        style: Theme.of(context).textTheme.titleMedium,
                                      ),
                                    ],
                                  ),
                                )
                              : SingleChildScrollView(
                                  scrollDirection: Axis.horizontal,
                                  controller: _horizontalScroll,
                                  child: SizedBox(
                                    width: _totalWidth,
                                    child: Column(
                                      children: [
                                        TableHeader(
                                          selectAll: _selectAll,
                                          onToggleSelectAll: _toggleSelectAll,
                                          columnWidths: _columnWidths,
                                          onColumnResize: _onColumnResize,
                                        ),
                                        Expanded(
                                          child: ListView.builder(
                                            itemCount: _paginatedUsers.length,
                                            itemBuilder: (context, index) {
                                              final user = _paginatedUsers[index];
                                              return admin_table.TableRow(
                                                user: user,
                                                columnWidths: _columnWidths,
                                                isSelected: _selectedUserIds.contains(user.id),
                                                onToggle: () => _toggleUserSelection(user.id),
                                                onEdit: () =>
                                                    ScaffoldMessenger.of(context).showSnackBar(
                                                  SnackBar(content: Text('Edit ${user.email}')),
                                                ),
                                                onDelete: () =>
                                                    ScaffoldMessenger.of(context).showSnackBar(
                                                  SnackBar(content: Text('Delete ${user.email}')),
                                                ),
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
                        // ── Пагінація ─────────────────────────────────────
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
    );
  }
}