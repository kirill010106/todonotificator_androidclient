import 'package:flutter/material.dart';

import '../../app/app_scope.dart';
import '../../app/timer_controller.dart';
import '../../data/models.dart';
import '../../ui/theme/app_colors.dart';
import '../task_detail_screen.dart';

class TimerTab extends StatefulWidget {
  const TimerTab({super.key});

  @override
  State<TimerTab> createState() => _TimerTabState();
}

class _TimerTabState extends State<TimerTab> {
  TimerController? _controller;
  bool _didAttach = false;
  bool _dialogOpen = false;
  Task? _task;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_didAttach) {
      _didAttach = true;
      _controller = AppScope.of(context).timer;
      _controller?.addListener(_handleTimerChange);
      _refreshTask();
    }
  }

  @override
  void dispose() {
    _controller?.removeListener(_handleTimerChange);
    super.dispose();
  }

  void _handleTimerChange() {
    if (!mounted) {
      return;
    }
    setState(() {});
    _maybeShowDialog();
    _refreshTask();
  }

  Future<void> _refreshTask({bool force = false}) async {
    final controller = _controller;
    if (controller == null) {
      return;
    }
    if (controller.mode != TimerMode.note || controller.taskId == null) {
      if (_task != null) {
        setState(() {
          _task = null;
        });
      }
      return;
    }
    if (!force && _task?.id == controller.taskId) {
      return;
    }
    final task = await AppScope.of(context).tasks.getTask(controller.taskId!);
    if (!mounted) {
      return;
    }
    if (task == null) {
      if (_task != null) {
        setState(() {
          _task = null;
        });
      }
      return;
    }
    setState(() {
      _task = task;
    });
  }

  void _maybeShowDialog() {
    if (_dialogOpen) {
      return;
    }
    final controller = _controller;
    if (controller == null) {
      return;
    }
    final dialog = controller.pendingDialog;
    if (dialog == null) {
      return;
    }
    _dialogOpen = true;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final consumed = controller.consumeDialog();
      if (consumed == TimerDialog.checkCompletion) {
        await _showCompletionDialog();
      } else if (consumed == TimerDialog.penalty) {
        await _showPenaltyDialog();
      } else if (consumed == TimerDialog.strictModeViolation) {
        await _showStrictModeViolationDialog();
      }
      _dialogOpen = false;
      
      if (mounted && controller.pendingDialog != null) {
        _maybeShowDialog();
      }
    });
  }

  Future<void> _showStrictModeViolationDialog() async {
    await showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFE8E8),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(Icons.timer_off_outlined, color: Color(0xFFD32F2F), size: 28),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Сессия прервана!',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Вы нарушили "Строгий режим", свернув приложение более чем на 10 секунд. Текущая сессия аннулирована.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.mutedText,
                        height: 1.4,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0F5B42),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                    child: const Text('Понятно', style: TextStyle(fontWeight: FontWeight.w600)),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _showCompletionDialog() async {
    final controller = _controller;
    if (controller == null) {
      return;
    }

    final result = await showDialog<_CompletionResult>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F5B42),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(Icons.check_circle_outline, color: Colors.white, size: 28),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Вы выполнили задачу?',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Сессия завершена. Отметьте прогресс для сохранения статистики.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.mutedText,
                        height: 1.4,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.of(context).pop(_CompletionResult.completed);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0F5B42),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                    icon: const Icon(Icons.check_circle_outline, size: 20),
                    label: const Text('Да, я справился!', style: TextStyle(fontWeight: FontWeight.w600)),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.of(context).pop(_CompletionResult.penalty);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFFE8E8),
                      foregroundColor: const Color(0xFFD32F2F),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                    icon: const Icon(Icons.cancel_outlined, size: 20),
                    label: const Text('Нет, сдаться', style: TextStyle(fontWeight: FontWeight.w600)),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.of(context).pop(_CompletionResult.backToWork);
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.black87,
                      side: const BorderSide(color: Color(0xFFE1E6E2)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    icon: const Icon(Icons.arrow_back, size: 20),
                    label: const Text('Вернуться к работе', style: TextStyle(fontWeight: FontWeight.w600)),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    switch (result) {
      case _CompletionResult.completed:
        await controller.confirmTaskCompleted();
        break;
      case _CompletionResult.penalty:
        await controller.declineTaskCompleted();
        break;
      case _CompletionResult.backToWork:
        controller.returnToWork();
        break;
      default:
        controller.returnToWork();
    }
    await _refreshTask(force: true);
  }

  Future<void> _showPenaltyDialog() async {
    final controller = _controller;
    if (controller == null) {
      return;
    }

    final result = await showDialog<_PenaltyResult>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFE8E8),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(Icons.warning_amber_rounded, color: Color(0xFFD32F2F), size: 28),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Не сдавайся, ты почти у цели!',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'В случае сдачи вы получите штраф к очкам опыта. Осталось совсем немного до конца таймера.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.mutedText,
                        height: 1.4,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop(_PenaltyResult.backToWork);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0F5B42),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                    child: const Text('Вернуться к работе', style: TextStyle(fontWeight: FontWeight.w600)),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    onPressed: () {
                      Navigator.of(context).pop(_PenaltyResult.surrender);
                    },
                    style: TextButton.styleFrom(
                      foregroundColor: const Color(0xFFD32F2F),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Все равно сдаться', style: TextStyle(fontWeight: FontWeight.w600)),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    switch (result) {
      case _PenaltyResult.backToWork:
        controller.penaltyReturnToWork();
        break;
      case _PenaltyResult.surrender:
      default:
        await controller.surrenderTask();
        await _refreshTask(force: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final controller = _controller;
    if (controller == null) {
      return const SizedBox.shrink();
    }

    final showNoteMode = controller.mode == TimerMode.note && _task != null;

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildTimerCard(theme, controller, showNoteMode),
            const SizedBox(height: 16),
            if (!showNoteMode) ...[
              Text(
                'Свободный режим',
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.mutedText,
                ),
              ),
              const SizedBox(height: 8),
              _buildFreeModeCard(theme, controller),
            ] else ...[
              _buildNoteCard(theme, controller, _task!),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTimerCard(
    ThemeData theme,
    TimerController controller,
    bool showNoteMode,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE1E6E2)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFE7EEE9),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              _cycleLabel(controller),
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppColors.primaryDark,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _phaseLabel(controller, showNoteMode),
            style: theme.textTheme.bodyMedium?.copyWith(
              color: AppColors.mutedText,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            _formatDuration(controller.remaining),
            style: const TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.w700,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          _buildTimerButtons(controller, _task),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Дебаг (сек вместо мин):',
                style: TextStyle(fontSize: 12, color: AppColors.mutedText),
              ),
              const SizedBox(width: 8),
              SizedBox(
                height: 24,
                child: Switch(
                  value: controller.debugFastMode,
                  onChanged: controller.setDebugFastMode,
                  activeThumbColor: AppColors.primary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTimerButtons(TimerController controller, Task? task) {
    if (controller.phase == TimerPhase.idle) {
      final isDone = controller.mode == TimerMode.note && task != null && task.isDone;
      return SizedBox(
        width: 140,
        child: ElevatedButton(
          onPressed: isDone
              ? null
              : () {
                  if (controller.mode == TimerMode.note &&
                      controller.taskId != null) {
                    controller.startForTask(controller.taskId!);
                  } else {
                    controller.startFree();
                  }
                },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 10),
            shape: const StadiumBorder(),
          ),
          child: const Text('Начать'),
        ),
      );
    }

    if (controller.phase == TimerPhase.breakTime ||
        controller.phase == TimerPhase.rest) {
      return SizedBox(
        width: 160,
        child: ElevatedButton(
          onPressed: controller.skipBreak,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 10),
            shape: const StadiumBorder(),
          ),
          child: const Text('Продолжить'),
        ),
      );
    }

    if (controller.isRunning) {
      return Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: controller.pause,
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.mutedText,
                side: const BorderSide(color: Color(0xFFCDD5CF)),
                padding: const EdgeInsets.symmetric(vertical: 10),
                shape: const StadiumBorder(),
              ),
              child: const Text('Приостановить'),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton(
              onPressed: controller.requestStop,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 10),
                shape: const StadiumBorder(),
              ),
              child: const Text('Закончить'),
            ),
          ),
        ],
      );
    }

    return Row(
      children: [
        Expanded(
          child: ElevatedButton(
            onPressed: controller.resume,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 10),
              shape: const StadiumBorder(),
            ),
            child: const Text('Продолжить'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: OutlinedButton(
            onPressed: controller.requestStop,
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.mutedText,
              side: const BorderSide(color: Color(0xFFCDD5CF)),
              padding: const EdgeInsets.symmetric(vertical: 10),
              shape: const StadiumBorder(),
            ),
            child: const Text('Закончить'),
          ),
        ),
      ],
    );
  }

  Widget _buildFreeModeCard(ThemeData theme, TimerController controller) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE1E6E2)),
      ),
      child: _buildStatsRow(theme, controller),
    );
  }

  Widget _buildNoteCard(
    ThemeData theme,
    TimerController controller,
    Task task,
  ) {
    final noteText = extractPlainNote(task.note);

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () async {
        await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => TaskDetailScreen(taskId: task.id),
          ),
        );
        await _refreshTask();
      },
      child: Container(
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
              'Заметка',
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: AppColors.mutedText,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              task.title.isEmpty ? 'Без названия' : task.title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              noteText.isEmpty
                  ? 'Добавьте описание заметки...'
                  : noteText,
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppColors.mutedText,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 12),
            _buildStatsRow(theme, controller),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsRow(ThemeData theme, TimerController controller) {
    return Row(
      children: [
        Expanded(
          child: _StatChip(
            icon: Icons.check_circle_outline,
            title: 'Выполнено',
            value: '${controller.completedPomodoros} Помодоро',
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _StatChip(
            icon: Icons.track_changes,
            title: 'Фокус',
            value: '${controller.focusRate}%',
          ),
        ),
      ],
    );
  }

  String _formatDuration(Duration duration) {
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    final totalMinutes = duration.inMinutes;
    return '${totalMinutes.toString().padLeft(2, '0')}:$seconds';
  }

  String _phaseLabel(TimerController controller, bool showNoteMode) {
    if (controller.isPenalty) {
      return 'Штрафной фокус';
    }
    switch (controller.phase) {
      case TimerPhase.breakTime:
        return 'Пора отдохнуть';
      case TimerPhase.rest:
        return 'Пора серьезно отдохнуть';
      case TimerPhase.focus:
      case TimerPhase.idle:
        return showNoteMode
            ? 'Осталось сфокусироваться!'
            : 'Свободный режим фокуса';
    }
  }

  String _cycleLabel(TimerController controller) {
    final cycle = controller.cycle;
    if (controller.phase == TimerPhase.breakTime) {
      final next = cycle == TimerController.totalCycles ? 1 : cycle + 1;
      return 'Цикл $cycle/${TimerController.totalCycles} → '
          'Цикл $next/${TimerController.totalCycles}';
    }
    if (controller.phase == TimerPhase.rest) {
      return 'Цикл $cycle/${TimerController.totalCycles} → '
          'Цикл 1/${TimerController.totalCycles}';
    }
    return 'Цикл $cycle/${TimerController.totalCycles}';
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({
    required this.icon,
    required this.title,
    required this.value,
  });

  final IconData icon;
  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F4F2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE1E6E2)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppColors.primaryDark),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 10,
                    color: AppColors.mutedText,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primaryDark,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

enum _CompletionResult {
  completed,
  penalty,
  backToWork,
}

enum _PenaltyResult {
  backToWork,
  surrender,
}
