import 'package:flutter/material.dart';

class AppThemeState extends ChangeNotifier {
  final ThemeMode _themeMode = ThemeMode.light;

  ThemeMode get themeMode => _themeMode;
}
