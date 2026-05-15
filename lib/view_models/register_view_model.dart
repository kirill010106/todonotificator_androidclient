import 'package:flutter/material.dart';
import '../data/models.dart';
import '../data/repositories.dart';

class RegisterViewModel extends ChangeNotifier {
  RegisterViewModel({
    required AuthRepository authRepository,
  }) : _authRepository = authRepository;

  final AuthRepository _authRepository;

  bool _isSubmitting = false;
  bool _accepted = false;

  String? _nicknameError;
  String? _emailError;
  String? _passwordError;
  String? _confirmError;
  String? _policyError;

  bool get isSubmitting => _isSubmitting;
  bool get accepted => _accepted;

  String? get nicknameError => _nicknameError;
  String? get emailError => _emailError;
  String? get passwordError => _passwordError;
  String? get confirmError => _confirmError;
  String? get policyError => _policyError;

  void setAccepted(bool value) {
    _accepted = value;
    if (_accepted) {
      _policyError = null;
    }
    notifyListeners();
  }

  Future<bool> register({
    required String nickname,
    required String email,
    required String password,
    required String confirm,
  }) async {
    _nicknameError = null;
    _emailError = null;
    _passwordError = null;
    _confirmError = null;
    _policyError = null;

    bool hasError = false;

    if (nickname.isEmpty) {
      _nicknameError = 'Введите никнейм';
      hasError = true;
    } else if (nickname.length < 3) {
      _nicknameError = 'Минимум 3 символа';
      hasError = true;
    }

    final emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    if (email.isEmpty) {
      _emailError = 'Введите email';
      hasError = true;
    } else if (!emailRegex.hasMatch(email)) {
      _emailError = 'Введите корректный email';
      hasError = true;
    }

    if (password.length < 8) {
      _passwordError = 'Пароль должен быть не менее 8 символов';
      hasError = true;
    }
    if (confirm != password) {
      _confirmError = 'Пароли не совпадают';
      hasError = true;
    }
    if (!_accepted) {
      _policyError = 'Подтвердите соглашение';
      hasError = true;
    }

    if (hasError) {
      notifyListeners();
      return false;
    }

    _isSubmitting = true;
    notifyListeners();

    try {
      final result = await _authRepository.register(
        nickname: nickname,
        email: email,
        password: password,
      );

      if (result.isSuccess) {
        return true;
      } else {
        _handleFailure(result.failure);
        return false;
      }
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }

  void _handleFailure(AuthFailure? failure) {
    switch (failure) {
      case AuthFailure.emailExists:
        _emailError = 'Такой аккаунт уже зарегистрирован';
        break;
      case AuthFailure.nicknameExists:
        _nicknameError = 'Никнейм уже занят';
        break;
      default:
        // Global errors can be handled by showing a SnackBar in the View
        // based on a message from VM if needed, but for now we follow the original logic.
        break;
    }
  }
}
