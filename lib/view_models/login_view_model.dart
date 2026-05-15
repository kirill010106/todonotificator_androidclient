import 'package:flutter/material.dart';
import '../data/models.dart';
import '../data/repositories.dart';

class LoginViewModel extends ChangeNotifier {
  LoginViewModel({
    required AuthRepository authRepository,
    required SettingsRepository settingsRepository,
  })  : _authRepository = authRepository,
        _settingsRepository = settingsRepository;

  final AuthRepository _authRepository;
  final SettingsRepository _settingsRepository;

  bool _isSubmitting = false;
  String? _loginError;
  String? _passwordError;
  String? _bannerMessage;

  bool get isSubmitting => _isSubmitting;
  String? get loginError => _loginError;
  String? get passwordError => _passwordError;
  String? get bannerMessage => _bannerMessage;

  void clearBanner() {
    _bannerMessage = null;
    notifyListeners();
  }

  Future<bool> login(String login, String password) async {
    _loginError = null;
    _passwordError = null;
    _bannerMessage = null;

    if (login.isEmpty) {
      _loginError = 'Введите email или никнейм';
    }
    if (password.isEmpty) {
      _passwordError = 'Введите пароль';
    }

    if (_loginError != null || _passwordError != null) {
      notifyListeners();
      return false;
    }

    _isSubmitting = true;
    notifyListeners();

    try {
      final result = await _authRepository.login(login: login, password: password);
      
      if (result.isSuccess) {
        return true;
      } else {
        _bannerMessage = _mapFailure(result.failure);
        return false;
      }
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }

  Future<bool> hasSelectedTarget() async {
    final targetId = await _settingsRepository.getSelectedTarget();
    return targetId != null;
  }

  String _mapFailure(AuthFailure? failure) {
    switch (failure) {
      case AuthFailure.invalidCredentials:
        return 'Неверный логин или пароль';
      case AuthFailure.serverError:
        return 'Ошибка сервера. Попробуйте позже';
      default:
        return 'Что-то пошло не так';
    }
  }
}
