import 'package:flutter/material.dart';
import '../../models/user_model.dart';

class TableRow extends StatelessWidget {
  final UserModel user;
  final bool isSelected;
  final Map<String, double> columnWidths;
  final VoidCallback onToggle;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onToggleLock;

  const TableRow({
    super.key,
    required this.user,
    required this.isSelected,
    required this.columnWidths,
    required this.onToggle,
    required this.onEdit,
    required this.onDelete,
    required this.onToggleLock,
  });

  @override
  Widget build(BuildContext context) {
    final firstInitial = user.firstName.isNotEmpty ? user.firstName[0] : '?';
    final lastInitial = user.lastName.isNotEmpty ? user.lastName[0] : '?';
    final initials = '$firstInitial$lastInitial'.toUpperCase();

    final Color statusColor;
    switch (user.status) {
      case UserStatus.active:
        statusColor = Colors.green;
        break;
      case UserStatus.locked:
        statusColor = Colors.red;
        break;
      case UserStatus.pendingActivation:
        statusColor = Colors.orange;
        break;
      case UserStatus.pendingPasswordChange:
        statusColor = Colors.blue;
        break;
      case UserStatus.tempPasswordExpired:
        statusColor = Colors.deepOrange;
        break;
    }

    return Container(
      height: 64,
      decoration: BoxDecoration(
        color: isSelected
            ? Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.2)
            : null,
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.1),
          ),
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: columnWidths['checkbox'],
            child: Checkbox(value: isSelected, onChanged: (_) => onToggle()),
          ),

          SizedBox(
            width: columnWidths['name'],
            child: ClipRect(
              child: Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Row(
                  children: [
                    user.avatarUrl != null
                        ? CircleAvatar(
                            radius: 20,
                            backgroundImage: NetworkImage(user.avatarUrl!),
                            onBackgroundImageError: (_, __) {},
                          )
                        : CircleAvatar(
                            radius: 20,
                            backgroundColor:
                                Theme.of(context).colorScheme.primaryContainer,
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
                ),
              ),
            ),
          ),

          SizedBox(
            width: columnWidths['email'],
            child: ClipRect(
              child: Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Text(
                  user.email,
                  style: Theme.of(context).textTheme.bodyMedium,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
            ),
          ),
          SizedBox(
            width: columnWidths['airline'],
            child: ClipRect(
              child: Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Row(
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
            ),
          ),
          SizedBox(
            width: columnWidths['role'],
            child: ClipRect(
              child: Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Text(
                  user.role.displayName,
                  style: Theme.of(context).textTheme.bodyMedium,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
            ),
          ),
          SizedBox(
            width: columnWidths['status'],
            child: ClipRect(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.circle, size: 8, color: statusColor),
                    const SizedBox(width: 6),
                    Text(
                      user.status.displayName,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: statusColor,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ],
                ),
              ),
            ),
          ),
          // actions
          SizedBox(
            width: columnWidths['actions'],
            child: PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert),
              onSelected: (value) {
                if (value == 'edit') onEdit();
                if (value == 'lock') onToggleLock();
                if (value == 'delete') onDelete();
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
        ],
      ),
    );
  }
}