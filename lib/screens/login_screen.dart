import 'package:flutter/material.dart';
import 'package:pomorodo_todo/l10n/app_localizations.dart';

import '../app/app_scope.dart';
import '../data/models.dart';
import '../ui/theme/app_colors.dart';
import '../ui/widgets/app_text_field.dart';
import 'home_screen.dart';
import 'register_screen.dart';
import 'target_select_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _loginController = TextEditingController();
  final _passwordController = TextEditingController();

  String? _loginError;
  String? _passwordError;
  String? _bannerMessage;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _loginController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    final l10n = AppLocalizations.of(context)!;

    final login = _loginController.text.trim();
    final password = _passwordController.text;

    String? loginError;
    String? passwordError;

    if (login.isEmpty) {
      loginError = l10n.fieldRequired;
    }
    if (password.isEmpty) {
      passwordError = l10n.fieldRequired;
    }

    setState(() {
      _loginError = loginError;
      _passwordError = passwordError;
      _bannerMessage = null;
    });

    if (loginError != null || passwordError != null) {
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    final auth = AppScope.of(context).auth;
    final result = await auth.login(login: login, password: password);

    if (!mounted) {
      return;
    }

    setState(() {
      _isSubmitting = false;
    });

    if (result.isSuccess) {
      final targetId = await AppScope.of(context).settings.getSelectedTarget();
      if (!mounted) {
        return;
      }
      if (targetId == null) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const TargetSelectScreen()),
        );
      } else {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const HomeScreen()),
        );
      }
      return;
    }

    setState(() {
      _bannerMessage = _mapFailure(result.failure, l10n);
    });
  }

  String _mapFailure(AuthFailure? failure, AppLocalizations l10n) {
    switch (failure) {
      case AuthFailure.invalidCredentials:
        return l10n.errorInvalidCredentials;
      case AuthFailure.serverError:
        return l10n.errorServer;
      default:
        return l10n.errorServer;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

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
                  if (_bannerMessage != null) ...[
                    _buildBanner(theme),
                    const SizedBox(height: 20),
                  ],
                  const SizedBox(height: 24),
                  Text(
                    l10n.appTitle,
                    style: theme.textTheme.headlineMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    l10n.welcomeBack,
                    style: theme.textTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 28),
                  AppTextField(
                    controller: _loginController,
                    hintText: '${l10n.email} / ${l10n.nickname}',
                    errorText: _loginError,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    autofillHints: const [AutofillHints.email],
                  ),
                  const SizedBox(height: 14),
                  AppTextField(
                    controller: _passwordController,
                    hintText: l10n.password,
                    errorText: _passwordError,
                    obscureText: true,
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => _submit(),
                    autofillHints: const [AutofillHints.password],
                  ),
                  const SizedBox(height: 18),
                  ElevatedButton(
                    onPressed: _isSubmitting ? null : _submit,
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
                        : Text(
                            l10n.login,
                            style: const TextStyle(
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
                        l10n.noAccount,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: AppColors.mutedText,
                        ),
                      ),
                      const SizedBox(width: 6),
                      GestureDetector(
                        onTap: () {
                          Navigator.of(context).pushReplacement(
                            MaterialPageRoute(
                              builder: (_) => const RegisterScreen(),
                            ),
                          );
                        },
                        child: Text(
                          l10n.register,
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

  Widget _buildBanner(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.errorBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.error),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: AppColors.error, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _bannerMessage ?? '',
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppColors.error,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          InkWell(
            onTap: () {
              setState(() {
                _bannerMessage = null;
              });
            },
            child: const Icon(Icons.close, color: AppColors.error, size: 18),
          ),
        ],
      ),
    );
  }
}
