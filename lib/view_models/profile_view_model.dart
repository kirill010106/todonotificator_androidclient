import 'package:flutter/material.dart';
import '../app/timer_controller.dart';
import '../data/models.dart';
import '../data/repositories.dart';

class ProfileViewModel extends ChangeNotifier {
  ProfileViewModel({
    required AuthRepository authRepository,
    required SettingsRepository settingsRepository,
    required TaskRepository taskRepository,
    required TimerController timerController,
  })  : _authRepository = authRepository,
        _settingsRepository = settingsRepository,
        _taskRepository = taskRepository,
        _timerController = timerController {
    _timerController.addListener(notifyListeners);
  }

  final AuthRepository _authRepository;
  final SettingsRepository _settingsRepository;
  final TaskRepository _taskRepository;
  final TimerController _timerController;

  User? _user;
  TargetOption? _target;
  int _doneTasks = 0;
  int _burnedTasks = 0;
  int _streak = 0;
  bool _isLoading = true;
  bool _showIntervals = true;

  User? get user => _user;
  TargetOption? get target => _target;
  int get doneTasks => _doneTasks;
  int get burnedTasks => _burnedTasks;
  int get streak => _streak;
  bool get isLoading => _isLoading;
  bool get showIntervals => _showIntervals;
  int get completedPomodoros => _timerController.completedPomodoros;

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

  Future<void> load() async {
    _isLoading = true;
    notifyListeners();

    try {
      _user = await _authRepository.getCurrentUser();
      
      final targetId = await _settingsRepository.getSelectedTarget();
      if (targetId != null) {
        _target = _options.firstWhere(
          (o) => o.id == targetId,
          orElse: () => _options[1],
        );
      } else {
        _target = _options[1];
      }

      final tasks = await _taskRepository.fetchTasks();
      _doneTasks = tasks.where((t) => t.isDone).length;
      _burnedTasks = tasks.where((t) => !t.isDone && t.isBurned).length;
      _streak = 0; // Still hardcoded as in original screen
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void setShowIntervals(bool value) {
    if (_showIntervals == value) return;
    _showIntervals = value;
    notifyListeners();
  }

  Future<void> logout() async {
    await _authRepository.logout();
  }

  @override
  void dispose() {
    _timerController.removeListener(notifyListeners);
    super.dispose();
  }
}
