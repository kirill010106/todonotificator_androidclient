import 'package:flutter/material.dart';
import '../app/timer_controller.dart';
import '../data/models.dart';
import '../data/repositories.dart';

class TimerViewModel extends ChangeNotifier {
  TimerViewModel({
    required TaskRepository taskRepository,
    required TimerController timerController,
  })  : _taskRepository = taskRepository,
        _timerController = timerController {
    _timerController.addListener(_handleTimerChange);
  }

  final TaskRepository _taskRepository;
  final TimerController _timerController;

  Task? _task;
  bool _isLoadingTask = false;

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
  int get completedPomodoros => _timerController.completedPomodoros;
  int get focusRate => _timerController.focusRate;
  bool get debugFastMode => _timerController.debugFastMode;
  TimerDialog? get pendingDialog => _timerController.pendingDialog;

  void _handleTimerChange() {
    _refreshTask();
    notifyListeners();
  }

  Future<void> load() async {
    await _refreshTask();
  }

  Future<void> _refreshTask({bool force = false}) async {
    if (_timerController.mode != TimerMode.note || _timerController.taskId == null) {
      if (_task != null) {
        _task = null;
        notifyListeners();
      }
      return;
    }

    if (!force && _task?.id == _timerController.taskId) {
      return;
    }

    _isLoadingTask = true;
    notifyListeners();

    try {
      final task = await _taskRepository.getTask(_timerController.taskId!);
      _task = task;
    } finally {
      _isLoadingTask = false;
      notifyListeners();
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
    _timerController.removeListener(_handleTimerChange);
    super.dispose();
  }
}
