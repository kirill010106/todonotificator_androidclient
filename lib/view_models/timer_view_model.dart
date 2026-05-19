import 'dart:async';
import 'package:flutter/material.dart';
import '../app/timer_controller.dart';
import '../data/models.dart';
import '../data/repositories.dart';

class TimerViewModel extends ChangeNotifier {
  TimerViewModel({
    required TaskRepository taskRepository,
    required TimerController timerController,
    required StatsRepository statsRepository,
  })  : _taskRepository = taskRepository,
        _timerController = timerController,
        _statsRepository = statsRepository {
    _timerController.addListener(_handleTimerChange);
  }

  final TaskRepository _taskRepository;
  final TimerController _timerController;
  final StatsRepository _statsRepository;

  Task? _task;
  bool _isLoadingTask = false;
  DailyStats? _todayStats;
  bool _isDisposed = false;

  Task? get task => _task;
  bool get isLoadingTask => _isLoadingTask;

  TimerController get controller => _timerController;

  // Expose controller properties for convenience
  TimerMode get mode => _timerController.mode;
  int? get taskId => _timerController.taskId;
  TimerPhase get phase => _timerController.phase;
  Duration get remaining => _timerController.remaining;
  bool get isRunning => _timerController.isRunning;
  bool get isPenalty => _timerController.isPenalty;
  int get cycle => _timerController.cycle;

  // Daily stats
  int get todayPomodoros => _todayStats?.pomodoros ?? 0;
  int get todayFocusMinutes => (_todayStats?.focusSeconds ?? 0) ~/ 60;

  bool get debugFastMode => _timerController.debugFastMode;
  TimerDialog? get pendingDialog => _timerController.pendingDialog;

  void _handleTimerChange() {
    if (_isDisposed) return;
    
    // We don't await here because this is a listener sync callback.
    // We trigger async refreshes which will notify when done.
    _refreshTask();
    _refreshStats();
    _safeNotify();
  }

  Future<void> load() async {
    if (_isDisposed) return;
    await Future.wait([
      _refreshTask(),
      _refreshStats(),
    ]);
  }

  Future<void> _refreshStats() async {
    final userId = _timerController.userId;
    if (userId == null || _isDisposed) return;

    final now = DateTime.now();
    final dateStr =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

    try {
      final stats = await _statsRepository.getStats(userId, dateStr);
      if (!_isDisposed) {
        _todayStats = stats;
        _safeNotify();
      }
    } catch (_) {
      // Ignore background refresh errors
    }
  }

  Future<void> _refreshTask({bool force = false}) async {
    if (_isDisposed) return;

    if (_timerController.mode != TimerMode.note || _timerController.taskId == null) {
      if (_task != null) {
        _task = null;
        _safeNotify();
      }
      return;
    }

    if (!force && _task?.id == _timerController.taskId) {
      return;
    }

    _isLoadingTask = true;
    _safeNotify();

    try {
      final task = await _taskRepository.getTask(_timerController.taskId!);
      if (!_isDisposed) {
        _task = task;
      }
    } finally {
      if (!_isDisposed) {
        _isLoadingTask = false;
        _safeNotify();
      }
    }
  }

  TimerDialog? consumeDialog() => _timerController.consumeDialog();

  Future<void> confirmTaskCompleted() async {
    await _timerController.confirmTaskCompleted();
    await _refreshTask(force: true);
  }

  Future<void> declineTaskCompleted() async {
    await _timerController.declineTaskCompleted();
    await _refreshTask(force: true);
  }

  void returnToWork() => _timerController.returnToWork();
  void penaltyReturnToWork() => _timerController.penaltyReturnToWork();

  Future<void> surrenderTask() async {
    await _timerController.surrenderTask();
    await _refreshTask(force: true);
  }

  void startForTask(int id) => _timerController.startForTask(id);
  void startFree() => _timerController.startFree();
  void skipBreak() => _timerController.skipBreak();
  void pause() => _timerController.pause();
  void resume() => _timerController.resume();
  void requestStop() => _timerController.requestStop();
  void setDebugFastMode(bool value) => _timerController.setDebugFastMode(value);

  @override
  void dispose() {
    if (_isDisposed) return;
    _timerController.removeListener(_handleTimerChange);
    _isDisposed = true;
    super.dispose();
  }

  void _safeNotify() {
    if (!_isDisposed) {
      notifyListeners();
    }
  }

  @override
  void notifyListeners() {
    if (!_isDisposed) {
      super.notifyListeners();
    }
  }
}
