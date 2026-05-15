import 'package:flutter/material.dart';

import '../app/app_scope.dart';
import '../ui/theme/app_colors.dart';
import '../view_models/notifications_view_model.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  NotificationsViewModel? _viewModel;
  bool _didAttach = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_didAttach) {
      _didAttach = true;
      _viewModel = NotificationsViewModel(
        settingsRepository: AppScope.of(context).settings,
        notificationService: AppScope.of(context).notifications,
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

  @override
  Widget build(BuildContext context) {
    final vm = _viewModel;
    if (vm == null) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    return Scaffold(
      backgroundColor: const Color(0xFFF6FAF7),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('Уведомления', style: TextStyle(fontWeight: FontWeight.w700)),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildSectionHeader('PUSH-УВЕДОМЛЕНИЯ'),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE1E6E2)),
                ),
                child: Column(
                  children: [
                    _buildSwitchTile(
                      title: 'Таймер завершен',
                      subtitle: 'Сигнал об окончании фокуса',
                      value: vm.timerEnd,
                      onChanged: vm.setTimerEnd,
                    ),
                    const Divider(height: 1, indent: 16),
                    _buildSwitchTile(
                      title: 'Перерыв начат',
                      subtitle: 'Напоминание об отдыхе',
                      value: vm.breakStart,
                      onChanged: vm.setBreakStart,
                    ),
                    const Divider(height: 1, indent: 16),
                    _buildSwitchTile(
                      title: 'Ежедневные напоминания',
                      subtitle: 'Мотивация к началу работы',
                      value: vm.dailyReminders,
                      onChanged: vm.setDailyReminders,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildSectionHeader('РЕЖИМ ТИШИНЫ'),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: GestureDetector(
                      onTap: vm.toggleQuietMode,
                      child: Text(
                        vm.quietMode ? 'ВКЛЮЧЕНО' : 'ВЫКЛЮЧЕНО',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: vm.quietMode ? AppColors.primaryDark : AppColors.mutedText,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE1E6E2)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Уведомления не будут приходить в\nвыбранный промежуток времени.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.mutedText,
                            height: 1.4,
                          ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: _buildTimePicker(
                            label: 'Начало',
                            time: vm.quietStart,
                            onTap: () async {
                              final t = await showTimePicker(context: context, initialTime: vm.quietStart);
                              if (t != null) vm.setQuietStart(t);
                            },
                          ),
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 12),
                          child: Text('—', style: TextStyle(color: AppColors.mutedText, fontSize: 16)),
                        ),
                        Expanded(
                          child: _buildTimePicker(
                            label: 'Конец',
                            time: vm.quietEnd,
                            onTap: () async {
                              final t = await showTimePicker(context: context, initialTime: vm.quietEnd);
                              if (t != null) vm.setQuietEnd(t);
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Повторять',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.mutedText),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: List.generate(7, (index) {
                        final isSelected = vm.days[index];
                        return GestureDetector(
                          onTap: () => vm.toggleDay(index),
                          child: Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: isSelected ? AppColors.primaryDark : const Color(0xFFE6EAE7),
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(
                                vm.dayLabels[index],
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: isSelected ? Colors.white : AppColors.mutedText,
                                ),
                              ),
                            ),
                          ),
                        );
                      }),
                    ),
                  ],
                ),
              ),
            ],
          ),
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
          color: AppColors.mutedText,
        ),
      ),
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 16, color: Colors.black87)),
                Text(subtitle, style: const TextStyle(fontSize: 12, color: AppColors.mutedText)),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: AppColors.primaryDark,
          ),
        ],
      ),
    );
  }

  Widget _buildTimePicker({required String label, required TimeOfDay time, required VoidCallback onTap}) {
    final h = time.hour.toString().padLeft(2, '0');
    final m = time.minute.toString().padLeft(2, '0');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 10, color: AppColors.mutedText, fontWeight: FontWeight.w600)),
        const SizedBox(height: 4),
        GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFE6EAE7),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text('$h:$m', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
          ),
        ),
      ],
    );
  }
}
