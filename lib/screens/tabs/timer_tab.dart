import 'package:flutter/material.dart';
import 'package:pomorodo_todo/l10n/app_localizations.dart';

import '../../app/app_scope.dart';
import '../../app/timer_controller.dart';
import '../../data/models.dart';
import '../../ui/theme/app_colors.dart';
import '../../view_models/timer_view_model.dart';
import '../task_detail_screen.dart';

class TimerTab extends StatefulWidget {
  const TimerTab({super.key});

  @override
  State<TimerTab> createState() => _TimerTabState();
}

class _TimerTabState extends State<TimerTab> {
  TimerViewModel? _vm;
  bool _didInitVm = false;
  bool _dialogOpen = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_didInitVm) {
      _didInitVm = true;
      final scope = AppScope.of(context);
      _vm = TimerViewModel(
        taskRepository: scope.tasks,
        timerController: scope.timer,
        statsRepository: scope.stats,
      );
      _vm!.addListener(_onVmChanged);
      _vm!.load();
    }
  }

  @override
  void dispose() {
    _vm?.removeListener(_onVmChanged);
    _vm?.dispose();
    super.dispose();
  }

  void _onVmChanged() {
    if (!mounted) return;
    setState(() {});
    _maybeShowDialog();
  }

  void _maybeShowDialog() {
    if (_dialogOpen) return;
    
    final vm = _vm;
    if (vm == null) return;
    
    final dialog = vm.pendingDialog;
    if (dialog == null) return;
    
    _dialogOpen = true;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final consumed = vm.consumeDialog();
      if (consumed == TimerDialog.checkCompletion) {
        await _showCompletionDialog();
      } else if (consumed == TimerDialog.penalty) {
        await _showPenaltyDialog();
      } else if (consumed == TimerDialog.strictModeViolation) {
        await _showStrictModeViolationDialog();
      }
      _dialogOpen = false;
      
      if (mounted && vm.pendingDialog != null) {
        _maybeShowDialog();
      }
    });
  }

  Future<void> _showStrictModeViolationDialog() async {
    final l10n = AppLocalizations.of(context)!;
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
                Text(
                  l10n.sessionInterrupted,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  l10n.strictModeViolationDesc,
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
                    child: Text(l10n.gotIt, style: const TextStyle(fontWeight: FontWeight.w600)),
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
    final vm = _vm;
    if (vm == null) return;
    final l10n = AppLocalizations.of(context)!;

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
                Text(
                  l10n.didYouCompleteTask,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  l10n.sessionFinishedDesc,
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
                    label: Text(l10n.yesIHandledIt, style: const TextStyle(fontWeight: FontWeight.w600)),
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
                    label: Text(l10n.noGiveUp, style: const TextStyle(fontWeight: FontWeight.w600)),
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
                    label: Text(l10n.backToWork, style: const TextStyle(fontWeight: FontWeight.w600)),
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
        await vm.confirmTaskCompleted();
        break;
      case _CompletionResult.penalty:
        await vm.declineTaskCompleted();
        break;
      case _CompletionResult.backToWork:
        vm.returnToWork();
        break;
      default:
        vm.returnToWork();
    }
  }

  Future<void> _showPenaltyDialog() async {
    final vm = _vm;
    if (vm == null) return;
    final l10n = AppLocalizations.of(context)!;

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
                Text(
                  l10n.dontGiveUp,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  l10n.penaltyDesc,
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
                    child: Text(l10n.backToWork, style: const TextStyle(fontWeight: FontWeight.w600)),
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
                    child: Text(l10n.surrenderAnyway, style: const TextStyle(fontWeight: FontWeight.w600)),
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
        vm.penaltyReturnToWork();
        break;
      case _PenaltyResult.surrender:
      default:
        await vm.surrenderTask();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final vm = _vm;
    if (vm == null) {
      return const Center(child: CircularProgressIndicator());
    }
    
    final showNoteMode = vm.mode == TimerMode.note && vm.task != null;

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildTimerCard(theme, l10n, vm, showNoteMode),
            const SizedBox(height: 16),
            if (!showNoteMode) ...[
              Text(
                l10n.freeMode,
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.mutedText,
                ),
              ),
              const SizedBox(height: 8),
              _buildFreeModeCard(theme, l10n, vm),
            ] else ...[
              _buildNoteCard(theme, l10n, vm, vm.task!),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTimerCard(
    ThemeData theme,
    AppLocalizations l10n,
    TimerViewModel vm,
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
          _buildCycleIcons(vm),
          const SizedBox(height: 8),
          Text(
            _phaseLabel(vm, l10n, showNoteMode),
            style: theme.textTheme.bodyMedium?.copyWith(
              color: AppColors.mutedText,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            _formatDuration(vm.remaining),
            style: const TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.w700,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          _buildTimerButtons(vm, l10n),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                l10n.debugMode,
                style: const TextStyle(fontSize: 12, color: AppColors.mutedText),
              ),
              const SizedBox(width: 8),
              SizedBox(
                height: 24,
                child: Switch(
                  value: vm.debugFastMode,
                  onChanged: vm.setDebugFastMode,
                  activeThumbColor: AppColors.primary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTimerButtons(TimerViewModel vm, AppLocalizations l10n) {
    if (vm.phase == TimerPhase.idle) {
      final isDone = vm.mode == TimerMode.note && vm.task != null && vm.task!.isDone;
      return SizedBox(
        width: 140,
        child: ElevatedButton(
          onPressed: isDone
              ? null
              : () {
                  if (vm.mode == TimerMode.note &&
                      vm.taskId != null) {
                    vm.startForTask(vm.taskId!);
                  } else {
                    vm.startFree();
                  }
                },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 10),
            shape: const StadiumBorder(),
          ),
          child: Text(l10n.start),
        ),
      );
    }

    if (vm.phase == TimerPhase.breakTime ||
        vm.phase == TimerPhase.rest) {
      return SizedBox(
        width: 160,
        child: ElevatedButton(
          onPressed: vm.skipBreak,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 10),
            shape: const StadiumBorder(),
          ),
          child: Text(l10n.resume),
        ),
      );
    }

    if (vm.isRunning) {
      return Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: vm.pause,
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.mutedText,
                side: const BorderSide(color: Color(0xFFCDD5CF)),
                padding: const EdgeInsets.symmetric(vertical: 10),
                shape: const StadiumBorder(),
              ),
              child: Text(l10n.pause),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton(
              onPressed: vm.requestStop,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 10),
                shape: const StadiumBorder(),
              ),
              child: Text(l10n.finish),
            ),
          ),
        ],
      );
    }

    return Row(
      children: [
        Expanded(
          child: ElevatedButton(
            onPressed: vm.resume,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 10),
              shape: const StadiumBorder(),
            ),
            child: Text(l10n.resume),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: OutlinedButton(
            onPressed: vm.requestStop,
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.mutedText,
              side: const BorderSide(color: Color(0xFFCDD5CF)),
              padding: const EdgeInsets.symmetric(vertical: 10),
              shape: const StadiumBorder(),
            ),
            child: Text(l10n.finish),
          ),
        ),
      ],
    );
  }

  Widget _buildFreeModeCard(ThemeData theme, AppLocalizations l10n, TimerViewModel vm) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE1E6E2)),
      ),
      child: _buildStatsRow(theme, l10n, vm),
    );
  }

  Widget _buildNoteCard(
    ThemeData theme,
    AppLocalizations l10n,
    TimerViewModel vm,
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
              l10n.appNote,
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: AppColors.mutedText,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              task.title.isEmpty ? l10n.noTitle : task.title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              noteText.isEmpty
                  ? l10n.addNoteDescriptionHint
                  : noteText,
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppColors.mutedText,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 12),
            _buildStatsRow(theme, l10n, vm),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsRow(ThemeData theme, AppLocalizations l10n, TimerViewModel vm) {
    return Row(
      children: [
        Expanded(
          child: _StatChip(
            icon: Icons.check_circle_outline,
            title: l10n.completedToday,
            value: l10n.pomodoroCount(vm.todayPomodoros),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _StatChip(
            icon: Icons.track_changes,
            title: l10n.focusToday,
            value: l10n.minutesShort(vm.todayFocusMinutes),
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

  Widget _buildCycleIcons(TimerViewModel vm) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(TimerController.totalCycles, (index) {
        final i = index + 1;
        final isCompleted = i < vm.cycle ||
            (i == vm.cycle &&
                (vm.phase == TimerPhase.breakTime ||
                    vm.phase == TimerPhase.rest));
        final isActive = i == vm.cycle && vm.phase == TimerPhase.focus;
        final isUpcoming = i == vm.cycle + 1 && vm.phase == TimerPhase.breakTime;

        IconData icon;
        Color color;

        if (isCompleted) {
          icon = Icons.check_circle;
          color = AppColors.primary;
        } else if (isActive) {
          icon = Icons.play_circle;
          color = AppColors.primary;
        } else if (isUpcoming) {
          icon = Icons.play_circle_outline;
          color = AppColors.primary.withOpacity(0.5);
        } else {
          icon = Icons.circle_outlined;
          color = AppColors.mutedText;
        }

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2),
          child: Icon(
            icon,
            size: 16,
            color: color,
          ),
        );
      }),
    );
  }

  String _phaseLabel(TimerViewModel vm, AppLocalizations l10n, bool showNoteMode) {
    if (vm.isPenalty) {
      return l10n.penaltyFocus;
    }
    switch (vm.phase) {
      case TimerPhase.breakTime:
        return l10n.timeToRest;
      case TimerPhase.rest:
        return l10n.timeToSeriousRest;
      case TimerPhase.focus:
      case TimerPhase.idle:
        return showNoteMode
            ? l10n.remainToFocus
            : l10n.freeFocusMode;
    }
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
