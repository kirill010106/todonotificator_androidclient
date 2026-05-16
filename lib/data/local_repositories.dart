import 'package:flutter/foundation.dart' hide Category;
import 'package:sqflite/sqflite.dart';

import '../services/gamification_service.dart';
import '../ui/widgets/game_banner.dart';
import 'local_database.dart';
import 'models.dart';
import 'repositories.dart';

class LocalSettingsRepository implements SettingsRepository {
  LocalSettingsRepository(this._db);

  static const _targetKey = 'selected_target_id';
  static const _currentUserKey = 'current_user_id';

  final LocalDatabase _db;

  @override
  Future<void> setSelectedTarget(String targetId) async {
    await _setValue(_targetKey, targetId);
  }

  @override
  Future<String?> getSelectedTarget() async {
    return _getValue(_targetKey);
  }

  Future<int?> getCurrentUserId() async {
    final value = await _getValue(_currentUserKey);
    if (value == null) {
      return null;
    }
    return int.tryParse(value);
  }

  Future<void> setCurrentUserId(int? id) async {
    if (id == null) {
      await _setValue(_currentUserKey, null);
      return;
    }
    await _setValue(_currentUserKey, id.toString());
  }

  Future<String?> _getValue(String key) async {
    final db = await _db.database;
    final rows = await db.query(
      'settings',
      columns: ['value'],
      where: 'key = ?',
      whereArgs: [key],
      limit: 1,
    );
    if (rows.isEmpty) {
      return null;
    }
    return rows.first['value'] as String?;
  }

  Future<void> _setValue(String key, String? value) async {
    final db = await _db.database;
    if (value == null) {
      await db.delete('settings', where: 'key = ?', whereArgs: [key]);
      return;
    }
    await db.insert(
      'settings',
      {'key': key, 'value': value},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  @override
  Future<void> setNotificationEnabled(String key, bool enabled) async {
    await _setValue('notif_enabled_$key', enabled ? '1' : '0');
  }

  @override
  Future<bool> isNotificationEnabled(String key, {bool defaultValue = true}) async {
    final val = await _getValue('notif_enabled_$key');
    if (val == null) return defaultValue;
    return val == '1';
  }

  @override
  Future<void> setQuietModeTime(String key, int hour, int minute) async {
    await _setValue('quiet_hour_$key', hour.toString());
    await _setValue('quiet_min_$key', minute.toString());
  }

  @override
  Future<Map<String, int>> getQuietModeTime(String key, {int defaultHour = 0, int defaultMinute = 0}) async {
    final h = await _getValue('quiet_hour_$key');
    final m = await _getValue('quiet_min_$key');
    return {
      'hour': h != null ? int.parse(h) : defaultHour,
      'minute': m != null ? int.parse(m) : defaultMinute,
    };
  }

  @override
  Future<void> setQuietDays(List<bool> days) async {
    final val = days.map((e) => e ? '1' : '0').join(',');
    await _setValue('quiet_days', val);
  }

  @override
  Future<List<bool>> getQuietDays() async {
    final val = await _getValue('quiet_days');
    if (val == null) return List.generate(7, (_) => false);
    return val.split(',').map((e) => e == '1').toList();
  }

  @override
  Future<void> setStrictModeEnabled(bool enabled) async {
    await _setValue('strict_mode', enabled ? '1' : '0');
  }

  @override
  Future<bool> isStrictModeEnabled() async {
    final val = await _getValue('strict_mode');
    return val == '1';
  }

  @override
  Future<void> setLocale(String languageCode) async {
    await _setValue('app_locale', languageCode);
  }

  @override
  Future<String?> getLocale() async {
    return await _getValue('app_locale');
  }
}

class LocalAuthRepository implements AuthRepository {
  LocalAuthRepository(this._db, this._settings);

  final LocalDatabase _db;
  final LocalSettingsRepository _settings;

  @override
  Future<AuthResult> register({
    required String nickname,
    required String email,
    required String password,
  }) async {
    try {
      final db = await _db.database;
      final result = await db.transaction((txn) async {
        final existingByEmail = await txn.query(
          'users',
          columns: ['id'],
          where: 'email = ?',
          whereArgs: [email],
          limit: 1,
        );
        if (existingByEmail.isNotEmpty) {
          return AuthResult.failure(AuthFailure.emailExists);
        }

        final existingByNickname = await txn.query(
          'users',
          columns: ['id'],
          where: 'nickname = ?',
          whereArgs: [nickname],
          limit: 1,
        );
        if (existingByNickname.isNotEmpty) {
          return AuthResult.failure(AuthFailure.nicknameExists);
        }

        final id = await txn.insert('users', {
          'nickname': nickname,
          'email': email,
          'password': password,
        });

        final user = User(id: id, nickname: nickname, email: email);
        return AuthResult.success(user);
      });

      if (result.isSuccess) {
        await _settings.setCurrentUserId(result.user!.id);
      }

      return result;
    } catch (_) {
      return AuthResult.failure(AuthFailure.serverError);
    }
  }

  @override
  Future<AuthResult> login({
    required String login,
    required String password,
  }) async {
    try {
      final db = await _db.database;
      final rows = await db.query(
        'users',
        where: '(email = ? OR nickname = ?) AND password = ?',
        whereArgs: [login, login, password],
        limit: 1,
      );
      if (rows.isEmpty) {
        return AuthResult.failure(AuthFailure.invalidCredentials);
      }

      final user = User.fromMap(rows.first);
      await _settings.setCurrentUserId(user.id);
      return AuthResult.success(user);
    } catch (_) {
      return AuthResult.failure(AuthFailure.serverError);
    }
  }

  @override
  Future<User?> getCurrentUser() async {
    final id = await _settings.getCurrentUserId();
    if (id == null) {
      return null;
    }
    final db = await _db.database;
    final rows = await db.query(
      'users',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (rows.isEmpty) {
      return null;
    }
    return User.fromMap(rows.first);
  }

  @override
  Future<void> logout() async {
    await _settings.setCurrentUserId(null);
  }

  @override
  Future<AuthResult> changePassword({
    required String oldPassword,
    required String newPassword,
  }) async {
    try {
      final user = await getCurrentUser();
      if (user == null) {
        return AuthResult.failure(AuthFailure.serverError);
      }

      final db = await _db.database;
      final rows = await db.query(
        'users',
        where: 'id = ? AND password = ?',
        whereArgs: [user.id, oldPassword],
      );

      if (rows.isEmpty) {
        return AuthResult.failure(AuthFailure.wrongPassword);
      }

      await db.update(
        'users',
        {'password': newPassword},
        where: 'id = ?',
        whereArgs: [user.id],
      );

      return AuthResult.success(user);
    } catch (_) {
      return AuthResult.failure(AuthFailure.serverError);
    }
  }
}

class LocalTaskRepository implements TaskRepository {
  LocalTaskRepository(this._db, this._settings);

  final LocalDatabase _db;
  final LocalSettingsRepository _settings;
  GamificationService? gamification;

  static const List<_DefaultCategory> _defaultCategories = [
    _DefaultCategory('Работа', 0xFF176A57),
    _DefaultCategory('Личное', 0xFFF5B400),
    _DefaultCategory('Срочное', 0xFFE25C5C),
    _DefaultCategory('Идеи', 0xFF4D7CFF),
  ];

  @override
  Future<List<Task>> fetchTasks({
    TaskFilter filter = TaskFilter.all,
    String? query,
    bool includeBurned = false,
  }) async {
    try {
      final db = await _db.database;
      final userId = await _settings.getCurrentUserId();
      final where = <String>[];
      final whereArgs = <Object?>[];

      if (userId != null) {
        where.add('user_id = ?');
        whereArgs.add(userId);
      }
      
      switch (filter) {
        case TaskFilter.active:
          where.add('is_done = 0 AND is_burned = 0');
          break;
        case TaskFilter.completed:
          where.add('is_done = 1 AND is_burned = 0');
          break;
        case TaskFilter.burned:
          where.add('is_burned = 1');
          break;
        case TaskFilter.all:
          if (includeBurned) {
            // No condition on is_burned - return all
          } else {
            where.add('is_burned = 0');
          }
          break;
      }

      final trimmed = query?.trim();
      if (trimmed != null && trimmed.isNotEmpty) {
        where.add(
          '(title LIKE ? OR category_id IN (SELECT id FROM categories WHERE name LIKE ?))',
        );
        whereArgs.add('%$trimmed%');
        whereArgs.add('%$trimmed%');
      }

      final rows = await db.query(
        'tasks',
        where: where.isEmpty ? null : where.join(' AND '),
        whereArgs: whereArgs,
        orderBy: 'created_at DESC',
      );
      return rows.map(Task.fromMap).toList();
    } catch (e) {
      debugPrint('[LocalTaskRepository] Error in fetchTasks: $e');
      rethrow;
    }
  }

  @override
  Future<Task> addTask({required String title}) async {
    try {
      final db = await _db.database;
      final userId = await _settings.getCurrentUserId();
      final now = DateTime.now();
      final id = await db.insert('tasks', {
        'user_id': userId,
        'title': title,
        'note': '',
        'category_id': null,
        'reminder_type': null,
        'reminder_minutes': null,
        'is_done': 0,
        'is_burned': 0,
        'is_hardcore': 0,
        'created_at': now.millisecondsSinceEpoch,
      });
      final task = Task(
        id: id,
        title: title,
        isDone: false,
        isBurned: false,
        isHardcore: false,
        createdAt: now,
        note: '',
      );
      
      if (userId != null) {
        gamification?.recordEvent(XpEvent.taskAdded, userId: userId);
      }
      
      return task;
    } catch (e) {
      debugPrint('[LocalTaskRepository] Error in addTask: $e');
      rethrow;
    }
  }

  @override
  Future<Task?> getTask(int id) async {
    try {
      final db = await _db.database;
      final rows = await db.query(
        'tasks',
        where: 'id = ?',
        whereArgs: [id],
        limit: 1,
      );
      if (rows.isEmpty) {
        return null;
      }
      return Task.fromMap(rows.first);
    } catch (e) {
      debugPrint('[LocalTaskRepository] Error in getTask: $e');
      rethrow;
    }
  }

  @override
  Future<void> updateTaskTitle(int id, String title) async {
    try {
      final db = await _db.database;
      await db.update(
        'tasks',
        {'title': title},
        where: 'id = ?',
        whereArgs: [id],
      );
    } catch (e) {
      debugPrint('[LocalTaskRepository] Error in updateTaskTitle: $e');
      rethrow;
    }
  }

  @override
  Future<void> updateTaskNote(int id, String note) async {
    try {
      final db = await _db.database;
      await db.update(
        'tasks',
        {'note': note},
        where: 'id = ?',
        whereArgs: [id],
      );
    } catch (e) {
      debugPrint('[LocalTaskRepository] Error in updateTaskNote: $e');
      rethrow;
    }
  }

  @override
  Future<void> setTaskDone(int id, bool isDone) async {
    try {
      final db = await _db.database;
      // When marking as done, always ensure it's not marked as burned anymore
      await db.update(
        'tasks',
        {
          'is_done': isDone ? 1 : 0,
          if (isDone) 'is_burned': 0,
        },
        where: 'id = ?',
        whereArgs: [id],
      );

      if (isDone) {
        final userId = await _settings.getCurrentUserId();
        if (userId != null) {
          // Fetch task to check for hardcore bonus and farming prevention
          final taskMap = await db.query(
            'tasks',
            columns: ['is_hardcore', 'xp_awarded'],
            where: 'id = ?',
            whereArgs: [id],
          );
          
          if (taskMap.isNotEmpty) {
            final xpAlreadyAwarded = (taskMap.first['xp_awarded'] as int?) == 1;
            
            if (!xpAlreadyAwarded) {
              double multiplier = 1.0;
              final val = taskMap.first['is_hardcore'];
              // Robust type check for SQLite 0/1
              if (val == 1 || val == '1' || val == true) {
                multiplier = 1.5;
              }

              final allTasks = await fetchTasks();
              final doneCount = allTasks.where((t) => t.isDone).length;
              
              await gamification?.recordEvent(
                XpEvent.taskComplete,
                userId: userId,
                xpMultiplier: multiplier,
                totalDoneTasks: doneCount,
              );

              // Mark as awarded
              await db.update(
                'tasks',
                {'xp_awarded': 1},
                where: 'id = ?',
                whereArgs: [id],
              );
            }
          }
        }
      }
    } catch (e) {
      debugPrint('[LocalTaskRepository] Error in setTaskDone: $e');
      rethrow;
    }
  }

  @override
  Future<void> setTaskBurned(int id, bool isBurned) async {
    try {
      final db = await _db.database;
      
      bool isHardcore = false;
      bool taskExisted = false;

      await db.transaction((txn) async {
        // Fetch task to check for current hardcore status
        final taskMap = await txn.query(
          'tasks',
          columns: ['is_hardcore'],
          where: 'id = ?',
          whereArgs: [id],
        );
        
        if (taskMap.isEmpty) return; // Task already gone
        taskExisted = true;

        final val = taskMap.first['is_hardcore'];
        // Robust type check for SQLite 0/1
        isHardcore = val == 1 || val == '1' || val == true;

        if (isBurned) {
          if (isHardcore) {
            // PERMADEATH: If it's a hardcore task, it gets deleted forever.
            await txn.delete('task_items', where: 'task_id = ?', whereArgs: [id]);
            await txn.delete('tasks', where: 'id = ?', whereArgs: [id]);
          } else {
            // Standard burn: Move to graveyard
            await txn.update(
              'tasks',
              {
                'is_burned': 1,
                'is_done': 0,
              },
              where: 'id = ?',
              whereArgs: [id],
            );
          }
        } else {
          // Manual unburn
          await txn.update(
            'tasks',
            {'is_burned': 0},
            where: 'id = ?',
            whereArgs: [id],
          );
        }
      });

      if (!taskExisted) return;

      if (isBurned) {
        final userId = await _settings.getCurrentUserId();
        if (userId != null) {
          // Record penalty event
          await gamification?.recordEvent(
            XpEvent.taskBurned,
            userId: userId,
            xpMultiplier: isHardcore ? 2.0 : 1.0,
          );

          if (isHardcore) {
            gamification?.showBanner(
              GameBannerType.hardcoreDeath,
              'Задача уничтожена! Вы провалили Hardcore-задачу. Штраф удвоен.',
            );
          } else {
            gamification?.showBanner(
              GameBannerType.standardBurn,
              'Задача сгорела! Она отправлена на кладбище. Воскресите её, чтобы получить бонус.',
            );
          }
        }
      }
    } catch (e) {
      debugPrint('[LocalTaskRepository] Error in setTaskBurned: $e');
      rethrow;
    }
  }

  @override
  Future<void> setTaskCategory(int id, int? categoryId) async {
    try {
      final db = await _db.database;
      await db.update(
        'tasks',
        {'category_id': categoryId},
        where: 'id = ?',
        whereArgs: [id],
      );
    } catch (e) {
      debugPrint('[LocalTaskRepository] Error in setTaskCategory: $e');
      rethrow;
    }
  }

  @override
  Future<void> setTaskReminder(int id, ReminderType? type, int? minutes) async {
    try {
      final db = await _db.database;
      await db.update(
        'tasks',
        {
          'reminder_type': type?.name,
          'reminder_minutes': minutes,
        },
        where: 'id = ?',
        whereArgs: [id],
      );
    } catch (e) {
      debugPrint('[LocalTaskRepository] Error in setTaskReminder: $e');
      rethrow;
    }
  }

  @override
  Future<void> deleteTask(int id) async {
    try {
      final db = await _db.database;
      await db.transaction((txn) async {
        await txn.delete('task_items', where: 'task_id = ?', whereArgs: [id]);
        await txn.delete('tasks', where: 'id = ?', whereArgs: [id]);
      });
    } catch (e) {
      debugPrint('[LocalTaskRepository] Error in deleteTask: $e');
      rethrow;
    }
  }

  @override
  Future<void> resurrectTask(int id) async {
    try {
      final db = await _db.database;
      await db.transaction((txn) async {
        // Explicitly clear burned status, reset done status, and enable hardcore mode
        await txn.update(
          'tasks',
          {
            'is_burned': 0,
            'is_hardcore': 1,
            'is_done': 0,
          },
          where: 'id = ?',
          whereArgs: [id],
        );
      });
    } catch (e) {
      debugPrint('[LocalTaskRepository] Error in resurrectTask: $e');
      rethrow;
    }
  }

  @override
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
  }) async {
    try {
      final db = await _db.database;
      final userId = await _settings.getCurrentUserId();

      final taskId = await db.transaction((txn) async {
        int tid;
        if (id == null) {
          final now = DateTime.now();
          tid = await txn.insert('tasks', {
            'user_id': userId,
            'title': title,
            'note': note ?? '',
            'category_id': categoryId,
            'reminder_type': reminderType?.name,
            'reminder_minutes': reminderMinutes,
            'is_done': isDone ? 1 : 0,
            'is_burned': isBurned ? 1 : 0,
            'is_hardcore': isHardcore ? 1 : 0,
            'created_at': now.millisecondsSinceEpoch,
          });
        } else {
          tid = id;
          await txn.update(
            'tasks',
            {
              'title': title,
              'note': note ?? '',
              'category_id': categoryId,
              'reminder_type': reminderType?.name,
              'reminder_minutes': reminderMinutes,
              'is_done': isDone ? 1 : 0,
              'is_burned': isBurned ? 1 : 0,
              'is_hardcore': isHardcore ? 1 : 0,
            },
            where: 'id = ?',
            whereArgs: [tid],
          );
          await txn.delete('task_items', where: 'task_id = ?', whereArgs: [tid]);
        }

        for (final item in items) {
          await txn.insert('task_items', {
            'task_id': tid,
            'text': item.text,
            'is_done': item.isDone ? 1 : 0,
            'position': item.position,
            'xp_awarded': item.xpAwarded ? 1 : 0,
          });
        }

        return tid;
      });

      if (id == null && userId != null) {
        gamification?.recordEvent(XpEvent.taskAdded, userId: userId);
      }

      return taskId;
    } catch (e) {
      debugPrint('[LocalTaskRepository] Error in saveTaskFull: $e');
      rethrow;
    }
  }

  @override
  Future<List<TaskItem>> fetchTaskItems(int taskId) async {
    try {
      final db = await _db.database;
      final rows = await db.query(
        'task_items',
        where: 'task_id = ?',
        whereArgs: [taskId],
        orderBy: 'position ASC, id ASC',
      );
      return rows.map(TaskItem.fromMap).toList();
    } catch (e) {
      debugPrint('[LocalTaskRepository] Error in fetchTaskItems: $e');
      rethrow;
    }
  }

  @override
  Future<TaskItem> addTaskItem({
    required int taskId,
    required String text,
  }) async {
    try {
      final db = await _db.database;
      final result = await db.rawQuery(
        'SELECT COALESCE(MAX(position), -1) + 1 AS pos '
        'FROM task_items WHERE task_id = ?',
        [taskId],
      );
      final position = (result.first['pos'] as int?) ?? 0;
      final id = await db.insert('task_items', {
        'task_id': taskId,
        'text': text,
        'is_done': 0,
        'position': position,
      });
      return TaskItem(
        id: id,
        taskId: taskId,
        text: text,
        isDone: false,
        position: position,
      );
    } catch (e) {
      debugPrint('[LocalTaskRepository] Error in addTaskItem: $e');
      rethrow;
    }
  }

  @override
  Future<void> setTaskItemDone(int id, bool isDone) async {
    try {
      final db = await _db.database;
      await db.update(
        'task_items',
        {'is_done': isDone ? 1 : 0},
        where: 'id = ?',
        whereArgs: [id],
      );

      if (isDone) {
        final userId = await _settings.getCurrentUserId();
        if (userId != null) {
          // Fetch parent task and item to check for hardcore bonus and farming prevention
          final itemMap = await db.query(
            'task_items',
            columns: ['task_id', 'xp_awarded'],
            where: 'id = ?',
            whereArgs: [id],
          );
          
          if (itemMap.isNotEmpty) {
            final xpAlreadyAwarded = (itemMap.first['xp_awarded'] as int?) == 1;
            
            if (!xpAlreadyAwarded) {
              double multiplier = 1.0;
              final taskId = itemMap.first['task_id'] as int;
              final taskMap = await db.query(
                'tasks',
                columns: ['is_hardcore'],
                where: 'id = ?',
                whereArgs: [taskId],
              );
              if (taskMap.isNotEmpty && (taskMap.first['is_hardcore'] as int) == 1) {
                multiplier = 1.5;
              }

              await gamification?.recordEvent(
                XpEvent.taskItemDone,
                userId: userId,
                xpMultiplier: multiplier,
              );

              // Mark as awarded
              await db.update(
                'task_items',
                {'xp_awarded': 1},
                where: 'id = ?',
                whereArgs: [id],
              );
            }
          }
        }
      }
    } catch (e) {
      debugPrint('[LocalTaskRepository] Error in setTaskItemDone: $e');
      rethrow;
    }
  }

  @override
  Future<void> deleteTaskItem(int id) async {
    try {
      final db = await _db.database;
      await db.delete('task_items', where: 'id = ?', whereArgs: [id]);
    } catch (e) {
      debugPrint('[LocalTaskRepository] Error in deleteTaskItem: $e');
      rethrow;
    }
  }

  @override
  Future<List<CategoryStats>> fetchCategories() async {
    try {
      final db = await _db.database;
      final userId = await _settings.getCurrentUserId();

      await _ensureDefaultCategories(db, userId);

      if (userId == null) {
        final rows = await db.rawQuery(
          'SELECT c.id, c.name, c.color, COUNT(t.id) AS task_count '
          'FROM categories c '
          'LEFT JOIN tasks t ON t.category_id = c.id '
          'GROUP BY c.id '
          'ORDER BY c.id DESC',
        );
        return rows.map(_mapCategoryStats).toList();
      }

      final rows = await db.rawQuery(
        'SELECT c.id, c.name, c.color, COUNT(t.id) AS task_count '
        'FROM categories c '
        'LEFT JOIN tasks t ON t.category_id = c.id AND t.user_id = ? '
        'WHERE c.user_id = ? '
        'GROUP BY c.id '
        'ORDER BY c.id DESC',
        [userId, userId],
      );
      return rows.map(_mapCategoryStats).toList();
    } catch (e) {
      debugPrint('[LocalTaskRepository] Error in fetchCategories: $e');
      rethrow;
    }
  }

  @override
  Future<Category> addCategory({
    required String name,
    required int color,
  }) async {
    try {
      final db = await _db.database;
      final userId = await _settings.getCurrentUserId();
      final id = await db.insert('categories', {
        'user_id': userId,
        'name': name,
        'color': color,
      });
      return Category(id: id, name: name, color: color);
    } catch (e) {
      debugPrint('[LocalTaskRepository] Error in addCategory: $e');
      rethrow;
    }
  }

  @override
  Future<void> updateCategory({
    required int id,
    String? name,
    int? color,
  }) async {
    try {
      final db = await _db.database;
      await db.transaction((txn) async {
        final updates = <String, Object?>{};
        if (name != null) updates['name'] = name;
        if (color != null) updates['color'] = color;

        if (updates.isNotEmpty) {
          await txn.update(
            'categories',
            updates,
            where: 'id = ?',
            whereArgs: [id],
          );
        }
      });
    } catch (e) {
      debugPrint('[LocalTaskRepository] Error in updateCategory: $e');
      rethrow;
    }
  }

  @override
  Future<void> deleteCategory(int id, {int? migrateToId}) async {
    try {
      final db = await _db.database;
      await db.transaction((txn) async {
        await txn.update(
          'tasks',
          {'category_id': migrateToId},
          where: 'category_id = ?',
          whereArgs: [id],
        );
        await txn.delete('categories', where: 'id = ?', whereArgs: [id]);
      });
    } catch (e) {
      debugPrint('[LocalTaskRepository] Error in deleteCategory: $e');
      rethrow;
    }
  }

  CategoryStats _mapCategoryStats(Map<String, Object?> row) {
    final category = Category(
      id: row['id'] as int,
      name: row['name'] as String,
      color: row['color'] as int,
    );
    final count = (row['task_count'] as int?) ?? 0;
    return CategoryStats(category: category, taskCount: count);
  }

  Future<void> _ensureDefaultCategories(
    Database db,
    int? userId,
  ) async {
    final where = userId == null ? 'user_id IS NULL' : 'user_id = ?';
    final args = userId == null ? null : [userId];
    final existing = await db.query(
      'categories',
      columns: ['id'],
      where: where,
      whereArgs: args,
      limit: 1,
    );
    if (existing.isNotEmpty) {
      return;
    }
    for (final item in _defaultCategories) {
      await db.insert('categories', {
        'user_id': userId,
        'name': item.name,
        'color': item.color,
      });
    }
  }
}

class _DefaultCategory {
  const _DefaultCategory(this.name, this.color);

  final String name;
  final int color;
}

class LocalGamificationRepository implements GamificationRepository {
  LocalGamificationRepository(this._db);

  final LocalDatabase _db;

  @override
  Future<UserProgress> getProgress(int userId) async {
    try {
      final db = await _db.database;
      final rows = await db.query(
        'user_xp',
        where: 'user_id = ?',
        whereArgs: [userId],
        limit: 1,
      );
      if (rows.isEmpty) {
        return UserProgress.fromTotalXp(0);
      }
      final row = rows.first;
      return UserProgress.fromTotalXp(
        (row['total_xp'] as int?) ?? 0,
        streakDays: (row['streak_days'] as int?) ?? 0,
      );
    } catch (e) {
      debugPrint('[LocalGamificationRepository] Error in getProgress: $e');
      rethrow;
    }
  }

  @override
  Future<UserProgress> addXp(int userId, int xpDelta) async {
    try {
      final db = await _db.database;
      await db.transaction((txn) async {
        // Upsert row if missing
        await txn.execute(
          'INSERT OR IGNORE INTO user_xp (user_id, total_xp, streak_days) VALUES (?, 0, 0)',
          [userId],
        );
        await txn.rawUpdate(
          'UPDATE user_xp SET total_xp = MAX(0, total_xp + ?) WHERE user_id = ?',
          [xpDelta, userId],
        );
      });
      return getProgress(userId);
    } catch (e) {
      debugPrint('[LocalGamificationRepository] Error in addXp: $e');
      rethrow;
    }
  }

  @override
  Future<int> updateStreak(int userId) async {
    try {
      final db = await _db.database;
      return await db.transaction((txn) async {
        await txn.execute(
          'INSERT OR IGNORE INTO user_xp (user_id, total_xp, streak_days) VALUES (?, 0, 0)',
          [userId],
        );

        final rows = await txn.query(
          'user_xp',
          columns: ['streak_days', 'last_active_date'],
          where: 'user_id = ?',
          whereArgs: [userId],
          limit: 1,
        );

        final today = _dateString(DateTime.now());
        final lastDate = rows.isEmpty ? null : rows.first['last_active_date'] as String?;
        final currentStreak = rows.isEmpty ? 0 : (rows.first['streak_days'] as int? ?? 0);

        if (lastDate == today) {
          // Already updated today — no change
          return currentStreak;
        }

        int newStreak;
        if (lastDate == _dateString(DateTime.now().subtract(const Duration(days: 1)))) {
          // Consecutive day
          newStreak = currentStreak + 1;
        } else {
          // Gap — reset
          newStreak = 1;
        }

        await txn.update(
          'user_xp',
          {'streak_days': newStreak, 'last_active_date': today},
          where: 'user_id = ?',
          whereArgs: [userId],
        );
        return newStreak;
      });
    } catch (e) {
      debugPrint('[LocalGamificationRepository] Error in updateStreak: $e');
      rethrow;
    }
  }

  @override
  Future<Set<String>> getUnlockedAchievementIds(int userId) async {
    try {
      final db = await _db.database;
      final rows = await db.query(
        'achievements',
        columns: ['id'],
        where: 'user_id = ?',
        whereArgs: [userId],
      );
      return rows.map((r) => r['id'] as String).toSet();
    } catch (e) {
      debugPrint('[LocalGamificationRepository] Error in getUnlockedAchievementIds: $e');
      rethrow;
    }
  }

  @override
  Future<void> unlockAchievement(int userId, String achievementId) async {
    try {
      final db = await _db.database;
      await db.insert(
        'achievements',
        {
          'id': achievementId,
          'user_id': userId,
          'unlocked_at': DateTime.now().millisecondsSinceEpoch,
        },
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );
    } catch (e) {
      debugPrint('[LocalGamificationRepository] Error in unlockAchievement: $e');
      rethrow;
    }
  }

  String _dateString(DateTime dt) =>
      '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
}
