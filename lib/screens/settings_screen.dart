import 'dart:async';
import 'package:flutter/material.dart';
import 'package:pomorodo_todo/l10n/app_localizations.dart';
import '../app/app_scope.dart';
import '../ui/theme/app_colors.dart';
import '../view_models/settings_view_model.dart';
import 'change_password_screen.dart';
import 'login_screen.dart';
import 'notifications_screen.dart';
import 'target_select_screen.dart';
import 'category_management_screen.dart';

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

  Future<void> _showLanguageSheet(BuildContext context, SettingsViewModel vm) async {
    final l10n = AppLocalizations.of(context)!;
    final services = AppScope.of(context);

    await showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: Text(l10n.russian),
                trailing: vm.languageCode == 'ru'
                    ? const Icon(Icons.check, color: AppColors.primary)
                    : null,
                onTap: () {
                  vm.setLanguage('ru');
                  services.locale.setLocale(const Locale('ru'));
                  Navigator.pop(context);
                },
              ),
              ListTile(
                title: Text(l10n.english),
                trailing: vm.languageCode == 'en'
                    ? const Icon(Icons.check, color: AppColors.primary)
                    : null,
                onTap: () {
                  vm.setLanguage('en');
                  services.locale.setLocale(const Locale('en'));
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        );
      },
    );
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
    final l10n = AppLocalizations.of(context)!;
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
        title: Text(
          l10n.settings,
          style: const TextStyle(fontWeight: FontWeight.w700),
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
                    _buildSectionHeader(l10n.appSettings),
                    _buildContainer([
                      _buildListTile(
                        icon: Icons.notifications_none,
                        title: l10n.notifications,
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
                      const Divider(height: 1, indent: 48),
                      _buildListTile(
                        icon: Icons.bookmarks_outlined,
                        title: l10n.categories,
                        trailing: const Icon(
                          Icons.chevron_right,
                          color: AppColors.mutedText,
                        ),
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const CategoryManagementScreen(),
                            ),
                          );
                        },
                      ),
                      const Divider(height: 1, indent: 48),
                      _buildListTile(
                        icon: Icons.language,
                        title: l10n.language,
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
                            vm.languageCode == 'ru'
                                ? l10n.russian.toUpperCase()
                                : l10n.english.toUpperCase(),
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primaryDark,
                            ),
                          ),
                        ),
                        onTap: () => _showLanguageSheet(context, vm),
                      ),
                      const Divider(height: 1, indent: 48),
                      _buildListTile(
                        icon: Icons.timer_outlined,
                        title: l10n.strictMode,
                        subtitle: l10n.strictModeDesc,
                        trailing: Switch(
                          value: vm.strictMode,
                          onChanged: (val) => vm.setStrictMode(val),
                          activeThumbColor: AppColors.primary,
                        ),
                      ),
                    ]),
                    const SizedBox(height: 24),
                    _buildSectionHeader(l10n.statusHeader),
                    _buildContainer([
                      _buildListTile(
                        title: l10n.goal,
                        subtitle: l10n.currentActivityDesc,
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
                            (vm.targetTitle == 'easy'
                                    ? l10n.paceEasyTitle
                                    : vm.targetTitle == 'burn'
                                        ? l10n.paceRoastTitle
                                        : l10n.paceToneTitle)
                                .toUpperCase(),
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
                    _buildSectionHeader(l10n.dataBackup),
                    _buildContainer([
                      _buildListTile(
                        icon: Icons.upload_file_outlined,
                        title: l10n.exportData,
                        onTap: () async {
                          final success = await vm.exportData(l10n);
                          if (!mounted) return;
                          if (!success) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(l10n.exportFailure)),
                            );
                          }
                        },
                      ),
                      const Divider(height: 1, indent: 48),
                      _buildListTile(
                        icon: Icons.file_download_outlined,
                        title: l10n.importData,
                        onTap: () async {
                          final result = await vm.importData();
                          if (!mounted) return;
                          if (result == true) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(l10n.importSuccess)),
                            );
                          } else if (result == false) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(l10n.importFailure)),
                            );
                          }
                        },
                      ),
                    ]),
                    const SizedBox(height: 24),
                    _buildSectionHeader(l10n.accountHeader),
                    _buildContainer([
                      _buildListTile(
                        icon: Icons.support_agent_outlined,
                        title: l10n.support,
                        trailing: const Icon(
                          Icons.chevron_right,
                          color: AppColors.mutedText,
                        ),
                        onTap: () {},
                      ),
                      const Divider(height: 1, indent: 48),
                      _buildListTile(
                        icon: Icons.lock_outline,
                        title: l10n.changePassword,
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
                        title: l10n.deleteAccount,
                        titleColor: AppColors.error,
                        onTap: _deleteAccount,
                      ),
                    ]),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 24),
              child: Text(
                l10n.versionLabel('1.0.0'),
                style: const TextStyle(fontSize: 12, color: AppColors.mutedText),
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
    final l10n = AppLocalizations.of(context)!;
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.areYouSure,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            Text(
              l10n.deleteAccountDesc,
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
                  child: Text(
                    l10n.cancel,
                    style: const TextStyle(fontWeight: FontWeight.w600),
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
                    _seconds > 0 ? l10n.deleteTimer(_seconds) : l10n.delete,
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
