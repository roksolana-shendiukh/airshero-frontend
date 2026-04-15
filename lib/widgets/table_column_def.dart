import 'package:flutter/material.dart';

class TableColumnDef<T> {
  final String key;
  final String label;
  final double initialWidth;
  final bool sticky;
  
  final Widget Function(BuildContext context, T item) cellBuilder;

  const TableColumnDef({
    required this.key,
    required this.label,
    required this.initialWidth,
    required this.cellBuilder,
    this.sticky = false,
  });
}

extension TableColumnDefListX<T> on List<TableColumnDef<T>> {
  List<TableColumnDef<T>> get stickyColumns => where((c) => c.sticky).toList();
  List<TableColumnDef<T>> get scrollableColumns => where((c) => !c.sticky).toList();

  double get stickyWidth =>
      stickyColumns.fold(0, (sum, c) => sum + c.initialWidth);
  double get scrollableWidth =>
      scrollableColumns.fold(0, (sum, c) => sum + c.initialWidth);
  double get totalWidth =>
      fold(0, (sum, c) => sum + c.initialWidth);
}