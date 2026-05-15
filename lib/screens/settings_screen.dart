import 'dart:async';
import 'package:flutter/material.dart';
import '../app/app_scope.dart';
import '../ui/theme/app_colors.dart';
import '../view_models/settings_view_model.dart';
import 'change_password_screen.dart';
import 'login_screen.dart';
import 'notifications_screen.dart';
import 'target_select_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  SettingsViewModel? _viewModel;
  bool _didAttach = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_didAttach) {
      _didAttach = true;
      final scope = AppScope.of(context);
      _viewModel = SettingsViewModel(
        settingsRepository: scope.settings,
        authRepository: scope.auth,
      );
      _viewModel!.addListener(_onViewModelChanged);
      _viewModel!.load();
    }
  }

  @override
  void dispose() {
    _viewModel?.removeListener(_onViewModelChanged);
    _viewModel?.dispose();
    super.dispose();
  }

  void _onViewModelChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _deleteAccount() async {
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => const _DeleteAccountDialog(),
    );

    if (confirmed == true && mounted) {
      await _viewModel?.deleteAccount();
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final vm = _viewModel;
    if (vm == null || vm.isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF6FAF7),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Настройки',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 8,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildSectionHeader('НАСТРОЙКИ ПРИЛОЖЕНИЯ'),
                    _buildContainer([
                      _buildListTile(
                        icon: Icons.notifications_none,
                        title: 'Уведомления',
                        trailing: const Icon(
                          Icons.chevron_right,
                          color: AppColors.mutedText,
                        ),
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const NotificationsScreen(),
                            ),
                          );
                        },
                      ),
                    ]),
                    const SizedBox(height: 24),
                    _buildSectionHeader('СТАТУС'),
                    _buildContainer([
                      _buildListTile(
                        title: 'Цель',
                        subtitle: 'Ваша текущая активность',
                        onTap: () async {
                          final targetId = await vm.getSelectedTargetId();
                          if (!context.mounted) return;
                          await Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => TargetSelectScreen(
                                isChanging: true,
                                initialId: targetId,
                              ),
                            ),
                          );
                          vm.load();
                        },
                        trailing: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE6F3EE),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            vm.targetTitle.toUpperCase(),
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primaryDark,
                            ),
                          ),
                        ),
                      ),
                    ]),
                    const SizedBox(height: 24),
                    _buildSectionHeader('АККАУНТ'),
                    _buildContainer([
                      _buildListTile(
                        icon: Icons.support_agent_outlined,
                        title: 'Связь с поддержкой',
                        trailing: const Icon(
                          Icons.chevron_right,
                          color: AppColors.mutedText,
                        ),
                        onTap: () {},
                      ),
                      const Divider(height: 1, indent: 48),
                      _buildListTile(
                        icon: Icons.lock_outline,
                        title: 'Сменить пароль',
                        trailing: const Icon(
                          Icons.chevron_right,
                          color: AppColors.mutedText,
                        ),
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const ChangePasswordScreen(),
                            ),
                          );
                        },
                      ),
                      const Divider(height: 1, indent: 48),
                      _buildListTile(
                        icon: Icons.delete_outline,
                        iconColor: AppColors.error,
                        title: 'Удалить аккаунт',
                        titleColor: AppColors.error,
                        onTap: _deleteAccount,
                      ),
                    ]),
                  ],
                ),
              ),
            ),
            const Padding(
              padding: EdgeInsets.only(bottom: 24),
              child: Text(
                'Версия: 1.0.0',
                style: TextStyle(fontSize: 12, color: AppColors.mutedText),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: AppColors.primaryDark,
        ),
      ),
    );
  }

  Widget _buildContainer(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE1E6E2)),
      ),
      child: Column(children: children),
    );
  }

  Widget _buildListTile({
    IconData? icon,
    Color iconColor = AppColors.primaryDark,
    required String title,
    Color titleColor = Colors.black87,
    String? subtitle,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return ListTile(
      onTap: onTap,
      leading: icon != null ? Icon(icon, color: iconColor) : null,
      title: Text(title, style: TextStyle(color: titleColor, fontSize: 16)),
      subtitle: subtitle != null
          ? Text(
              subtitle,
              style: const TextStyle(color: AppColors.mutedText, fontSize: 12),
            )
          : null,
      trailing: trailing,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    );
  }
}

class _DeleteAccountDialog extends StatefulWidget {
  const _DeleteAccountDialog();

  @override
  State<_DeleteAccountDialog> createState() => _DeleteAccountDialogState();
}

class _DeleteAccountDialogState extends State<_DeleteAccountDialog> {
  int _seconds = 10;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_seconds > 0) {
        setState(() => _seconds--);
      } else {
        _timer?.cancel();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Вы уверены?',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            Text(
              'Вы действительно хотите удалить аккаунт?\nОтменить данное действие невозможно.\nПосле подтверждения вся сохраненная о Вас информация будет удалена с наших серверов.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.mutedText,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.primaryDark,
                  ),
                  child: const Text(
                    'Отменить',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
                const SizedBox(width: 8),
                TextButton(
                  onPressed: _seconds == 0
                      ? () => Navigator.of(context).pop(true)
                      : null,
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.primaryDark,
                    disabledForegroundColor: AppColors.mutedText,
                  ),
                  child: Text(
                    _seconds > 0 ? 'Удалить ($_seconds)' : 'Удалить',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
