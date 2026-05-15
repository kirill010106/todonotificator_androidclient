import 'package:flutter/material.dart';
import '../data/models.dart';
import '../data/repositories.dart';

class SettingsViewModel extends ChangeNotifier {
  SettingsViewModel({
    required SettingsRepository settingsRepository,
    required AuthRepository authRepository,
  }) : _settingsRepository = settingsRepository,
       _authRepository = authRepository;

  final SettingsRepository _settingsRepository;
  final AuthRepository _authRepository;

  bool _darkTheme = false;
  bool _strictMode = false;
  String _targetTitle = 'В ТОНУСЕ';
  bool _isLoading = true;

  bool get darkTheme => _darkTheme;
  bool get strictMode => _strictMode;
  String get targetTitle => _targetTitle;
  bool get isLoading => _isLoading;

  static const List<TargetOption> _options = [
    TargetOption(
      id: 'easy',
      title: 'ЛЕГКИЙ',
      subtitle: '',
      tasks: 1,
      intervals: 2,
    ),
    TargetOption(
      id: 'tone',
      title: 'В ТОНУСЕ',
      subtitle: '',
      tasks: 2,
      intervals: 4,
    ),
    TargetOption(
      id: 'burn',
      title: 'ПРОЖАРКА',
      subtitle: '',
      tasks: 3,
      intervals: 8,
    ),
  ];

  Future<void> load() async {
    _isLoading = true;
    notifyListeners();

    final targetId = await _settingsRepository.getSelectedTarget();
    if (targetId != null) {
      final t = _options.firstWhere(
        (o) => o.id == targetId,
        orElse: () => _options[1],
      );
      _targetTitle = t.title;
    }

    _strictMode = await _settingsRepository.isStrictModeEnabled();

    _isLoading = false;
    notifyListeners();
  }

  void setDarkTheme(bool value) {
    _darkTheme = value;
    notifyListeners();
  }

  Future<void> setStrictMode(bool value) async {
    _strictMode = value;
    await _settingsRepository.setStrictModeEnabled(value);
    notifyListeners();
  }

  Future<void> deleteAccount() async {
    // In a real app we would call a delete API here.
    await _authRepository.logout();
  }

  Future<String?> getSelectedTargetId() async {
    return await _settingsRepository.getSelectedTarget();
  }
}
