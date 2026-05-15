import 'dart:math';

import 'package:flutter/material.dart';

import '../../app/app_scope.dart';
import '../../data/models.dart';
import '../../ui/theme/app_colors.dart';
import '../login_screen.dart';
import '../settings_screen.dart';

class ProfileTab extends StatefulWidget {
  const ProfileTab({super.key});

  @override
  State<ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends State<ProfileTab> {
  User? _user;
  TargetOption? _target;
  int _doneTasks = 0;
  int _burnedTasks = 0;
  final int _streak = 0; // Hardcoded for now
  bool _isLoading = true;
  bool _showIntervals = true;

  static const List<TargetOption> _options = [
    TargetOption(
      id: 'easy',
      title: 'ЛЕГКИЙ',
      subtitle: 'Цель дня на выбор',
      tasks: 1,
      intervals: 2,
    ),
    TargetOption(
      id: 'tone',
      title: 'В ТОНУСЕ',
      subtitle: 'Цель дня на выбор',
      tasks: 2,
      intervals: 4,
    ),
    TargetOption(
      id: 'burn',
      title: 'ПРОЖАРКА',
      subtitle: 'Цель дня на выбор',
      tasks: 3,
      intervals: 8,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _loadData();
    // Listen to timer to update pomodoros
    WidgetsBinding.instance.addPostFrameCallback((_) {
      AppScope.of(context).timer.addListener(_onTimerChanged);
    });
  }

  @override
  void dispose() {
    AppScope.of(context).timer.removeListener(_onTimerChanged);
    super.dispose();
  }

  void _onTimerChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _loadData() async {
    try {
      final scope = AppScope.of(context);
      final user = await scope.auth.getCurrentUser();
      final targetId = await scope.settings.getSelectedTarget();
      TargetOption? target;
      if (targetId != null) {
        target = _options.firstWhere(
          (o) => o.id == targetId,
          orElse: () => _options[1],
        );
      }

      final tasks = await scope.tasks.fetchTasks();
      int doneCount = 0;
      int burnedCount = 0;
      for (final t in tasks) {
        if (t.isDone) {
          doneCount++;
        } else if (t.isBurned) {
          burnedCount++;
        }
      }

      if (!mounted) return;
      setState(() {
        _user = user;
        _target = target ?? _options[1];
        _doneTasks = doneCount;
        _burnedTasks = burnedCount;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Подтверждение выхода',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                'Действительно выйти из аккаунта?\nВы перейдете на экран входа',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.mutedText,
                      height: 1.4,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.primaryDark,
                      ),
                      child: const Text('Отменить', style: TextStyle(fontWeight: FontWeight.w600)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFE4ECE8),
                        foregroundColor: AppColors.primaryDark,
                        elevation: 0,
                        shape: const StadiumBorder(),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text('Выйти', style: TextStyle(fontWeight: FontWeight.w600)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    if (confirmed != true) return;

    if (!mounted) return;
    await AppScope.of(context).auth.logout();

    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  Future<void> _openSettings() async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const SettingsScreen()),
    );
    _loadData();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final theme = Theme.of(context);
    final nickname = _user?.nickname ?? 'Пользователь';

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Профиль',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
                ),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.settings_outlined),
                      onPressed: _openSettings,
                    ),
                    IconButton(
                      icon: const Icon(Icons.logout),
                      onPressed: _logout,
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 24),
            Container(
              width: 80,
              height: 80,
              decoration: const BoxDecoration(
                color: Color(0xFFE6F3EE),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.person, size: 40, color: AppColors.primaryDark),
            ),
            const SizedBox(height: 16),
            Text(
              nickname,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFE6F3EE),
                borderRadius: BorderRadius.circular(999),
              ),
              child: const Text(
                'Уровень 1  |  Опыт 0',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primaryDark,
                ),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(child: _buildStatBox('серия', _streak.toString(), Icons.local_fire_department, AppColors.mutedText)),
                const SizedBox(width: 8),
                Expanded(child: _buildStatBox('выполнено', _doneTasks.toString(), Icons.check_circle_outline, AppColors.primaryDark)),
                const SizedBox(width: 8),
                Expanded(child: _buildStatBox('сгорело', _burnedTasks.toString(), Icons.cancel_outlined, AppColors.error)),
              ],
            ),
            const SizedBox(height: 32),
            _buildGoalCard(theme),
          ],
        ),
      ),
    );
  }

  Widget _buildStatBox(String label, String value, IconData icon, Color iconColor) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE1E6E2)),
      ),
      child: Column(
        children: [
          Icon(icon, color: iconColor, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
          ),
          Text(
            label.toUpperCase(),
            style: const TextStyle(fontSize: 10, color: AppColors.mutedText, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _buildGoalCard(ThemeData theme) {
    final timer = AppScope.of(context).timer;
    final int targetTasks = _target?.tasks ?? 1;
    final int targetIntervals = _target?.intervals ?? 2;

    int passed = 0;
    int targetVal = 1;

    if (_showIntervals) {
      passed = timer.completedPomodoros;
      targetVal = targetIntervals;
    } else {
      passed = _doneTasks;
      targetVal = targetTasks;
    }

    final int remaining = max(0, targetVal - passed);
    final double progress = targetVal == 0 ? 0 : min(1.0, passed / targetVal);
    final int percent = (progress * 100).round();

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE1E6E2)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Цель дня',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFF0F4F2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    _buildToggleBtn('Интервалы', _showIntervals, () {
                      setState(() => _showIntervals = true);
                    }),
                    _buildToggleBtn('Задачи', !_showIntervals, () {
                      setState(() => _showIntervals = false);
                    }),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: 160,
            height: 160,
            child: Stack(
              fit: StackFit.expand,
              children: [
                CircularProgressIndicator(
                  value: progress,
                  strokeWidth: 16,
                  backgroundColor: const Color(0xFFF0F4F2),
                  color: AppColors.primaryDark,
                ),
                Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '$percent%',
                        style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w700),
                      ),
                      const Text(
                        'Прогресс',
                        style: TextStyle(fontSize: 12, color: AppColors.mutedText),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          _buildGoalRow(AppColors.primaryDark, 'Пройдено', passed.toString()),
          const SizedBox(height: 12),
          _buildGoalRow(const Color(0xFFE1E6E2), 'Осталось', remaining.toString()),
        ],
      ),
    );
  }

  Widget _buildToggleBtn(String text, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          border: isSelected ? Border.all(color: const Color(0xFFE1E6E2)) : null,
          boxShadow: isSelected
              ? [BoxShadow(color: Colors.black.withAlpha(13), blurRadius: 2, offset: const Offset(0, 1))]
              : null,
        ),
        child: Text(
          text,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: isSelected ? AppColors.primaryDark : AppColors.mutedText,
          ),
        ),
      ),
    );
  }

  Widget _buildGoalRow(Color dotColor, String label, String value) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(fontSize: 14, color: AppColors.mutedText),
        ),
        const Spacer(),
        Text(
          value,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
      ],
    );
  }
}
