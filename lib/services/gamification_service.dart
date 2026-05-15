import 'package:flutter/material.dart';

import '../data/models.dart';
import '../data/repositories.dart';

/// Central service for XP, levels, and achievements.
/// Exposed as a [ChangeNotifier] so ViewModels can listen to it.
class GamificationService extends ChangeNotifier {
  GamificationService(this._repository);

  final GamificationRepository _repository;

  // ── State ──────────────────────────────────────────────────────────────────

  UserProgress _progress = UserProgress.fromTotalXp(0);
  Set<String> _unlockedIds = {};

  /// Queued achievement to show in an animated popup.
  /// Consumed by the UI after displaying.
  Achievement? _pendingUnlock;

  /// Queue of XP deltas (positive or negative) accumulated since the last
  /// UI frame consumed them. Each entry corresponds to one discrete event
  /// so the UI can show individual toasts.
  final List<int> _pendingXpDeltas = [];

  // ── Catalogue ──────────────────────────────────────────────────────────────

  static const List<AchievementDefinition> catalogue = [
    // Pomodoro
    AchievementDefinition(
      id: 'first_pomodoro',
      title: 'Первый томат',
      description: 'Завершить 1 pomodoro-интервал',
      icon: '🍅',
      xpReward: 50,
    ),
    AchievementDefinition(
      id: 'pomodoro_10',
      title: 'Томатная серия',
      description: 'Завершить 10 pomodoro-интервалов',
      icon: '🔟',
      xpReward: 100,
    ),
    AchievementDefinition(
      id: 'pomodoro_50',
      title: 'Фабрика фокуса',
      description: 'Завершить 50 pomodoro-интервалов',
      icon: '🏭',
      xpReward: 300,
    ),
    AchievementDefinition(
      id: 'pomodoro_100',
      title: 'Мастер времени',
      description: 'Завершить 100 pomodoro-интервалов',
      icon: '⏳',
      xpReward: 1000,
    ),
    // Tasks
    AchievementDefinition(
      id: 'first_task',
      title: 'С чего-то надо начать',
      description: 'Выполнить первую задачу',
      icon: '✅',
      xpReward: 30,
    ),
    AchievementDefinition(
      id: 'tasks_10',
      title: 'Продуктивный день',
      description: 'Выполнить 10 задач',
      icon: '📋',
      xpReward: 150,
    ),
    AchievementDefinition(
      id: 'tasks_50',
      title: 'На волне',
      description: 'Выполнить 50 задач',
      icon: '🌊',
      xpReward: 400,
    ),
    AchievementDefinition(
      id: 'tasks_100',
      title: 'Легенда продуктивности',
      description: 'Выполнить 100 задач',
      icon: '🏆',
      xpReward: 1000,
    ),
    // Streak
    AchievementDefinition(
      id: 'streak_3',
      title: 'В ритме',
      description: '3 дня подряд с активностью',
      icon: '🔥',
      xpReward: 75,
    ),
    AchievementDefinition(
      id: 'streak_7',
      title: 'Неделя силы',
      description: '7 дней подряд с активностью',
      icon: '💪',
      xpReward: 200,
    ),
    AchievementDefinition(
      id: 'streak_30',
      title: 'Легендарный',
      description: '30 дней подряд с активностью',
      icon: '🌟',
      xpReward: 1000,
    ),
    // Time of day
    AchievementDefinition(
      id: 'night_owl',
      title: 'Сова',
      description: 'Выполнить задачу после 23:00',
      icon: '🦉',
      xpReward: 50,
    ),
    AchievementDefinition(
      id: 'early_bird',
      title: 'Жаворонок',
      description: 'Выполнить задачу до 7:00',
      icon: '🐦',
      xpReward: 50,
    ),
    // Level milestones
    AchievementDefinition(
      id: 'level_5',
      title: 'Опытный',
      description: 'Достичь 5-го уровня',
      icon: '⭐',
      xpReward: 200,
    ),
    AchievementDefinition(
      id: 'level_10',
      title: 'Мастер',
      description: 'Достичь 10-го уровня',
      icon: '🎖️',
      xpReward: 500,
    ),
  ];

  static final Map<String, AchievementDefinition> _catalogueMap = {
    for (final a in catalogue) a.id: a,
  };

  // ── Public API ─────────────────────────────────────────────────────────────

  UserProgress get progress => _progress;
  Achievement? get pendingUnlock => _pendingUnlock;

  /// Returns the full achievement list merged with unlock status.
  List<Achievement> get achievements => catalogue
      .map(
        (def) => Achievement(
          definition: def,
          isUnlocked: _unlockedIds.contains(def.id),
          unlockedAt: null, // simplified: timestamp not cached in memory
        ),
      )
      .toList();

  int get unlockedCount => _unlockedIds.length;

  /// Load initial state from repository.
  Future<void> load(int userId) async {
    _progress = await _repository.getProgress(userId);
    _unlockedIds = await _repository.getUnlockedAchievementIds(userId);
    notifyListeners();
  }

  /// Called whenever an XP-bearing event occurs.
  /// Pass [userId] of the current user. If null, no XP is granted.
  Future<void> recordEvent(
    XpEvent event, {
    required int? userId,
    // Extra context needed for some achievements:
    int? totalPomodoros,
    int? totalDoneTasks,
    int? streakDays,
  }) async {
    if (userId == null) return;

    // 1. Add XP for the event itself
    if (event.xpDelta != 0) {
      _progress = await _repository.addXp(userId, event.xpDelta);
      _pendingXpDeltas.add(event.xpDelta);
    }

    // 2. Streak update on any positive event
    if (event.xpDelta > 0) {
      final newStreak = await _repository.updateStreak(userId);
      _progress = UserProgress.fromTotalXp(
        _progress.totalXp,
        streakDays: newStreak,
      );
      await _checkStreakAchievements(userId, newStreak);
    }

    // 3. Check counters-based achievements
    if (totalPomodoros != null) {
      await _checkPomodoroAchievements(userId, totalPomodoros);
    }
    if (totalDoneTasks != null) {
      await _checkTaskAchievements(userId, totalDoneTasks, event);
    }

    // 4. Level achievements
    await _checkLevelAchievements(userId);

    notifyListeners();
  }

  /// Drains and returns all pending XP deltas for toast display.
  /// Call from UI (e.g. inside a listener) to consume the queue.
  List<int> consumeXpDeltas() {
    if (_pendingXpDeltas.isEmpty) return const [];
    final copy = List<int>.from(_pendingXpDeltas);
    _pendingXpDeltas.clear();
    return copy;
  }

  /// Call from UI after the popup has been shown.
  Achievement? consumePendingUnlock() {
    final a = _pendingUnlock;
    _pendingUnlock = null;
    return a;
  }

  // ── Private helpers ────────────────────────────────────────────────────────

  Future<void> _unlock(int userId, String id) async {
    if (_unlockedIds.contains(id)) return;
    final def = _catalogueMap[id];
    if (def == null) return;

    await _repository.unlockAchievement(userId, id);
    _unlockedIds.add(id);

    // Award bonus XP for unlocking
    if (def.xpReward > 0) {
      _progress = await _repository.addXp(userId, def.xpReward);
      _pendingXpDeltas.add(def.xpReward);
    }

    _pendingUnlock = Achievement(
      definition: def,
      isUnlocked: true,
      unlockedAt: DateTime.now(),
    );
  }

  Future<void> _checkPomodoroAchievements(int userId, int total) async {
    if (total >= 1) await _unlock(userId, 'first_pomodoro');
    if (total >= 10) await _unlock(userId, 'pomodoro_10');
    if (total >= 50) await _unlock(userId, 'pomodoro_50');
    if (total >= 100) await _unlock(userId, 'pomodoro_100');
  }

  Future<void> _checkTaskAchievements(
    int userId,
    int totalDone,
    XpEvent event,
  ) async {
    if (totalDone >= 1) await _unlock(userId, 'first_task');
    if (totalDone >= 10) await _unlock(userId, 'tasks_10');
    if (totalDone >= 50) await _unlock(userId, 'tasks_50');
    if (totalDone >= 100) await _unlock(userId, 'tasks_100');

    // Time-of-day achievements
    if (event == XpEvent.taskComplete) {
      final hour = DateTime.now().hour;
      if (hour >= 23) await _unlock(userId, 'night_owl');
      if (hour < 7) await _unlock(userId, 'early_bird');
    }
  }

  Future<void> _checkStreakAchievements(int userId, int streak) async {
    if (streak >= 3) await _unlock(userId, 'streak_3');
    if (streak >= 7) await _unlock(userId, 'streak_7');
    if (streak >= 30) await _unlock(userId, 'streak_30');
  }

  Future<void> _checkLevelAchievements(int userId) async {
    if (_progress.level >= 5) await _unlock(userId, 'level_5');
    if (_progress.level >= 10) await _unlock(userId, 'level_10');
  }
}
