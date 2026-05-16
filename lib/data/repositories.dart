import 'models.dart';

abstract class AuthRepository {
  Future<AuthResult> register({
    required String nickname,
    required String email,
    required String password,
  });

  Future<AuthResult> login({
    required String login,
    required String password,
  });

  Future<AuthResult> changePassword({
    required String oldPassword,
    required String newPassword,
  });

  Future<User?> getCurrentUser();

  Future<void> logout();
}

abstract class TaskRepository {
  Future<List<Task>> fetchTasks({
    TaskFilter filter = TaskFilter.all,
    String? query,
    bool includeBurned = false,
  });

  Future<Task> addTask({required String title});

  Future<Task?> getTask(int id);

  Future<void> updateTaskTitle(int id, String title);

  Future<void> updateTaskNote(int id, String note);

  Future<void> setTaskDone(int id, bool isDone);

  Future<void> setTaskBurned(int id, bool isBurned);

  Future<void> setTaskCategory(int id, int? categoryId);

  Future<void> setTaskReminder(int id, ReminderType? type, int? minutes);

  Future<void> deleteTask(int id);

  Future<void> resurrectTask(int id);

  /// Saves a task with all its associated data in a single atomic operation.
  Future<int> saveTaskFull({
    int? id,
    required String title,
    String? note,
    int? categoryId,
    ReminderType? reminderType,
    int? reminderMinutes,
    bool isDone = false,
    bool isBurned = false,
    bool isHardcore = false,
    List<TaskItem> items = const [],
  });

  Future<List<TaskItem>> fetchTaskItems(int taskId);

  Future<TaskItem> addTaskItem({
    required int taskId,
    required String text,
  });

  Future<void> setTaskItemDone(int id, bool isDone);

  Future<void> deleteTaskItem(int id);

  Future<List<CategoryStats>> fetchCategories();

  Future<Category> addCategory({
    required String name,
    required int color,
  });

  Future<void> updateCategory({
    required int id,
    String? name,
    int? color,
  });

  /// Deletes a category and optionally migrates its tasks to another category.
  /// If [migrateToId] is null, tasks become category-less.
  Future<void> deleteCategory(int id, {int? migrateToId});
}

abstract class SettingsRepository {
  Future<void> setSelectedTarget(String targetId);
  Future<String?> getSelectedTarget();

  Future<void> setNotificationEnabled(String key, bool enabled);
  Future<bool> isNotificationEnabled(String key, {bool defaultValue = true});

  Future<void> setQuietModeTime(String key, int hour, int minute);
  Future<Map<String, int>> getQuietModeTime(String key, {int defaultHour = 0, int defaultMinute = 0});

  Future<void> setQuietDays(List<bool> days);
  Future<List<bool>> getQuietDays();

  Future<void> setStrictModeEnabled(bool enabled);
  Future<bool> isStrictModeEnabled();

  Future<void> setLocale(String languageCode);
  Future<String?> getLocale();
}

abstract class GamificationRepository {
  /// Returns current progress for [userId], creating a zero-state if none.
  Future<UserProgress> getProgress(int userId);

  /// Adds [xpDelta] to [userId]'s total XP (can be negative).
  Future<UserProgress> addXp(int userId, int xpDelta);

  /// Updates the streak: increments if last activity was yesterday,
  /// resets to 1 if it was earlier. No-op if already updated today.
  /// Returns the new streak length.
  Future<int> updateStreak(int userId);

  /// Returns all achievement IDs already unlocked by [userId].
  Future<Set<String>> getUnlockedAchievementIds(int userId);

  /// Persists a newly unlocked achievement.
  Future<void> unlockAchievement(int userId, String achievementId);
}
