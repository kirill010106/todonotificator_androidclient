import 'dart:async';

import 'package:flutter/material.dart';

import '../data/models.dart';
import '../data/repositories.dart';
import '../services/gamification_service.dart';
import '../services/notification_service.dart';
import '../services/audio_service.dart';

class TimerController extends ChangeNotifier {
  TimerController({
    required TaskRepository tasks,
    required GamificationService gamification,
    required AudioService audio,
    required StatsRepository stats,
    NotificationService? notifications,
    int? userId,
  }) : _tasks = tasks,
       _gamification = gamification,
       _audio = audio,
       _stats = stats,
       _notifications = notifications,
       _userId = userId {
    _remaining = focusDuration;
  }

  static const Duration _baseFocusDuration = Duration(minutes: 25);
  static const Duration _baseBreakDuration = Duration(minutes: 5);
  static const Duration _baseRestDuration = Duration(minutes: 15);
  static const Duration _basePenaltyDuration = Duration(minutes: 5);
  static const int totalCycles = 4;

  final TaskRepository _tasks;
  final GamificationService _gamification;
  final AudioService _audio;
  final StatsRepository _stats;
  final NotificationService? _notifications;
  final int? _userId;
  Timer? _timer;
  bool _ongoingNotificationsEnabled = false;

  bool _debugFastMode = false;
  TimerMode _mode = TimerMode.free;
  TimerPhase _phase = TimerPhase.idle;
  Duration _remaining = _baseFocusDuration;
  bool _isRunning = false;
  bool _isPenalty = false;
  int _cycle = 1;
  int _completedPomodoros = 0;
  int _interruptedPomodoros = 0;
  bool _isMiniPlayerDismissed = false;
  int? _taskId;
  TimerDialog? _pendingDialog;

  bool get debugFastMode => _debugFastMode;
  TimerMode get mode => _mode;
  TimerPhase get phase => _phase;
  Duration get remaining => _remaining;
  bool get isRunning => _isRunning;
  bool get isPenalty => _isPenalty;
  int get cycle => _cycle;
  int get completedPomodoros => _completedPomodoros;
  int get focusRate {
    final total = _completedPomodoros + _interruptedPomodoros;
    if (total == 0) {
      return 0;
    }
    return ((_completedPomodoros / total) * 100).round();
  }

  int? get taskId => _taskId;
  int? get userId => _userId;
  TimerDialog? get pendingDialog => _pendingDialog;
  bool get isMiniPlayerDismissed => _isMiniPlayerDismissed;

  Duration get focusDuration => _scaleDuration(_baseFocusDuration);
  Duration get breakDuration => _scaleDuration(_baseBreakDuration);
  Duration get restDuration => _scaleDuration(_baseRestDuration);
  Duration get penaltyDuration => _scaleDuration(_basePenaltyDuration);

  void setDebugFastMode(bool value) {
    if (_debugFastMode == value) {
      return;
    }
    _debugFastMode = value;
    _resetSession();
  }

  void startFree() {
    _mode = TimerMode.free;
    _taskId = null;
    _resetSession();
    _audio.playEffect(AudioEffect.timerStart);
    _startFocus();
  }

  void startForTask(int taskId) {
    _mode = TimerMode.note;
    _taskId = taskId;
    _resetSession();
    _audio.playEffect(AudioEffect.timerStart);
    _startFocus();
  }

  void pause() {
    _timer?.cancel();
    _isRunning = false;
    _audio.playEffect(AudioEffect.timerPause);
    notifyListeners();
  }

  void resume() {
    if (_phase == TimerPhase.idle) {
      _audio.playEffect(AudioEffect.timerStart);
      _startFocus();
      return;
    }
    _audio.playEffect(AudioEffect.timerStart);
    _startTicker();
  }

  void stop() {
    if (_phase == TimerPhase.focus && _remaining > Duration.zero) {
      _interruptedPomodoros += 1;
    }
    _timer?.cancel();
    _phase = TimerPhase.idle;
    _remaining = focusDuration;
    _isRunning = false;
    _isPenalty = false;
    _pendingDialog = null;
    _audio.playEffect(AudioEffect.timerStop);
    _notifications?.cancelNotification(2000);
    notifyListeners();
  }

  void setOngoingNotificationsEnabled(bool enabled) {
    _ongoingNotificationsEnabled = enabled;
    if (!enabled) {
      _notifications?.cancelNotification(2000);
    }
  }

  void skipBreak() {
    _timer?.cancel();
    if (_phase == TimerPhase.breakTime) {
      _cycle = _cycle == totalCycles ? 1 : _cycle + 1;
    } else if (_phase == TimerPhase.rest) {
      _cycle = 1;
    }
    _startFocus();
  }

  Future<void> confirmTaskCompleted() async {
    _pendingDialog = null;
    if (_mode == TimerMode.note && _taskId != null) {
      await _tasks.setTaskDone(_taskId!, true);
    }
    _mode = TimerMode.free;
    _taskId = null;
    _resetSession();
    _notifications?.cancelNotification(2000);
  }

  Future<void> declineTaskCompleted() async {
    _pendingDialog = TimerDialog.penalty;
    notifyListeners();
  }

  void returnToWork() {
    _pendingDialog = null;
    // Возобновляем таймер с места паузы, не переходим к перерыву
    resume();
  }

  void penaltyReturnToWork() {
    _pendingDialog = null;
    resume();
  }

  Future<void> surrenderTask() async {
    _pendingDialog = null;
    if (_mode == TimerMode.note && _taskId != null) {
      await _tasks.setTaskBurned(_taskId!, true);
    }
    stop();
    _notifications?.cancelNotification(2000);
  }

  Future<void> strictModeViolation() async {
    if (_mode == TimerMode.note && _taskId != null) {
      await _tasks.setTaskBurned(_taskId!, true);
      
      _notifications?.showNotification(
        id: 3000,
        title: 'Строгий режим нарушен!',
        body: 'Задача была уничтожена или отправлена на кладбище.',
      );
    }
    _timer?.cancel();
    _phase = TimerPhase.idle;
    _remaining = focusDuration;
    _isRunning = false;
    _isPenalty = false;
    _notifications?.cancelNotification(2000);
    _pendingDialog = TimerDialog.strictModeViolation;
    notifyListeners();
  }

  void requestStop() {
    if (_mode == TimerMode.note &&
        _phase == TimerPhase.focus &&
        _remaining > Duration.zero) {
      pause();
      _pendingDialog = TimerDialog.checkCompletion;
      notifyListeners();
    } else {
      stop();
    }
  }

  void dismissMiniPlayer() {
    _isMiniPlayerDismissed = true;
    notifyListeners();
  }

  TimerDialog? consumeDialog() {
    final dialog = _pendingDialog;
    _pendingDialog = null;
    return dialog;
  }

  void _resetSession() {
    _timer?.cancel();
    _phase = TimerPhase.idle;
    _remaining = focusDuration;
    _isRunning = false;
    _isPenalty = false;
    _pendingDialog = null;
    _cycle = 1;
    _isMiniPlayerDismissed = false;
    notifyListeners();
  }

  void _startFocus({Duration? duration, bool penalty = false}) {
    _phase = TimerPhase.focus;
    _remaining = duration ?? focusDuration;
    _isPenalty = penalty;
    _startTicker();
  }

  void _startBreak() {
    _phase = TimerPhase.breakTime;
    _remaining = breakDuration;
    _isPenalty = false;
    _startTicker();
  }

  void _startRest() {
    _phase = TimerPhase.rest;
    _remaining = restDuration;
    _isPenalty = false;
    _startTicker();
  }

  void _startTicker() {
    _timer?.cancel();
    _isRunning = true;
    notifyListeners();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      _tick();
      _updateOngoingNotification();
    });
  }

  void _tick() {
    if (_remaining.inSeconds <= 1) {
      _timer?.cancel();
      _remaining = Duration.zero;
      _audio.playEffect(AudioEffect.timerComplete);
      _onPhaseComplete();
      // cancel ongoing notification when phase completes
      _notifications?.cancelNotification(2000);
      return;
    }
    _remaining -= const Duration(seconds: 1);
    notifyListeners();
  }

  void _updateOngoingNotification() {
    if (_notifications == null) return;
    if (!_ongoingNotificationsEnabled) return;
    
    final minutes = _remaining.inMinutes;
    final seconds = _remaining.inSeconds
        .remainder(60)
        .toString()
        .padLeft(2, '0');
    
    String title;
    if (_mode == TimerMode.note && _taskId != null) {
      title = 'Таймер задачи запущен';
    } else {
      title = 'Таймер запущен';
    }
    
    final body = 'Осталось $minutes:$seconds';
    _notifications.showOngoingNotification(id: 2000, title: title, body: body);
  }

  Future<void> _onPhaseComplete() async {
    _isRunning = false;

    if (_phase == TimerPhase.focus) {
      _completedPomodoros += 1;

      double multiplier = 1.0;
      if (_mode == TimerMode.note && _taskId != null) {
        final tasks = await _tasks.fetchTasks();
        final task = tasks.where((t) => t.id == _taskId).firstOrNull;
        if (task?.isHardcore == true) {
          multiplier = 1.5;
        }
      }

      await _gamification.recordEvent(
        XpEvent.pomodoroComplete,
        userId: _userId,
        xpMultiplier: multiplier,
        totalPomodoros: _completedPomodoros,
      );

      // Persist daily stats
      if (_userId != null) {
        final now = DateTime.now();
        final dateStr =
            '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
        await _stats.incrementStats(
          userId: _userId,
          date: dateStr,
          pomodoros: 1,
          focusSeconds: focusDuration.inSeconds,
        );
      }

      // When a focus period completes, advance to break/rest automatically.
      // Only show dialogs when the user explicitly requested stop.
      _advanceAfterFocus();
      return;
    }

    if (_phase == TimerPhase.breakTime) {
      _cycle = _cycle == totalCycles ? 1 : _cycle + 1;
      _startFocus();
      return;
    }

    if (_phase == TimerPhase.rest) {
      _cycle = 1;
      _startFocus();
    }
  }

  void _advanceAfterFocus() {
    if (_cycle >= totalCycles) {
      _startRest();
      return;
    }
    _startBreak();
  }

  Duration _scaleDuration(Duration base) {
    if (!_debugFastMode) {
      return base;
    }
    final seconds = base.inMinutes;
    return Duration(seconds: seconds == 0 ? 1 : seconds);
  }
}

enum TimerMode { free, note }

enum TimerPhase { idle, focus, breakTime, rest }

enum TimerDialog { checkCompletion, penalty, strictModeViolation }
