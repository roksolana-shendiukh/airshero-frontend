import 'package:flutter/material.dart';
import '../widgets/admin/users_table_columns.dart';

class TableHeader extends StatelessWidget {
  final bool selectAll;
  final VoidCallback onToggleSelectAll;

  const TableHeader({
    super.key,
    required this.selectAll,
    required this.onToggleSelectAll,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
          ),
        ),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(6),
          topRight: Radius.circular(6),
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: UsersTableColumns.checkbox.width,
            child: Checkbox(value: selectAll, onChanged: (_) => onToggleSelectAll()),
          ),
          _cell('Name',    UsersTableColumns.name.width),
          _cell('Email',   UsersTableColumns.email.width),
          _cell('Airline', UsersTableColumns.airline.width),
          _cell('Role',    UsersTableColumns.role.width),
          _cell('Status',  UsersTableColumns.status.width),
          SizedBox(width: UsersTableColumns.actions.width),
        ],
      ),
    );
  }

  Widget _cell(String label, double width) {
    return SizedBox(
      width: width,
      child: Padding(
        padding: const EdgeInsets.only(right: 12),
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }
}