import 'package:flutter/material.dart';

import '../app/app_scope.dart';
import '../data/models.dart';
import '../ui/theme/app_colors.dart';
import '../ui/widgets/app_text_field.dart';
import 'login_screen.dart';
import 'target_select_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _nicknameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();

  bool _accepted = false;
  bool _isSubmitting = false;

  String? _nicknameError;
  String? _emailError;
  String? _passwordError;
  String? _confirmError;
  String? _policyError;

  @override
  void dispose() {
    _nicknameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();

    final nickname = _nicknameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final confirm = _confirmController.text;

    String? nicknameError;
    String? emailError;
    String? passwordError;
    String? confirmError;
    String? policyError;

    if (nickname.isEmpty) {
      nicknameError = 'Введите никнейм';
    } else if (nickname.length < 3) {
      nicknameError = 'Минимум 3 символа';
    }

    final emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    if (email.isEmpty) {
      emailError = 'Введите email';
    } else if (!emailRegex.hasMatch(email)) {
      emailError = 'Введите корректный email';
    }

    if (password.length < 8) {
      passwordError = 'Пароль должен быть не менее 8 символов';
    }
    if (confirm != password) {
      confirmError = 'Пароли не совпадают';
    }
    if (!_accepted) {
      policyError = 'Подтвердите соглашение';
    }

    setState(() {
      _nicknameError = nicknameError;
      _emailError = emailError;
      _passwordError = passwordError;
      _confirmError = confirmError;
      _policyError = policyError;
    });

    if (nicknameError != null ||
        emailError != null ||
        passwordError != null ||
        confirmError != null ||
        policyError != null) {
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    final result = await AppScope.of(context).auth.register(
          nickname: nickname,
          email: email,
          password: password,
        );

    if (!mounted) {
      return;
    }

    setState(() {
      _isSubmitting = false;
    });

    if (result.isSuccess) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const TargetSelectScreen()),
      );
      return;
    }

    setState(() {
      switch (result.failure) {
        case AuthFailure.emailExists:
          _emailError = 'Такой аккаунт уже зарегистрирован';
          break;
        case AuthFailure.nicknameExists:
          _nicknameError = 'Никнейм уже занят';
          break;
        case AuthFailure.serverError:
        default:
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Ошибка сервера. Попробуйте позже'),
            ),
          );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 360),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 32),
                  Text(
                    'Помодоро ТуДу',
                    style: theme.textTheme.headlineMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Зарегистрируйтесь, чтобы начать!',
                    style: theme.textTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 28),
                  AppTextField(
                    controller: _nicknameController,
                    hintText: 'Никнейм',
                    errorText: _nicknameError,
                    textInputAction: TextInputAction.next,
                  ),
                  const SizedBox(height: 14),
                  AppTextField(
                    controller: _emailController,
                    hintText: 'Email',
                    errorText: _emailError,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    autofillHints: const [AutofillHints.email],
                  ),
                  const SizedBox(height: 14),
                  AppTextField(
                    controller: _passwordController,
                    hintText: 'Пароль',
                    errorText: _passwordError,
                    obscureText: true,
                    textInputAction: TextInputAction.next,
                    autofillHints: const [AutofillHints.newPassword],
                  ),
                  const SizedBox(height: 14),
                  AppTextField(
                    controller: _confirmController,
                    hintText: 'Повторите пароль',
                    errorText: _confirmError,
                    obscureText: true,
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => _submit(),
                    autofillHints: const [AutofillHints.newPassword],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Checkbox(
                        value: _accepted,
                        onChanged: (value) {
                          setState(() {
                            _accepted = value ?? false;
                            if (_accepted) {
                              _policyError = null;
                            }
                          });
                        },
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4),
                        ),
                        side: const BorderSide(color: Color(0xFFCED4DA)),
                        activeColor: AppColors.primary,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: RichText(
                          text: TextSpan(
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: AppColors.mutedText,
                              height: 1.35,
                            ),
                            children: [
                              const TextSpan(text: 'Я согласен с '),
                              TextSpan(
                                text: 'Пользовательским соглашением',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const TextSpan(text: ' и '),
                              TextSpan(
                                text: 'Политикой конфиденциальности',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (_policyError != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      _policyError ?? '',
                      style: const TextStyle(
                        color: AppColors.error,
                        fontSize: 12,
                      ),
                    ),
                  ],
                  const SizedBox(height: 18),
                  ElevatedButton(
                    onPressed: _accepted && !_isSubmitting ? _submit : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      disabledBackgroundColor: const Color(0xFFCFE3D9),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: const StadiumBorder(),
                    ),
                    child: _isSubmitting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text(
                            'Регистрация',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Уже зарегистрированы?',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: AppColors.mutedText,
                        ),
                      ),
                      const SizedBox(width: 6),
                      GestureDetector(
                        onTap: () {
                          Navigator.of(context).pushReplacement(
                            MaterialPageRoute(
                              builder: (_) => const LoginScreen(),
                            ),
                          );
                        },
                        child: Text(
                          'Войти',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
