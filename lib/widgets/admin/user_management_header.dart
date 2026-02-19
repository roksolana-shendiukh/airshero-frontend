import 'package:flutter/material.dart';
import '../custom_button.dart';

class UserManagementHeader extends StatelessWidget {
  final int userCount;
  final VoidCallback onCreateUser;

  const UserManagementHeader({
    super.key,
    required this.userCount,
    required this.onCreateUser,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'User Management',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              '$userCount users found',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ],
        ),
        CustomButton(
          label: 'Create User',
          icon: Icons.add,
          isIconAfterLabel: false,
          onPressed: onCreateUser,
        ),
      ],
    );
  }
}