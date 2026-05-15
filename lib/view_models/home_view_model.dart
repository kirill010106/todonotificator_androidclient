import 'package:flutter/material.dart';
import '../app/navigation_state.dart';

class HomeViewModel extends ChangeNotifier {
  HomeViewModel({
    required AppNavigationState navigationState,
  }) : _navigationState = navigationState {
    _navigationState.addListener(_handleNavigation);
  }

  final AppNavigationState _navigationState;

  int get tabIndex => _navigationState.tabIndex;

  @override
  void dispose() {
    _navigationState.removeListener(_handleNavigation);
    super.dispose();
  }

  void _handleNavigation() {
    notifyListeners();
  }

  void setTab(int index) {
    _navigationState.setTab(index);
  }
}
