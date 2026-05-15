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
}
