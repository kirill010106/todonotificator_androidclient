import 'package:flutter/material.dart';
import '../app/timer_controller.dart';
import '../data/models.dart';
import '../data/repositories.dart';
import '../services/gamification_service.dart';

class ProfileViewModel extends ChangeNotifier {
  ProfileViewModel({
    required AuthRepository authRepository,
    required SettingsRepository settingsRepository,
    required TaskRepository taskRepository,
    required TimerController timerController,
    required GamificationService gamificationService,
  })  : _authRepository = authRepository,
        _settingsRepository = settingsRepository,
        _taskRepository = taskRepository,
        _timerController = timerController,
        _gamificationService = gamificationService {
    _timerController.addListener(_onServiceUpdate);
    _gamificationService.addListener(_onServiceUpdate);
  }

  final AuthRepository _authRepository;
  final SettingsRepository _settingsRepository;
  final TaskRepository _taskRepository;
  final TimerController _timerController;
  final GamificationService _gamificationService;

  User? _user;
  TargetOption? _target;
  int _doneTasks = 0;
  int _burnedTasks = 0;
  bool _isLoading = true;
  bool _showIntervals = true;
  bool _isDisposed = false;

  User? get user => _user;
  TargetOption? get target => _target;
  int get doneTasks => _doneTasks;
  int get burnedTasks => _burnedTasks;
  int get streak => _gamificationService.progress.streakDays;
  bool get isLoading => _isLoading;
  bool get showIntervals => _showIntervals;
  int get completedPomodoros => _timerController.completedPomodoros;
  UserProgress get progress => _gamificationService.progress;
  List<Achievement> get recentAchievements =>
      _gamificationService.achievements
          .where((a) => a.isUnlocked)
          .toList()
          .reversed
          .take(3)
          .toList();

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
    if (_isDisposed) return;
    _isLoading = true;
    _safeNotify();

    try {
      _user = await _authRepository.getCurrentUser();
      if (_isDisposed) return;
      
      final targetId = await _settingsRepository.getSelectedTarget();
      if (_isDisposed) return;

      if (targetId != null) {
        _target = _options.firstWhere(
          (o) => o.id == targetId,
          orElse: () => _options[1],
        );
      } else {
        _target = _options[1];
      }

      final tasks = await _taskRepository.fetchTasks();
      if (_isDisposed) return;

      _doneTasks = tasks.where((t) => t.isDone).length;
      _burnedTasks = tasks.where((t) => !t.isDone && t.isBurned).length;
    } finally {
      if (!_isDisposed) {
        _isLoading = false;
        _safeNotify();
      }
    }
  }

  void setShowIntervals(bool value) {
    if (_showIntervals == value) return;
    _showIntervals = value;
    _safeNotify();
  }

  Future<void> logout() async {
    await _authRepository.logout();
  }

  @override
  void dispose() {
    if (_isDisposed) return;
    _timerController.removeListener(_onServiceUpdate);
    _gamificationService.removeListener(_onServiceUpdate);
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

  void _onServiceUpdate() {
    _safeNotify();
  }
}
