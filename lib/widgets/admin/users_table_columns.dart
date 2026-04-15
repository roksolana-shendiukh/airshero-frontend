import 'package:flutter/material.dart';
import '../../models/user_model.dart';
import '../table_column_def.dart'; 

class UsersTableColumns {
  static List<TableColumnDef<UserModel>> buildColumns({
    required void Function(UserModel) onEdit,
    required void Function(UserModel) onDelete,
    required void Function(UserModel) onToggleLock,
  }) {
    return [
      TableColumnDef<UserModel>(
        key: 'name',
        label: 'Name',
        initialWidth: 220,
        sticky: true,
        cellBuilder: (context, user) {
          final firstInitial = user.firstName.isNotEmpty ? user.firstName[0] : '?';
          final lastInitial = user.lastName.isNotEmpty ? user.lastName[0] : '?';
          final initials = '$firstInitial$lastInitial'.toUpperCase();

          return Row(
            children: [
              user.avatarUrl != null
                  ? CircleAvatar(
                      radius: 20,
                      backgroundImage: NetworkImage(user.avatarUrl!),
                      onBackgroundImageError: (_, __) {},
                    )
                  : CircleAvatar(
                      radius: 20,
                      backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                      child: Text(
                        initials,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      user.fullName,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                    Text(
                      user.role.displayName,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
      TableColumnDef<UserModel>(
        key: 'email',
        label: 'Email',
        initialWidth: 260,
        cellBuilder: (context, user) => Text(
          user.email,
          style: Theme.of(context).textTheme.bodyMedium,
          overflow: TextOverflow.ellipsis,
          maxLines: 1,
        ),
      ),
      TableColumnDef<UserModel>(
        key: 'airline',
        label: 'Airline',
        initialWidth: 200,
        cellBuilder: (context, user) => Row(
          children: [
            Container(
              width: 28,
              height: 28,
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Icon(
                Icons.flight,
                size: 16,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            Expanded(
              child: Text(
                user.airlineName ?? 'N/A',
                style: Theme.of(context).textTheme.bodyMedium,
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
          ],
        ),
      ),
      TableColumnDef<UserModel>(
        key: 'role',
        label: 'Role',
        initialWidth: 180,
        cellBuilder: (context, user) => Text(
          user.role.displayName,
          style: Theme.of(context).textTheme.bodyMedium,
          overflow: TextOverflow.ellipsis,
          maxLines: 1,
        ),
      ),
      TableColumnDef<UserModel>(
        key: 'status',
        label: 'Status',
        initialWidth: 140,
        cellBuilder: (context, user) {
          Color statusColor;
          switch (user.status) {
            case UserStatus.active: statusColor = Colors.green; break;
            case UserStatus.locked: statusColor = Colors.red; break;
            case UserStatus.pendingActivation: statusColor = Colors.orange; break;
            case UserStatus.pendingPasswordChange: statusColor = Colors.blue; break;
            case UserStatus.tempPasswordExpired: statusColor = Colors.deepOrange; break;
          }

          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text.rich(
              TextSpan(
                children: [
                  WidgetSpan(
                    alignment: PlaceholderAlignment.middle,
                    child: Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: Icon(Icons.circle, size: 8, color: statusColor),
                    ),
                  ),
                  TextSpan(
                    text: user.status.displayName,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: statusColor,
                    ),
                  ),
                ],
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          );
        },
      ),
      
      TableColumnDef<UserModel>(
        key: 'actions',
        label: '',
        initialWidth: 56,
        cellBuilder: (context, user) => PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert),
          onSelected: (value) {
            if (value == 'edit') onEdit(user);
            if (value == 'lock') onToggleLock(user);
            if (value == 'delete') onDelete(user);
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'edit',
              child: Row(children: [
                Icon(Icons.edit, size: 20),
                SizedBox(width: 12),
                Text('Edit User'),
              ]),
            ),
            PopupMenuItem(
              value: 'lock',
              child: Row(children: [
                Icon(
                  user.status == UserStatus.active ? Icons.lock : Icons.lock_open,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Text(user.status == UserStatus.active ? 'Lock Account' : 'Unlock Account'),
              ]),
            ),
            const PopupMenuItem(
              value: 'delete',
              child: Row(children: [
                Icon(Icons.delete, size: 20, color: Colors.red),
                SizedBox(width: 12),
                Text('Delete User', style: TextStyle(color: Colors.red)),
              ]),
            ),
          ],
        ),
      ),
    ];
  }
}