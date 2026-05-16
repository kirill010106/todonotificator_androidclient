import 'package:flutter/material.dart';
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
  String _languageCode = 'ru';
  String _targetTitle = 'В ТОНУСЕ';
  bool _isLoading = true;

  bool get darkTheme => _darkTheme;
  bool get strictMode => _strictMode;
  String get languageCode => _languageCode;
  String get targetTitle => _targetTitle;
  bool get isLoading => _isLoading;

  Future<void> load() async {
    _isLoading = true;
    notifyListeners();

    _strictMode = await _settingsRepository.isStrictModeEnabled();
    _languageCode = await _settingsRepository.getLocale() ?? 'ru';

    final targetId = await _settingsRepository.getSelectedTarget();
    if (targetId == 'easy') {
      _targetTitle = 'easy';
    } else if (targetId == 'burn') {
      _targetTitle = 'burn';
    } else {
      _targetTitle = 'tone';
    }

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

  Future<void> setLanguage(String code) async {
    if (_languageCode == code) return;
    _languageCode = code;
    await _settingsRepository.setLocale(code);
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
