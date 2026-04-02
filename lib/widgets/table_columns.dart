class TableColumnDef {
  final String key;
  final String label;
  final double width;
  final bool sticky;

  const TableColumnDef({
    required this.key,
    required this.label,
    required this.width,
    this.sticky = false,
  });
}

extension TableColumnDefListX on List<TableColumnDef> {
  List<TableColumnDef> get stickyColumns => where((c) => c.sticky).toList();
  List<TableColumnDef> get scrollableColumns => where((c) => !c.sticky).toList();

  double get stickyWidth =>
      stickyColumns.fold(0, (sum, c) => sum + c.width);
  double get scrollableWidth =>
      scrollableColumns.fold(0, (sum, c) => sum + c.width);
  double get totalWidth =>
      fold(0, (sum, c) => sum + c.width);
}