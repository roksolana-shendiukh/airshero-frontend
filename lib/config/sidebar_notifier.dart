import 'package:flutter/material.dart';

class SidebarNotifier extends ChangeNotifier {
  bool _collapsed = false;
  bool get collapsed => _collapsed;

  void toggle() {
    _collapsed = !_collapsed;
    notifyListeners();
  }
}