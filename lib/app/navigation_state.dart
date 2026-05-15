import 'package:flutter/material.dart';

class AppNavigationState extends ChangeNotifier {
  int _tabIndex = 0;

  int get tabIndex => _tabIndex;

  void setTab(int index) {
    if (index == _tabIndex) {
      return;
    }
    _tabIndex = index;
    notifyListeners();
  }
}
