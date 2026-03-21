import '../table_columns.dart';

class UsersTableColumns {
  static const checkbox = TableColumnDef(key: 'checkbox', label: '',        width: 48,  sticky: true);
  static const name     = TableColumnDef(key: 'name',     label: 'Name',    width: 220, sticky: true);
  static const email    = TableColumnDef(key: 'email',    label: 'Email',   width: 260);
  static const airline  = TableColumnDef(key: 'airline',  label: 'Airline', width: 200);
  static const role     = TableColumnDef(key: 'role',     label: 'Role',    width: 180);
  static const status   = TableColumnDef(key: 'status',   label: 'Status',  width: 140);
  static const actions  = TableColumnDef(key: 'actions',  label: '',        width: 56);

  static const List<TableColumnDef> all = [
    checkbox, name, email, airline, role, status, actions,
  ];
}