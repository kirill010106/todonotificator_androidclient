import 'package:flutter/material.dart';
import '../data/models.dart';
import '../data/repositories.dart';

class ChangePasswordViewModel extends ChangeNotifier {
  ChangePasswordViewModel({required AuthRepository authRepository})
    : _authRepository = authRepository;

  final AuthRepository _authRepository;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _error;
  String? get error => _error;

  bool _isSuccess = false;
  bool get isSuccess => _isSuccess;

  Future<void> changePassword({
    required String oldPassword,
    required String newPassword,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await _authRepository.changePassword(
        oldPassword: oldPassword,
        newPassword: newPassword,
      );

      if (result.isSuccess) {
        _isSuccess = true;
      } else {
        _error = _mapFailure(result.failure);
      }
    } catch (_) {
      _error = 'Произошла ошибка на сервере';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  String _mapFailure(AuthFailure? failure) {
    switch (failure) {
      case AuthFailure.wrongPassword:
        return 'Неверный текущий пароль';
      case AuthFailure.serverError:
      default:
        return 'Ошибка сервера. Попробуйте позже';
    }
  }
}
